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
        let response = try await session.data(for: request)
        return try Self.parse(response)
    }

    private static func parse(_ resopnse: URLSessionResponse) throws -> Response {
        guard let httpResponse = resopnse.urlResponse as? HTTPURLResponse else {
            throw URLSessionHTTPClient.UnexpectedResponseRepresentation()
        }
        
        return (resopnse.data, httpResponse)
    }
}
