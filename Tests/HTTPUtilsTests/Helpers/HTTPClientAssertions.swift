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
        XCTAssertEqual(receivedResponse.urlResponse.url, expectedResponse.urlResponse.url, file: file, line: line)
        XCTAssertEqual(receivedResponse.urlResponse.statusCode, expectedResponse.urlResponse.statusCode, file: file, line: line)
    }
}
