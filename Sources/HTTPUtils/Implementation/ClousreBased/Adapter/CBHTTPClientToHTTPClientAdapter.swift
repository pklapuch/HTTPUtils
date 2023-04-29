//
//  CBHTTPClientToHTTPClientAdapter.swift
//  
//
//  Created by Pawel Klapuch on 4/29/23.
//

import Foundation

public final class CBHTTPClientToHTTPClientAdapter: HTTPClient {
    private let adaptee: CBHTTPClient
    
    public init(adaptee: CBHTTPClient) {
        self.adaptee = adaptee
    }
    
    public func execute(request: URLRequest) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            adaptee.execute(request: request) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: (response.data, response.httpResponse))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
