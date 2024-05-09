
import Foundation

public enum XONValue : Hashable {
    case null
    case bool(Bool)
    case string(String)
    case data(Data)
    case number(NSNumber)
    case time(XONTime)
    case message(Message<XONValue>)
    case array([XONValue])
    
    public func isNull() -> Bool {
        if case .null = self {
            return true
        } else {
            return false
        }
    }
    
    public func boolValue() throws -> Bool {
        guard case .bool(let bool) = self else {
            throw XON.typeError
        }
        return bool
    }

    public func numberValue() throws -> NSNumber {
        guard case .number(let value) = self else {
            throw XON.typeError
        }
        return value
    }
    
    public func timeValue() throws -> XONTime {
        guard case .time(let value) = self else {
            throw XON.typeError
        }
        return value
    }
    
    public func stringValue() throws -> String {
        guard case .string(let value) = self else {
            throw XON.typeError
        }
        return value
    }
    
    public func dataValue() throws -> Data {
        guard case .data(let value) = self else {
            throw XON.typeError
        }
        return value
    }
    
    public func messageValue() throws -> Message<XONValue> {
        guard case .message(let value) = self else {
            throw XON.typeError
        }
        return value
    }
    
    public func arrayValue() throws -> [XONValue] {
        guard case .array(let value) = self else {
            throw XON.typeError
        }
        return value
    }
    
