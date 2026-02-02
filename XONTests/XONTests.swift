//
//  XONTests.swift
//  XONTests
//
//  Created by vector on 2024/4/28.
//

import XCTest
@testable import XON

final class XONTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBase() throws {

        
        
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XONTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XONTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        try testTime()
        
        testNumbers()
        testStrings()
        testStringNumberArray()
        testStringNumberMap()

        testCollection()
        try testRandomedJson()
        try testSpeed()
    }

    func testCCSpeed() {

    }
    
    func testBool() throws {
        try! {
            let data = try XONSerialization.encode(.null)
            assert(data.count == 1 && data[0] == 0, "error")
        } ()

        let data = try XONSerialization.encode(.bool(true))
        let b = try XONSerialization.decode(data)
        assert(try! b.boolValue() == true)

        try! {
            let data = try XONSerialization.encode(.bool(false))
            let b = try XONSerialization.decode(data)
            assert(try! b.boolValue() == false)
        } ()
    }

    func testString() throws {
        try! {
            let data = try XONSerialization.encode(.string(string))
            let b = try XONSerialization.decode(data)
            assert(try! b.stringValue() == string)
        } ()
        try! {
            let data = try XONSerialization.encode(.string(string2))
            let b = try XONSerialization.decode(data)
            assert(try! b.stringValue() == string2)
        } ()
        
        try! {
            var string = ""
            for _ in 1 ... 1000 {
                string += string2
            }
            let data = try XONSerialization.encode(.data(string.data(using: .utf8)!))
            let b = try XONSerialization.decode(data)
            assert(try! b.dataValue() as Data == string.data(using: .utf8)!)
        } ()
    }

    func testData() {
        
    }
    
    func checkTime(microsecond: Int64) throws {
        try autoreleasepool {
            let time = XONTime.time(microsecond: microsecond)
            let value: XONValue = .time(time)
            let number = time.numberValue()
            print(string)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)
            assert(b == value)
            
            guard let time2 = XONTime(number: number) else {
                assert(false)
                return
            }
            assert(time == time2)
        }
    }
    
    func testTime() throws {
        try! {
            print("\(#line)")
            let value: XONValue = .time(XONTime.invalid)
            let data = try XONSerialization.encode(value)
            print("\(#line)")
            let b = try XONSerialization.decode(data)
            print("\(#line)")
            assert(b == value)
        } ()
        try! {
            let value: XONValue = .time(XONTime.min)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)
            assert(b == value)
        } ()
        try! {
            let value: XONValue = .time(XONTime.max)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)
            assert(b == value)
        } ()
        try! {
            let value: XONValue = .time(XONTime.zero)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)
            assert(b == value)
        } ()
        
        try checkTime(microsecond: 2257394757394845625)
        try checkTime(microsecond: 2257394757394845625)

        try checkTime(microsecond: 8432091145)
        try checkTime(microsecond: 9223372036854775800)
        try checkTime(microsecond: -9223372036854775800)

        let values = TestObject.timeArray.map { timeval in
            return XONTestObject(.time(timeval))
        }
        
        testCoder(tag: "Time", objects: values, times: 10)
    }
    
    func testCodeNumber(_ n: NSNumber) {
        let v: XONValue = .number(n)
        let data = try! XONSerialization.encode(v)
        let b = try! XONSerialization.decode(data)
        assert(v == b, "")
    }
    
    func testNumber() throws {
        
        try! {
            let n = Double.nan as NSNumber
            testCodeNumber(n)
        } ()

        try! {
            let n = Double.infinity as NSNumber
            testCodeNumber(n)
        } ()
        try! {
            let n = (-1.0 * Double.infinity) as NSNumber
            testCodeNumber(n)
        } ()
        try! {
            let n = Double.zero as NSNumber
            testCodeNumber(n)
        } ()
        try! {
            let v: UInt64 = 479782221394380
            let n = Double.init(bitPattern: v) as NSNumber
            testCodeNumber(n)
        } ()
        for _ in 0 ..< 10000 {
            // 非规约数
            try! {
                let v = UInt64.random(in: 0 ..< 1 << 52)
                let n = Double.init(bitPattern: v) as NSNumber
                testCodeNumber(n)
            } ()
        }

        try! {
            let n = Int64.max as NSNumber
            testCodeNumber(n)
        } ()
        try! {
            let n = Int64.min as NSNumber
            testCodeNumber(n)
        } ()

        try! {
            let n = UInt64.max as NSNumber
            testCodeNumber(n)
        } ()
        try! {
            let n = UInt64.min as NSNumber
            testCodeNumber(n)
        } ()

        try! {
            let n = Int64.random(in: Int64.min ... Int64.max) as NSNumber
            testCodeNumber(n)
        } ()

        try! {
            // 13128835290283576832 0xB632FE230FF70E00
            // 15164535251138657408 0xD27340773C023C80
            let v: Int64 = -3282208822570894208
            let n = v as NSNumber
            testCodeNumber(n)
        } ()


        try! {
            let bitPattern: UInt64 = 13833650284833841868
            let n = Double(bitPattern: bitPattern) as NSNumber
            do {
                testCodeNumber(n)
            } catch let error {
                print("\(bitPattern)  :  \(n)  \nerror:\(error)")
                abort()
            }
        } ()

        for _ in 0 ..< 10000 {
            try! {
                let bitPattern = UInt64.random(in: UInt64.min ... UInt64.max)
                let n = Double(bitPattern: bitPattern) as NSNumber
                do {
                    testCodeNumber(n)
                } catch let error {
                    print("\(bitPattern)  :  \(n)  \nerror:\(error)")
                    abort()
                }
            } ()
        }
    }

    public func testNumbers() {
        let tag = "Number"
        let values: [XONTestObject] = TestObject.stringNumberElements.map { (_, _, n) in
            return XONTestObject(.number(n))
        }
        testCoder(tag: tag, objects: values, times: 100)
    }
    public func testTimes() {
        let tag = "Time"
        let values: [XONTestObject] = TestObject.timeArray.map { n in
            return XONTestObject(.time(n))
        }
        testCoder(tag: tag, objects: values, times: 100)
    }
    public func testStrings() {
        let tag = "String"
        let values: [XONTestObject] = TestObject.stringNumberElements.map { (_, s, _) in
            return XONTestObject(.string(XONValue.randomString(length: Int.random(in: 0 ... 4096))))
        }
        testCoder(tag: tag, objects: values, times: 100)
    }
    public func testStrings1() {
        let tag = "String"
        let values: [XONTestObject] = TestObject.stringNumberElements.map { (_, s, _) in
            return XONTestObject(.string(XONValue.randomString(length: Int.random(in: 0 ... 4096))))
        }
        testCoder(tag: tag, objects: values, times: 1)
    }
    public func testStrings2() {
        let tag = "String"
        let values: [XONTestObject] = TestObject.stringNumberElements.map { (_, s, _) in
            return XONTestObject(.string(XONValue.randomString(length: Int.random(in: 0 ... 80))))
        }
        testCoder(tag: tag, objects: values, times: 100)
    }
    
    public func testSimpleStrings1() {
        let str = """
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#iLW0Xk<177c4!Nj{aPVM-tp?zH>.[dk4)-'#n4.2%k98+#/-:WK3_Y}PEFHQDL<v4W34Y~Iks}YubrCbz>"KKjbc_Ln/77V9!tQ5a=SkJ$0ABeBG"Z$[00w#L/0s/znXl-C;6^4?IP?a)/gkJ>B}'6/r,u8s$a-pCdG[8T1z"'or7@~UZaLP6U<=f.S:Aul2,KqFZ4zNgU!ye-v)gID,<@jtyBYlkm;}K[joG`G8bVUL_ClaFEiVhDl7,R8z~k!0JnV:zX@}>QX3F)&m#5?z]}Q6>sA|u,yVCj)Xm,l~_:whXZ<y(.-Ec$Y*9f0mQYZ:"&#]?JT9BAJMG*Csw}d53:Q'g{f*XE_c+Vd-G$<<i>6vS_eW6b(]@F`.z:OIk;tan]Aq9n(3M`DJoWvK;B'IYmuIbnqut-h/OBUQTw9m4R_Ufs/~RAgM`qaXK2wJu2Gk"o9ci/]39dn]LL1`$N/9/Tbj/It=O@1yZ<cQOQFroHF<OFU]xJb*7[e*sl5!sm/{N.=V#52$Q-KIMEVl8$~KEeL;<KdM^tfBE~"`Jv0zi3S--#F~i(o'S_,_r6B`k-Pp0qt&AktzNNNКомпьютерыP
"""
        print("\(str.utf8.count)  \(str.data(using: .utf8)?.count)")
        testCoder(tag: "sss", objects: [XONTestObject(.string(str))], times: 1)
    }
    public func testSimpleStrings13() {
        let str = """
                计算机abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef计算机
"""
        print("\(str.count)")
        testCoder(tag: "sss", objects: [XONTestObject(.string(str))], times: 1)
    }

    func testStringNumberArray() {
        let tag = "[String,Number]"
        usleep(1000000)

        let values: [XONTestObject] = TestObject.stringNumberElements.map { (_, s, n) in
            return XONTestObject(.array([.string(s), .number(n)]))
        }
        
        testCoder(tag: tag, objects: values, times: 100)
    }
    public func testStringNumberMap() {
        usleep(1000000)

        let tag = "{string:Number}"

        let values: [XONTestObject] = TestObject.stringNumberElements.map { (s, _, n) in
            var map: [UInt32 : XONValue] = [:]
            map[s] = .number(n)
            return XONTestObject(.message(map))
        }

        testCoder(tag: tag, objects: values, times: 100)
    }

    public func testRandomedJson() throws {
        let tag = "JSON.randomJson"

        let values: [XONTestObject] = (1 ... 100).map { index in
            let result = XONValue.randomMessage(deep: 0, jsonSupport: true)
            return XONTestObject(.message(result))
        }
        usleep(1000000)

        testCoder(tag: tag, objects: values, times: 100, log: false)
    }
    
    public func testSingleMessages() throws {
        let tag = "JSON.randomSingleMessage"
        let values: [XONTestObject] = (1 ... 100).map { index in
            let result = XONValue.randomSingleMessage(jsonSupport: true)
            return XONTestObject(result)
        }
        usleep(1000000)

        testCoder(tag: tag, objects: values, times: 100, log: false)
    }
    public func testMessages() throws {
        let tag = "JSON.randomMessage"

        let values: [XONTestObject] = (1 ... 100).map { index in
            let result = XONValue.randomMessage(deep: 0, jsonSupport: true)
            return XONTestObject(.message(result))
        }
        usleep(1000000)

        testCoder(tag: tag, objects: values, times: 100, log: false)
    }

    
    
    func testSpeed() throws {
        testNumbers()
        testTimes()
        testStrings()
        testStringNumberArray()
        testStringNumberMap()
        
        try testSingleMessages()

        try testMessages()
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}



