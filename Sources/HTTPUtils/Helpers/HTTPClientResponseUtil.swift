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
    
    static func parse(data: Data?, urlResponse: URLResponse?, error: Error?) -> HTTPClient.Result {
        if let error = error {
            return .failure(error)
        } else if let data = data, let urlResponse = urlResponse {
            return parse((data, urlResponse))
        } else {
            return .failure(UnexpectedResponseRepresentation())
        }
    }
    
    private static func parse(_ resopnse: URLSessionResponse) -> HTTPClient.Result {
        do {
            let parsedResponse = try parse(rawResponse: resopnse)
            return .success(parsedResponse)
        } catch {
            return .failure(error)
        }
    }
    
    static func parse(rawResponse response: URLSessionResponse) throws -> HTTPClient.Response {
        guard let data = response.data, let urlResponse = response.urlResponse else {
            throw UnexpectedResponseRepresentation()
        }
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw UnexpectedResponseRepresentation()
        }
        
        return (data, httpResponse)
    }
}
