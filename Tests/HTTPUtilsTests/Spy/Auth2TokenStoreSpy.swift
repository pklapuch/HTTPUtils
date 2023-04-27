import Foundation
import HTTPUtils

final class Auth2TokenStoreSpy: Auth2TokenStore {
    private var getTokenStubs = [Result<Auth2Token, Error>]()
    private var getTokenCallCount = 0
    
    private var storeTokenStubs = [Result<Void, Error>]()
    private var storeTokenCallCount = 0
    
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        case getToken
        case store(Auth2Token)
    }
    
    func stubGetToken(_ result: Result<Auth2Token, Error>) {
        getTokenStubs.append(result)
    }
    
    func stubStoreToken(_ result: Result<Void, Error>) {
        storeTokenStubs.append(result)
    }
    
    func getToken() async throws -> Auth2Token {
        defer { getTokenCallCount += 1 }
        messages.append(.getToken)
        return try getTokenStubs[getTokenCallCount].get()
    }

    func store(token: Auth2Token) async throws {
        defer { storeTokenCallCount += 1}
        messages.append(.store(token))
        
        switch storeTokenStubs[storeTokenCallCount] {
        case let .failure(error):
            throw error
        default:
            break
        }
    }
}

extension Auth2TokenStoreSpy.Message: CustomStringConvertible {
    var description: String {
        switch self {
        case .getToken: return "getToken"
        case let .store(token): return "store(\(token.accessToken))"
        }
    }
}
