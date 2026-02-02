//
//  XONTests.swift
//  XONTests
//
//  Created by vector on 2024/4/28.
//

import XCTest
@testable import XON

final class XONTests: XCTestCase {
    let tester = XONTestCase()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBase() throws {
        
        
    }

    func testExample() throws {
        try tester.test()
    }
    
    func testBool() throws {
        try tester.testBool()
    }

    func testString() throws {
        try tester.testString()
    }

    func testData() throws {
        try tester.testData()
    }
    
    func testTime() throws {
        try tester.testTime()
    }
        
    func testNumber() throws {
        try tester.testNumber()
    }

    public func testNumbers() throws {
        try tester.testNumbers()
    }
    public func testTimes() throws {
        try tester.testTimes()
    }
    public func testStrings() throws {
        try tester.testStrings()
    }
    public func testStrings1() throws {
        try tester.testStrings1()
    }
    public func testStrings2() throws {
        try tester.testStrings2()
    }

    func testStringNumberArray() throws {
        try tester.testStringNumberArray()
    }
    public func testStringNumberMap() throws {
        try tester.testStringNumberMap()
    }

    public func testRandomedJson() throws {
        try tester.testRandomedJson()
    }
    
    public func testSingleMessages() throws {
        try tester.testSingleMessages()
    }
    public func testMessages() throws {
        try tester.testMessages()
    }
    func testSpeed() throws {
        try tester.testSpeed()
    }

}
