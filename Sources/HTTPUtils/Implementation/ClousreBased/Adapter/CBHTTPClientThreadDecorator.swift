//
//  CBHTTPClientThreadDecorator.swift
//  
//
//  Created by Pawel Klapuch on 4/29/23.
//

import Foundation

public final class CBHTTPClientThreadDecorator: CBHTTPClient {
    private let decoratee: CBHTTPClient
    private let queue: DispatchQueue
    
    public init(decoratee: CBHTTPClient, queue: DispatchQueue) {
        self.decoratee = decoratee
        self.queue = queue
    }
    
    public func execute(request: URLRequest, completion: @escaping (Result<(data: Data, httpResponse: HTTPURLResponse), Error>) -> Void) -> CBHTTPTask {
        let wrapper = TaskWrapper()
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            guard !wrapper.cancelled else {
                completion(.failure(NSError(domain: URLError.errorDomain, code: URLError.cancelled.rawValue)))
                return
            }
            
            let task = self.decoratee.execute(request: request) { result in
                self.queue.async {
                    completion(result)
                }
            }
            wrapper.set(task: task)
        }
        
        return wrapper
    }
    
    private final class TaskWrapper: CBHTTPTask {
        var cancelled = false
        private var task: CBHTTPTask?
        
        func set(task: CBHTTPTask) {
            self.task = task
        }
        
        func cancel() {
            cancelled = true
            task?.cancel()
        }
    }
}
