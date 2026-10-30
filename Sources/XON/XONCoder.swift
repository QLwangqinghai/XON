
import Foundation
import CX

public final class XONEncoder {
    public func encode<T>(_ value: T) throws -> Data where T : XEncodable {
        let encoder = XEncoderImpl(userInfo: [:])
        var e: XEncoder = encoder
        try value.encode(to: &e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        return try XONSerialization.encode(v)
    }
}

public final class XONDecoder {
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : XDecodable {
        let value = try XONSerialization.decode(data)
        let decoder = XDecoderImpl(userInfo: [:], value: value)
        return try T(from: decoder)
    }
}

public enum XONCodingKey {
    case messageField(UInt32)
    case arrayIndex(Int)
    case top
}

public protocol XONCodingContainer {
    var parent: XONCodingContainer? { get }
    var key: XONCodingKey { get }
    var userInfo: [AnyHashable : Any] { get }
}

extension XONCodingContainer {
    public var codingPath: [XONCodingKey] {
        var result: [XONCodingKey] = [self.key]
        while let parent = self.parent {
            result.insert(parent.key, at: 0)
        }
        return result
    }
}

public struct XMessageDecodingContainer : XONCodingContainer {
    public let parent: XONCodingContainer?
    public let key: XONCodingKey
    public let userInfo: [AnyHashable : Any]
    public let message: [UInt32 : XONValue]
    
    public init(parent: XONCodingContainer?, key: XONCodingKey, userInfo: [AnyHashable : Any], message: [UInt32 : XONValue]) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
        self.message = message
    }
    
    public var count: Int {
        return self.message.count
    }
    
    public func collection() throws -> [UInt32 : XONValue] {
        return self.message
    }
    
    public func elements() throws -> [(UInt32, XDecoder)] {
        return self.message.map { (key, value) in
            return (key, value)
        }.sorted { lhs, rhs in
            return lhs.0 < rhs.0
        }.map { (key, value) in
            return (key, XDecoderImpl(parent: self, key: .messageField(key), userInfo: self.userInfo, value: value))
        }
    }

    public var allKeys: [UInt32] {
        return self.message.keys.sorted()
    }

    public func contains(_ key: UInt32) -> Bool {
        return nil != self.message[key]
    }

    public func decoder(forKey key: UInt32) throws -> XDecoder {
        guard let value = self.message[key] else {
            throw XON.fieldNotFound
        }
        return XDecoderImpl(parent: self, key: .messageField(key), userInfo: self.userInfo, value: value)
    }
}


public struct XArrayDecodingContainer : XONCodingContainer {
    public let parent: XONCodingContainer?
    public let key: XONCodingKey
    public let userInfo: [AnyHashable : Any]
    let array: [XONValue]
    
    public init(parent: XONCodingContainer?, key: XONCodingKey, userInfo: [AnyHashable : Any], array: [XONValue]) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
        self.array = array
    }
    
    public var count: Int {
        return self.array.count
    }
    
    public func collection() throws -> [XONValue] {
        return self.array
    }
    
    public func elements() throws -> [(Int, XDecoder)] {
        return self.array.enumerated().map { (index, element) in
            return (index, XDecoderImpl(parent: self, key: .arrayIndex(index), userInfo: self.userInfo, value: element))
        }
    }
}

public protocol XDecoder : XONCodingContainer {

    func isNull() -> Bool
    
    func boolValue() throws -> Bool

    func numberValue() throws -> NSNumber

    func timeValue() throws -> XONTime

    func stringValue() throws -> String

    func dataValue() throws -> Data
    
    func messageContainer() throws -> XMessageDecodingContainer
    
    func arrayContainer() throws -> XArrayDecodingContainer

    func decode<T>(_ type: T.Type) throws -> T where T : XONCodable
    
}

public class XDecoderImpl : XDecoder {

    public let value: XONValue
    public let parent: XONCodingContainer?
    public let key: XONCodingKey
    
    public let userInfo: [AnyHashable : Any]

    public init(userInfo: [AnyHashable : Any], value: XONValue) {
        self.value = value
        self.parent = nil
        self.key = .top
        self.userInfo = userInfo
    }
    
    public init(parent: XONCodingContainer, key: XONCodingKey, userInfo: [AnyHashable : Any], value: XONValue) {
        self.value = value
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
    }
    
    public func isNull() -> Bool {
        return .null == self.value
    }
    
    public func boolValue() throws -> Bool {
        guard case .bool(let bool) = self.value else {
            throw XON.typeError
        }
        return bool
    }

    public func numberValue() throws -> NSNumber {
        guard case .number(let value) = self.value else {
            throw XON.typeError
        }
        return value
    }
    
    public func timeValue() throws -> XONTime {
        guard case .time(let value) = self.value else {
            throw XON.typeError
        }
        return value
    }
    
    public func stringValue() throws -> String {
        guard case .string(let value) = self.value else {
            throw XON.typeError
        }
        return value
    }
    
    public func dataValue() throws -> Data {
        guard case .data(let value) = self.value else {
            throw XON.typeError
        }
        return value
    }
    
    public func decode<T>(_ type: T.Type) throws -> T where T : XDecodable, T : XEncodable {
        return try T(from: self)
    }
    
    public func messageValue() throws -> [UInt32 : XONValue] {
        guard case .message(let value) = self.value else {
            throw XON.typeError
        }
        return value
    }
    
