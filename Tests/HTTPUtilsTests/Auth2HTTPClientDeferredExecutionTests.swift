//
//  Auth2NetworkGatewayDeferredExecutionTests.swift
//
//
//  Created by Pawel Klapuch on 4/25/23.
//

import XCTest
import HTTPUtils

final class Auth2NetworkGatewayDeferredExecutionTests: XCTestCase {
    
    /// Ensure that `execute` is non-blocking (in case where `token` is valid) and different clients can
    /// send requests at the same time. I.e. requests should be executed concurrently when possible.
    ///
    /// Use case:
    /// [0s]: `execute` first request
    /// [0s]: `execute` second request
    /// Wait for both requets to start executing against `URLProtocol loading system`
    /// Then complete both requests
    /// [0.1s] `first request` completes
    /// [0.1s] `second requset` completes
    /// Requests may complete in any order
    ///
    func test_executeTwice_requestsExecuteConcurrently() async throws {
        let token = uniqueToken()

        let firstRequest = anyRequest(url: URL(string: "https://first.com")!)
        let secondRequest = anyRequest(url: URL(string: "https://second.com")!)
        
        let firstRequestHitNetworkExp = expectation(description: "wait for first request to hit network")
        let secondRequestHitNetworkExp = expectation(description: "wait for second request to hit network")
        
        let (sut, gateway, tokenProvider) = makeSUT()
        
        await tokenProvider.observeGetToken { [tokenProvider] index in
            Task { await tokenProvider.completeGetToken(.success(token), at: index) }
        }
        
        await gateway.observeExecute { request, index in
            if request.url == firstRequest.url { firstRequestHitNetworkExp.fulfill() }
            else if request.url == secondRequest.url { secondRequestHitNetworkExp.fulfill() }
        }
        
        Task { _ = try? await sut.execute(request: firstRequest) }
        Task { _ = try? await sut.execute(request: secondRequest) }
        
        await fulfillment(of: [firstRequestHitNetworkExp, secondRequestHitNetworkExp], timeout: 1.0)
        await assertMessagesContain(gateway: gateway, requests: [firstRequest, secondRequest], range: 0...1)
        
        let tokenProviderMessages = await tokenProvider.messages
        XCTAssertEqual(tokenProviderMessages, [.getToken, .getToken])
        
        await gateway.completeExecute(with: .failure(anyNSError()), at: 0)
        await gateway.completeExecute(with: .failure(anyNSError()), at: 1)
                
        await tokenProvider.reset()
    }
    
