import Foundation

/// AUTH2 decorator over `HTTPClient`
///
public actor Auth2HTTPClient: HTTPClient {
    private struct Config {
        static let expiredAccessTokenStatusCode = 401
    }
    
    private let gateway: HTTPClient
    private let tokenProvider: Auth2TokenProvidable
    
    typealias PendingTask = (id: UUID, task: Task<Response, Error>)
    private var gatewayTasks = [PendingTask]()
    
    public init(gateway: HTTPClient, tokenProvider: Auth2TokenProvidable) {
        self.gateway = gateway
        self.tokenProvider = tokenProvider
    }
    
    public func cancelAllRequests() async {
        await tokenProvider.cancelRefreshToken()
        gatewayTasks.forEach { $0.task.cancel() }
    }
    
    public func execute(request: URLRequest) async throws -> Response {
        let token = try await tokenProvider.getToken()
        let response = try await signAndExecute(request: request, withToken: token)
        
        if response.httpResponse.statusCode == Config.expiredAccessTokenStatusCode {
            let newToken = try await tokenProvider.refresh(token: token)
            return try await signAndExecute(request: request, withToken: newToken)
        } else {
            return response
        }
    }
    
    private func signAndExecute(request: URLRequest, withToken token: Auth2Token) async throws -> Response {
        let signedRequest = Auth2RequestUtil.signRequestViaHeaders(request, signature: token.accessToken)
        
        let taskID = UUID()
        let task = Task { () throws -> Response in
            defer { forgetTask(taskID) }
            try Task.checkCancellation()
            
            return try await gateway.execute(request: signedRequest)
        }
        
        gatewayTasks.append((taskID, task))
        
        return try await task.value
    }
    
    private func forgetTask(_ id: UUID) {
        gatewayTasks.removeAll(where: { $0.id == id })
    }
}
