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

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        
        testNumbers()
        testStrings()
        testStringNumberArray()
        testStringNumberMap()

        testCollection()
        try testRandomedJson()
        
    }

    
    func testBool() throws {
        try! {
            let data = try XONSerialization.encode(.null)
            assert(data.count == 1 && data[0] == 0, "error")
        } ()

        let data = try XONSerialization.encode(.bool(true))
        let b = try XONSerialization.decode(data)!
        assert(try! b.boolValue() == true)

        try! {
            let data = try XONSerialization.encode(.bool(false))
            let b = try XONSerialization.decode(data)!
            assert(try! b.boolValue() == false)
        } ()
    }

    func testString() throws {
        try! {
            let data = try XONSerialization.encode(.string(string))
            let b = try XONSerialization.decode(data)!
            assert(try! b.stringValue() == string)
        } ()
        try! {
            let data = try XONSerialization.encode(.string(string2))
            let b = try XONSerialization.decode(data)!
            assert(try! b.stringValue() == string2)
        } ()
        
        try! {
            var string = ""
            for _ in 1 ... 1000 {
                string += string2
            }
            let data = try XONSerialization.encode(.data(string.data(using: .utf8)!))
            let b = try XONSerialization.decode(data)!
            assert(try! b.dataValue() as Data == string.data(using: .utf8)!)
        } ()
    }

    func testData() {
        
    }
    
    func testTime() throws {
        try! {
            let value: XONValue = .time(XONTime.invalid)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)!
            assert(b == value)
        } ()
        try! {
            let value: XONValue = .time(XONTime.distantPast)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)!
            assert(b == value)
        } ()
        try! {
            let value: XONValue = .time(XONTime.distantFuture)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)!
            assert(b == value)
        } ()
        try! {
            let value: XONValue = .time(XONTime.zero)
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)!
            assert(b == value)
        } ()
        
        try autoreleasepool {
            let value: XONValue = .time(XONTime.time(second: 2257394757394845625, attosecond: 0))
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)!
            assert(b == value)
        }
        
        try autoreleasepool {
            let value: XONValue = .time(XONTime.time(second: 2257394757394845625, attosecond: 0))
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)!
            assert(b == value)
        }
        
        try autoreleasepool {
            let value: XONValue = .time(XONTime.time(second: 8432091145, attosecond: 575167568000000000))
            let data = try XONSerialization.encode(value)
            let b = try XONSerialization.decode(data)!
            assert(b == value)
        }
        
        let values = TestObject.timeArray.map { timeval in
            return XCTestObject(.time(timeval))
        }
        
        testCoder(tag: "Time", objects: values, times: 10)
    }
    
    func testCodeNumber(_ n: NSNumber) {
        let v: XONValue = .number(n)
        let data = try! XONSerialization.encode(v)
        let b = try! XONSerialization.decode(data)!
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
        let values: [XCTestObject] = TestObject.stringNumberElements.map { (_, _, n) in
            return XCTestObject(.number(n))
        }
        testCoder(tag: tag, objects: values, times: 100)
    }

    public func testStrings() {
        let tag = "String"
        let values: [XCTestObject] = TestObject.stringNumberElements.map { (_, s, _) in
            return XCTestObject(.string(s))
        }
        testCoder(tag: tag, objects: values, times: 100)
    }

    func testStringNumberArray() {
        let tag = "[String,Number]"
        usleep(1000000)

        let values: [XCTestObject] = TestObject.stringNumberElements.map { (_, s, n) in
            return XCTestObject(.array([.string(s), .number(n)]))
        }
        
        testCoder(tag: tag, objects: values, times: 100)
    }
    public func testStringNumberMap() {
        usleep(1000000)

        let tag = "{string:Number}"

        //let tag = "JSON.random"

        let values: [XCTestObject] = TestObject.stringNumberElements.map { (s, _, n) in
            var map: [UInt32 : XONValue] = [:]
            map[s] = .number(n)
            return XCTestObject(.message(Message<XONValue>(type: Int64.random(in: 1 ..< Int64.max), collection: map)))
        }

        testCoder(tag: tag, objects: values, times: 100)
    }

    public func testRandomedJson() throws {
        let tag = "JSON.random"

        let values: [XCTestObject] = (1 ... 100).map { index in
            let result = XONValue.randomMessage(deep: 0, jsonSupport: true)
            return XCTestObject(.message(result))
        }
        usleep(1000000)

        testCoder(tag: tag, objects: values, times: 100)
    }

    func testMessage() throws {
        var map: [UInt32 : XONValue] = [:]
        let n: UInt64 = 15177217206540917685
        map[4132148881] = .number(n as NSNumber)
        let message = Message<XONValue>(type: 1165060215785297051, collection: map)
        
        let value: XONValue = .message(message)
        let data = try! XONSerialization.encode(value)
        let decoded = try! XONSerialization.decode(data)!
        
    }
    
    
    func testSpeed() throws {
        testNumbers()
        testStrings()
        testStringNumberArray()
        testStringNumberMap()
        try testRandomedJson()
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
    
    public static let timeArray: [XONTime] = (1 ... 100000).map { index in
        if index == 0 {
            return XONTime.invalid
        } else if index == 1 {
            return XONTime.distantPast
        } else if index == 2 {
            return XONTime.distantFuture
        } else {
            switch index % 5 {
            case 0:
                return XONTime(second: Int64.random(in: Int64.min ..< Int64.max))
            case 1:
                return XONTime(nanosecond: Int64.random(in: Int64.min ..< Int64.max))
            case 2:
                return XONTime(millisecond: Int64.random(in: Int64.min ..< Int64.max))
            case 3:
                return XONTime(microsecond: Int64.random(in: Int64.min ..< Int64.max))
            default:
                return XONTime.time(second: Int64.random(in: Int64.min ..< Int64.max), attosecond: UInt64.random(in: 0 ..< XONTime.attosecondPerSecond))
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

public class XCTestObject {
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
            var id = UInt32.random(in: 1 ..< UInt32.max)
            while ids.contains(id) {
                id = UInt32.random(in: 1 ..< UInt32.max)
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
            return v.encodeToJsonString() as NSString
        case .message(let v):
            let map: NSMutableDictionary = NSMutableDictionary()
            v.collection.forEach { (k, v) in
                map.setObject(v.jsonValue(), forKey: XONValue.messageKeyMap[k]! as NSString)
            }
            return map
        }
    }
    
    public static func randomKey() -> String {
        let len = Int.random(in: 1 ... 32)
        let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
        arc4random_buf(p, len)
        let data = Data(bytes: p, count: len)
        let string = data.base64EncodedString().replacingOccurrences(of: "=", with: "")
        p.deallocate()
        return string
    }
    
    public static func random(deep: Int, jsonSupport: Bool) -> XONValue {
        if deep > 30 {
            return randomSingleValue(jsonSupport: jsonSupport)
        }
        // (3/2)e
        let rint = Int.random(in: 0 ... (50 + 50 * deep))
        switch rint {
        case 0:
            let count = randomLength(50)
            var array: [XONValue] = []
            array.reserveCapacity(count)
            for _ in 0 ..< count {
                array.append(random(deep: deep + 1, jsonSupport: jsonSupport))
            }
            return .array(array)
        case 1:
            return .message(randomMessage(deep: deep, jsonSupport: jsonSupport))
        default:
            return randomSingleValue(jsonSupport: jsonSupport)
        }
    }
    
    public static func randomMessageKey() -> UInt32 {
        return XONValue.keys[Int.random(in: 0 ..< 10000)].0
    }
    public static func randomMessage(deep: Int, jsonSupport: Bool) -> Message<XONValue> {
        let count = randomLength(50)
        var map: [UInt32 : XONValue] = [:]
        for _ in 0 ..< count {
            map[XONValue.keys[Int.random(in: 0 ..< 10000)].0] = random(deep: deep + 1, jsonSupport: jsonSupport)
        }
        let message = Message(type: Int64.random(in: 0 ... Int64.max), collection: map)
        return message
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
            return XONTime.distantPast
        case 2:
            return XONTime.distantPast
        case 3:
            return XONTime.zero
        default:
            return XONTime(second: Int64.random(in: Int64.min ... Int64.max))
        }
    }
    
    public static func randomString(maxLength: Int) -> String {
        var string = ""
        let len = randomLength(maxLength)
        let p = UnsafeMutableRawPointer.allocate(byteCount: len * 2, alignment: 8)
        arc4random_buf(p, len)
        let uint16p = p.bindMemory(to: UInt16.self, capacity: len)
        for i in 0 ..< len {
            let u = uint16p.advanced(by: i).pointee
            string += String(UTF32Char(u == 0 ? 1 : u))
        }
        p.deallocate()
        return string
    }
    
    public static func randomSingleValue(jsonSupport: Bool) -> XONValue {
        let type = Int.random(in: 0 ... 49)
        switch type {
        case 0:
            return .string(self.randomString(maxLength: 7000))
        case 1:
            let len = randomLength(4000000)
            let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
            arc4random_buf(p, len)
            let data = Data(bytes: p, count: len)
            p.deallocate()
            return .data(data)
        default:
            switch (type - 2) % 6 {
            case 0:
                return .null
            case 1:
                return .bool(Bool.random())
            case 2:
                return .time(randomTime())
            default:
                return .number(randomNumber(jsonSupport: jsonSupport))
            }
        }
    }
    
}


let string: String = "asdfryejfkj"
let string2: String = "()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj"




//try! {
//    let data = try XONSerialization.encode(value: .data(string.data(using: .utf8)!))
//    let b = try XONSerialization.decode(data: data)!
//    assert(try! b.dataValue() == string.data(using: .utf8)!)
//} ()
//try! {
//    let data = try XONSerialization.encode(value: .data(string2.data(using: .utf8)!))
//    let b = try XONSerialization.decode(data: data)!
//    assert(try! b.dataValue() == string2.data(using: .utf8)!)
//} ()



//▿ 5 : XONValue
//  - number : -8535150335806580789
//▿ 6 : XONValue
//  ▿ timeval : Timeval
//    - value : 1034584475061637028
//▿ 7 : XONValue
//  - number : 5280776537546213781
//▿ 8 : XONValue
//  - number : -6901312967598468725




//        try! {
//            let v: UInt64 = 1 << 51
//            let d = Double(bitPattern: v)
//            let d80 = Float80(d)
//
//
//            let numberContent = _XCEncodeNumberFloat64(d)
//            assert(d80.exponent == numberContent.exponent)
//        } ()
//
//
//        try! {
//            let v: UInt64 = 1
//            let d = Double(bitPattern: v)
//            let d80 = Float80(d)
//
//            let numberContent = _XCEncodeNumberFloat64(d)
//            assert(d80.exponent == numberContent.exponent)
//        } ()

func randomSingleValueArray(count: Int) -> [XONValue] {
    var array: [XONValue] = []
    array.reserveCapacity(count)
    for _ in 0 ..< count {
        array.append(XONValue.randomSingleValue(jsonSupport: false))
    }
    return array
}

//func randomSingleValueMap(count: Int) -> XMap {
//    var set: Set<XONValue> = []
//    var array: [(XONValue, XONValue)] = []
//    array.reserveCapacity(count)
//    for _ in 0 ..< count {
//        let key = XONValue.randomSingleValue(jsonSupport: false)
//        if !set.contains(key) {
//            set.insert(key)
//            array.append((key, XONValue.randomSingleValue(jsonSupport: false)))
//        }
//    }
//    return OrderedMap(uniqueKeysWithValues: array)
//}
//func randomSingleValueSet(count: Int) -> XSet {
//    var set: Set<XONValue> = []
//    var array: [XONValue] = []
//    array.reserveCapacity(count)
//    for _ in 0 ..< count {
//        let key = XONValue.randomSingleValue(jsonSupport: false)
//        if !set.contains(key) {
//            set.insert(key)
//            array.append(key)
//        }
//    }
//    return OrderedSet(uniqueKeys: array)
//}

func randomSingleValueMessage(count: Int) -> Message<XONValue> {
    var map: [UInt32 : XONValue] = [:]
    for _ in 0 ..< count {
        map[UInt32.random(in: 1 ... UInt32.max)] = XONValue.randomSingleValue(jsonSupport: false)
    }
    return Message(type: Int64.random(in: 0 ... Int64.max), collection: map)
}

func testCollection() {
//    autoreleasepool {
//        let value: XONValue = .array([XONValue.bool(true), XONValue.bool(false), XONValue.bool(true), XONValue.number(-4935517242844051799), XONValue.number(7254530496614344569), XONValue.time(XONTime(second: -6575567707239634815))])
//
//        let data = try! XONSerialization.encode(value)
//        let b = try! XONSerialization.decode(data)!
//
//        assert(b == value)
//
//    }
    for _ in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XONValue = .array(randomSingleValueArray(count: count))
            let data = try! XONSerialization.encode(value)
            
            let b = try! XONSerialization.decode(data)!
            assert(b == value)
        }
    }

//    for _ in 0 ..< 10 {
//        autoreleasepool {
//            let count: Int = Int.random(in: 0 ... 333)
//            let value: XONValue = .map(randomSingleValueMap(count: count))
//            let data = try! XONSerialization.encode(value)
//            let b = try! XONSerialization.decode(data)!
//            assert(b == value)
//        }
//    }
//    for _ in 0 ..< 10 {
//        autoreleasepool {
//            let count: Int = Int.random(in: 0 ... 333)
//            let value: XONValue = .set(randomSingleValueSet(count: count))
//            let data = try! XONSerialization.encode(value: value)
//            let b = try! XONSerialization.decode(data: data)!
//            assert(b == value)
//        }
//    }
    for i in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XONValue = .message(randomSingleValueMessage(count: count))
            let data = try! XONSerialization.encode(value)
            let b = try! XONSerialization.decode(data)!
            if b != value {
                
                abort()
            }
        }
    }
}




