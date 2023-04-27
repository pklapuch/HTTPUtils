//
//  Auth2Token.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

public struct Auth2Token: Equatable {
    public let accessToken: String
    public let refreshToken: String
    
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

