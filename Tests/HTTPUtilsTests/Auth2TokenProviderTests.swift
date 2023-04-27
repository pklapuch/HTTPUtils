//
//  Auth2TokenProviderTests.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest
import HTTPUtils

final class Auth2TokenProviderTests: XCTestCase {
    func test_init_doesNotMessageCollaborators() {
        let (_, store, refresh) = makeSUT()

        XCTAssertEqual(store.messages, [])
        XCTAssertEqual(refresh.messages, [])
    }
    
    func test_refresh_whenRefreshFails_deliversRefreshError() async throws {
        let expiredToken = uniqueToken()
        let refreshError = anyNSError()
        let (sut, store, refresh) = makeSUT()
        
        refresh.stubRefreshToken(.failure(refreshError))
        
        let reeivedError = await errorForRefreshToken(expiredToken, sut)
        
        XCTAssertEqual(reeivedError as NSError?, refreshError)
        XCTAssertEqual(refresh.messages, [.refresh(expiredToken)])
        XCTAssertEqual(store.messages, [])
    }
    
    func test_refresh_whenRefreshSucceeds_andStoreFails_deliversStoreError() async throws {
        let expiredToken = uniqueToken()
        let newToken = uniqueToken()
        let storeError = anyNSError()
        let (sut, store, refresh) = makeSUT()
        
        refresh.stubRefreshToken(.success(newToken))
        store.stubStoreToken(.failure(storeError))
        
        let reeivedError = await errorForRefreshToken(expiredToken, sut)
        
        XCTAssertEqual(reeivedError as NSError?, storeError)
        XCTAssertEqual(refresh.messages, [.refresh(expiredToken)])
        XCTAssertEqual(store.messages, [.store(newToken)])
    }
    
    func test_refresh_whenRefreshSucceeds_andStoreTokenSucceeds_deliversNewToken() async throws {
        let expiredToken = uniqueToken()
        let newToken = uniqueToken()
        let (sut, store, refresh) = makeSUT()
        
        refresh.stubRefreshToken(.success(newToken))
        store.stubStoreToken(.success(()))
        store.stubGetToken(.success(newToken))
        
        let receivedToken = try await sut.refresh(token: expiredToken)
        
        XCTAssertEqual(receivedToken, newToken)
        XCTAssertEqual(refresh.messages, [.refresh(expiredToken)])
        XCTAssertEqual(store.messages, [.store(newToken), .getToken])
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: Auth2TokenProvidable, store: Auth2TokenStoreSpy, refresh: Auth2TokenRefreshSpy) {
        let store = Auth2TokenStoreSpy()
        let refresh = Auth2TokenRefreshSpy()
        let sut = Auth2TokenProvider(store: store, refreshService: refresh)
        
        trackForMmeoryLeaks(store)
        trackForMmeoryLeaks(refresh)
        trackForMmeoryLeaks(sut)
        
        return (sut, store, refresh)
    }
    
    private func errorForRefreshToken(_ token: Auth2Token,
                                      _ sut: Auth2TokenProvidable,
                                      file: StaticString = #file,
                                      line: UInt = #line) async -> Error? {
        
        do {
            _ = try await sut.refresh(token: token)
            return nil
        } catch {
            return error
        }
    }
}
