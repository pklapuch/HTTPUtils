//
//  URLProtocolWithDeferredCompletionSpy.swift
//
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

class URLProtocolWithDeferredCompletionSpy: URLProtocol {
    private static var completions = [((Stub) -> Void)]()
    private static var onStartLoading: ((URLRequest) -> Void)?
    
    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(Self.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(Self.self)
        completions.removeAll()
        onStartLoading = nil
    }
    
    static func observeStartLoading(_ block: @escaping (URLRequest) -> Void) {
        Self.onStartLoading = block
    }
    
    static func complete(with stub: Stub, at index: Int = 0) {
        completions[index](stub)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        print("started loading: \(request.url?.absoluteString ?? "--")")
        let completion: (Stub) -> Void = { stub in
            self.completeLoading(with: stub)
        }
        
        Self.completions.append(completion)
        Self.onStartLoading?(request)
    }
    
    private func completeLoading(with stub: Stub) {
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        print("stopped loading: \(request.url?.absoluteString ?? "--")")
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
}
