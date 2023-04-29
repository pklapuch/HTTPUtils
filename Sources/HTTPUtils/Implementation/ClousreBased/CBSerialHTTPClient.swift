//
//  CBSerialHTTPClient.swift
//  
//
//  Created by Pawel Klapuch on 4/29/23.
//

import Foundation

public class CBSerialHTTPClient: CBHTTPClient {
    private final class RequestOperation: CBHTTPTask {
        let uuid: UUID
        let request: URLRequest
        let completion: (HTTPClient.Result) -> Void
        
        var cancelled = false
        private var onCancelled: (() -> Void)?
        
        init(uuid: UUID,
             request: URLRequest,
             completion: @escaping (Result<(data: Data, httpResponse: HTTPURLResponse), Error>) -> Void) {
            self.uuid = uuid
            self.request = request
            self.completion = completion
        }
        
        func set(onCancelled: @escaping () -> Void) {
            self.onCancelled = onCancelled
        }
        
        func cancel() {
            cancelled = true
            onCancelled?()
        }
    }

    private let httpClient: CBHTTPClient
    private var operations = [RequestOperation]()
    private var currentOperation: RequestOperation?
    
    public init(httpClient: CBHTTPClient) {
        self.httpClient = httpClient
    }
    
    public func execute(request: URLRequest, completion: @escaping (CBHTTPClient.Result) -> Void) -> CBHTTPTask {
        let uuid = UUID()
        let operation = RequestOperation(uuid: uuid, request: request, completion: completion)
        
        operations.append(operation)
        startNextOperationIfIdle()
        
        return operation
    }
    
    private func startNextOperationIfIdle() {
        guard currentOperation == nil else { return }
        guard !operations.isEmpty else { return }
        
        startNextOperation()
    }
    
    private func startNextOperation() {
        let operation = operations.removeFirst()
        
        if operation.cancelled {
            operation.completion(.failure(NSError(domain: URLError.errorDomain, code: URLError.cancelled.rawValue)))
            startNextOperationIfIdle()
            return
        }
        
        currentOperation = operation
     
        let httpTask = httpClient.execute(request: operation.request) { [weak self] result in
            self?.currentOperation = nil
            operation.completion(result)
            self?.startNextOperationIfIdle()
        }
        
        operation.set(onCancelled: {
            httpTask.cancel()
        })
    }
}
