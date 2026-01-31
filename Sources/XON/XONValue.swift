
import Foundation


public enum XCType : UInt32 {
    case simpleValue = 0
    case string
    case data
    case message
    case array
}
public enum XONValue : Hashable {
    case null
    case bool(Bool)
    case string(String)
    case data(Data)
    case number(NSNumber)
    case time(XONTime)
    case message([UInt32 : XONValue])
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
    
    public func messageValue() throws -> [UInt32 : XONValue] {
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
    
    public func value(_ type: [UInt32 : XONValue].Type) throws -> [UInt32 : XONValue] {
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
    public let microsecond: Int64
    
    public init(microsecond: Int64) {
        self.microsecond = microsecond
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.microsecond)
    }
    
    public static func == (lhs: XONTime, rhs: XONTime) -> Bool {
        return lhs.microsecond == rhs.microsecond
    }
    
    public var isInvalid: Bool {
        return XTimestampIsInvalid(self.microsecond)
    }
    
    public static let microsecondPerSecond: UInt64 = 1_000_000
    public static let invalid = XONTime(microsecond: XTimestampInvalidDefault())
    public static let zero = XONTime(microsecond: 0)
    
    public static func time(microsecond: Int64) -> XONTime {
        return XONTime(microsecond: microsecond)
    }
}
