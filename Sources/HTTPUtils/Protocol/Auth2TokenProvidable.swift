//
//  Auth2TokenProvidable.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

public protocol Auth2TokenProvidable {
    func refresh(token: Auth2Token) async throws -> Auth2Token
    
    func getToken() async throws -> Auth2Token
    
    func cancelRefreshToken() async
}
