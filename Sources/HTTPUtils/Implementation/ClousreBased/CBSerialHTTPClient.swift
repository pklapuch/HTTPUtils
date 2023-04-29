//
//  CBSerialHTTPClient.swift
//  
//
//  Created by Pawel Klapuch on 4/29/23.
//

import Foundation

public class CBSerialHTTPClient: CBHTTPClient {
    private struct RequestOperation {
        let request: URLRequest
        let completion: (HTTPClient.Result) -> Void
    }
    
    private let httpClient: CBHTTPClient
    private var operations = [RequestOperation]()
    private var currentOperation: RequestOperation?
    
    public init(httpClient: CBHTTPClient) {
        self.httpClient = httpClient
    }
    
    public func execute(request: URLRequest, completion: @escaping (CBHTTPClient.Result) -> Void) {
        let operation = RequestOperation(request: request, completion: completion)
        operations.append(operation)
        
        startNextOperationIfIdle()
    }
    
    private func startNextOperationIfIdle() {
        guard currentOperation == nil else { return }
        guard !operations.isEmpty else { return }
        
        startNextOperation()
    }
    
    private func startNextOperation() {
        let operation = operations.removeFirst()
        currentOperation = operation
     
        httpClient.execute(request: operation.request) { [weak self] result in
            self?.currentOperation = nil
            operation.completion(result)
            self?.startNextOperationIfIdle()
        }
    }
}
