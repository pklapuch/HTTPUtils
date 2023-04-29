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
        let wrapper = TaskWrapper()
        
        return try await withTaskCancellationHandler(operation: {
            return try await withCheckedThrowingContinuation { continuation in
                let task = adaptee.execute(request: request) { result in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: (response.data, response.httpResponse))
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
                
                wrapper.set(task: task)
            }
        }, onCancel: {
            wrapper.cancel()
        })
    }
    
    private final class TaskWrapper {
        private var task: CBHTTPTask?
        
        func set(task: CBHTTPTask) {
            self.task = task
        }
        
        func cancel() {
            task?.cancel()
        }
    }
}