public struct TestObject {
    public static let stringNumberElements: [(UInt32, String, NSNumber)] = (1 ... 1000).map { index in
        var n = XONValue.randomNumber(jsonSupport: true)
        while n.doubleValue.isNaN {
            n = XONValue.randomNumber(jsonSupport: true)
        }
        let idx = XONValue.randomMessageKey()
        return (idx, XONValue.messageKeyMap[idx]!, n)
    }
    
    public static let timeArray: [XONTime] = (1 ... 1000).map { index in
        if index == 0 {
            return XONTime.invalid
        } else if index == 1 {
            return XONTime.min
        } else if index == 2 {
            return XONTime.max
        } else {
            switch index % 5 {
            case 0:
                return XONTime(microsecond: Int64.random(in: Int64.min ..< Int64.max))
            case 1:
                return XONTime(microsecond: Int64.random(in: Int64.min ..< Int64.max))
            case 2:
                return XONTime(microsecond: Int64.random(in: Int64.min ..< Int64.max))
            case 3:
                return XONTime(microsecond: Int64.random(in: Int64.min ..< Int64.max))
            default:
                return XONTime.time(microsecond: Int64.random(in: Int64.min ..< Int64.max))
            }
        }
    }
    public static let uint63Array: [UInt64] = (1 ... 100000).map { index in
        if index == 0 {
            return 0
        } else if index == 1 {
            return UInt64.max / 2
        } else {
            return UInt64.random(in: 0 ..< UInt64.max / 2)
        }
    }
    public static let uint64Array: [UInt64] = (1 ... 100000).map { index in
        if index == 0 {
            return 0
        } else if index == 1 {
            return UInt64.max
        } else {
            return UInt64.random(in: 0 ..< UInt64.max)
        }
    }
    
}

