
import Foundation

extension JSONSerialization {
    public static func decode(_ data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .json5Allowed])
    }

    public static func encode(_ value: Any) throws -> Data {
        return try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
    }
}

public struct XONSerialization {
    public static func decode(_ data: Data) throws -> XONValue {
        let reader = XCReader(data: data as NSData)
        return try reader.readValue()
    }

    public static func encode(_ value: XONValue) throws -> Data {
        return try XCWriter.writeValue(value)
    }
}

public class XCReader {
    public var offset: Int
    public let endIndex: Int
    public let data: NSData
    public let bytes: UnsafePointer<UInt8>

    public init(offset: Int = 0, data: NSData, endIndex: Int? = nil) {
        self.offset = offset
        self.data = data
        self.bytes = data.bytes.bindMemory(to: UInt8.self, capacity: data.count)
        if let endIndex = endIndex {
            self.endIndex = min(endIndex, data.endIndex)
        } else {
            self.endIndex = data.endIndex
        }
    }
    
    public func read(_ closure: () -> XONError_e) throws {
        let value = closure()
        if value != XONErrorNone {
            throw XON.error(code: value)
        }
    }
    private func readHeader(index: UnsafeMutablePointer<Int>) throws -> XCValueHeader_s {
        var header = XCValueHeaderMake()
        let error = XCDecodeHeader(self.bytes, self.endIndex, index, &header)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        return header
    }
    
    private func readMessageFieldOffset(index: UnsafeMutablePointer<Int>) throws -> UInt32 {
        var offset: UInt32 = 0
        let error = XCDecodeFieldKeyOffset(self.bytes, self.endIndex, index, &offset)
        guard error == XONErrorNone else {
            throw XON.typeError
        }
        return offset
    }
    
    public func readDataBody(index: UnsafeMutablePointer<Int>, length: Int) throws -> Data {
        guard length >= 0 else {
            throw XON.countError
        }
        guard index.pointee + length <= self.data.count else {
            throw XON.notEnoughError
        }
        let data = Data(bytes: self.bytes.advanced(by: index.pointee), count: length)
        index.pointee += length
        return data
    }
    
    public func readStringBody(index: UnsafeMutablePointer<Int>, length: Int) throws -> String {
        guard length >= 0 else {
            throw XON.countError
        }
        guard index.pointee + length <= self.data.count else {
            throw XON.notEnoughError
        }
        guard let string = NSString(bytes: self.bytes.advanced(by: index.pointee), length: length, encoding: String.Encoding.utf8.rawValue) else {
            throw XON.stringContentError
        }
        index.pointee += length
        return string as String
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
    private func readNumber(index: UnsafeMutablePointer<Int>, header: XCNumberHeader_s) throws -> NSNumber {
        var value = XCNumberValue_s()
        let error = XCDecodeNumber64(self.bytes, self.endIndex, index, header.format, header.length, &value)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        guard let n = NSNumber.number(xvalue: value) else {
            throw XON.error(code: XONErrorNumberOutOfBounds)
        }
        return n
    }
    private func readTime(index: UnsafeMutablePointer<Int>, header: XCTime_s) throws -> XONTime {
        return XONTime.time(second: header.second, attosecond: header.attosecond)
    }
    
    private func readValue(index: UnsafeMutablePointer<Int>) throws -> XONValue {
        let header = try self.readHeader(index: index)
        guard let type = XONType(rawValue: header.type) else {
            throw XON.typeError
        }
        switch type {
        case .null:
            return .null
        case .bool:
            return .bool(header.value.boolValue)
        case .string:
            let length = header.value.count
            return .string(try readStringBody(index: index, length: length))
        case .data:
            let length = header.value.count
            return .data(try readDataBody(index: index, length: length))
        case .array:
            let count = header.value.count
            var elements: [XONValue] = []
            elements.reserveCapacity(count)
            for _ in 0 ..< count {
                let value = try self.readValue(index: index)
                elements.append(value)
            }
            return .array(elements)
        case .number:
            let n = try self.readNumber(index: index, header: header.value.number)
            return .number(n)
        case .time:
            let t = try self.readTime(index: index, header: header.value.time)
            return .time(t)
        case .message:
            let count = header.value.count
            var prev: UInt32 = 0
            var collection: [UInt32 : XONValue] = [:]
            collection.reserveCapacity(count)
            for _ in 0 ..< count {
                let offset = try self.readMessageFieldOffset(index: index)
                guard prev <= UInt32.max - offset else {
                    throw XON.error(code: XONErrorMessageFieldKeyOffset)
                }
                let key = prev + offset
                prev = key
                let field = try self.readValue(index: index)
                collection[key] = field
            }
            guard collection.count == count else {
                throw XON.error(code: XONErrorMessageContent)
            }
            return .message(Message(collection: collection))
        }
    }
    
    public func readValue() throws -> XONValue {
        var index = 0
        return try self.readValue(index: &index)
    }
}

public class XCWriter {
    public var count: Int = 0
    private var capacity: Int
    private var _bytes: UnsafeMutableRawPointer
    
    public var bytes: UnsafeMutablePointer<UInt8> {
        return self._bytes.bindMemory(to: UInt8.self, capacity: self.capacity)
    }
    
    public init(minimumCapacity: Int) {
        let value = XCWriter.roundUpCapacity(minimumCapacity)
        self.capacity = value
        self._bytes = realloc(nil, value)
    }
    
    public func reserveCapacity(_ minimumCapacity: Int) {
        guard minimumCapacity >= self.capacity else {
            return
        }
        let value = XCWriter.roundUpCapacity(minimumCapacity)
        guard self.capacity != value else {
            return
        }
        self._bytes = realloc(self._bytes, value)
        self.capacity = value
    }
    
