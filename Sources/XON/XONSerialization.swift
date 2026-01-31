
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
    private func readTime(index: UnsafeMutablePointer<Int>, count: Int) throws -> XONTime {
        var value: XTimestamp = XTimestampZero()
        let error = XCDecodeTime(self.bytes, self.endIndex, index, count, &value)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        return XONTime(microsecond: value)
    }
    
    private func readCount(index: UnsafeMutablePointer<Int>, layout: UInt32) throws -> Int {
        var value: Int = 0
        let error = XCDecodeCount(self.bytes, self.endIndex, index, layout, &value)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        return value
    }
    private func readMessageFieldOffset(index: UnsafeMutablePointer<Int>) throws -> UInt32 {
        var offset: UInt32 = 0
        let error = XCDecodeFieldKeyOffset(self.bytes, self.endIndex, index, &offset)
        guard error == XONErrorNone else {
            throw XON.typeError
        }
        return offset
    }
    
    public func readData(index: UnsafeMutablePointer<Int>, layout: UInt32) throws -> Data {
        let length: Int = try self.readCount(index: index, layout: layout)
        guard index.pointee <= self.data.count - length else {
            throw XON.notEnoughError
        }
        let data = NSData(bytes: self.bytes.advanced(by: index.pointee), length: length)
        index.pointee += length
        return data as Data
    }
    
    public func readString(index: UnsafeMutablePointer<Int>, layout: UInt32) throws -> String {
        let length: Int = try self.readCount(index: index, layout: layout)
        guard index.pointee <= self.data.count - length else {
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
    
    private func readNumber(index: UnsafeMutablePointer<Int>, contentLength: Int) throws -> NSNumber {
        var value = XCNumberNormalContent_s()
        let error = XCDecodeNormalNumber(self.bytes, self.endIndex, index, contentLength, &value)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        
        var d: Double = 0
        if XONErrorNone == XCNumberToFloat64(&value, &d) {
            return NSNumber(value: d)
        }
        var si: Int64 = 0
        if XONErrorNone == XCNumberToSInt64(&value, &si) {
            return NSNumber(value: si)
        }
        var ui: UInt64 = 0
        if XONErrorNone == XCNumberToUInt64(&value, &ui) {
            return NSNumber(value: ui)
        }
        throw XON.error(code: XONErrorNumberOutOfRange)
    }
    
    private func readValue(index: UnsafeMutablePointer<Int>) throws -> XONValue {
        let header = try self.readHeader(index: index)
        guard let type = XCType(rawValue: header.type.rawValue) else {
            throw XON.typeError
        }
        switch type {
        case .simpleValue:
            switch header.layout {
            case XCSimpleValueError.rawValue:
                throw XON.typeError
            case XCSimpleValueNil.rawValue:
                return .null
            case XCSimpleValueBoolFalse.rawValue:
                return .bool(false)
            case XCSimpleValueBoolTrue.rawValue:
                return .bool(true)
            case XCSimpleValueTimeInvalid.rawValue:
                return .time(XONTime.invalid)
            case XCSimpleValueTime0.rawValue:
                return .time(XONTime.zero)
            case XCSimpleValueTime1.rawValue:
                return .time(try self.readTime(index: index, count: 1))
            case XCSimpleValueTime2.rawValue:
                return .time(try self.readTime(index: index, count: 2))
            case XCSimpleValueTime3.rawValue:
                return .time(try self.readTime(index: index, count: 3))
            case XCSimpleValueTime4.rawValue:
                return .time(try self.readTime(index: index, count: 4))
            case XCSimpleValueTime5.rawValue:
                return .time(try self.readTime(index: index, count: 5))
            case XCSimpleValueTime6.rawValue:
                return .time(try self.readTime(index: index, count: 6))
            case XCSimpleValueTime7.rawValue:
                return .time(try self.readTime(index: index, count: 7))
            case XCSimpleValueTime8.rawValue:
                return .time(try self.readTime(index: index, count: 8))
            case XCSimpleValueUndefine14.rawValue:
                throw XON.notSupport
            case XCSimpleValueNumberLarge.rawValue:
                throw XON.notSupport
            case XCSimpleValueNumberNAN.rawValue:
                return .number(NSNumber(value: Double.nan))
            case XCSimpleValueNumberPositiveInfinity.rawValue:
                return .number(NSNumber(value: Double.infinity))
            case XCSimpleValueNumberNegativeInfinity.rawValue:
                return .number(NSNumber(value: Double.infinity * (-1.0)))
            case XCSimpleValueNumberZero.rawValue:
                return .number(NSNumber(value: Double.zero))
            default:
                let contentLength = Int(header.layout - XCSimpleValueNumberZero.rawValue)
                return .number(try self.readNumber(index: index, contentLength: contentLength))
            }
        case .string:
            return .string(try readString(index: index, layout: header.layout))
        case .data:
            return .data(try readData(index: index, layout: header.layout))
        case .message:
            let count: Int = try self.readCount(index: index, layout: header.layout)
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
        case .array:
            let count: Int = try self.readCount(index: index, layout: header.layout)
            var elements: [XONValue] = []
            elements.reserveCapacity(count)
            for _ in 0 ..< count {
                let value = try self.readValue(index: index)
                elements.append(value)
            }
            return .array(elements)
        }
    }
    
    public func readValue() throws -> XONValue {
        var index = 0
        return try self.readValue(index: &index)
    }
}

public class XCWriter {
    public var buffer: XONEncodeBuffer_s = XONEncodeBufferMakeDefault()
    
    public init(minimumCapacity: Int) {
        XONEncodeBufferReserveCapacity(&buffer, minimumCapacity)
    }
    
    public func fit() {
        XONEncodeBufferFitSize(&buffer)
    }
    
    deinit {
        XONEncodeBufferDeallocate(&buffer)
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
            try self.write({
                return XONEncodeNull(&self.buffer)
            })
        case .bool(let v):
            try self.write({
                return XONEncodeBool(&self.buffer, v)
            })
        case .string(let _v):
            var v = _v as String
            let count = v.utf8.count
            try self.write({
                return XONEncodeStringHeader(&self.buffer, count)
            })
            if count > 0 {
                try v.withUTF8 { ptr in
                    try self.write({
                        return XONEncodeBody(&self.buffer, ptr.baseAddress!, count)
                    })
                }
            }
        case .data(let data):
            try self.write({
                return XONEncodeDataHeader(&self.buffer, data.count)
            })
            if !data.isEmpty {
                try data.withUnsafeBytes { ptr in
                    try self.write({
                        return XONEncodeBody(&self.buffer, ptr.baseAddress!, data.count)
                    })
                }
            }
        case .array(let array):
            try self.write({
                return XONEncodeArrayHeader(&self.buffer, array.count)
            })
            try array.forEach { item in
                try self._writeValue(item)
            }
        case .number(let n):
            let v = n
            if let value = v as? Double {
                try self.write({
                    return XONEncodeNumberDouble(&self.buffer, value)
                })
            } else if let value = v as? Int64 {
                try self.write({
                    return XONEncodeNumberSInt64(&self.buffer, value)
                })
            } else if let value = v as? UInt64 {
                try self.write({
                    return XONEncodeNumberUInt64(&self.buffer, value)
                })
            } else {
                throw XON.error(code: XONErrorNumberContent)
            }
        case .time(let v):
            try self.write({
                return XONEncodeTime(&self.buffer, v.microsecond)
            })
        case .message(let message):
            try self.write({
                return XONEncodeMessageHeader(&self.buffer, message.collection.count)
            })
            var elements = message.collection.map { e in
                return e
            }
            elements.sort { lhs, rhs in
                return lhs.0 < rhs.0
            }
            var prev: UInt32 = 0
            try elements.forEach { (key, value) in
                try self.write({
                    return XONEncodeFieldKeyOffset(&self.buffer, key - prev)
                })
                prev = key
                try self._writeValue(value)
            }
        }
    }
    
    public static func writeValue(_ value: XONValue) throws -> Data {
        let writer = XCWriter(minimumCapacity: 0)
        try writer._writeValue(value)
        if writer.buffer.location >= 0x1000 {
            writer.fit()
            let p = Unmanaged<XCWriter>.passRetained(writer)
            return Data(bytesNoCopy: writer.buffer.bytes!, count: writer.buffer.location, deallocator: Data.Deallocator.custom({ ptr, size in
                p.release()
            }))
        } else {
            return Data(bytes: writer.buffer.bytes!, count: writer.buffer.location)
        }
    }
}
