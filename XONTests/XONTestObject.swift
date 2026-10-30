//
//import XCTest
//import XON
//
//
//extension XONValue {
//    public func jsonValue() -> NSObject {
//        switch self {
//        case .null:
//            return NSNull()
//        case .bool(let v):
//            return NSNumber(booleanLiteral: v)
//        case .string(let v):
//            return v as NSString
//        case .data(let v):
//            return v.base64EncodedString() as NSString
//        case .array(let v):
//            return v.map { item in
//                return item.jsonValue()
//            } as NSArray
//        case .number(let v):
//            return v
//        case .time(let v):
//            return v.numberValue()
//        case .message(let v):
//            let map: NSMutableDictionary = NSMutableDictionary()
//            v.forEach { (k, v) in
//                map.setObject(v.jsonValue(), forKey: XONTestObject.messageKeyMap[k]! as NSString)
//            }
//            return map
//        }
//    }
//
//    
//    public static func randomMessage(deep: Int, jsonSupport: Bool) -> [UInt32 : XONValue] {
//        let count = randomLength(50)
//        var map: [UInt32 : XONValue] = [:]
//        for _ in 0 ..< count {
//            map[XONTestObject.randomMessageFieldKey()] = random(deep: deep + 1, jsonSupport: jsonSupport)
//        }
//        return map
//    }
//    public static func random(jsonSupport: Bool) -> XONValue {
//        return random(deep: 0, jsonSupport: jsonSupport)
//    }
//    
//    public static func randomLength(_ max: Int) -> Int {
//        if max < 64 {
//            return Int.random(in: 0 ... max)
//        } else if max < 4096 {
//            let n = sqrt(Double(max))
//            let up = Int(n.rounded(.up))
//            return up * up
//        } else {
//            let n = sqrt(sqrt(Double(max)))
//            let up0 = Int(n.rounded(.down))
//            let up1 = up0 + 1
//            let qlen0 = Int.random(in: 1 ... up0)
//            let qlen1 = Int.random(in: 1 ... up1)
//            return qlen0 * qlen0 * qlen1 * qlen1
//        }
//    }
//    
//    public static func randomNumber(jsonSupport: Bool) -> NSNumber {
//        return _randomNumber(jsonSupport: jsonSupport)
//    }
//    
//    public static func _randomNumber(jsonSupport: Bool) -> NSNumber {
//        let numbers: [Double] = [Double.nan, Double.zero, Double.infinity, -1 * Double.infinity]
//        let i = Int.random(in: 0 ... 200)
//        if i < 4 && !jsonSupport {
//            return numbers[i] as NSNumber
//        } else {
//            let itype = i % 7
//            switch itype {
//            case 0:
//                let n: Int64 = Int64.random(in: Int64.min ... Int64.max)
//                return n as NSNumber
//            case 1:
//                let n: UInt64 = UInt64.random(in: UInt64.min ... UInt64.max)
//                return n as NSNumber
//            case 2:
//                let n: UInt32 = UInt32.random(in: UInt32.min ... UInt32.max)
//                return n as NSNumber
//            case 3:
//                let n: Int32 = Int32.random(in: Int32.min ... Int32.max)
//                return n as NSNumber
//            case 4:
//                let n: UInt16 = UInt16.random(in: UInt16.min ... UInt16.max)
//                return n as NSNumber
//            case 5:
//                let n: Int16 = Int16.random(in: Int16.min ... Int16.max)
//                return n as NSNumber
//            default:
//                let bitPattern = UInt64.random(in: UInt64.min ... UInt64.max)
//                var n = Double(bitPattern: bitPattern)
//                while n.isNaN || n.isInfinite {
//                    let bitPattern = UInt64.random(in: UInt64.min ... UInt64.max)
//                    n = Double(bitPattern: bitPattern)
//                }
//                return n as NSNumber
//            }
//        }
//    }
//    
//    public static func randomTime() -> XONTime {
//        let rint = Int.random(in: 0 ..< 1000)
//        switch rint {
//        case 0:
//            return XONTime.invalid
//        case 1:
//            return XONTime.min
//        case 2:
//            return XONTime.max
//        case 3:
//            return XONTime.zero
//        default:
//            return XONTime(microsecond: Int64.random(in: Int64.min ... Int64.max))
//        }
//    }
//    public static func randomString(length: Int) -> String {
//        let len = length
//        let blen = len * 4 / 5
//        var data: Data = randomData(length: len * 3 / 5).base64EncodedData(options: [])
//        for _ in blen ..< len {
//            let i = Int.random(in: 0 ... 1000)
//            if i == 0 {
//                data.append("计算机".data(using: .utf8)!)
//            } else if i == 1 {
//                data.append("コンピュータ".data(using: .utf8)!)
//            } else if i == 2 {
//                data.append("컴퓨터".data(using: .utf8)!)
//            } else if i == 3 {
//                data.append("Компьютеры".data(using: .utf8)!)
//            } else {
//                var char = UInt8.random(in: 1 ... 0x7f)
//                while isgraph(Int32(char)) == 0 || char == 92 {
//                    char = UInt8.random(in: 1 ... 0x7f)
//                }
//                data.append(contentsOf: [char])
//            }
//        }
//        return String(data: data, encoding: .utf8) ?? ""
//    }
//
//    public static func randomString(maxLength: Int) -> String {
//        let len = randomLength(maxLength)
//        return self.randomString(length: len)
//    }
//    public static func randomData(length: Int) -> Data {
//        let p = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: 8)
//        arc4random_buf(p, length)
//        let data = Data(bytes: p, count: length)
//        p.deallocate()
//        return data
//    }
//    public static func randomData(maxLength: Int) -> Data {
//        let len = randomLength(maxLength)
//        return randomData(length: len)
//    }
//    public static func randomSingleValue(jsonSupport: Bool) -> XONValue {
//        let rint = Int.random(in: 0 ... 444)
//        if rint > 400 {
//            return .data(randomData(maxLength: 1000))
//        }
//        
//        let type = rint % 10
//        switch type {
//        case 0:
//            return .null
//        case 1:
//            return .bool(Bool.random())
//        case 2:
//            return .time(randomTime())
//        case 3:
//            fallthrough
//        case 4:
//            fallthrough
//        case 5:
//            fallthrough
//        case 6:
//            fallthrough
//        case 7:
//            return .string(self.randomString(maxLength: 512))
//        default:
//            return .number(randomNumber(jsonSupport: jsonSupport))
//        }
//    }
//    public static func randomSingleMessage(jsonSupport: Bool) -> XONValue {
//        let count = randomLength(50)
//        var map: [UInt32 : XONValue] = [:]
//        for _ in 0 ..< count {
//            map[XONTestObject.randomMessageFieldKey()] = XONValue.random(deep: 0, allowCollection: false, jsonSupport: jsonSupport)
//        }
//        return XONValue.message(map)
//    }
//
//    
//    public static func random(deep: Int, allowCollection: Bool, jsonSupport: Bool) -> XONValue {
//        if deep > 30 {
//            return randomSingleValue(jsonSupport: jsonSupport)
//        }
//        if !allowCollection {
//            return randomSingleValue(jsonSupport: jsonSupport)
//        }
//        // (3/2)e
//        let rint = Int.random(in: 0 ... 100)
//        switch rint {
//        case 0:
//            let count = randomLength(50)
//            var array: [XONValue] = []
//            array.reserveCapacity(count)
//            for _ in 0 ..< count {
//                array.append(random(deep: deep + 1, allowCollection: allowCollection, jsonSupport: jsonSupport))
//            }
//            return .array(array)
//        case 1:
//            return .message(randomMessage(deep: deep, jsonSupport: jsonSupport))
//        default:
//            return randomSingleValue(jsonSupport: jsonSupport)
//        }
//    }
//
//    
//    public static func random(deep: Int, jsonSupport: Bool) -> XONValue {
//        return self.random(deep: deep, allowCollection: true, jsonSupport: jsonSupport)
//    }
//
//}
//
//@objc public class XONTestObject : NSObject {
//    static let keyCount: Int = 4096
//    private static let keys: [(UInt32, String)] = {
//        var ids: Set<UInt32> = []
//        var strings: Set<String> = []
//        var items: [(UInt32, String)] = []
//        for _ in 1 ... keyCount {
//            var id = UInt32.random(in: 1 ..< 4096 * 3)
//            while ids.contains(id) {
//                id = UInt32.random(in: 1 ..< 4096 * 3)
//            }
//            var key = XONTestObject.generateKey()
//            while strings.contains(key) {
//                key = XONTestObject.generateKey()
//            }
//            items.append((id, key))
//        }
//        return items
//    } ()
//    
//    public static let messageKeyMap: [UInt32 : String] = {
//        var items: [UInt32 : String] = [:]
//        XONTestObject.keys.forEach { (mindex, value) in
//            items[mindex] = value
//        }
//        return items
//    } ()
//    
//    public static func generateKey(length: Int) -> String {
//        let len = length
//        let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
//        arc4random_buf(p, len)
//        let data = Data(bytes: p, count: len)
//        let string = data.base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+-", with: "_")
//        p.deallocate()
//        return string
//    }
//    public static func generateKey() -> String {
//        let len = Int.random(in: 2 ... 12)
//        return self.generateKey(length: len)
//    }
//    
//    public static func randomMessageFieldKey() -> UInt32 {
//        return XONTestObject.keys[Int.random(in: 0 ..< XONTestObject.keys.count)].0
//    }
//    
//    public var xlength: Int = 0
//    public var jsonlength: Int = 0
//
//    @objc public let jsonObject: NSObject
//    public let value: XONValue
//
//    public init(_ value: XONValue) {
//        self.jsonObject = value.jsonValue()
//        self.value = value
//        super.init()
//    }
//    
//    public override func isEqual(to object: Any?) -> Bool {
//        guard let obj = object as? XONTestObject else {
//            return false
//        }
//        return obj.value == self.value
//    }
//    public override var hash: Int {
//        return self.value.hashValue
//    }
//}
//
//
//let string: String = "asdfryejfkj"
//let string2: String = "()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj"
//
//
//func randomSingleValueArray(count: Int) -> [XONValue] {
//    var array: [XONValue] = []
//    array.reserveCapacity(count)
//    for _ in 0 ..< count {
//        array.append(XONValue.randomSingleValue(jsonSupport: false))
//    }
//    return array
//}
//
//func randomSingleValueMessage(count: Int) -> [UInt32 : XONValue] {
//    var map: [UInt32 : XONValue] = [:]
//    for _ in 0 ..< count {
//        map[UInt32.random(in: 1 ... UInt32.max)] = XONValue.randomSingleValue(jsonSupport: false)
//    }
//    return map
//}
//
//func testCollection() {
//    for _ in 0 ..< 10 {
//        autoreleasepool {
//            let count: Int = Int.random(in: 0 ... 333)
//            let value: XONValue = .array(randomSingleValueArray(count: count))
//            let data = try! XONSerialization.encode(value)
//            
//            let b = try! XONSerialization.decode(data)
//            assert(b == value)
//        }
//    }
//    for _ in 0 ..< 10 {
//        autoreleasepool {
//            let count: Int = Int.random(in: 0 ... 333)
//            let value: XONValue = .message(randomSingleValueMessage(count: count))
//            let data = try! XONSerialization.encode(value)
//            let b = try! XONSerialization.decode(data)
//            if b != value {
//                
//                abort()
//            }
//        }
//    }
//}
//
//
//
//
//
//func testVarint() {
////    TestObject.uint63Array
////    TestObject.uint64Array
////
////
////    let buffer = XONBuffer(minimumCapacity: 1024 * 10 * 10)
////
////    usleep(1000000)
////
////    TestObject.uint63Array.forEach { _ in
////
////    }
////
////    let int64time = testVarint(buffer: buffer, encode: __XONEncodeUInt64Varint, decode: __XONDecodeUInt64Varint)
////
////    usleep(1000000)
////
////
////    TestObject.uint63Array.forEach { _ in
////
////    }
////    let int63time = testVarint(buffer: buffer, encode: __XONEncodeUInt63Varint, decode: __XONDecodeUInt63Varint)
////
//////    let int63time = testVarint(buffer: buffer, encode: __XONEncodeUInt64Varint2, decode: __XONDecodeUInt64Varint)
////
////    print("testVarint: int64time:\(int64time) int63time:\(int63time) fast:\(int64time - int63time)")
//    
//}
//
//public struct CodeInfo {
//    public var encode: CFAbsoluteTime
//    public var decode: CFAbsoluteTime
//    public var data: Int
//    
//    public var code: CFAbsoluteTime {
//        return encode + decode
//    }
//    public var codeString: String {
//        return CodeInfo.formatter.string(from: self.code as NSNumber) ?? ""
//    }
//    public var encodeString: String {
//        return CodeInfo.formatter.string(from: self.encode as NSNumber) ?? ""
//    }
//    public var decodeString: String {
//        return CodeInfo.formatter.string(from: self.decode as NSNumber) ?? ""
//    }
//    public var dataString: String {
//        var v = self.data
//        var string = ""
//        if v >= 1024 * 1024 {
//            let mb = 1024 * 1024
//            string += String(format: "%ld_", v / mb)
//            v = v % mb
//            string += String(format: "%04ld_", v / 1024)
//            v = v % 1024
//            string += String(format: "%04ld", v)
//        } else if v >= 1024 {
//            string += String(format: "%04ld_", v / 1024)
//            v = v % 1024
//            string += String(format: "%04ld", v)
//        } else {
//            string += String(format: "%04ld", v)
//        }
//        return string
//    }
//
//    public init(encode: CFAbsoluteTime, decode: CFAbsoluteTime, data: Int) {
//        self.encode = encode
//        self.decode = decode
//        self.data = data
//    }
//    
//    public static let formatter: NumberFormatter = {
//        var formater = NumberFormatter()
//        formater.usesGroupingSeparator = true
//        formater.groupingSize = 6
//        formater.groupingSeparator = "_"
//        formater.maximumFractionDigits = 7
//        return formater
//    } ()
//    
//    public static func + (lhs: CodeInfo, rhs: CodeInfo) -> CodeInfo {
//        return CodeInfo(encode: lhs.encode + rhs.encode, decode: lhs.decode + rhs.decode, data: lhs.data + rhs.data)
//    }
//
//    public static func - (lhs: CodeInfo, rhs: CodeInfo) -> CodeInfo {
//        return CodeInfo(encode: lhs.encode - rhs.encode, decode: lhs.decode - rhs.decode, data: lhs.data - rhs.data)
//    }
//    
//}
//public struct Profile : CustomStringConvertible {
//    public var tag: String
//    public var x: CodeInfo
//    public var json: CodeInfo
//
//    public init(tag: String, x: CodeInfo, json: CodeInfo) {
//        self.tag = tag
//        self.x = x
//        self.json = json
//    }
//    
//
//    public var description: String {
//        let delta = self.json - self.x
//        
//        func scale(_ s: Double) -> String {
//            return String(format: "%.01lf%%", s * 100)
//        }
//        
//        var result = ""
//        result += "\(tag) x: total: \(x.codeString), encode: \(x.encodeString), decode: \(x.decodeString), data: \(x.dataString)\n"
//        result += "\(tag) json: total: \(json.codeString), encode: \(json.encodeString), decode: \(json.decodeString), data: \(json.dataString)\n"
//        result += "\(tag) delta: total: \(delta.codeString), encode: \(delta.encodeString), decode: \(delta.decodeString), data: \(delta.dataString)\n"
//        result += "\(tag) code speed: \(scale(x.code / json.code)), encode speed: \(scale(x.encode / json.encode)), decode speed: \(scale(x.decode / json.decode)), data: \(scale(Double(x.data) / Double(json.data)))\n"
//        return result
//    }
//    
//}
//
//public func testCoder(tag: String, objects: [XONTestObject], times: Int) {
//    testCoder(tag: tag, objects: objects, times: times, log: false)
//}
//func testCoder(tag: String, objects: [XONTestObject], times: Int, log: Bool) {
//    var time0: CFAbsoluteTime = 0
//    var time0a: CFAbsoluteTime = 0
//    var time0b: CFAbsoluteTime = 0
//    var dataSum0: Int = 0
//
//    let range = 0 ..< times
//    
//    range.forEach { i in
//        for object in objects {
//            autoreleasepool {
//                var dataCount: Int = 0
//                var datat: Data? = nil
//                let value = object.xobject
//                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
//                let data = try! XONSerialization.encode(value)
//                datat = data
//                dataCount = data.count
//                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
//                let decoded = try! XONSerialization.decode(data)
//                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
//                
//                object.xlength = data.count
//                time0 += end - start
//                time0a += mtime - start
//                time0b += end - mtime
//                dataSum0 += data.count
//                
//                assert(value == decoded)
//            }
//
//        }
//    }
//
//    usleep(1000000)
//
//    var time1: CFAbsoluteTime = 0
//    var time1a: CFAbsoluteTime = 0
//    var time1b: CFAbsoluteTime = 0
//
//    var dataSum1: Int = 0
//    
//    range.forEach { i in
//        for obj in objects {
//            autoreleasepool {
//                let json = obj.jsonObject
//                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
//                let data = try! JSONSerialization.encode(json)
//                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
//                let object = try! JSONSerialization.decode(data)
//                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
//                
//                time1 += end - start
//                time1a += mtime - start
//                time1b += end - mtime
//                dataSum1 += data.count
//                obj.jsonlength = data.count
//
//                if i == 1 && log {
//                    if let str = String(data: data, encoding: .utf8) {
//                        print("\n----- xlen: \(obj.xlength) jlen: \(obj.jsonlength) delta:\(obj.jsonlength - obj.xlength) JSON: \n\(str)")
//                    }
//                }
//
//                let results = NSMutableArray()
//                if !compareJsonObject(lhs: json, rhs: object, results: results) {
//                    abort()
//                }
//                if results.count > 0 {
////                    print("")
////                    print(results)
////                    print("")
//                }
//            }
//        }
//    }
//    
//    let x = CodeInfo(encode: time0a, decode: time0b, data: dataSum0)
//    let json = CodeInfo(encode: time1a, decode: time1b, data: dataSum1)
//
//    let profile = Profile(tag: tag, x: x, json: json)
//    print(profile)
//    
//}
//
//
//
//func compareDictionary(lhs: NSDictionary, rhs: NSDictionary, results: NSMutableArray) -> Bool {
//    guard lhs.count == rhs.count else {
//        results.add(NSString(format: "%@ | %@", lhs, rhs))
//        return false
//    }
//    var result = true
//    lhs.allKeys.forEach { k in
//        let lv = lhs.object(forKey: k)! as! NSObject
//        let rv = rhs.object(forKey: k) as! NSObject
//        let r = compareJsonObject(lhs: lv, rhs: rv, results: results)
//        if !r {
//            result = false
//        }
//    }
//    return result
//}
//
//func compareArray(lhs: NSArray, rhs: NSArray, results: NSMutableArray) -> Bool {
//    guard lhs.count == rhs.count else {
//        results.add(NSString(format: "%@ | %@", lhs, rhs))
//        return false
//    }
//    var result = true
//    lhs.enumerated().forEach { (index, item) in
//        let r = compareJsonObject(lhs: item as! NSObject, rhs: rhs.object(at: index) as! NSObject, results: results)
//        if !r {
//            result = false
//        }
//    }
//    return result
//}
//
//func compareJsonObject(lhs l: Any, rhs r: Any, results: NSMutableArray) -> Bool {
//    guard let lhs = l as? NSObject, let rhs = r as? NSObject else {
//        results.add("\(l) | (r)" as NSString)
//        return false
//    }
//    
//    if !lhs.isEqual(to: rhs) {
//        if lhs is NSNumber {
//            if let lvd = lhs as? Double, let rvd = rhs as? Double {
//                let d = lvd - rvd
//                let string = NSString(format: "%.012lf", d)
//                results.add(NSString(format: "%@ | %@  [%@]", lhs, rhs, string))
//                if d > 0.00000000001 || d < -0.00000000001 {
//                    return false
//                } else {
//                    return true
//                }
//            }
//        } else if lhs is NSString {
//            results.add(NSString(format: "%@ | %@", lhs, rhs))
//            return false
//        } else if let lv = lhs as? NSArray {
//            return compareArray(lhs: lv, rhs: rhs as! NSArray, results: results)
//        } else if let lv = lhs as? NSDictionary {
//            return compareDictionary(lhs: lv, rhs: rhs as! NSDictionary, results: results)
//        } else {
//            results.add(NSString(format: "%@ | %@", lhs, rhs))
//            return false
//        }
//    }
//    return true
//}