public class XONTestObject {
    public var xlength: Int = 0
    public var jsonlength: Int = 0

    public let jsonObject: NSObject
    public let xobject: XONValue

    public init(_ value: XONValue) {
        self.jsonObject = value.jsonValue()
        self.xobject = value
    }
}


extension XONValue {
    
    public static let keyCount: Int = 10000
    public static let keys: [(UInt32, String)] = {
        var ids: Set<UInt32> = []
        var strings: Set<String> = []
        var items: [(UInt32, String)] = []
        for _ in 1 ... 10000 {
            var id = UInt32.random(in: 1 ..< 0x10000)
            while ids.contains(id) {
                id = UInt32.random(in: 1 ..< 0x100000)
            }
            var key = XONValue.randomKey()
            while strings.contains(key) {
                key = XONValue.randomKey()
            }
            items.append((id, key))
        }
        return items
    } ()
    
    public static let messageKeyMap: [UInt32 : String] = {
        var items: [UInt32 : String] = [:]
        XONValue.keys.forEach { (mindex, value) in
            items[mindex] = value
        }
        return items
    } ()
    
    
    public func jsonValue() -> NSObject {
        switch self {
        case .null:
            return NSNull()
        case .bool(let v):
            return NSNumber(booleanLiteral: v)
        case .string(let v):
            return v as NSString
        case .data(let v):
            return v.base64EncodedString() as NSString
        case .array(let v):
            return v.map { item in
                return item.jsonValue()
            } as NSArray
        case .number(let v):
            return v
        case .time(let v):
            return v.numberValue()
        case .message(let v):
            let map: NSMutableDictionary = NSMutableDictionary()
            v.forEach { (k, v) in
                map.setObject(v.jsonValue(), forKey: XONValue.messageKeyMap[k]! as NSString)
            }
            return map
        }
    }
    
