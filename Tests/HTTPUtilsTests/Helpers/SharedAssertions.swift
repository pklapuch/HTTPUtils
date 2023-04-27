//
//  SharedAssertions.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest

extension XCTestCase {
    func assertNotNil(_ object: Any?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(object, file: file, line: line)
    }
}
