
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
        let reader = XONDecodeBuffer(data: data as NSData)
        return try reader.readValue()
    }

    public static func encode(_ value: XONValue) throws -> Data {
        return try XONEncodeBuffer.writeValue(value)
    }
}

public class XONDecodeBuffer {
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
    private func readHeader(index: UnsafeMutablePointer<Int>) throws -> XONValueHeader_s {
        var header = XONValueHeaderMake()
        let error = XONDecodeHeader(self.bytes, self.endIndex, index, &header)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        return header
    }
    private func readTime(index: UnsafeMutablePointer<Int>, count: Int) throws -> XONTime {
        var value: XTimestamp = XTimestampZero()
        let error = XONDecodeTime(self.bytes, self.endIndex, index, count, &value)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        return XONTime(microsecond: value)
    }
    
    private func readCount(index: UnsafeMutablePointer<Int>, layout: UInt32) throws -> Int {
        var value: Int = 0
        let error = XONDecodeCount(self.bytes, self.endIndex, index, layout, &value)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        return value
    }
    private func readMessageFieldOffset(index: UnsafeMutablePointer<Int>) throws -> UInt32 {
        var offset: UInt32 = 0
        let error = XONDecodeFieldKeyOffset(self.bytes, self.endIndex, index, &offset)
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
        guard let string = NSString(bytes: self.bytes.advanced(by: index.pointee), length: length, encoding: NSUTF8StringEncoding) else {
            throw XON.stringContentError
        }
        index.pointee += length
        return string as String
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
    
    private func readNumber(index: UnsafeMutablePointer<Int>, contentLength: Int) throws -> NSNumber {
        var value = XONNumberNormalContent_s()
        let error = XONDecodeNormalNumber(self.bytes, self.endIndex, index, contentLength, &value)
        guard error == XONErrorNone else {
            throw XON.error(code: error)
        }
        
        var d: Double = 0
        if XONErrorNone == XONNumberToFloat64(&value, &d) {
            return NSNumber(value: d)
        }
        var si: Int64 = 0
        if XONErrorNone == XONNumberToSInt64(&value, &si) {
            return NSNumber(value: si)
        }
        var ui: UInt64 = 0
        if XONErrorNone == XONNumberToUInt64(&value, &ui) {
            return NSNumber(value: ui)
        }
        throw XON.error(code: XONErrorNumberOutOfRange)
    }
    
    private func readValue(index: UnsafeMutablePointer<Int>, deep: Int) throws -> XONValue {
        guard deep < 65536 else {
            throw XON.deepError
        }
        let header = try self.readHeader(index: index)
        guard let type = XONWireType(rawValue: header.type.rawValue) else {
            throw XON.typeError
        }
        switch type {
        case .simpleValue:
            switch header.layout {
            case XONSimpleValueError.rawValue:
                throw XON.typeError
            case XONSimpleValueNil.rawValue:
                return .null
            case XONSimpleValueBoolFalse.rawValue:
                return .bool(false)
            case XONSimpleValueBoolTrue.rawValue:
                return .bool(true)
            case XONSimpleValueTimeInvalid.rawValue:
                return .time(XONTime.invalid)
            case XONSimpleValueTime0.rawValue:
                return .time(XONTime.zero)
            case XONSimpleValueTime1.rawValue:
                return .time(try self.readTime(index: index, count: 1))
            case XONSimpleValueTime2.rawValue:
                return .time(try self.readTime(index: index, count: 2))
            case XONSimpleValueTime3.rawValue:
                return .time(try self.readTime(index: index, count: 3))
            case XONSimpleValueTime4.rawValue:
                return .time(try self.readTime(index: index, count: 4))
            case XONSimpleValueTime5.rawValue:
                return .time(try self.readTime(index: index, count: 5))
            case XONSimpleValueTime6.rawValue:
                return .time(try self.readTime(index: index, count: 6))
            case XONSimpleValueTime7.rawValue:
                return .time(try self.readTime(index: index, count: 7))
            case XONSimpleValueTime8.rawValue:
                return .time(try self.readTime(index: index, count: 8))
            case XONSimpleValueUndefine14.rawValue:
                throw XON.notSupport
            case XONSimpleValueNumberLarge.rawValue:
                throw XON.notSupport
            case XONSimpleValueNumberNAN.rawValue:
                return .number(NSNumber(value: Double.nan))
            case XONSimpleValueNumberPositiveInfinity.rawValue:
                return .number(NSNumber(value: Double.infinity))
            case XONSimpleValueNumberNegativeInfinity.rawValue:
                return .number(NSNumber(value: Double.infinity * (-1.0)))
            case XONSimpleValueNumberZero.rawValue:
                return .number(NSNumber(value: Double.zero))
            default:
                let contentLength = Int(header.layout - XONSimpleValueNumberZero.rawValue)
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
                let field = try self.readValue(index: index, deep: deep + 1)
                collection[key] = field
            }
            guard collection.count == count else {
                throw XON.error(code: XONErrorMessageContent)
            }
            return .message(collection)
        case .array:
            let count: Int = try self.readCount(index: index, layout: header.layout)
            var elements: [XONValue] = []
            elements.reserveCapacity(count)
            for _ in 0 ..< count {
                let value = try self.readValue(index: index, deep: deep + 1)
                elements.append(value)
            }
            return .array(elements)
        }
    }
    
    public func readValue() throws -> XONValue {
        var index = 0
        return try self.readValue(index: &index, deep: 0)
    }
}

public class XONEncodeBuffer {
    public var buffer: XONEncodeBuffer_s = XONEncodeBufferMakeDefault()
    