    public func doubleValue() throws -> Double {
        let v = try self.numberValue()
        guard let value = v as? Double else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func floatValue() throws -> Float {
        let v = try self.numberValue()
        guard let value = v as? Float else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func intValue() throws -> Int {
        let v = try self.numberValue()
        guard let value = v as? Int else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func uintValue() throws -> UInt {
        let v = try self.numberValue()
        guard let value = v as? UInt else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func int8Value() throws -> Int8 {
        let v = try self.numberValue()
        guard let value = v as? Int8 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint8Value() throws -> UInt8 {
        let v = try self.numberValue()
        guard let value = v as? UInt8 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }

    public func int16Value() throws -> Int16 {
        let v = try self.numberValue()
        guard let value = v as? Int16 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint16Value() throws -> UInt16 {
        let v = try self.numberValue()
        guard let value = v as? UInt16 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func int32Value() throws -> Int32 {
        let v = try self.numberValue()
        guard let value = v as? Int32 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint32Value() throws -> UInt32 {
        let v = try self.numberValue()
        guard let value = v as? UInt32 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func int64Value() throws -> Int64 {
        let v = try self.numberValue()
        guard let value = v as? Int64 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint64Value() throws -> UInt64 {
        let v = try self.numberValue()
        guard let value = v as? UInt64 else {
            throw XON.numberOutOfBoundsError
        }
        return value
    }

    public func value(_ type: Bool.Type) throws -> Bool {
        return try self.boolValue()
    }

    public func value(_ type: NSNumber.Type) throws -> NSNumber {
        return try self.numberValue()
    }
    
    public func value(_ type: XONTime.Type) throws -> XONTime {
        return try self.timeValue()
    }
    
    public func value(_ type: String.Type) throws -> String {
        return try self.stringValue()
    }
    
    public func value(_ type: Data.Type) throws -> Data {
        return try self.dataValue()
    }
    
    public func value(_ type: Message<XONValue>.Type) throws -> Message<XONValue> {
        return try self.messageValue()
    }
}

public enum XONType : Int {
    case null = 0
    case bool = -1
    case number = 1
    case time = 2
    case string = 3
    case data = 4
    case message = 5
    case array = 6
}

public struct XONTime : Hashable {
    public let second: Int64
    public let attosecond: UInt64
    
    private init(second: Int64, attosecond: UInt64) {
        self.second = second
        self.attosecond = attosecond
    }
    
    public init(second: Int64) {
        self.second = second
        self.attosecond = 0
    }

    public init(millisecond: Int64) {
        var second = millisecond / 1000
        var tmp = millisecond % 1000
        if tmp < 0 {
            tmp += 1000
            second -= 1
        }
        self.second = second
        self.attosecond = UInt64(tmp) * (XONTime.attosecondPerSecond / 1000)
    }
    
    public init(microsecond: Int64) {
        var second = microsecond / 1000_000
        var tmp = microsecond % 1000_000
        if tmp < 0 {
            tmp += 1000_000
            second -= 1
        }
        self.second = second
        self.attosecond = UInt64(tmp) * (XONTime.attosecondPerSecond / 1000_000)
    }
    
    public init(nanosecond: Int64) {
        var second = nanosecond / 1000_000_000
        var tmp = nanosecond % 1000_000_000
        if tmp < 0 {
            tmp += 1000_000_000
            second -= 1
        }
        self.second = second
        self.attosecond = UInt64(tmp) * (XONTime.attosecondPerSecond / 1000_000_000)
    }
    
    public func hash(into hasher: inout Hasher) {
        if self.isInvalid {
            hasher.combine(Int64.max)
        } else {
            hasher.combine(self.second)
            hasher.combine(self.attosecond)
        }
    }
    
    public static func == (lhs: XONTime, rhs: XONTime) -> Bool {
        if lhs.isInvalid {
            if rhs.isInvalid {
                return true
            } else {
                return false;
            }
        } else {
            return lhs.second == rhs.second && lhs.attosecond == rhs.attosecond
        }
    }
    
    public var isInvalid: Bool {
        return XCTimeIsInvalid(self.second, self.attosecond)
    }
    
    public static let attosecondPerSecond: UInt64 = 1_000_000_000_000_000_000
    public static let invalid = XONTime(second: Int64.min, attosecond: UInt64.max - 1)
    public static let distantPast = XONTime(second: Int64.min, attosecond: UInt64.max)
    public static let distantFuture = XONTime(second: Int64.max, attosecond: UInt64.max)
    public static let zero = XONTime(second: 0, attosecond: 0)
    
    public static func time(second: Int64, attosecond: UInt64) -> XONTime {
        if XCTimeIsInvalid(second, attosecond) {
            return XONTime.invalid
        } else {
            return XONTime(second: second, attosecond: attosecond)
        }
    }
}

//public final class XBool : NSObject, NSCopying {
//    public let value: Bool
//
//    private init(_ value: Bool) {
//        self.value = value
//    }
//
//    public func copy(with zone: NSZone? = nil) -> Any {
//        return self
//    }
//
//    public override func isEqual(to object: Any?) -> Bool {
//        if let rhs = object as? XBool {
//            return self.value == rhs.value
//        } else {
//            return false
//        }
//    }
//    public override var hash: Int {
//        return self.value ? Int.max : 0
//    }
//
//    public static func bool(_ value: Bool) -> XBool {
//        return value ? trueValue : falseValue
//    }
//
//    public static let trueValue: XBool = XBool(true)
//    public static let falseValue: XBool = XBool(false)
//}
//
//public final class XTime : NSObject, NSCopying {
//    public let value: XONTime
//
//    private init(_ value: XONTime) {
//        self.value = value
//    }
//
//    public func copy(with zone: NSZone? = nil) -> Any {
//        return self
//    }
//
//    public override func isEqual(to object: Any?) -> Bool {
//        if let rhs = object as? XTime {
//            return self.value == rhs.value
//        } else {
//            return false
//        }
//    }
//    public override var hash: Int {
//        return self.value.hashValue
//    }
//
//    public static func timeval(_ value: XONTime) -> XTime {
//        return XTime(value)
//    }
//}
//public final class XMessage : NSObject, NSCopying {
//    public let value: Message
//
//    public init(_ value: Message) {
//        self.value = value
//    }
//
//    public func copy(with zone: NSZone? = nil) -> Any {
//        return self
//    }
//
//    public override func isEqual(to object: Any?) -> Bool {
//        if let rhs = object as? XMessage {
//            return self.value == rhs.value
//        } else {
//            return false
//        }
//    }
//    public override var hash: Int {
//        return self.value.hashValue
//    }
//}

public class XCValueObject : NSObject, NSCopying {
    public let value: XONValue
    
    public init(_ value: XONValue) {
        self.value = value
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override func isEqual(to object: Any?) -> Bool {
        if let rhs = object as? XCValueObject {
            return self.value == rhs.value
        } else {
            return false
        }
    }
    public override var hash: Int {
        return self.value.hashValue
    }
}
