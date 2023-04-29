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
        
    public func execute(request: URLRequest, completion: @escaping (CBHTTPClient.Result) -> Void) {
        session.dataTask(with: request) { data, urlResponse, error in
            completion(Self.parse(data: data, urlResponse: urlResponse, error: error))
        }.resume()
    }
    
    private static func parse(data: Data?, urlResponse: URLResponse?, error: Error?) -> CBHTTPClient.Result {
        if let error = error {
            return .failure(error)
        } else {
            return parse(data: data, urlResponse: urlResponse)
        }
    }

    private static func parse(data: Data?, urlResponse: URLResponse?) -> CBHTTPClient.Result {
        do {
            let response = try HTTPClientResponseUtil.parse((data, urlResponse))
            return .success((response.data, response.httpResponse))
        } catch {
            return .failure(error)
        }
    }
}
