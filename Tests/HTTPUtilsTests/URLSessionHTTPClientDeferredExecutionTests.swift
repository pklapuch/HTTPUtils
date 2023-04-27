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
        let secondRequest = anyRequest(url: URL(string: "https://secondRequest.com")!)
        let sut = makeSUT()
        
        let firstRequestHitNetworkExp = expectation(description: "wait for first request to hit network")
        let secondRequestHitNetworkExp = expectation(description: "wait for second request to hit network")
        
        URLProtocolWithDeferredCompletionSpy.observeStartLoading { request in
            if request.url == firstRequest.url { firstRequestHitNetworkExp.fulfill() }
            else if request.url == secondRequest.url { secondRequestHitNetworkExp.fulfill() }
        }
        
        var receivedResults = [HTTPClient.Result]()
        let task = Task {
            async let firstResult = await resultForExecute(sut: sut, request: firstRequest)
            async let ssecondResult = await resultForExecute(sut: sut, request: secondRequest)
            return await [firstResult, ssecondResult]
        }
        
        await fulfillment(of: [firstRequestHitNetworkExp, secondRequestHitNetworkExp], timeout: 1.0)
        XCTAssertTrue(receivedResults.isEmpty, "expected that none of the requests completed, but got some results: \(receivedResults)")
        
        task.cancel()
        
        receivedResults = await task.value
        XCTAssertEqual(receivedResults.count, 2)
        XCTAssertEqual(receivedResults.first?.nsError?.code, URLError.cancelled.rawValue)
        XCTAssertEqual(receivedResults.last?.nsError?.code, URLError.cancelled.rawValue)
    }
    
    /// I think this test is redundant - basically there's no way to `free` a `SUT` as long as it's waiting for `await` to complete...
    /// So a stubbed version would do just fine.
    ///
    func test_execute_instanceDoesNotDeallocateUnlessExecuteCompletes() async {
        let request = anyRequest(url: anyURL())
        
        weak var weakSUT: URLSessionHTTPClient?
        let assignSUTToWeakProperty: ((URLSessionHTTPClient?) -> Void)? = { weakSUT = $0 }
        let getWeakSUT: () -> URLSessionHTTPClient? = { return weakSUT }
        
        let taskCompletedExp = expectation(description: "wait for task completion")
        let requestHitNetworkExp = expectation(description: "wait for request to hit network")
        let requestWasCancelledExp = expectation(description: "wait for request cancellation")
        
        Task {
            var sut: URLSessionHTTPClient? = URLSessionHTTPClient()
            assignSUTToWeakProperty?(sut)
            trackForMmeoryLeaks(sut!)
            
            URLProtocolWithDeferredCompletionSpy.observeStartLoading { _ in
                requestHitNetworkExp.fulfill()
            }

            let executeTask = Task { [sut] in
                _ = try await sut!.execute(request: request)
            }
            
            await fulfillment(of: [requestHitNetworkExp], timeout: 1.0)
            executeTask.cancel()
            sut = nil
            
            /// `executeTask` was cancelled -> let's give it a moment and see if it completes...
            ///  This is not ideal, but it works for now
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01, execute: {
                requestWasCancelledExp.fulfill()
            })
            
            XCTAssertNotNil(getWeakSUT(), "expected `sut` to still be around, but it was deallocated")
            await fulfillment(of: [requestWasCancelledExp], timeout: 1.0)
            
            taskCompletedExp.fulfill()
        }

        await fulfillment(of: [taskCompletedExp], timeout: 1.0)
        XCTAssertNil(weakSUT, "expected `sut` to have been deallocated, but it still exists")
    }

    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient(session: .shared)
        trackForMmeoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultForExecute(sut: HTTPClient, request: URLRequest, file: StaticString = #file, line: UInt = #line) async -> HTTPClient.Result {
        do {
            return .success(try await sut.execute(request: request))
        } catch {
            return .failure(error)
        }
    }
}

private extension HTTPClient.Result {
    var nsError: NSError? {
        switch self {
        case let .failure(error as NSError?): return error
        default: return nil
        }
    }
}
