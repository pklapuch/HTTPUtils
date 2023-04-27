//
//  Auth2TokenStore.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

public protocol Auth2TokenStore {
    func getToken() async throws -> Auth2Token
    func store(token: Auth2Token) async throws
}