    public func fit() {
        if self.capacity != self.count {
            self._bytes = realloc(self._bytes, self.count)
            self.capacity = self.count
        }
    }
    
    deinit {
        free(self._bytes)
    }
    
    private static func roundUpCapacity(_ minimumCapacity: Int) -> Int {
        var value = max(0x1000, minimumCapacity)
        if value.leadingZeroBitCount + value.trailingZeroBitCount != value.bitWidth - 1 {
            value = 1 << (value.bitWidth - value.leadingZeroBitCount)
        }
//        if value >= 0x200000 {
//            value = (value + 0x200000 - 1) / 0x200000 * 0x200000
//        } else {
//            value = (value + 0x1000 - 1) / 0x1000 * 0x1000
//        }
        return value
    }
    
    public func write(_ closure: () -> XONError_e) throws {
        let value = closure()
        if value != XONErrorNone {
            throw NSError(domain: XON.domain, code: Int(value.rawValue))
        }
    }
    
    private func _writeValue(_ value: XONValue) throws {
        switch value {
        case .null:
            if self.count + 1 > self.capacity {
                self.reserveCapacity(self.count + 1)
            }
            try self.write({
                return XCencodeNull(self.bytes, self.capacity, &self.count)
            })
        case .bool(let v):
            if self.count + 1 > self.capacity {
                self.reserveCapacity(self.count + 1)
            }
            try self.write({
                return XCEncodeBool(self.bytes, self.capacity, &self.count, v)
            })
        case .string(let _v):
            let v = _v as String
            guard let data = v.data(using: .utf8) else {
                throw XON.error(code: XONErrorStringContent)
            }
            
            if self.count + 16 + data.count > self.capacity {
                self.reserveCapacity(self.count + 16 + data.count)
            }
            
            try self.write({
                return XCEncodeStringHeader(self.bytes, self.capacity, &self.count, data.count)
            })
            if self.count + data.count > self.capacity {
                self.reserveCapacity(self.count + data.count)
            }
            if !data.isEmpty {
                try self.write({
                    return data.withUnsafeBytes { ptr in
                        return XCEncodeBody(self.bytes, self.capacity, &self.count, ptr.baseAddress!, data.count)
                    }
                })
            }
        case .data(let data):
            if self.count + 16 + data.count > self.capacity {
                self.reserveCapacity(self.count + 16 + data.count)
            }
            try self.write({
                return XCEncodeDataHeader(self.bytes, self.capacity, &self.count, data.count)
            })
            if !data.isEmpty {
                try data.withUnsafeBytes { ptr in
                    try self.write({
                        return XCEncodeBody(self.bytes, self.capacity, &self.count, ptr.baseAddress!, data.count)
                    })
                }
            }
        case .array(let array):
            if self.count + 16 + array.count > self.capacity {
                self.reserveCapacity(self.count + 16 + array.count)
            }
            
            try self.write({
                return XCEncodeArrayHeader(self.bytes, self.capacity, &self.count, array.count)
            })
            try array.forEach { item in
                try self._writeValue(item)
            }
        case .number(let n):
            if self.count + 32 > self.capacity {
                self.reserveCapacity(self.count + 32)
            }
            let v = n
            if let value = v as? Double {
                try self.write({
                    return XCEncodeNumberDouble(self.bytes, self.capacity, &self.count, value)
                })
            } else if let value = v as? Int64 {
                try self.write({
                    return XCEncodeNumberSInt64(self.bytes, self.capacity, &self.count, value)
                })
            } else if let value = v as? UInt64 {
                try self.write({
                    return XCEncodeNumberUInt64(self.bytes, self.capacity, &self.count, value)
                })
            } else {
                throw XON.error(code: XONErrorNumberContent)
            }
        case .time(let v):
            if self.count + 16 > self.capacity {
                self.reserveCapacity(self.count + 16)
            }
            try self.write({
                if v == XONTime.invalid {
                    return XCEncodeTimeInvalid(self.bytes, self.capacity, &self.count)
                } else if v == XONTime.distantPast {
                    return XCEncodeTimeDistantPast(self.bytes, self.capacity, &self.count)
                } else if v == XONTime.distantFuture {
                    return XCEncodeTimeDistantFuture(self.bytes, self.capacity, &self.count)
                } else {
                    return XCEncodeTime(self.bytes, self.capacity, &self.count, v.second, v.attosecond)
                }
            })
        case .message(let message):
            if self.count + 32 + message.count * 2 > self.capacity {
                self.reserveCapacity(self.count + 32 + message.count * 2)
            }
            
            try self.write({
                return XCEncodeMessageHeader(self.bytes, self.capacity, &self.count, message.collection.count)
            })
            var elements = message.collection.map { e in
                return e
            }
            elements.sort { lhs, rhs in
                return lhs.0 < rhs.0
            }
            var prev: UInt32 = 0
            try elements.forEach { (key, value) in
                if self.count + 10 > self.capacity {
                    self.reserveCapacity(self.count + 10)
                }
                try self.write({
                    return XCEncodeFieldKeyOffset(self.bytes, self.capacity, &self.count, key - prev)
                })
                prev = key
                try self._writeValue(value)
            }
        }
    }
    
    public static func writeValue(_ value: XONValue) throws -> Data {
        let writer = XCWriter(minimumCapacity: 0)
        try writer._writeValue(value)
        if writer.count >= 0x1000 {
            writer.fit()
            let p = Unmanaged<XCWriter>.passRetained(writer)
            return Data(bytesNoCopy: writer._bytes, count: writer.count, deallocator: Data.Deallocator.custom({ ptr, size in
                p.release()
            }))
        } else {
            return Data(bytes: writer._bytes, count: writer.count)
        }
    }
}
