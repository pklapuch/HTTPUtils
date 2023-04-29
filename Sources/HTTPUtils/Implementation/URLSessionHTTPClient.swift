//
//  URLSessionNetworkGateway.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func execute(request: URLRequest) async throws -> Response {
        let response = try await session.data(for: request)
        return try HTTPClientResponseUtil.parse(response)
    }
}
