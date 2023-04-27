//
//  SharedTestHelpers.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation
import HTTPUtils

func anyRequest(url: URL = URL(string: "https://any-url.com")!, method: String = "GET") -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method
    return request
}

func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "any", code: 0)
}

func anyData() -> Data {
    return Data("any".utf8)
}

func anyHTTPURLReesponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

func nonHTTPURLResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}

func anyHTTPClientFailureResult() -> HTTPClient.Result {
    return .failure(anyNSError())
}

func anyHTTPClientSuccessResult() -> Result<HTTPClient.Response, Error>! {
    return .success((anyData(), anyHTTPURLReesponse()))
}

func httpClientExpiredTokenResponseResult() -> Result<HTTPClient.Response, Error> {
    let data = Data()
    let response = HTTPURLResponse(url: anyURL(), statusCode: expiredTokenStatusCode, httpVersion: nil, headerFields: nil)!
    return .success((data, response))
}

func uniqueToken() -> Auth2Token {
    return Auth2Token(accessToken: UUID().uuidString, refreshToken: UUID().uuidString)
}

var expiredTokenStatusCode: Int { 401 }
var signatureHeaderName: String { "Authorization" }
var signatureValueFormat: String { "Bearer %@" }
