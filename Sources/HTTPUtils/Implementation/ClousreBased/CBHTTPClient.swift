//
//  CBHTTPClient.swift
//  
//
//  Created by Pawel Klapuch on 4/29/23.
//

import Foundation

public protocol CBHTTPClient {
    typealias Response = (data: Data, httpResponse: HTTPURLResponse)
    typealias Result = Swift.Result<Response, Error>
    
    func execute(request: URLRequest, completion: @escaping (CBHTTPClient.Result) -> Void) -> CBHTTPTask
}

public protocol CBHTTPTask {
    func cancel()
}