    /// Use case:
    /// [0s]: `execute` first request
    /// [0.1s] `first request` completes with `token expired response`
    /// [0.2s] `refresh token starts` (due to `first request` failure)
    /// [0.3s]: `execute` second request
    /// Ensure `second request` is queued and does not hit network (becuase `refresh token` is in progress)
    /// [0.4s]: complete `refresh token` operation with success (`new token`)`
    /// Ensure that both `first` and `second` request hit network (in any order) and that both were signed with `new token`
    ///
    func test_execute_whileRefreshTokenIsPending_secondRequestDoesNotReachGatewayUntilRefreshTokenHasCompleted() async throws {
        let token = uniqueToken()
        let newToken = uniqueToken()

        let firstRequest = anyRequest(url: URL(string: "https://first.com")!)
        let secondRequest = anyRequest(url: URL(string: "https://second.com")!)
        let expiredTokenResponseResult = httpClientExpiredTokenResponseResult()
        
        let refreshTokenStartedExp = expectation(description: "wait for refresh token operation to start")
        let firstRequestRetryHitNetworkExp = expectation(description: "wait for first request retry to hit network")
        let secondRequestGetTokenExp = expectation(description: "wait for second request to trigger `getToken` during refresh token")
        let secondRequestHitNetworkExp = expectation(description: "wait for first request retry to hit network")
        let firstExecuteCompletedExp = expectation(description: "wait for completion of first `execute`")
        let secondExecuteCompletedExp = expectation(description: "wait for completion of second `execute`")
        
        let (sut, gateway, tokenProvider) = makeSUT()
        
        await tokenProvider.observeGetToken { [tokenProvider] index in
            if index == 0 { Task { await tokenProvider.completeGetToken(.success(token), at: index) } }
            if index == 1 { secondRequestGetTokenExp.fulfill() }
        }
        
        await tokenProvider.observeRefreshToken { _, _ in refreshTokenStartedExp.fulfill() }
        
        await gateway.observeExecute { [gateway] request, index in
            if index == 0 { Task { await gateway.completeExecute(with: expiredTokenResponseResult, at: index) }}
            else if request.url == firstRequest.url { firstRequestRetryHitNetworkExp.fulfill() }
            else if request.url == secondRequest.url { secondRequestHitNetworkExp.fulfill() }
        }
        
        /// Execute `firstRequest` -> wait until it triggers `refresh token`operation
        Task {
            _ = try? await sut.execute(request: firstRequest)
            firstExecuteCompletedExp.fulfill()
        }
        
        await fulfillment(of: [refreshTokenStartedExp], timeout: 1.0)
        
        /// Execute `secondRequest` -> wait until it triggers `getToken` operation
        Task {
            _ = try? await sut.execute(request: secondRequest)
            secondExecuteCompletedExp.fulfill()
        }
        
        await fulfillment(of: [secondRequestGetTokenExp], timeout: 1.0)
        
        /// At this point, `firstRequest` is waiting for `refreshToken` to complete, while `secondRequset` is waiting for `getToken` to complete
        await assertEqual(gateway: gateway, messages: [.execute(.wrap(firstRequest))])
        await assertEqual(tokenProvider: tokenProvider, messages: [.getToken, .refresh(token), .getToken])
        
        Task {
            /// Resume `secondRequest` from suspension
            await tokenProvider.completeGetToken(.success(newToken), at: 1)
            
            /// Resume `firstRequest` from suspension
            await tokenProvider.completeRefreshToken(.success(newToken))
        }
        
        await fulfillment(of: [firstRequestRetryHitNetworkExp, secondRequestHitNetworkExp])
        
        await gateway.completeExecute(with: .failure(anyNSError()), at: 1)
        await gateway.completeExecute(with: .failure(anyNSError()), at: 2)

        /// Wait for completion of both `execute` commands to ensure all resources are released
        await fulfillment(of: [firstExecuteCompletedExp, secondExecuteCompletedExp])
        await assertSignature(gateway: gateway, signature: newToken.accessToken, at: 1)
        await assertSignature(gateway: gateway, signature: newToken.accessToken, at: 2)
        
        await tokenProvider.reset()
        await gateway.reset()
    }
    
