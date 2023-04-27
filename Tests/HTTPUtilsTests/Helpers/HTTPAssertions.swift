//
//  HTTPAssertions.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest

extension XCTestCase {
    func assertEqual(lhs: HTTPURLResponse?, rhs: HTTPURLResponse?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(lhs?.url, rhs?.url, file: file, line: line)
        XCTAssertEqual(lhs?.statusCode, rhs?.statusCode, file: file, line: line)
    }
}

