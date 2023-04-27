//
//  Auth2TokenRefreshSpy.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import Foundation
import HTTPUtils

final class Auth2TokenRefreshSpy: Auth2TokenRefreshable {
    private var refreshTokenStubs = [Result<Auth2Token, Error>]()
    private var refreshTokenCallCount = 0
    
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        case refresh(Auth2Token)
    }
    
    func stubRefreshToken(_ result: Result<Auth2Token, Error>) {
        refreshTokenStubs.append(result)
    }
    
    func refresh(token: Auth2Token) async throws -> Auth2Token {
        defer { refreshTokenCallCount += 1 }
        messages.append(.refresh(token))
        return try refreshTokenStubs[refreshTokenCallCount].get()
    }
}

extension Auth2TokenRefreshSpy.Message: CustomStringConvertible {
    var description: String {
        switch self {
        case let .refresh(token): return "refresh(\(token.accessToken))"
        }
    }
}
