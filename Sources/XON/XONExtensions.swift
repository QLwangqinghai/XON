
import Foundation
import XONBase

extension NSNumber {
    public var isBoolType: Bool {
        let n = self as CFNumber
        return CFGetTypeID(n) == CFBooleanGetTypeID()
    }
    
    public static func number(xvalue: XONNumberValue_s) -> NSNumber? {
        switch xvalue.type {
        case Int(XONNumberTypeSInt.rawValue):
            return xvalue.value.s as NSNumber
        case Int(XONNumberTypeUInt.rawValue):
            return xvalue.value.u as NSNumber
        case Int(XONNumberTypeFloat64.rawValue):
            return xvalue.value.f as NSNumber
        default:
            return nil
        }
    }
}

extension Bool : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeBool(self)
    }
    
    public init(from decoder: XDecoder) throws {
        self = try decoder.boolValue()
    }
}

extension Data : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeData(self)
    }
    public init(from decoder: XDecoder) throws {
        self = try decoder.dataValue()
    }
}

extension String : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeString(self)
    }
    public init(from decoder: XDecoder) throws {
        self = try decoder.stringValue()
    }
}

extension Int8 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? Int8 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}
extension UInt8 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? UInt8 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}

extension Int16 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? Int16 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}
extension UInt16 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? UInt16 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}

extension Int32 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? Int32 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}
extension UInt32 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? UInt32 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}

extension Int64 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? Int64 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}
extension UInt64 : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? UInt64 else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}

extension Int : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? Int else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}
extension UInt : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? UInt else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}

extension Float : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? Float else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}
extension Double : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeNumber(self as NSNumber)
    }
    public init(from decoder: XDecoder) throws {
        guard let v = try decoder.numberValue() as? Double else {
            throw XON.numberOutOfBoundsError
        }
        self = v
    }
}

extension XONTime : XONCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeTime(self)
    }
    public init(from decoder: XDecoder) throws {
        self = try decoder.timeValue()
    }
}
