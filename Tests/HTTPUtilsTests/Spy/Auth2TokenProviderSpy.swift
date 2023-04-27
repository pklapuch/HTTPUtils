//
//  Auth2TokenProviderSpy.swift
//
//
//  Created by Pawel Klapuch on 4/24/23.
//

import Foundation
import HTTPUtils

final class Auth2TokenProviderSpy: Auth2TokenProvidable {
    
    private var refreshStubs = [Result<Auth2Token, Error>]()
    private var refreshCallCount = 0
    
    private var getTokenStubs = [Result<Auth2Token, Error>]()
    private var getTokenCallCount = 0
    
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        case refresh(Auth2Token)
        case getToken
        case cancelRefreshToken
    }
    
    func stubGetToken(_ result: Result<Auth2Token, Error>) {
        getTokenStubs.append(result)
    }
    
    func stubRefreshToken(_ result: Result<Auth2Token, Error>) {
        refreshStubs.append(result)
    }
    
    func refresh(token: Auth2Token) async throws -> Auth2Token {
        defer { refreshCallCount += 1}
        messages.append(.refresh(token))
        return try refreshStubs[refreshCallCount].get()
    }
    
    func getToken() async throws -> Auth2Token {
        defer { getTokenCallCount += 1}
        messages.append(.getToken)
        return try getTokenStubs[getTokenCallCount].get()
    }
    
    func cancelRefreshToken() async {
        messages.append(.cancelRefreshToken)
    }
}

extension Auth2TokenProviderSpy.Message: CustomStringConvertible {
    var description: String {
        switch self {
        
        case let .refresh(token): return "refresh(\(token.accessToken))"
        case .getToken: return "getToken"
        case .cancelRefreshToken: return "cancelRefreshToken"
        }
    }
}
