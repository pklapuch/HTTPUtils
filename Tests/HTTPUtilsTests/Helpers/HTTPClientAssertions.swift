//
//  HTTPClientAssertions.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest
import HTTPUtils

extension XCTestCase {
    func assertEqual(receivedResponse: HTTPClient.Response,
                     expectedResponse: HTTPClient.Response,
                     file: StaticString = #file,
                     line: UInt = #line) {
        XCTAssertEqual(receivedResponse.data, expectedResponse.data, file: file, line: line)
        XCTAssertEqual(receivedResponse.httpResponse.url, expectedResponse.httpResponse.url, file: file, line: line)
        XCTAssertEqual(receivedResponse.httpResponse.statusCode, expectedResponse.httpResponse.statusCode, file: file, line: line)
    }
}
