import XCTest
import HTTPUtils

final class URLSessionHTTPClientDeferredExecutionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolWithDeferredCompletionSpy.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolWithDeferredCompletionSpy.stopInterceptingRequests()
    }
    
    /// Use case:
    /// [0s]: `execute` first request
    /// [0s]: `execute` second request
    /// Wait for both requets to start executing against `URLProtocol loading system`
    /// Then complete both requests
    /// [0.1s] `first request` completes
    /// [0.1s] `second requset` completes
    /// Requests may complete in any order
    ///
    func test_execute_whenAnotherRequestIsAlreadyExecuting_triggersLatestRequestConcurrently() async {
        let firstRequest = anyRequest(url: URL(string: "https://firstRequest.com")!)
        let secondRequset = anyRequest(url: URL(string: "https://secondRequest.com")!)
        let anyNetworkFailureStub = URLProtocolWithDeferredCompletionSpy.Stub(data: nil, response: nil, error: anyNSError())
        
        let sut = makeSUT()
        
        let firstRequestHitNetworkExp = expectation(description: "wait for first request to hit network")
        let secondRequestHitNetworkExp = expectation(description: "wait for first request to hit network")
        
        URLProtocolWithDeferredCompletionSpy.observeStartLoading { request in
            if request.url == firstRequest.url { firstRequestHitNetworkExp.fulfill() }
            else if request.url == secondRequset.url { secondRequestHitNetworkExp.fulfill() }
        }
        
        let firstRequestCompletedExp = expectation(description: "first request completed")
        let secondRequestCompletedExp = expectation(description: "second request completed")
        
        Task {
            _ = try? await sut.execute(request: firstRequest)
            firstRequestCompletedExp.fulfill()
        }
        
        Task {
            _ = try? await sut.execute(request: secondRequset)
            secondRequestCompletedExp.fulfill()
        }
        
        await fulfillment(of: [firstRequestHitNetworkExp, secondRequestHitNetworkExp], timeout: 1.0)
        
        URLProtocolWithDeferredCompletionSpy.complete(with: anyNetworkFailureStub, at: 0)
        URLProtocolWithDeferredCompletionSpy.complete(with: anyNetworkFailureStub, at: 1)
        
        await fulfillment(of: [firstRequestCompletedExp, secondRequestCompletedExp], timeout: 10.0)
    }

    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient(session: .shared)
        trackForMmeoryLeaks(sut, file: file, line: line)
        return sut
    }
}
