//
//  Array+ContainsInAnyOrder.swift
//  
//
//  Created by Pawel Klapuch on 4/26/23.
//

import XCTest

extension Array where Element: Equatable {
    func assertElementEquals(_ element: Element, at index: Int, file: StaticString = #file, line: UInt = #line) {
        guard count > index else {
            XCTFail("invalid index: \(index), count: \(count)", file: file, line: line)
            return
        }
        
        XCTAssertEqual(
            self[index],
            element,
            "expected \(element) at index: \(index), got: \(self)",
            file: file,
            line: line
        )
    }
    
    func assertContainsInAnyOrder(_ elements: [Element], _ range: ClosedRange<Int>, file: StaticString = #file, line: UInt = #line) {
        let rangeIndices = range.map { $0 }
        
        guard !rangeIndices.isEmpty else {
            XCTFail("invalid range: \(range)", file: file, line: line)
            return
        }
        
        let firstIndex = rangeIndices[0]
        let lastIndex = rangeIndices[rangeIndices.count-1]
        
        guard count > lastIndex else {
            XCTFail(
                "range out of bounds: \(range), but collection count: \(count)",
                file: file,
                line: line
            )
            return
        }
    
        let actualElements = self[firstIndex...lastIndex]
        for expectedElement in elements {
            XCTAssertTrue(
                actualElements.contains(expectedElement),
                "actual elements: \(actualElements), does not contain: \(expectedElement)",
                file: file,
                line: line
            )
        }
    }
}
