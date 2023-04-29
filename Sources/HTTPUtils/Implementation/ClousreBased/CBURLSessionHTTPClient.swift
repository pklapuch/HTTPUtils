//
//  CBURLSessionHTTPClient.swift
//  
//
//  Created by Pawel Klapuch on 4/29/23.
//

import Foundation

import Foundation

public class CBURLSessionHTTPClient: CBHTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    final class Task: CBHTTPTask {
        private var dataTask: URLSessionDataTask?
        
        init() { }
        
        func set(dataTask: URLSessionDataTask) {
            self.dataTask = dataTask
        }
        
        func resume() {
            dataTask?.resume()
        }
        
        func cancel() {
            dataTask?.cancel()
        }
    }
        
    public func execute(request: URLRequest, completion: @escaping (CBHTTPClient.Result) -> Void) -> CBHTTPTask {
        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
            completion(Self.parse(data: data, urlResponse: urlResponse, error: error))
        }
        
        let wrapper = Task()
        wrapper.set(dataTask: dataTask)
        wrapper.resume()
        return wrapper
    }
    
    private static func parse(data: Data?, urlResponse: URLResponse?, error: Error?) -> CBHTTPClient.Result {
        let result = HTTPClientResponseUtil.parse(data: data, urlResponse: urlResponse, error: error)
        
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error)
        }
    }
}
