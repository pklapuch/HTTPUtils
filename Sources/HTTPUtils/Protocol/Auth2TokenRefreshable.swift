//
//  Auth2TokenRefreshable.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation

public protocol Auth2TokenRefreshable {
    func refresh(token: Auth2Token) async throws -> Auth2Token
}
