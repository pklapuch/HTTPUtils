import Foundation

public actor Auth2TokenProvider: Auth2TokenProvidable {
    private let store: Auth2TokenStore
    private let refreshService: Auth2TokenRefreshable
    
    private var refreshTask: Task<Void, Error>?
    
    public init(store: Auth2TokenStore, refreshService: Auth2TokenRefreshable) {
        self.store = store
        self.refreshService = refreshService
    }
    
    /// NOTE: Upon consideration  - we probably don't need to pass `token` to this method - provider can get it directly from store.
    /// TODO: fix later
    public func refresh(token: Auth2Token) async throws -> Auth2Token {
        try await refreshToken(token)
        return try await getToken()
    }
    
    public func getToken() async throws -> Auth2Token {
        return try await getCurrentToken()
    }
    
    public func cancelRefreshToken() {
        refreshTask?.cancel()
    }
    
    private func getCurrentToken() async throws -> Auth2Token {
        if let task = refreshTask {
            _ = try await task.value
            return try await store.getToken()
        }
        
        return try await store.getToken()
    }
    
    private func refreshToken(_ token: Auth2Token) async throws {
        let task = Task { () throws -> Void in
            defer { refreshTask = nil }
            try Task.checkCancellation()
            
            let newToken = try await refreshService.refresh(token: token)
            try await store.store(token: newToken)
        }
        
        refreshTask = task
        try await task.value
    }
}