    public static func randomKey() -> String {
        let len = Int.random(in: 2 ... 12)
        let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
        arc4random_buf(p, len)
        let data = Data(bytes: p, count: len)
        let string = data.base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+-", with: "_")
        p.deallocate()
        return string
    }
    
    public static func random(deep: Int, allowCollection: Bool, jsonSupport: Bool) -> XONValue {
        if deep > 30 {
            return randomSingleValue(jsonSupport: jsonSupport)
        }
        if !allowCollection {
            return randomSingleValue(jsonSupport: jsonSupport)
        }
        // (3/2)e
        let rint = Int.random(in: 0 ... 100)
        switch rint {
        case 0:
            let count = randomLength(50)
            var array: [XONValue] = []
            array.reserveCapacity(count)
            for _ in 0 ..< count {
                array.append(random(deep: deep + 1, allowCollection: allowCollection, jsonSupport: jsonSupport))
            }
            return .array(array)
        case 1:
            return .message(randomMessage(deep: deep, jsonSupport: jsonSupport))
        default:
            return randomSingleValue(jsonSupport: jsonSupport)
        }
    }

    
    public static func random(deep: Int, jsonSupport: Bool) -> XONValue {
        return self.random(deep: deep, allowCollection: true, jsonSupport: jsonSupport)
    }
    
