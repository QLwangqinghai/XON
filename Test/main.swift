//
//  main.swift
//  Test
//
//  Created by vector on 2025/8/8.
//

import Foundation
@testable import CX
import XON

//let xobj = XONTestObject(XONValue.string("vedaHciS965O55c=/u@!"))
//testCoder(tag: "", objects: [xobj], times: 100)

let xobj1 = XONTestObject(XONValue.array([XONValue.string("rFFd3y17x88"), XONValue.number(NSNumber(value: 1580253625))]))
testCoder(tag: "", objects: [xobj1], times: 100)


let tester = XONTestCase()
for _ in 0 ... 4 {
    try! tester.test()
}
