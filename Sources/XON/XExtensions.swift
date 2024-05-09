
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
    public enum CodingValue : String {
        case invalid = "NaN"
        case distantPast = "-Infinity"
        case distantFuture = "Infinity"
    }
    
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
        switch string {
        case CodingValue.invalid.rawValue:
            self = .invalid
        case CodingValue.distantPast.rawValue:
            self = .distantPast
        case CodingValue.distantFuture.rawValue:
            self = .distantFuture
        default:
            guard string.count > 0, var decimal = Decimal(string: string) else {
                return nil
            }
            var secondDecimal = Decimal()
            NSDecimalRound(&secondDecimal, &decimal, 0, NSDecimalNumber.RoundingMode.down)
            let asecondDecimal = (decimal - secondDecimal) * Decimal(XONTime.attosecondPerSecond)
            guard let second = NSDecimalNumber(decimal: secondDecimal) as? Int64, let asecond = NSDecimalNumber(decimal: asecondDecimal) as? UInt64 else {
                return nil
            }
            self = XONTime.time(second: second, attosecond: asecond)
        }
    }
    
    public func encodeToJsonString() -> String {
        if self.isInvalid {
            return CodingValue.invalid.rawValue
        } else if self == .distantPast {
            return CodingValue.distantPast.rawValue
        } else if self == .distantFuture {
            return CodingValue.distantFuture.rawValue
        } else {
            let d = (Decimal(self.second) * Decimal(XONTime.attosecondPerSecond) + Decimal(self.attosecond)) / Decimal(XONTime.attosecondPerSecond)
            return d.formatted(.number)
        }
    }
    
    public func decimalValue() -> Decimal {
        if self.isInvalid {
            return Decimal.nan
        } else if self == .distantPast {
            return Decimal(-Double.infinity)
        } else if self == .distantFuture {
            return Decimal(Double.infinity)
        } else {
            let d = (Decimal(self.second) * Decimal(XONTime.attosecondPerSecond) + Decimal(self.attosecond)) / Decimal(XONTime.attosecondPerSecond)
            return d
        }
    }
    
    public init?(decimal: Decimal) {
        if decimal.isNaN {
            self = .invalid
        } else if decimal.isInfinite {
            if decimal.isSignMinus {
                self = .distantPast
            } else {
                self = .distantFuture
            }
        } else {
            var d = decimal
            var secondDecimal = Decimal()
            NSDecimalRound(&secondDecimal, &d, 0, NSDecimalNumber.RoundingMode.down)
            let asecondDecimal = (decimal - secondDecimal) * Decimal(XONTime.attosecondPerSecond)
            guard let second = NSDecimalNumber(decimal: secondDecimal) as? Int64, let asecond = NSDecimalNumber(decimal: asecondDecimal) as? UInt64 else {
                return nil
            }
            self = XONTime.time(second: second, attosecond: asecond)
        }
    }
    
    public func numberValue() -> NSNumber {
        if self.isInvalid {
            return Double.nan as NSNumber
        } else if self == .distantPast {
            return (-Double.infinity) as NSNumber
        } else if self == .distantFuture {
            return Double.infinity as NSNumber
        } else {
            let d = (Decimal(self.second) * Decimal(XONTime.attosecondPerSecond) + Decimal(self.attosecond)) / Decimal(XONTime.attosecondPerSecond)
            return NSDecimalNumber(decimal: d)
        }
    }
    
    public init?(number: NSNumber) {
        if let second = number as? Int64 {
            self = XONTime(second: second)
        } else if var decimal = number as? Decimal {
            var secondDecimal = Decimal()
            NSDecimalRound(&secondDecimal, &decimal, 0, NSDecimalNumber.RoundingMode.down)
            let asecondDecimal = (decimal - secondDecimal) * Decimal(XONTime.attosecondPerSecond)
            guard let second = NSDecimalNumber(decimal: secondDecimal) as? Int64, let asecond = NSDecimalNumber(decimal: asecondDecimal) as? UInt64 else {
                return nil
            }
            self = XONTime.time(second: second, attosecond: asecond)
        } else {
            return nil
        }
    }

}
