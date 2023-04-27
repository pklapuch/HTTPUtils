//
//  ErrorAssertions.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest

extension XCTestCase {
    func assertEqual(lhs: NSError?, rhs: NSError?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(lhs?.domain, rhs?.domain, file: file, line: line)
        XCTAssertEqual(lhs?.code, rhs?.code, file: file, line: line)
    }
    
    func assertEqualDomainAndCode(lhs: NSError?, rhs: NSError?, file: StaticString = #file, line: UInt = #line) {
        guard lhs != nil && rhs != nil else { return }
        
        XCTAssertEqual(lhs?.domain, rhs?.domain, file: file, line: line)
        XCTAssertEqual(lhs?.code, rhs?.code, file: file, line: line)
    }
}