    public static func randomMessageKey() -> UInt32 {
        return XONValue.keys[Int.random(in: 0 ..< 10000)].0
    }
    public static func randomMessage(deep: Int, jsonSupport: Bool) -> [UInt32 : XONValue] {
        let count = randomLength(50)
        var map: [UInt32 : XONValue] = [:]
        for _ in 0 ..< count {
            map[XONValue.keys[Int.random(in: 0 ..< 10000)].0] = random(deep: deep + 1, jsonSupport: jsonSupport)
        }
        return map
    }
    public static func random(jsonSupport: Bool) -> XONValue {
        return random(deep: 0, jsonSupport: jsonSupport)
    }
    
    public static func randomLength(_ max: Int) -> Int {
        if max < 64 {
            return Int.random(in: 0 ... max)
        } else if max < 4096 {
            let n = sqrt(Double(max))
            let up = Int(n.rounded(.up))
            return up * up
        } else {
            let n = sqrt(sqrt(Double(max)))
            let up0 = Int(n.rounded(.down))
            let up1 = up0 + 1
            let qlen0 = Int.random(in: 1 ... up0)
            let qlen1 = Int.random(in: 1 ... up1)
            return qlen0 * qlen0 * qlen1 * qlen1
        }
    }
    
    public static func randomNumber(jsonSupport: Bool) -> NSNumber {
        return _randomNumber(jsonSupport: jsonSupport)
    }
    
    public static func _randomNumber(jsonSupport: Bool) -> NSNumber {
        let numbers: [Double] = [Double.nan, Double.zero, Double.infinity, -1 * Double.infinity]
        let i = Int.random(in: 0 ... 200)
        if i < 4 && !jsonSupport {
            return numbers[i] as NSNumber
        } else {
            let itype = i % 7
            switch itype {
            case 0:
                let n: Int64 = Int64.random(in: Int64.min ... Int64.max)
                return n as NSNumber
            case 1:
                let n: UInt64 = UInt64.random(in: UInt64.min ... UInt64.max)
                return n as NSNumber
            case 2:
                let n: UInt32 = UInt32.random(in: UInt32.min ... UInt32.max)
                return n as NSNumber
            case 3:
                let n: Int32 = Int32.random(in: Int32.min ... Int32.max)
                return n as NSNumber
            case 4:
                let n: UInt16 = UInt16.random(in: UInt16.min ... UInt16.max)
                return n as NSNumber
            case 5:
                let n: Int16 = Int16.random(in: Int16.min ... Int16.max)
                return n as NSNumber
            default:
                let bitPattern = UInt64.random(in: UInt64.min ... UInt64.max)
                var n = Double(bitPattern: bitPattern)
                while n.isNaN || n.isInfinite {
                    let bitPattern = UInt64.random(in: UInt64.min ... UInt64.max)
                    n = Double(bitPattern: bitPattern)
                }
                return n as NSNumber
            }
        }
    }
    
