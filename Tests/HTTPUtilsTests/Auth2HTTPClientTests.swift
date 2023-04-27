//
//  Auth2HTTPClientTests.swift
//
//
//  Created by Pawel Klapuch on 4/21/23.
//

import XCTest
import HTTPUtils

final class Auth2HTTPClientTests: XCTestCase {
    
    func test_init_doesNotMessageCollaborators() {
        let (_, gateway, tokenProvider) = makeSUT()
        
        XCTAssertEqual(gateway.messages, [])
        XCTAssertEqual(tokenProvider.messages, [])
    }

    func test_execute_whenFailsToGetToken_deliversError() async throws {
        let request = anyRequest(url: anyURL())
        let getTokenError = anyNSError()
        
        let (sut, gateway, tokenProvider) = makeSUT()
        
        tokenProvider.stubGetToken(.failure(getTokenError))
        
        await expectExecute(expectedResult: .failure(getTokenError), request: request, sut: sut)
        
        XCTAssertEqual(gateway.messages, [])
        XCTAssertEqual(tokenProvider.messages, [.getToken])
    }
    
    func test_execute_forwardsSignedRequestToGateway() async throws {
        let token = uniqueToken()
        let request = anyRequest(url: anyURL())
        
        let (sut, gateway, tokenProvider) = makeSUT()

        tokenProvider.stubGetToken(.success(token))
        gateway.stub(anyHTTPClientFailureResult())
        
        XCTAssertEqual(gateway.messages, [], "precondition failed")
        _ = try? await sut.execute(request: request)
        
        XCTAssertEqual(gateway.messages, [.execute(.wrap(request))])
        assertSignature(gateway: gateway, signature: token.accessToken, at: 0)
    }
    
    func test_execute_whenGatewayFailsWithNonExpiredTokenResponse_deliversError() async throws {
        let token = uniqueToken()
        let request = anyRequest(url: anyURL())
        let gatewayResult = HTTPClient.Result.failure(anyNSError())
        
        let (sut, gateway, tokenProvider) = makeSUT()

        tokenProvider.stubGetToken(.success(token))
        gateway.stub(gatewayResult)
        
        await expectExecute(expectedResult: gatewayResult, request: request, sut: sut)
    }
    
    func test_execute_whenGatewayFailsWithExpiredTokenResponse_triggersRefreshToken() async throws {
        let token = uniqueToken()
        let request = anyRequest(url: anyURL())
        let expiredTokenGatewayResult = httpClientExpiredTokenResponseResult()
        
        let (sut, gateway, tokenProvider) = makeSUT()

        tokenProvider.stubGetToken(.success(token))
        gateway.stub(expiredTokenGatewayResult)
        tokenProvider.stubRefreshToken(.failure(anyNSError()))
        
        _ = try? await sut.execute(request: request)
        XCTAssertEqual(gateway.messages, [.execute(.wrap(request))])
        XCTAssertEqual(tokenProvider.messages, [.getToken, .refresh(token)])
    }

    func test_execute_whenRefreshTokenSucceeds_forwardRetryRequestToNetworkGateway() async throws {
        let token = uniqueToken()
        let newToken = uniqueToken()
        let request = anyRequest(url: anyURL())
        let expiredTokenGatewayResult = httpClientExpiredTokenResponseResult()
        let anyRetryGatewayResult: HTTPClient.Result = .failure(anyNSError())
        
        let (sut, gateway, tokenProvider) = makeSUT()

        tokenProvider.stubGetToken(.success(token))
        gateway.stub(expiredTokenGatewayResult)
        tokenProvider.stubRefreshToken(.success(newToken))
        gateway.stub(anyRetryGatewayResult)
        
        _ = try? await sut.execute(request: request)
        XCTAssertEqual(gateway.messages, [.execute(.wrap(request)), .execute(.wrap(request))])
        XCTAssertEqual(tokenProvider.messages, [.getToken, .refresh(token)])
        assertSignature(gateway: gateway, signature: newToken.accessToken, at: 1)
    }
        
    private func expectExecute(expectedResult: HTTPClient.Result,
                               request: URLRequest,
                               sut: HTTPClient,
                               file: StaticString = #file,
                               line: UInt = #line) async {
        
        var receivedResult: HTTPClient.Result?
        do {
            let response = try await sut.execute(request: request)
            receivedResult = .success(response)
        } catch {
            receivedResult = .failure(error)
        }
        
        guard let receivedResult = receivedResult else {
            XCTFail("expected \(expectedResult), got nothing", file: file, line: line)
            return
        }
        
        switch (receivedResult, expectedResult) {
        case let (.success(receivedResponse), .success(expectedResponse)):
            assertEqual(receivedResponse: receivedResponse, expectedResponse: expectedResponse)
        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            assertEqual(lhs: receivedError, rhs: expectedError)
        default:
            XCTFail("expected \(expectedResult), got \(receivedResult)", file: file, line: line)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: HTTPClient,
                                                                             gateway: HTTPClientSpy,
                                                                             tokenProvider: Auth2TokenProviderSpy) {
        let gateway = HTTPClientSpy()
        let tokenProvider = Auth2TokenProviderSpy()
        
        let sut = Auth2HTTPClient(gateway: gateway, tokenProvider: tokenProvider)
        
        trackForMmeoryLeaks(gateway, file: file, line: line)
        trackForMmeoryLeaks(tokenProvider, file: file, line: line)
        trackForMmeoryLeaks(sut, file: file, line: line)
        
        return (sut, gateway, tokenProvider)
    }

    private func assertSignature(gateway: HTTPClientSpy, signature: String, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let messages = gateway.messages
        
        guard index < messages.count else {
            XCTFail("index (\(index)) is out of bounds (message count: \(messages.count))", file: file, line: line)
            return
        }
        
        switch messages[index] {
        case let .execute(wrappedRequest):
            let requestSignature = wrappedRequest.request.allHTTPHeaderFields?[signatureHeaderName]
            XCTAssertEqual(requestSignature, String(format: signatureValueFormat, signature), file: file, line: line)
        }
    }
}