public class XCBuffer {
    public var count: Int = 0
    private var capacity: Int
    private var _bytes: UnsafeMutableRawPointer
    
    public var bytes: UnsafeMutablePointer<UInt8> {
        return self._bytes.bindMemory(to: UInt8.self, capacity: self.capacity)
    }
    
    public init(minimumCapacity: Int) {
        let value = XCBuffer.capacityAlign(minimumCapacity)
        self.capacity = value
        self._bytes = realloc(nil, value)
    }
    
    public func reserveCapacity(_ minimumCapacity: Int) {
        guard minimumCapacity >= self.capacity else {
            return
        }
        let value = XCBuffer.capacityAlign(minimumCapacity)
        guard self.capacity != value else {
            return
        }
        self._bytes = realloc(self._bytes, value)
        self.capacity = value
    }
    deinit {
        free(self._bytes)
    }
    
    private static func capacityAlign(_ minimumCapacity: Int) -> Int {
        var value = max(0x1000, minimumCapacity)
        if value.leadingZeroBitCount + value.trailingZeroBitCount != value.bitWidth - 1 {
            value = 1 << (value.bitWidth - value.leadingZeroBitCount)
        }
        if value >= 0x200000 {
            value = (value + 0x200000 - 1) / 0x200000 * 0x200000
        } else {
            value = (value + 0x1000 - 1) / 0x1000 * 0x1000
        }
        return value
    }
}