    public static func randomTime() -> XONTime {
        let rint = Int.random(in: 0 ..< 1000)
        switch rint {
        case 0:
            return XONTime.invalid
        case 1:
            return XONTime.min
        case 2:
            return XONTime.max
        case 3:
            return XONTime.zero
        default:
            return XONTime(microsecond: Int64.random(in: Int64.min ... Int64.max))
        }
    }
    public static func randomString(length: Int) -> String {
        let len = length
        let blen = len * 4 / 5
        var data: Data = randomData(length: len * 3 / 5).base64EncodedData(options: [])
        for _ in blen ..< len {
            let i = Int.random(in: 0 ... 1000)
            if i == 0 {
                data.append("计算机".data(using: .utf8)!)
            } else if i == 1 {
                data.append("コンピュータ".data(using: .utf8)!)
            } else if i == 2 {
                data.append("컴퓨터".data(using: .utf8)!)
            } else if i == 3 {
                data.append("Компьютеры".data(using: .utf8)!)
            } else {
                var char = UInt8.random(in: 1 ... 0x7f)
                while isgraph(Int32(char)) == 0 || char == 92 {
                    char = UInt8.random(in: 1 ... 0x7f)
                }
                data.append(contentsOf: [char])
            }
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    public static func randomString(maxLength: Int) -> String {
        let len = randomLength(maxLength)
        return self.randomString(length: len)
    }
    public static func randomData(length: Int) -> Data {
        let p = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: 8)
        arc4random_buf(p, length)
        let data = Data(bytes: p, count: length)
        p.deallocate()
        return data
    }
    public static func randomData(maxLength: Int) -> Data {
        let len = randomLength(maxLength)
        return randomData(length: len)
    }
    public static func randomSingleValue(jsonSupport: Bool) -> XONValue {
        let rint = Int.random(in: 0 ... 444)
        if rint > 400 {
            return .data(randomData(maxLength: 1000))
        }
        
        let type = rint % 10
        switch type {
        case 0:
            return .null
        case 1:
            return .bool(Bool.random())
        case 2:
            return .time(randomTime())
        case 3:
            fallthrough
        case 4:
            fallthrough
        case 5:
            fallthrough
        case 6:
            fallthrough
        case 7:
            return .string(self.randomString(maxLength: 512))
        default:
            return .number(randomNumber(jsonSupport: jsonSupport))
        }
    }
    public static func randomSingleMessage(jsonSupport: Bool) -> XONValue {
        let count = randomLength(50)
        var map: [UInt32 : XONValue] = [:]
        for _ in 0 ..< count {
            map[XONValue.keys[Int.random(in: 0 ..< 10000)].0] = random(deep: 0, allowCollection: false, jsonSupport: jsonSupport)
        }
        return XONValue.message(map)
    }

}


let string: String = "asdfryejfkj"
let string2: String = "()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj"


func randomSingleValueArray(count: Int) -> [XONValue] {
    var array: [XONValue] = []
    array.reserveCapacity(count)
    for _ in 0 ..< count {
        array.append(XONValue.randomSingleValue(jsonSupport: false))
    }
    return array
}

func randomSingleValueMessage(count: Int) -> [UInt32 : XONValue] {
    var map: [UInt32 : XONValue] = [:]
    for _ in 0 ..< count {
        map[UInt32.random(in: 1 ... UInt32.max)] = XONValue.randomSingleValue(jsonSupport: false)
    }
    return map
}

func testCollection() {
    for _ in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XONValue = .array(randomSingleValueArray(count: count))
            let data = try! XONSerialization.encode(value)
            
            let b = try! XONSerialization.decode(data)
            assert(b == value)
        }
    }
    for _ in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XONValue = .message(randomSingleValueMessage(count: count))
            let data = try! XONSerialization.encode(value)
            let b = try! XONSerialization.decode(data)
            if b != value {
                
                abort()
            }
        }
    }
}





func testVarint() {
//    TestObject.uint63Array
//    TestObject.uint64Array
//
//
//    let buffer = XONBuffer(minimumCapacity: 1024 * 10 * 10)
//
//    usleep(1000000)
//
//    TestObject.uint63Array.forEach { _ in
//
//    }
//
//    let int64time = testVarint(buffer: buffer, encode: __XONEncodeUInt64Varint, decode: __XONDecodeUInt64Varint)
//
//    usleep(1000000)
//
//
//    TestObject.uint63Array.forEach { _ in
//
//    }
//    let int63time = testVarint(buffer: buffer, encode: __XONEncodeUInt63Varint, decode: __XONDecodeUInt63Varint)
//
////    let int63time = testVarint(buffer: buffer, encode: __XONEncodeUInt64Varint2, decode: __XONDecodeUInt64Varint)
//
//    print("testVarint: int64time:\(int64time) int63time:\(int63time) fast:\(int64time - int63time)")
    
}

