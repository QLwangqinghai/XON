//
//  Message.swift
//  XON
//
//  Created by vector on 2024/5/4.
//

import Foundation

public struct Message<Value> : Hashable where Value : Hashable {
    public var type: Int64
    public var collection: [UInt32 : Value]
    public var count: Int {
        return self.collection.count
    }

    public init(type: Int64) {
        assert(type >= 0)
        self.type = type
        self.collection = [:]
    }

    public init(type: Int64, collection: [UInt32 : Value]) {
        assert(type >= 0)
        self.type = type
        self.collection = collection
    }
    
    public subscript(key: UInt32) -> Value? {
        get {
            return self.collection[key]
        }
        set {
            if let v = newValue {
                // setvalue
                _ = self.updateValue(v, forKey: key)
            } else {
                // removeValue
                self.collection.removeValue(forKey: key)
            }
        }
    }
    @discardableResult public mutating func updateValue(_ value: Value, forKey key: UInt32) -> Value? {
        return self.collection.updateValue(value, forKey: key)
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.collection.reserveCapacity(minimumCapacity)
    }
    
    public static func == (lhs: Message<Value>, rhs: Message<Value>) -> Bool {
        return lhs.type == rhs.type && lhs.collection == rhs.collection
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.type)
        hasher.combine(self.collection)
    }
}