func testVarint() {
//    TestObject.uint63Array
//    TestObject.uint64Array
//
//
//    let buffer = XCBuffer(minimumCapacity: 1024 * 10 * 10)
//
//    usleep(1000000)
//
//    TestObject.uint63Array.forEach { _ in
//
//    }
//
//    let int64time = testVarint(buffer: buffer, encode: __XCEncodeUInt64Varint, decode: __XCDecodeUInt64Varint)
//
//    usleep(1000000)
//
//
//    TestObject.uint63Array.forEach { _ in
//
//    }
//    let int63time = testVarint(buffer: buffer, encode: __XCEncodeUInt63Varint, decode: __XCDecodeUInt63Varint)
//
////    let int63time = testVarint(buffer: buffer, encode: __XCEncodeUInt64Varint2, decode: __XCDecodeUInt64Varint)
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
            return String(format: "%.03lf", s)
        }
        
        var result = ""
        result += "\(tag) x: total: \(x.codeString), encode: \(x.encodeString), decode: \(x.decodeString), data: \(x.dataString)\n"
        result += "\(tag) json: total: \(json.codeString), encode: \(json.encodeString), decode: \(json.decodeString), data: \(json.dataString)\n"
        result += "\(tag) delta: total: \(delta.codeString), encode: \(delta.encodeString), decode: \(delta.decodeString), data: \(delta.dataString)\n"
        result += "\(tag) codefast: \(scale(delta.code / x.code)), encode fast: \(scale(delta.encode / x.encode)), decode fast: \(scale(delta.decode / x.decode)), data less: \(scale(Double(delta.data) / Double(x.data))))\n"
        return result
    }
    
}

public func testCoder(tag: String, objects: [XCTestObject], times: Int) {
    var time0: CFAbsoluteTime = 0
    var time0a: CFAbsoluteTime = 0
    var time0b: CFAbsoluteTime = 0
    var dataSum0: Int = 0

    let range = 0 ..< times

    let values = objects.map { value in
        return value.xobject
    }
    
    range.forEach { i in
        for value in values {
            autoreleasepool {
                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let data = try! XONSerialization.encode(value)
                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let decoded = try! XONSerialization.decode(data)!
                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

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
    
    let jsons = objects.map { value in
        return value.jsonObject
    }
    range.forEach { i in
        for json in jsons {
            autoreleasepool {
                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                
                
                let data = try! JSONSerialization.encode(json)
                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let object = try! JSONSerialization.decode(data)
                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                
                time1 += end - start
                time1a += mtime - start
                time1b += end - mtime
                dataSum1 += data.count

                if i == 1 {
                    //  && index == 1
//                    if let str = String(data: data, encoding: .utf8) {
//                        print("JSON: \(str)")
//                    }
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

