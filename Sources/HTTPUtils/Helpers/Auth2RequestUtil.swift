//
//  Auth2RequestUtil.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

struct Auth2RequestUtil {
    private static let signatureHeaderName = "Authorization"
    private static let signatureValueFormat = "Bearer %@"
    
    static func signRequestViaHeaders(_ request: URLRequest, signature: String) -> URLRequest {
        var allHeaders = request.allHTTPHeaderFields ?? [:]
        allHeaders[signatureHeaderName] = String(format: signatureValueFormat, signature)
        
        var signedRequest = request
        signedRequest.allHTTPHeaderFields = allHeaders
        
        return signedRequest
    }
}
