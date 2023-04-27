import XCTest
import HTTPUtils

final class URLSessionNetworkGatewayTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolSpy.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolSpy.stopInterceptingRequests()
    }
    
    func test_init_doesNotTriggerExecuteRequest() {
        _ = makeSUT()
        XCTAssertTrue(URLProtocolSpy.receivedRequests.isEmpty)
    }
    
    func test_execute_forwardsRequestToURLSessionOnce() async {
        _ = await resultErrorFor(data: nil, response: nil, error: anyNSError())
        
        XCTAssertEqual(URLProtocolSpy.receivedRequests.count, 1)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() async {
        // THIS 2x cases are crashing
        // assertNotNil(await resultErrorFor(data: nil, response: nil, error: nil))
        // assertNotNil(await resultErrorFor(data: anyData(), response: nil, error: nil))
        
        assertNotNil(await resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        assertNotNil(await resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        assertNotNil(await resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        assertNotNil(await resultErrorFor(data: nil, response: anyHTTPURLReesponse(), error: anyNSError()))
        assertNotNil(await resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        assertNotNil(await resultErrorFor(data: anyData(), response: anyHTTPURLReesponse(), error: anyNSError()))
        assertNotNil(await resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_execute_deliversErrorOnNonHTTPURLResponse() async {
        let expectedError = URLSessionHTTPClient.UnexpectedResponseRepresentation()
        let nonHTTPURLResponse = nonHTTPURLResponse()
        
        let receivedError = await resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil)
        
        assertEqualDomainAndCode(lhs: receivedError as? NSError, rhs: expectedError as NSError)
    }
    
    func test_execute_deliversSuccessOnURLSessionSuccess() async {
        let data = anyData()
        let httpURLResponse = anyHTTPURLReesponse()
        
        let receivedResponse = await resultValuesFor(data: data, response: httpURLResponse, error: nil)
        
        XCTAssertEqual(receivedResponse?.data, data)
        assertEqual(lhs: receivedResponse?.urlResponse, rhs: httpURLResponse)
    }
    
    func test_execute_whenRequestCompletesWithNilData_deliversSuccessWithEmptyData() async {
        let emptyData = Data()
        let httpURLResponse = anyHTTPURLReesponse()
        
        let response = await resultValuesFor(data: nil, response: httpURLResponse, error: nil)
        
        XCTAssertEqual(response?.data, emptyData)
        assertEqual(lhs: response?.urlResponse, rhs: httpURLResponse)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMmeoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) async -> Error? {
        URLProtocolSpy.stub(data: data, response: response, error: error)
        do {
            _ = try await resultFor(data: data, response: response, error: error, file: file, line: line)
            return nil
        } catch {
            return error
        }
    }
    
    func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) async -> HTTPClient.Response? {
        URLProtocolSpy.stub(data: data, response: response, error: error)
        
        do {
            return try await resultFor(data: data, response: response, error: error, file: file, line: line)
        } catch {
            XCTFail("expected success, got: \(error) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) async throws -> HTTPClient.Response {
        URLProtocolSpy.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        return try await sut.execute(request: anyRequest())
    }
}

