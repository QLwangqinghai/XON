//
//  XONCoder.swift
//  XON
//
//  Created by vector on 2024/4/28.
//

import Foundation

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

public enum XCodingKey {
    case messageField(UInt32)
    case arrayIndex(Int)
    case top
}

public protocol XCodingContainer {
    var parent: XCodingContainer? { get }
    var key: XCodingKey { get }
    var userInfo: [AnyHashable : Any] { get }
}

extension XCodingContainer {
    public var codingPath: [XCodingKey] {
        var result: [XCodingKey] = [self.key]
        while let parent = self.parent {
            result.insert(parent.key, at: 0)
        }
        return result
    }
}

public struct XMessageDecodingContainer : XCodingContainer {
    public let parent: XCodingContainer?
    public let key: XCodingKey
    public let userInfo: [AnyHashable : Any]
    public let message: Message<XONValue>
    
    public init(parent: XCodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any], message: Message<XONValue>) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
        self.message = message
    }
    
    public var count: Int {
        return self.message.count
    }
    
    public func collection() throws -> Message<XONValue> {
        return self.message
    }
    
    public func elements() throws -> [(UInt32, XDecoder)] {
        return self.message.collection.map { (key, value) in
            return (key, value)
        }.sorted { lhs, rhs in
            return lhs.0 < rhs.0
        }.map { (key, value) in
            return (key, XDecoderImpl(parent: self, key: .messageField(key), userInfo: self.userInfo, value: value))
        }
    }

    public var allKeys: [UInt32] {
        return self.message.collection.keys.sorted()
    }

    public func contains(_ key: UInt32) -> Bool {
        return nil != self.message.collection[key]
    }

    public func decoder(forKey key: UInt32) throws -> XDecoder {
        guard let value = self.message.collection[key] else {
            throw XON.fieldNotFound
        }
        return XDecoderImpl(parent: self, key: .messageField(key), userInfo: self.userInfo, value: value)
    }
}


public struct XArrayDecodingContainer : XCodingContainer {
    public let parent: XCodingContainer?
    public let key: XCodingKey
    public let userInfo: [AnyHashable : Any]
    let array: [XONValue]
    
    public init(parent: XCodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any], array: [XONValue]) {
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

public protocol XDecoder : XCodingContainer {

    func isNull() -> Bool
    
    func boolValue() throws -> Bool

    func numberValue() throws -> NSNumber

    func timeValue() throws -> XONTime

    func stringValue() throws -> String

    func dataValue() throws -> Data
    
    func messageContainer() throws -> XMessageDecodingContainer
    
    func arrayContainer() throws -> XArrayDecodingContainer

    func decode<T>(_ type: T.Type) throws -> T where T : XCodable
    
}

public class XDecoderImpl : XDecoder {

    public let value: XONValue
    public let parent: XCodingContainer?
    
    public let key: XCodingKey
    
    public let userInfo: [AnyHashable : Any]

    public init(userInfo: [AnyHashable : Any], value: XONValue) {
        self.value = value
        self.parent = nil
        self.key = .top
        self.userInfo = userInfo
    }
    
    public init(parent: XCodingContainer, key: XCodingKey, userInfo: [AnyHashable : Any], value: XONValue) {
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
    
    public func messageValue() throws -> Message<XONValue> {
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

public protocol XEncoder : XCodingContainer {
    mutating func encodeNull() throws
    mutating func encodeBool(_ value: Bool) throws
    mutating func encodeNumber(_ value: NSNumber) throws
    mutating func encodeTime(_ value: XONTime) throws
    mutating func encodeString(_ value: String) throws
    mutating func encodeData(_ value: Data) throws
    mutating func encodeMessage(_ message: Message<XONValue>) throws
    mutating func encodeArray(_ array: [XONValue]) throws
    mutating func encodeMessage(type: Int64, container: (inout XMessageEncodingContainer) throws -> Void) throws
    mutating func encodeArray(_ container: (inout XArrayEncodingContainer) throws -> Void) throws
    mutating func encode<T>(_ value: T) throws -> Data where T : XEncodable
}

public struct XMessageEncodingContainer : XCodingContainer {
    public let parent: XCodingContainer?
    public let key: XCodingKey
    public let userInfo: [AnyHashable : Any]
    var message: Message<XONValue>
    
    init(parent: XCodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any], type: Int64) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
        self.message = Message<XONValue>()
    }
    
    public mutating func encodeElement<T>(key: UInt32, value: T) throws where T : XEncodable {
        let encoder = XEncoderImpl(parent: self, key: XCodingKey.messageField(key), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try value.encode(to: &e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.message[key] = v
    }
    public mutating func encodeElement(key: UInt32, coding: (inout XEncoder) throws -> Void) throws {
        let encoder = XEncoderImpl(parent: self, key: XCodingKey.messageField(key), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try coding(&e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.message[key] = v
    }
}

public struct XArrayEncodingContainer : XCodingContainer {
    public let parent: XCodingContainer?
    public let key: XCodingKey
    public let userInfo: [AnyHashable : Any]
    var array: [XONValue] = []
    
    init(parent: XCodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any]) {
        self.parent = parent
        self.key = key
        self.userInfo = userInfo
    }
    
    public mutating func encodeElement<T>(_ value: T) throws where T : XEncodable {
        let encoder = XEncoderImpl(parent: self, key: XCodingKey.arrayIndex(self.array.count), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try value.encode(to: &e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.array.append(v)
    }

    public mutating func encodeElement(_ coding: (inout XEncoder) throws -> Void) throws {
        let encoder = XEncoderImpl(parent: self, key: XCodingKey.arrayIndex(self.array.count), userInfo: self.userInfo)
        var e: XEncoder = encoder
        try coding(&e)
        guard let v = encoder.value else {
            throw XON.objectError
        }
        self.array.append(v)
    }
}

public struct XEncoderImpl: XEncoder {
    public let parent: XCodingContainer?
    public let key: XCodingKey
    public let userInfo: [AnyHashable : Any]
    var value: XONValue? = nil
    
    init(userInfo: [AnyHashable : Any]) {
        self.parent = nil
        self.key = .top
        self.userInfo = userInfo
    }
    init(parent: XCodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any]) {
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
    public mutating func encodeMessage(_ message: Message<XONValue>) throws {
        self.value = .message(message)
    }
    public mutating func encodeArray(_ array: [XONValue]) throws {
        self.value = .array(array)
    }
    
    public mutating func encodeMessage(type: Int64, container: (inout XMessageEncodingContainer) throws -> Void) throws {
        var encoder = XMessageEncodingContainer(parent: self.parent, key: self.key, userInfo: self.userInfo, type: type)
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
public typealias XCodable = XDecodable & XEncodable

