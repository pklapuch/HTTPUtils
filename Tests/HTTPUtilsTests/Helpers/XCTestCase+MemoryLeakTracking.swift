//
//  XCTestCase+MemoryLeakTracking.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest

extension XCTestCase {
    func trackForMmeoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance not freed. Memory leak?", file: file, line: line)
        }
    }
}
