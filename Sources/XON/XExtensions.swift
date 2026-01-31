
import Foundation

extension NSNumber {
    public var isBoolType: Bool {
        let n = self as CFNumber
        return CFGetTypeID(n) == CFBooleanGetTypeID()
    }
    
    public static func number(xvalue: XCNumberValue_s) -> NSNumber? {
        switch xvalue.type {
        case Int(XCNumberTypeSInt.rawValue):
            return xvalue.value.s as NSNumber
        case Int(XCNumberTypeUInt.rawValue):
            return xvalue.value.u as NSNumber
        case Int(XCNumberTypeFloat64.rawValue):
            return xvalue.value.f as NSNumber
        default:
            return nil
        }
    }
}

extension Bool : XCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeBool(self)
    }
    
    public init(from decoder: XDecoder) throws {
        self = try decoder.boolValue()
    }
}

extension Data : XCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeData(self)
    }
    public init(from decoder: XDecoder) throws {
        self = try decoder.dataValue()
    }
}

extension String : XCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeString(self)
    }
    public init(from decoder: XDecoder) throws {
        self = try decoder.stringValue()
    }
}

extension Int8 : XCodable {
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
extension UInt8 : XCodable {
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

extension Int16 : XCodable {
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
extension UInt16 : XCodable {
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

extension Int32 : XCodable {
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
extension UInt32 : XCodable {
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

extension Int64 : XCodable {
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
extension UInt64 : XCodable {
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

extension Int : XCodable {
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
extension UInt : XCodable {
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

extension Float : XCodable {
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
extension Double : XCodable {
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

extension XONTime : XCodable {
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeTime(self)
    }
    public init(from decoder: XDecoder) throws {
        self = try decoder.timeValue()
    }
}
extension XONTime : Codable {
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard let v = XONTime(jsonString: string) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: ""))
        }
        self = v
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.encodeToJsonString())
    }
    
    public init?(jsonString string: String) {
        guard string.count > 0, var value = Int64(string) else {
            return nil
        }
        self = XONTime.time(microsecond: value)
    }
    
    public func encodeToJsonString() -> String {
        return self.microsecond.description
    }
    
    public func numberValue() -> NSNumber {
        if self.isInvalid {
            return Double.nan as NSNumber
        } else {
            return self.microsecond as NSNumber
        }
    }
    
    public init?(number: NSNumber) {
        if let n = number as? Double, n.isNaN {
            self = XONTime.invalid
        } else {
            guard let n = number as? Int64 else {
                return nil
            }
            self = XONTime(microsecond: n)
        }
    }

}
