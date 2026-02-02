
import Foundation
import XONBase

public struct XONTime : Hashable, Codable {
    public let microsecond: Int64
    
    public init(microsecond: Int64) {
        self.microsecond = microsecond
    }
    public init(from decoder: Decoder) throws {
        self.microsecond = try decoder.singleValueContainer().decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.microsecond)
    }
    
    public func numberValue() -> NSNumber {
        return self.microsecond as NSNumber
    }
    
    public init?(number: NSNumber) {
        guard let n = number as? Int64 else {
            return nil
        }
        self = XONTime(microsecond: n)
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
    public static let min = XONTime(microsecond: XTimestampMin())
    public static let max = XONTime(microsecond: XTimestampMax())
    
    public static func time(microsecond: Int64) -> XONTime {
        return XONTime(microsecond: microsecond)
    }
}