    public func arrayValue() throws -> [XONValue] {
        guard case .array(let value) = self.value else {
            throw XON.typeError
        }
        return value
    }
    public func messageContainer() throws -> XMessageDecodingContainer {
        guard case .message(let value) = self.value else {
            throw XON.typeError
        }
        return XMessageDecodingContainer(parent: self.parent, key: self.key, userInfo: self.userInfo, message: value)
    }
    
    public func arrayContainer() throws -> XArrayDecodingContainer {
        guard case .array(let value) = self.value else {
            throw XON.typeError
        }
        return XArrayDecodingContainer(parent: self.parent, key: self.key, userInfo: self.userInfo, array: value)
    }

}

public protocol XEncoder : XONCodingContainer {
    mutating func encodeNull() throws
    mutating func encodeBool(_ value: Bool) throws
    mutating func encodeNumber(_ value: NSNumber) throws
    mutating func encodeTime(_ value: XONTime) throws
    mutating func encodeString(_ value: String) throws
    mutating func encodeData(_ value: Data) throws
    mutating func encodeMessage(_ message: [UInt32 : XONValue]) throws
    mutating func encodeArray(_ array: [XONValue]) throws
    mutating func encodeMessage(_ container: (inout XMessageEncodingContainer) throws -> Void) throws
    mutating func encodeArray(_ container: (inout XArrayEncodingContainer) throws -> Void) throws
    mutating func encode<T>(_ value: T) throws -> Data where T : XEncodable
}

public struct XMessageEncodingContainer : XONCodingContainer {
    public let parent: XONCodingContainer?
    public let key: XONCodingKey
    public let userInfo: [AnyHashable : Any]
    var message: [UInt32 : XONValue]
    
    init(parent: XONCodingContainer?, key: XONCodingKey, userInfo: [AnyHashable : Any]) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
        self.message = [UInt32 : XONValue]()
    }
    
    public mutating func encodeElement<T>(key: UInt32, value: T) throws where T : XEncodable {
        let encoder = XEncoderImpl(parent: self, key: XONCodingKey.messageField(key), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try value.encode(to: &e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.message[key] = v
    }
    public mutating func encodeElement(key: UInt32, coding: (inout XEncoder) throws -> Void) throws {
        let encoder = XEncoderImpl(parent: self, key: XONCodingKey.messageField(key), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try coding(&e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.message[key] = v
    }
}

public struct XArrayEncodingContainer : XONCodingContainer {
    public let parent: XONCodingContainer?
    public let key: XONCodingKey
    public let userInfo: [AnyHashable : Any]
    var array: [XONValue] = []
    
    init(parent: XONCodingContainer?, key: XONCodingKey, userInfo: [AnyHashable : Any]) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
    }
    
    public mutating func encodeElement<T>(_ value: T) throws where T : XEncodable {
        let encoder = XEncoderImpl(parent: self, key: XONCodingKey.arrayIndex(self.array.count), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try value.encode(to: &e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.array.append(v)
    }

    public mutating func encodeElement(_ coding: (inout XEncoder) throws -> Void) throws {
        let encoder = XEncoderImpl(parent: self, key: XONCodingKey.arrayIndex(self.array.count), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try coding(&e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.array.append(v)
    }
}

public struct XEncoderImpl: XEncoder {
    public let parent: XONCodingContainer?
    public let key: XONCodingKey
    public let userInfo: [AnyHashable : Any]
    var value: XONValue? = nil
    
    init(userInfo: [AnyHashable : Any]) {
        self.parent = nil
        self.key = .top
        self.userInfo = userInfo
    }
    init(parent: XONCodingContainer?, key: XONCodingKey, userInfo: [AnyHashable : Any]) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
    }
    
    public mutating func encodeNull() throws {
        self.value = .null
    }
    public mutating func encodeBool(_ value: Bool) throws {
        self.value = .bool(value)
    }
    public mutating func encodeNumber(_ value: NSNumber) throws {
        self.value = .number(value)
    }

    public mutating func encodeTime(_ value: XONTime) throws {
        self.value = .time(value)
    }
    public mutating func encodeString(_ value: String) throws {
        self.value = .string(value)
    }
    public mutating func encodeData(_ value: Data) throws {
        self.value = .data(value)
    }
    public mutating func encodeMessage(_ message: [UInt32 : XONValue]) throws {
        self.value = .message(message)
    }
    public mutating func encodeArray(_ array: [XONValue]) throws {
        self.value = .array(array)
    }
    
    public mutating func encodeMessage(_ container: (inout XMessageEncodingContainer) throws -> Void) throws {
        var encoder = XMessageEncodingContainer(parent: self.parent, key: self.key, userInfo: self.userInfo)
        do {
            try container(&encoder)
        } catch let error {
            throw error
        }
        self.value = .message(encoder.message)
    }
    
    public mutating func encodeArray(_ closure: (inout XArrayEncodingContainer) throws -> Void) throws {
        var encoder = XArrayEncodingContainer(parent: self.parent, key: self.key, userInfo: self.userInfo)
        do {
            try closure(&encoder)
        } catch let error {
            throw error
        }
        self.value = .array(encoder.array)
    }
    
    public mutating func encode<T>(_ value: T) throws -> Data where T : XEncodable {
        var e: XEncoder = self
        try value.encode(to: &e)
        guard let v = self.value else {
            throw XON.objectError
        }
        return try XONSerialization.encode(v)
    }

}

public protocol XDecodable {
    init(from decoder: XDecoder) throws
}

public protocol XEncodable {
    func encode(to encoder: inout XEncoder) throws
}
public typealias XONCodable = XDecodable & XEncodable

