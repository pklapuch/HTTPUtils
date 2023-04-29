//
//  HTTPClientResponseUtil.swift
//  
//
//  Created by Pawel Klapuch on 4/29/23.
//

import Foundation

struct HTTPClientResponseUtil {
    typealias URLSessionResponse = (data: Data?, urlResponse: URLResponse?)
    
    private init() { }
    
    static func parse(_ resopnse: URLSessionResponse) throws -> HTTPClient.Response {
        guard let data = resopnse.data, let urlResponse = resopnse.urlResponse else {
            throw UnexpectedResponseRepresentation()
        }
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw UnexpectedResponseRepresentation()
        }
        
        return (data, httpResponse)
    }
}
