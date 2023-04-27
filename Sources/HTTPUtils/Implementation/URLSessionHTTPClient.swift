//
//  URLSessionNetworkGateway.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private typealias URLSessionResponse = (data: Data, urlResponse: URLResponse)
    private let session: URLSession
    
    public struct UnexpectedResponseRepresentation: Error {
        public init() { }
    }
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func execute(request: URLRequest) async throws -> Response {
        let task = CancellableURLSessionTask(session: session)
        
        return try await withTaskCancellationHandler(operation: {
            let response = try await task.start(request)
            return try Self.parse(response)
        }, onCancel: { [task] in
            task.cancel()
        })
    }

    private static func parse(_ resopnse: URLSessionResponse) throws -> Response {
        guard let httpResponse = resopnse.urlResponse as? HTTPURLResponse else {
            throw URLSessionHTTPClient.UnexpectedResponseRepresentation()
        }
        
        return (resopnse.data, httpResponse)
    }
}

/// `URLSession` wrapper for convenient handling of `cancellation`
///
private final class CancellableURLSessionTask {
    private let session: URLSession
    private var task: Task<(Data, URLResponse), Error>?
    
    init(session: URLSession) {
        self.session = session
    }
    
    func start(_ request: URLRequest) async throws -> (Data, URLResponse) {
        task = Task { () throws -> (Data, URLResponse) in
            return try await session.data(for: request)
        }
        
        return try await task!.value
    }
    
    func cancel() {
        task?.cancel()
    }
}
