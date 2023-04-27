//
//  HTTPClient.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

public protocol HTTPClient {
    typealias Response = (data: Data, urlResponse: HTTPURLResponse)
    typealias Result = Swift.Result<Response, Error>
    
    func execute(request: URLRequest) async throws -> Response
}
