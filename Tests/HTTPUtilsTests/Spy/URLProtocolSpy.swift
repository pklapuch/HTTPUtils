//
//  URLProtocolSpy.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

class URLProtocolSpy: URLProtocol {
    private static var stub: Stub?
    private(set) static var receivedRequests = [URLRequest]()
    
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        self.stub = Stub(data: data, response: response, error: error)
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(Self.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(Self.self)
        stub = nil
        receivedRequests.removeAll()
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        Self.receivedRequests.append(request)
        
        if let data = URLProtocolSpy.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = URLProtocolSpy.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = URLProtocolSpy.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

