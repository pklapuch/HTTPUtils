//
//  Auth2TokenProviderWithContinuationSpy.swift
//
//
//  Created by Pawel Klapuch on 4/25/23.
//

import Foundation
import HTTPUtils

final actor Auth2TokenProviderWithContinuationSpy: Auth2TokenProvidable {
    typealias OperationIndex = Int
    
    typealias RefreshTokenContinuation = CheckedContinuation<Auth2Token, Error>
    typealias GetTokenContinuation = CheckedContinuation<Auth2Token, Error>
    typealias CancelRefreshContinuation = CheckedContinuation<Void, Never>
    
    private var refreshTokenContinuations = [RefreshTokenContinuation]()
    private var getTokenContinuations = [GetTokenContinuation]()
    private var cancelRefreshContinuations = [CancelRefreshContinuation]()
    
    private var refreshTokenObserver: ((Auth2Token, OperationIndex) -> Void)?
    private var getTokenObserver: ((OperationIndex) -> Void)?
    private var cancelRefreshObserver: ((OperationIndex) -> Void)?
    
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        case refresh(Auth2Token)
        case getToken
        case cancelRefreshToken
    }

    func observeRefreshToken(_ block: @escaping (Auth2Token, OperationIndex) -> Void) {
        refreshTokenObserver = block
    }
    
    func completeRefreshToken(_ result: Result<Auth2Token, Error>, at index: OperationIndex = 0) {
        refreshTokenContinuations[index].resume(with: result)
    }
    
    func observeGetToken(_ block: @escaping (OperationIndex) -> Void) {
        getTokenObserver = block
    }
    
    func completeGetToken(_ result: Result<Auth2Token, Error>, at index: OperationIndex = 0) {
        getTokenContinuations[index].resume(with: result)
    }
    
    func observeCancelRefresh(_ block: @escaping (OperationIndex) -> Void) {
        cancelRefreshObserver = block
    }
    
    func completeCancelRefresh(at index: OperationIndex = 0) {
        cancelRefreshContinuations[index].resume(with: .success(()))
    }
    
    func refresh(token: Auth2Token) async throws -> Auth2Token {
        messages.append(.refresh(token))
        
        return try await withCheckedThrowingContinuation { continuation in
            refreshTokenContinuations.append(continuation)
            refreshTokenObserver?(token, refreshTokenContinuations.count - 1)
        }
    }
    
    func getToken() async throws -> Auth2Token {
        messages.append(.getToken)
        
        return try await withCheckedThrowingContinuation { continuation in
            getTokenContinuations.append(continuation)
            getTokenObserver?(getTokenContinuations.count - 1)
        }
    }
    
    func cancelRefreshToken() async {
        messages.append(.cancelRefreshToken)
        
        return await withCheckedContinuation { continuation in
            cancelRefreshContinuations.append(continuation)
            cancelRefreshObserver?(cancelRefreshContinuations.count - 1)
        }
    }
    
    func reset() {
        messages.removeAll()
        refreshTokenContinuations.removeAll()
        refreshTokenObserver = nil
        getTokenContinuations.removeAll()
        getTokenObserver = nil
        cancelRefreshContinuations.removeAll()
        cancelRefreshObserver = nil
    }
}

extension Auth2TokenProviderWithContinuationSpy.Message: CustomStringConvertible {
    var description: String {
        switch self {
        
        case let .refresh(token): return "refresh(\(token.accessToken))"
        case .getToken: return "getToken"
        case .cancelRefreshToken: return "cancelRefreshToken"
        }
    }
}
