//
//  Collection.swift
//  XON
//
//  Created by vector on 2024/5/3.
//

import Foundation

public struct OrderedMap<Key, Value> where Key : Hashable {
    public class Element<Key, Value> {
        public let key: Key
        public let value: Value
        public init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    public private(set) var map: Dictionary<Key, Element<Key, Value>>
    
    /// The order of the first insertion
    public private(set) var array: [Element<Key, Value>]
    
    public var count: Int {
        return self.array.count
    }
    
    public init() {
        self.map = [:]
        self.array = []
    }
        
    public init<S>(uniqueKeysWithValues: S) where S : Sequence, S.Element == (Key, Value) {
        let array = uniqueKeysWithValues.map { (key, value) in
            return (key, Element(key: key, value: value))
        }
        let map = Dictionary(uniqueKeysWithValues: array)
        self.map = map
        self.array = array.map({ element in
            return element.1
        })
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return self.map[key]?.value
        }
        set {
            if let v = newValue {
                // setvalue
                _ = self.updateValue(v, forKey: key)
            } else {
                // removeValue
                if let _ = self.map.removeValue(forKey: key) {
                    let index = self.array.firstIndex(where: { element in
                        return element.key == key
                    })!
                    self.array.remove(at: index)
                }
            }
        }
    }

    public func forEach(_ body: (Key, Value) throws -> Void) rethrows {
        return try self.array.forEach({ element in
            try body(element.key, element.value)
        })
    }
    public func map<T>(_ transform: (Key, Value) throws -> T) rethrows -> [T] {
        return try self.array.map({ element in
            return try transform(element.key, element.value)
        })
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.map.reserveCapacity(minimumCapacity)
        self.array.reserveCapacity(minimumCapacity)
    }
    
    @discardableResult public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let element = Element(key: key, value: value)
        if let old = self.map.updateValue(element, forKey: key) {
            let index = self.array.firstIndex(where: { element in
                return element.key == key
            })!
            self.array[index] = element
            return old.value
        } else {
            self.array.append(element)
            return nil
        }
    }
}

extension OrderedMap : XCodable where Key : XCodable, Value : XCodable {
    public init(from decoder: XDecoder) throws {
        self.init()
        let elements = try decoder.arrayContainer().elements()
        guard elements.count % 2 == 0 else {
            throw XON.contentError
        }
        for i in 0 ..< elements.count where i % 2 == 0 {
            let key = try Key(from: elements[i].1)
            let value = try Value(from: elements[i + 1].1)
            guard nil == self.updateValue(value, forKey: key) else {
                throw XON.contentError
            }
        }
    }
    
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeArray { container in
            try self.forEach { key, value in
                try container.encodeElement(key)
                try container.encodeElement(value)
            }
        }
    }
}

extension OrderedMap.Element : Equatable where Key : Equatable, Value : Equatable {
    public static func == (lhs: OrderedMap.Element<Key, Value>, rhs: OrderedMap.Element<Key, Value>) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}

extension OrderedMap: Equatable where Value : Equatable {
    public static func == (lhs: OrderedMap<Key, Value>, rhs: OrderedMap<Key, Value>) -> Bool {
        return lhs.array == rhs.array
    }
}

extension OrderedMap: Hashable where Value : Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.array.count)
        // 最后4个elements
        self.array.reversed().prefix(4).forEach { element in
            hasher.combine(element.key)
        }
    }
}

public struct OrderedSet<Key> : Hashable where Key : Hashable {
    public private(set) var set: Set<Key>
    
    /// The order of the first insertion
    public private(set) var array: [Key]
    
    public var count: Int {
        return self.array.count
    }
    
    public init() {
        self.set = []
        self.array = []
    }
    
    public init<S>(uniqueKeys: S) where S : Sequence, S.Element == Key {
        let array = Array(uniqueKeys)
        let set = Set(array)
        assert(array.count == set.count)
        self.set = set
        self.array = array
    }

    public func contains(_ member: Key) -> Bool {
        return self.set.contains(member)
    }
    public mutating func update(with key: Key) -> Key? {
        if let v = self.set.update(with: key) {
            return v
        } else {
            self.array.append(key)
            return nil
        }
    }
    public mutating func insert(_ member: Key) {
        if !self.set.contains(member) {
            self.array.append(member)
            self.set.insert(member)
        }
    }
    @discardableResult public mutating func remove(_ member: Key) -> Key? {
        if let old = self.set.remove(member) {
            self.array.removeAll(where: { k in
                return k == member
            })
            return old
        }
        return nil
    }
    public func forEach(_ body: (Key) throws -> Void) rethrows {
        try self.array.forEach(body)
    }
    public func map<T>(_ transform: (Key) throws -> T) rethrows -> [T] {
        return try self.array.map(transform)
    }

    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.set.reserveCapacity(minimumCapacity)
        self.array.reserveCapacity(minimumCapacity)
    }
    
    public static func == (lhs: OrderedSet<Key>, rhs: OrderedSet<Key>) -> Bool {
        return lhs.array == rhs.array
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.array.count)
        // 最后4个elements
        self.array.reversed().prefix(4).forEach { key in
            hasher.combine(key)
        }
    }
}

extension OrderedSet : XCodable where Key : XCodable {
    public init(from decoder: XDecoder) throws {
        self.init()
        let elements = try decoder.arrayContainer().elements()
        for (_, coder) in elements {
            let key = try Key(from: coder)
            guard nil == self.update(with: key) else {
                throw XON.contentError
            }
        }
    }
    
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeArray { container in
            try self.forEach { key in
                try container.encodeElement(key)
            }
        }
    }
}

extension Array : XCodable where Array.Element : XCodable {
    public init(from decoder: XDecoder) throws {
        let elements = try decoder.arrayContainer().elements()
        self = try elements.map({ (index, coder) in
            return try Element(from: coder)
        })
    }
    
    public func encode(to encoder: inout XEncoder) throws {
        try encoder.encodeArray { container in
            try self.forEach { element in
                try container.encodeElement(element)
            }
        }
    }
}