    /// The intent here was to test that we can `nullify` SUT while request has not completed - but this proved wrong.
    /// `await` keeps `SUT` alive until the opreation completes. There's no way to force `deallocation` (all we can do is to `cancel` task and wait for completeion)
    ///
    func test_execute_whenInstanceIsNullified_intanceIsNotDeallocatedUntilRequestCompletes() async {
        weak var weakSUT: Auth2HTTPClient?
        let assignSUTToWeakProperty: ((Auth2HTTPClient?) -> Void)? = { weakSUT = $0 }
        
        let token = uniqueToken()
        let request = anyRequest(url: anyURL())

        let taskCompletedExp = expectation(description: "wait for task completion")
        let requestHitNetworkExp = expectation(description: "wait for request to hit network")
        let gatewayRequestWasCancelledExp = expectation(description: "wait for request cancellation")

        Task {
            let gateway = HTTPClientWithContinuationSpy()
            let tokenProvider = Auth2TokenProviderWithContinuationSpy()
            
            var sut: Auth2HTTPClient? = Auth2HTTPClient(gateway: gateway, tokenProvider: tokenProvider)
            assignSUTToWeakProperty?(sut)

            trackForMmeoryLeaks(gateway)
            trackForMmeoryLeaks(tokenProvider)
            trackForMmeoryLeaks(sut!)
            
            await tokenProvider.observeGetToken { [tokenProvider] _ in
                Task { await tokenProvider.completeGetToken(.success(token)) }
            }
            
            await tokenProvider.observeCancelRefresh { [tokenProvider] _ in
                Task { await tokenProvider.completeCancelRefresh() }
            }

            await gateway.observeExecute { _, _ in
                requestHitNetworkExp.fulfill()
            }
            
            await gateway.observeCancel { _ in
                gatewayRequestWasCancelledExp.fulfill()
            }

            Task { [sut] in
                _ = try await sut!.execute(request: request)
            }
            
            await fulfillment(of: [requestHitNetworkExp], timeout: 1.0)
            await sut!.cancelAllRequests()
            sut = nil
            
            await fulfillment(of: [gatewayRequestWasCancelledExp], timeout: 1.0)
            await gateway.reset()
            await tokenProvider.reset()
            
            taskCompletedExp.fulfill()
        }

        await fulfillment(of: [taskCompletedExp], timeout: 1.0)
        XCTAssertNil(weakSUT, "expected `sut` to have been deallocated, but it still exists")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: HTTPClient,
                                                                             gateway: HTTPClientWithContinuationSpy,
                                                                             tokenProvider: Auth2TokenProviderWithContinuationSpy) {
        let gateway = HTTPClientWithContinuationSpy()
        let tokenProvider = Auth2TokenProviderWithContinuationSpy()

        let sut = Auth2HTTPClient(gateway: gateway, tokenProvider: tokenProvider)

        trackForMmeoryLeaks(gateway, file: file, line: line)
        trackForMmeoryLeaks(tokenProvider, file: file, line: line)
        trackForMmeoryLeaks(sut, file: file, line: line)

        return (sut, gateway, tokenProvider)
    }
    
    private func assertMessagesContain(gateway: HTTPClientWithContinuationSpy,
                                       requests: [URLRequest],
                                       range: ClosedRange<Int>,
                                       file: StaticString = #file,
                                       line: UInt = #line) async {
        
        let eqRequests = requests.map { EQRequest.wrap($0) }
        let expectedMessages: [HTTPClientWithContinuationSpy.Message] = eqRequests.map { .execute($0) }
        
        let receivedMessages = await gateway.messages
        receivedMessages.assertContainsInAnyOrder(expectedMessages, range, file: file, line: line)
    }
  
    private func assertEqual(gateway: HTTPClientWithContinuationSpy,
                             messages: [HTTPClientWithContinuationSpy.Message],
                             file: StaticString = #file,
                             line: UInt = #line) async {
        
        let receivedMessages = await gateway.messages
        XCTAssertEqual(receivedMessages, messages, file: file, line: line)
    }
    
    private func assertEqual(tokenProvider: Auth2TokenProviderWithContinuationSpy,
                             messages: [Auth2TokenProviderWithContinuationSpy.Message],
                             file: StaticString = #file,
                             line: UInt = #line) async {
        
        let receivedMessages = await tokenProvider.messages
        XCTAssertEqual(receivedMessages, messages, file: file, line: line)
    }
    
    private func assertSignature(gateway: HTTPClientWithContinuationSpy,
                                 signature: String,
                                 at index: Int,
                                 file: StaticString = #file,
                                 line: UInt = #line) async {
        let receivedMessages = await gateway.messages
        
        guard index < receivedMessages.count else {
            XCTFail("index (\(index)) is out of bounds (message count: \(receivedMessages.count))", file: file, line: line)
            return
        }
        
        switch receivedMessages[index] {
        case let .execute(wrappedRequest):
            let requestSignature = wrappedRequest.request.allHTTPHeaderFields?[signatureHeaderName]
            XCTAssertEqual(requestSignature, String(format: signatureValueFormat, signature), file: file, line: line)
        }
    }
}