    public init(minimumCapacity: Int = 0) {
        XONEncodeBufferReserveCapacity(&buffer, minimumCapacity)
    }
    
    public func fit() {
        XONEncodeBufferFitSize(&buffer)
    }
    
    deinit {
        XONEncodeBufferDeallocate(&buffer)
    }
    
    private func write(_ closure: () -> XONError_e) throws {
        let value = closure()
        if value != XONErrorNone {
            throw NSError(domain: XON.domain, code: Int(value.rawValue))
        }
    }
    
    public func writeNull() throws {
        try self.write({
            return XONEncodeNull(&self.buffer)
        })
    }
    public func writeBool(_ value: Bool) throws {
        try self.write({
            return XONEncodeBool(&self.buffer, value)
        })
    }
    public func writeNumber(_ value: NSNumber) throws {
        if let n = value as? Double {
            try self.writeDouble(n)
        } else if let n = value as? Int64 {
            try self.writeSInt64(n)
        } else if let n = value as? UInt64 {
            try self.writeUInt64(n)
        } else {
            throw XON.error(code: XONErrorNumberContent)
        }
    }
    public func writeDouble(_ value: Double) throws {
        try self.write({
            return XONEncodeNumberDouble(&self.buffer, value)
        })
    }
    public func writeSInt64(_ value: Int64) throws {
        try self.write({
            return XONEncodeNumberSInt64(&self.buffer, value)
        })
    }
    public func writeUInt64(_ value: UInt64) throws {
        try self.write({
            return XONEncodeNumberUInt64(&self.buffer, value)
        })
    }
    public func writeTime(_ value: XONTime) throws {
        try self.write({
            return XONEncodeTime(&self.buffer, value.microsecond)
        })
    }
    public func writeString(_ value: String) throws {
        try self.write({
            return value.withCString { ptr in
                return XONEncodeString(&self.buffer, ptr, value.utf8.count)
            }
        })
    }
    public func writeData(_ value: Data) throws {
        try value.withUnsafeBytes { ptr in
            try self.write({
                return XONEncodeData(&self.buffer, ptr.baseAddress!, value.count)
            })
        }
    }
    
    // string.utf8.count
    public func writeStringHeader(_ count: Int) throws {
        try self.write({
            return XONEncodeStringHeader(&self.buffer, count)
        })
    }
    public func writeDataHeader(_ count: Int) throws {
        try self.write({
            return XONEncodeDataHeader(&self.buffer, count)
        })
    }
    // String's or Data's body
    public func writeBody(_ body: UnsafeRawPointer, count: Int) throws {
        try self.write({
            return XONEncodeBody(&self.buffer, body, count)
        })
    }

    /*
        Message:
        header; fieldKeyOffset, value, fieldKeyOffset, value, fieldKeyOffset, value ...... fieldKeyOffset, value
     */

    public func writeMessageHeader(_ count: Int) throws {
        try self.write({
            return XONEncodeMessageHeader(&self.buffer, count)
        })
    }
    public func writeMessageFieldKeyOffset(_ offset: UInt32) throws {
        try self.write({
            return XONEncodeFieldKeyOffset(&self.buffer, offset)
        })
    }
    
    public func writeMessage(_ message: [UInt32 : XONValue]) throws {
        try self.write({
            return XONEncodeMessageHeader(&self.buffer, message.count)
        })
        var elements = message.map { e in
            return e
        }
        elements.sort { lhs, rhs in
            return lhs.0 < rhs.0
        }
        var prev: UInt32 = 0
        try elements.forEach { (key, value) in
            try self.writeMessageFieldKeyOffset(key - prev)
            prev = key
            try self.writeValue(value)
        }
    }
    
    /*
        Array:
        header; value, value, value ...... value
     */
    public func writeArrayHeader(_ count: Int) throws {
        try self.write({
            return XONEncodeArrayHeader(&self.buffer, count)
        })
    }
    public func writeArray(_ array: [XONValue]) throws {
        try self.write({
            return XONEncodeArrayHeader(&self.buffer, array.count)
        })
        try array.forEach { item in
            try self.writeValue(item)
        }
    }
    public func writeMessage(_ container: (inout XMessageEncodingContainer) throws -> Void) throws {
        
    }
    public func writeArray(_ container: (inout XArrayEncodingContainer) throws -> Void) throws {
        
    }
//    public func write<T>(_ value: T) throws -> Data where T : XEncodable {
//
//    }
    
    public func writeValue(_ value: XONValue) throws {
        switch value {
        case .null:
            try self.writeNull()
        case .bool(let v):
            try self.writeBool(v)
        case .string(let v):
            try self.writeString(v)
        case .data(let data):
            try self.writeData(data)
        case .array(let array):
            try self.writeArray(array)
        case .number(let n):
            try self.writeNumber(n)
        case .time(let v):
            try self.writeTime(v)
        case .message(let message):
            try self.writeMessage(message)
        }
    }
    public static func writeValue(_ value: XONValue) throws -> Data {
        let writer = XONEncodeBuffer()
        try writer.writeValue(value)
        if writer.buffer.location >= 0x1000 {
            writer.fit()
            let p = Unmanaged<XONEncodeBuffer>.passRetained(writer)
            return Data(bytesNoCopy: writer.buffer.bytes!, count: writer.buffer.location, deallocator: Data.Deallocator.custom({ ptr, size in
                p.release()
            }))
        } else {
            return Data(bytes: writer.buffer.bytes!, count: writer.buffer.location)
        }
    }
}