public struct CodeInfo {
    public var encode: CFAbsoluteTime
    public var decode: CFAbsoluteTime
    public var data: Int
    
    public var code: CFAbsoluteTime {
        return encode + decode
    }
    public var codeString: String {
        return CodeInfo.formatter.string(from: self.code as NSNumber) ?? ""
    }
    public var encodeString: String {
        return CodeInfo.formatter.string(from: self.encode as NSNumber) ?? ""
    }
    public var decodeString: String {
        return CodeInfo.formatter.string(from: self.decode as NSNumber) ?? ""
    }
    public var dataString: String {
        var v = self.data
        var string = ""
        if v >= 1024 * 1024 {
            let mb = 1024 * 1024
            string += String(format: "%ld_", v / mb)
            v = v % mb
            string += String(format: "%04ld_", v / 1024)
            v = v % 1024
            string += String(format: "%04ld", v)
        } else if v >= 1024 {
            string += String(format: "%04ld_", v / 1024)
            v = v % 1024
            string += String(format: "%04ld", v)
        } else {
            string += String(format: "%04ld", v)
        }
        return string
    }

    public init(encode: CFAbsoluteTime, decode: CFAbsoluteTime, data: Int) {
        self.encode = encode
        self.decode = decode
        self.data = data
    }
    
    public static let formatter: NumberFormatter = {
        var formater = NumberFormatter()
        formater.usesGroupingSeparator = true
        formater.groupingSize = 6
        formater.groupingSeparator = "_"
        formater.maximumFractionDigits = 7
        return formater
    } ()
    
    public static func + (lhs: CodeInfo, rhs: CodeInfo) -> CodeInfo {
        return CodeInfo(encode: lhs.encode + rhs.encode, decode: lhs.decode + rhs.decode, data: lhs.data + rhs.data)
    }

    public static func - (lhs: CodeInfo, rhs: CodeInfo) -> CodeInfo {
        return CodeInfo(encode: lhs.encode - rhs.encode, decode: lhs.decode - rhs.decode, data: lhs.data - rhs.data)
    }
    
}
public struct Profile : CustomStringConvertible {
    public var tag: String
    public var x: CodeInfo
    public var json: CodeInfo

    public init(tag: String, x: CodeInfo, json: CodeInfo) {
        self.tag = tag
        self.x = x
        self.json = json
    }
    

    public var description: String {
        let delta = self.json - self.x
        
        func scale(_ s: Double) -> String {
            return String(format: "%.01lf%%", s * 100)
        }
        
        var result = ""
        result += "\(tag) x: total: \(x.codeString), encode: \(x.encodeString), decode: \(x.decodeString), data: \(x.dataString)\n"
        result += "\(tag) json: total: \(json.codeString), encode: \(json.encodeString), decode: \(json.decodeString), data: \(json.dataString)\n"
        result += "\(tag) delta: total: \(delta.codeString), encode: \(delta.encodeString), decode: \(delta.decodeString), data: \(delta.dataString)\n"
        result += "\(tag) code speed: \(scale(x.code / json.code)), encode speed: \(scale(x.encode / json.encode)), decode speed: \(scale(x.decode / json.decode)), data: \(scale(Double(x.data) / Double(json.data)))\n"
        return result
    }
    
}

