
import Foundation
@testable import CX
import XON

final class XONTestCase: NSObject {

    func test() throws {
        // This is an example of a functional test case.
        // Use XONTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XONTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
//        try testTime()
//
//        testNumbers()
//        testStrings()
//        testDatas()
//        testStringNumberArray()
//        testStringNumberMap()
//
//        testCollection()
        try testRandomedJson()
//        try testSpeed()
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
    public func testDatas() {
        let tag = "Data"
        let values: [XONTestObject] = TestObject.stringNumberElements.map { (_, s, _) in
            return XONTestObject(.data(XONValue.randomString(length: Int.random(in: 0 ... 4096)).data(using: .utf8)!))
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

    func testStringNumberArray() {
        let tag = "[String,Number]"
        usleep(100000)

        let values: [XONTestObject] = TestObject.stringNumberElements.map { (_, s, n) in
            return XONTestObject(.array([.string(s), .number(n)]))
        }
        
        testCoder(tag: tag, objects: values, times: 100)
    }
    public func testStringNumberMap() {
        usleep(100000)

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
        usleep(200000)

        testCoder(tag: tag, objects: values, times: 100, log: false)
    }
    
    public func testSingleMessages() throws {
        let tag = "JSON.randomSingleMessage"
        let values: [XONTestObject] = (1 ... 100).map { index in
            let result = XONValue.randomSingleMessage(jsonSupport: true)
            return XONTestObject(result)
        }
        usleep(200000)

        testCoder(tag: tag, objects: values, times: 100, log: false)
    }
    public func testMessages() throws {
        let tag = "JSON.randomMessage"

        let values: [XONTestObject] = (1 ... 100).map { index in
            let result = XONValue.randomMessage(deep: 0, jsonSupport: true)
            return XONTestObject(.message(result))
        }
        usleep(200000)

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


}



public struct TestObject {
    public static let stringNumberElements: [(UInt32, String, NSNumber)] = (1 ... 1024).map { index in
        var items = XONMessage.messageKeyMap.map { v in
            return v
        }
        var n = XONValue.randomNumber(jsonSupport: true)
        while n.doubleValue.isNaN {
            n = XONValue.randomNumber(jsonSupport: true)
        }
        let idx = Int.random(in: 0 ..< items.count)
        let item = items.remove(at: idx)
        return (item.0, item.1, n)
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

public class XWrapper : Equatable {

    public let object: UnsafeMutableRawPointer?
    
    public init(_ object: UnsafeMutableRawPointer?) {
        self.object = object
    }
    deinit {
        XObjectRelease(self.object)
    }
    
    public static func == (lhs: XWrapper, rhs: XWrapper) -> Bool {
        return XObjectEqual(lhs.object, rhs.object)
    }
    
}

public class XONTestObject {
    public var xlength: Int = 0
    public var jsonlength: Int = 0

    public let jsonObject: NSObject
    public let xobject: XONValue
    public let xvalue: UnsafeMutableRawPointer?
    
    public init(_ value: XONValue) {
        self.jsonObject = value.jsonValue()
        self.xobject = value
        self.xvalue = value.xValue()
    }
    deinit {
        XObjectRelease(self.xvalue)
    }
}

extension XONValue {
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
                map.setObject(v.jsonValue(), forKey: XONMessage.messageKeyMap[k]! as NSString)
            }
            return map
        }
    }
    public func xValue() -> UnsafeMutableRawPointer? {
        switch self {
        case .null:
            return nil
        case .bool(let v):
            return XBoolWithValue(v)
        case .string(let v):
            var vv = v
            return vv.withUTF8 { ptr in
                
                return XStringCreateWithBytes(0, ptr.baseAddress!, v.utf8.count, XStringEncodingUtf8, 0)
            }
        case .data(let v):
            return XDataCreate(0, (v as NSData).bytes, v.count)
        case .array(let v):
            let array = XArrayBuilderCreateWithCount(0, v.count)
            v.enumerated().forEach { (index, value) in
                XArrayBuilderReplaceWithRetainedValue(array, index, value.xValue())
            }
            XArrayBuilderComplete(array);
            return array
        case .number(let v):
            if let d = v as? Double {
                return XNumberCreateWithFloat64(0, d)
            } else if let d = v as? Int64 {
                return XNumberCreateWithSInt64(0, d)
            } else if let d = v as? UInt64 {
                return XNumberCreateWithUInt64(0, d)
            }
            return nil
        case .time(let v):
            return XDateCreate(0, v.microsecond)
        case .message(let v):
            let message = XMessageBuilderCreateWithCount(0, v.count)
            v.sorted { lhs, rhs in
                return lhs.key < rhs.key
            }.enumerated().forEach { (index, item) in
                XMessageBuilderReplaceWithRetainedValue(message, index, Int32(item.0), item.1.xValue());
            }
            XMessageBuilderComplete(message);
            return message
        }
    }

    
    public static func randomMessage(deep: Int, jsonSupport: Bool) -> [UInt32 : XONValue] {
        let count = randomLength(50)
        var map: [UInt32 : XONValue] = [:]
        for _ in 0 ..< count {
            map[XONMessage.randomMessageFieldKey()] = random(deep: deep + 1, jsonSupport: jsonSupport)
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
            map[XONMessage.randomMessageFieldKey()] = XONValue.random(deep: 0, allowCollection: false, jsonSupport: jsonSupport)
        }
        return XONValue.message(map)
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

}

public struct XONMessage {
    
    static let keyCount: Int = 4096
    private static let keys: [(UInt32, String)] = {
        var ids: Set<UInt32> = []
        var strings: Set<String> = []
        var items: [(UInt32, String)] = []
        for _ in 1 ... keyCount {
            var id = UInt32.random(in: 1 ..< 4096 * 3)
            while ids.contains(id) {
                id = UInt32.random(in: 1 ..< 4096 * 3)
            }
            var key = XONMessage.generateKey()
            while strings.contains(key) {
                key = XONMessage.generateKey()
            }
            items.append((id, key))
        }
        return items
    } ()
    
    public static let messageKeyMap: [UInt32 : String] = {
        var items: [UInt32 : String] = [:]
        XONMessage.keys.forEach { (mindex, value) in
            items[mindex] = value
        }
        return items
    } ()
    
    public static func generateKey(length: Int) -> String {
        let len = length
        let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
        arc4random_buf(p, len)
        let data = Data(bytes: p, count: len)
        let string = data.base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+-", with: "_")
        p.deallocate()
        return string
    }
    public static func generateKey() -> String {
        let len = Int.random(in: 2 ... 12)
        return self.generateKey(length: len)
    }
    
    public static func randomMessageFieldKey() -> UInt32 {
        return XONMessage.keys[Int.random(in: 0 ..< XONMessage.keys.count)].0
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
//    usleep(100000)
//
//    TestObject.uint63Array.forEach { _ in
//
//    }
//
//    let int64time = testVarint(buffer: buffer, encode: __XONEncodeUInt64Varint, decode: __XONDecodeUInt64Varint)
//
//    usleep(100000)
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
    public var c: CodeInfo

    public init(tag: String, x: CodeInfo, json: CodeInfo, c: CodeInfo) {
        self.tag = tag
        self.x = x
        self.json = json
        self.c = c
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

        result += "\(tag) xcode speed: \(scale(x.code / json.code)), encode speed: \(scale(x.encode / json.encode)), decode speed: \(scale(x.decode / json.decode)), data: \(scale(Double(x.data) / Double(json.data)))\n"
        
        result += "\(tag) c: total: \(c.codeString), encode: \(c.encodeString), decode: \(c.decodeString), data: \(c.dataString)\n"
        let delta2 = self.json - self.c
        result += "\(tag) cdelta: total: \(delta2.codeString), encode: \(delta2.encodeString), decode: \(delta2.decodeString), data: \(delta2.dataString)\n"
        result += "\(tag) c speed: \(scale(c.code / json.code)), encode speed: \(scale(c.encode / json.encode)), decode speed: \(scale(c.decode / json.decode)), data: \(scale(Double(c.data) / Double(json.data)))\n"

        return result
    }
    
}

public func testCoder(tag: String, objects: [XONTestObject], times: Int) {
    testCoder(tag: tag, objects: objects, times: times, log: false)
}

func code<T, D>(tag: String, objects: [XONTestObject], times: Int, encode: (XONTestObject) -> (T, Int), decode: (T) -> D, compare: (XONTestObject, D) -> Bool) -> CodeInfo {
    var encodeTime: CFAbsoluteTime = 0
    var decodeTime: CFAbsoluteTime = 0
    var dataLength: Int = 0
    let range = 0 ..< times
    
    range.forEach { i in
        for object in objects {
            autoreleasepool {
                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let (data, count) = encode(object)
                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let decoded = decode(data)
                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                encodeTime += mtime - start
                decodeTime += end - mtime
                dataLength += count
                if !compare(object, decoded) {
                    print("789tag\(tag): \(decoded)\n \(object.jsonObject)\n \(object.xobject)\n")
                    abort();
                }
            }

        }
    }
    return CodeInfo(encode: encodeTime, decode: decodeTime, data: dataLength)
}



func testCoder(tag: String, objects: [XONTestObject], times: Int, log: Bool) {
    let x = code(tag: tag, objects: objects, times: times) { object in
        let data = try! XONSerialization.encode(object.xobject)
        return (data, data.count)
    } decode: { data in
        return try! XONSerialization.decode(data)
    } compare: { object, value in
        return object.xobject == value
    }
    
    usleep(200000)

    let json = code(tag: tag, objects: objects, times: times) { object in
        let data = try! JSONSerialization.encode(object.jsonObject)
        return (data, data.count)
    } decode: { data in
        return try! JSONSerialization.decode(data)
    } compare: { object, value in
        let results = NSMutableArray()
        let result = compareJsonObject(lhs: object.jsonObject, rhs: value, results: results)
        return result
    }
    
    usleep(200000)

    let c = code(tag: tag, objects: objects, times: times) { object -> (XWrapper, Int) in
        var error: XONError_e = XONErrorNone
        let data = XONEncode(object.xvalue, &error)!
        let count = XDataGetLength(data)
        
        return (XWrapper(data), count)
    } decode: { data -> XWrapper in
        var error: XONError_e = XONErrorNone
        let object = XWrapper(XONDecodeWithData(data.object!, &error))
        return object
    } compare: { object, value in
        let result = XObjectEqual(object.xvalue, value.object)
        if !result {
            XObjectEqual(object.xvalue, value.object)
        }
        return result
    }
    
    let profile = Profile(tag: tag, x: x, json: json, c: c)
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
        results.add("\(l) | \(r)" as NSString)
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

