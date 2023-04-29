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
    
    public func execute(request: URLRequest, completion: @escaping (Result<(data: Data, httpResponse: HTTPURLResponse), Error>) -> Void) {
        queue.async { [weak self] in
            self?.decoratee.execute(request: request) { result in
                self?.queue.async {
                    completion(result)
                }
            }
        }
    }
}