public func testCoder(tag: String, objects: [XONTestObject], times: Int) {
    testCoder(tag: tag, objects: objects, times: times, log: false)
}
func testCoder(tag: String, objects: [XONTestObject], times: Int, log: Bool) {
    var time0: CFAbsoluteTime = 0
    var time0a: CFAbsoluteTime = 0
    var time0b: CFAbsoluteTime = 0
    var dataSum0: Int = 0

    let range = 0 ..< times
    
    range.forEach { i in
        for object in objects {
            autoreleasepool {
                var dataCount: Int = 0
                var datat: Data? = nil
                let value = object.xobject
                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let data = try! XONSerialization.encode(value)
                datat = data
                dataCount = data.count
                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let decoded = try! XONSerialization.decode(data)
                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                
                object.xlength = data.count
                time0 += end - start
                time0a += mtime - start
                time0b += end - mtime
                dataSum0 += data.count
                
                assert(value == decoded)
            }

        }
    }

    usleep(1000000)

    var time1: CFAbsoluteTime = 0
    var time1a: CFAbsoluteTime = 0
    var time1b: CFAbsoluteTime = 0

    var dataSum1: Int = 0
    
    range.forEach { i in
        for obj in objects {
            autoreleasepool {
                let json = obj.jsonObject
                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let data = try! JSONSerialization.encode(json)
                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let object = try! JSONSerialization.decode(data)
                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                
                time1 += end - start
                time1a += mtime - start
                time1b += end - mtime
                dataSum1 += data.count
                obj.jsonlength = data.count

                if i == 1 && log {
                    if let str = String(data: data, encoding: .utf8) {
                        print("\n----- xlen: \(obj.xlength) jlen: \(obj.jsonlength) delta:\(obj.jsonlength - obj.xlength) JSON: \n\(str)")
                    }
                }

                let results = NSMutableArray()
                if !compareJsonObject(lhs: json, rhs: object, results: results) {
                    abort()
                }
                if results.count > 0 {
//                    print("")
//                    print(results)
//                    print("")
                }
            }
        }
    }
    
    let x = CodeInfo(encode: time0a, decode: time0b, data: dataSum0)
    let json = CodeInfo(encode: time1a, decode: time1b, data: dataSum1)

    let profile = Profile(tag: tag, x: x, json: json)
    print(profile)
    
}



func compareDictionary(lhs: NSDictionary, rhs: NSDictionary, results: NSMutableArray) -> Bool {
    guard lhs.count == rhs.count else {
        results.add(NSString(format: "%@ | %@", lhs, rhs))
        return false
    }
    var result = true
    lhs.allKeys.forEach { k in
        let lv = lhs.object(forKey: k)! as! NSObject
        let rv = rhs.object(forKey: k) as! NSObject
        let r = compareJsonObject(lhs: lv, rhs: rv, results: results)
        if !r {
            result = false
        }
    }
    return result
}

func compareArray(lhs: NSArray, rhs: NSArray, results: NSMutableArray) -> Bool {
    guard lhs.count == rhs.count else {
        results.add(NSString(format: "%@ | %@", lhs, rhs))
        return false
    }
    var result = true
    lhs.enumerated().forEach { (index, item) in
        let r = compareJsonObject(lhs: item as! NSObject, rhs: rhs.object(at: index) as! NSObject, results: results)
        if !r {
            result = false
        }
    }
    return result
}

func compareJsonObject(lhs l: Any, rhs r: Any, results: NSMutableArray) -> Bool {
    guard let lhs = l as? NSObject, let rhs = r as? NSObject else {
        results.add("\(l) | (r)" as NSString)
        return false
    }
    
    if !lhs.isEqual(to: rhs) {
        if lhs is NSNumber {
            if let lvd = lhs as? Double, let rvd = rhs as? Double {
                let d = lvd - rvd
                let string = NSString(format: "%.012lf", d)
                results.add(NSString(format: "%@ | %@  [%@]", lhs, rhs, string))
                if d > 0.00000000001 || d < -0.00000000001 {
                    return false
                } else {
                    return true
                }
            }
        } else if lhs is NSString {
            results.add(NSString(format: "%@ | %@", lhs, rhs))
            return false
        } else if let lv = lhs as? NSArray {
            return compareArray(lhs: lv, rhs: rhs as! NSArray, results: results)
        } else if let lv = lhs as? NSDictionary {
            return compareDictionary(lhs: lv, rhs: rhs as! NSDictionary, results: results)
        } else {
            results.add(NSString(format: "%@ | %@", lhs, rhs))
            return false
        }
    }
    return true
}

//for i in 1 ..< 1000 {
//    testVarint()
//}

