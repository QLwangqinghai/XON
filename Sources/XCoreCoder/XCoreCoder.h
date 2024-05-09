
#ifndef XCoreCoder_h
#define XCoreCoder_h

#include <stdlib.h>
#include <stdbool.h>

#define XCAttosecondPerSecond 1000000000000000000LL

#define XONTypeLength 1

extern char * _Nonnull const XONErrorDomain;


#define XONTypeConstant 0

// NULL, true, false, nan, +inf, -inf, 0, timemax, timemin, time0

typedef enum {
    
    XONTypeNil = 0x0,

    /// Type - Value
    XONTypeBool = -0x1,
    
    // 为了保证编码的一致性，编码成 varint(e) + (sign + 尾数)， sign+尾数的尾部的0省略
    XONTypeNumber = 0x1,
    
    // unit3
    // 8 4 8
    
    // flag:
    
    // 11
    // nanosecond: int128
    //
    
    //  unused: 0, invalid: 1, min: 2, zero: 3, max: 4, second8, millisecond8, microsecond11
    
    /// [0, 31]: { unused: 0, min: 1, max: 2, zero: 3, nanosecond:[4, 11],  second(μs): [3, 15]}
    /// [0, 31]: { nanosecond:[16, 31], min: 0, max: 1, unused: 2, second(μs): [3, 15]}
    XONTypeTime = 0x2,
    
    /// Type - Count - Value
    XONTypeString = 0x3,

    /// Type - Count - Value
    XONTypeData = 0x4,

    /// Type - Count - Value[(offst, Item)]
    XONTypeMessage = 0x5,

    /// Type - Count - Value[Item]
    XONTypeArray = 0x6,
    
    // 最大值23
} XONType_e;

typedef enum {
    XONErrorNone = 0,
    
    XONErrorContent = -1,
    XONErrorCount = -2,
    XONErrorNotEnough = -3,
    XONErrorNotSupport = -4,
    
    XONErrorNotImplemented = -0xa,
    
    /// 编码压缩错误 编码错误，高位为0， 占用了更多的字节， 这种不允许;
    XONErrorVarInt = -0x5,
        
    /// 非法编码
    XONErrorType = -0x6,
    XONErrorLayout = -0x7,

    XONErrorMessageFieldKeyOffset = -0x8,
    XONErrorNumberOutOfBounds = -0x9,
    
    XONErrorTimeContent = -0x12,
    XONErrorNumberContent = -0x13,
    XONErrorMessageIndexOffset = -0x14,
    XONErrorStringContent = -0x15,
    XONErrorArrayContent = -0x16,
    XONErrorMessageContent = -0x17,
    XONErrorMapContent = -0x18,
    XONErrorSetContent = -0x19,
    
    XONErrorFieldNotFound = -0x1a
} XONError_e;

/// 取值范围最大63
typedef enum {
    XCNumberTypeNone = 0x0,
    XCNumberTypeSInt,
    XCNumberTypeUInt,
    XCNumberTypeFloat64,
} XCNumberType_e;

typedef enum {
    XCNumberFormatZero = 0x0,
    XCNumberFormatNan = 0x1,
    XCNumberFormatPositiveInfinity = 0x2,
    XCNumberFormatNegativeInfinity = 0x3,
    
    // unused
    XCNumberFormatFloat = 0x4,

    // other:  len = layout - XCNumberFormatLarge
} XCNumberFormat_e;

static inline double __XCDoubleNan(void) {
    uint64_t v = ((uint64_t)0x7ff8000000000000ULL);
    return *(double *)(&v);
}
static inline double __XCDoublePositiveInfinity(void) {
    uint64_t v = ((uint64_t)0x7ff0000000000000ULL);
    return *(double *)(&v);
}
static inline double __XCDoubleNegativeInfinity(void) {
    uint64_t v = ((uint64_t)0xfff0000000000000ULL);
    return *(double *)(&v);
}
static inline double __XCDoubleZero(void) {
    double v = 0.0;
    return v;
}

typedef struct {
    ssize_t type;
    union {
        int64_t s;
        uint64_t u;
        double f;
    } value;
} XCNumberValue_s;

typedef struct {
    int64_t exponent;
    uint64_t signAndSignificand;
} XCNumber_s;

typedef struct {
    ssize_t format;
    ssize_t length;

//    int64_t exponent;
//    uint64_t signAndSignificand;
//    ssize_t moreSignificandCount;
} XCNumberHeader_s;


typedef struct {
    int64_t type;
    ssize_t count;
} XCMessageHeader_s;

static inline XCMessageHeader_s XCMessageHeaderMake(uint64_t type, ssize_t count) {
    XCMessageHeader_s result = {
        .type = type,
        .count = count,
    };
    return result;
}

///
typedef struct {
    int64_t exponent;
    uint64_t signAndSignificand;
} XCNumberNormalContent_s;

typedef struct {
    int64_t second;
    
    
    /// [0, XCAttosecondPerSecond)
    uint64_t attosecond;
} XCTime_s;

static inline bool XCTimeIsInvalid(int64_t second, uint64_t attosecond) {
    int64_t oneSecond = 1000000000000000000LL;
    if (attosecond >= oneSecond) {
        if (attosecond == UINT64_MAX && (second == INT64_MAX || second == INT64_MIN)) {
            return false;
        } else {
            return true;
        }
    } else {
        return false;
    }
}

static inline bool __XCTimeIsInvalid(XCTime_s time) {
    return XCTimeIsInvalid(time.second, time.attosecond);
}

static inline XCTime_s __XCTimeInvalidDefault(void) {
    XCTime_s time = {
        .second = INT64_MIN,
        .attosecond = UINT64_MAX - 1,
    };
    return time;
}

static inline XCTime_s __XCTimeDistantPast(void) {
    XCTime_s time = {
        .second = INT64_MIN,
        .attosecond = UINT64_MAX,
    };
    return time;
}

static inline XCTime_s __XCTimeDistantFuture(void) {
    XCTime_s time = {
        .second = INT64_MAX,
        .attosecond = UINT64_MAX,
    };
    return time;
}


//public struct XONTime : Hashable {
//    public let second: Int64
//    public let attosecond: UInt64
//    
//    private init(second: Int64, attosecond: UInt64) {
//        self.second = second
//        self.attosecond = attosecond
//    }
//    
//    public init(second: Int64) {
//        self.second = second
//        self.attosecond = 0
//    }
//
//    public init(millisecond: Int64) {
//        var second = millisecond / 1000
//        var tmp = millisecond % 1000
//        if tmp < 0 {
//            tmp += 1000
//            second -= 1
//        }
//        self.second = second
//        self.attosecond = UInt64(tmp) * (XONTime.scale / 1000)
//    }
//    
//    public init(microsecond: Int64) {
//        var second = microsecond / 1000_000
//        var tmp = microsecond % 1000_000
//        if tmp < 0 {
//            tmp += 1000_000
//            second -= 1
//        }
//        self.second = second
//        self.attosecond = UInt64(tmp) * (XONTime.scale / 1000_000)
//    }
//    
//    public init(nanosecond: Int64) {
//        var second = nanosecond / 1000_000_000
//        var tmp = nanosecond % 1000_000_000
//        if tmp < 0 {
//            tmp += 1000_000_000
//            second -= 1
//        }
//        self.second = second
//        self.attosecond = UInt64(tmp) * (XONTime.scale / 1000_000_000)
//    }
//    
//    public static let scale: UInt64 = 1_000_000_000_000_000_000
//    public static let invalid = XONTime(second: Int64.min, attosecond: UInt64.max - 1)
//    public static let distantPast = XONTime(second: Int64.min, attosecond: UInt64.max)
//    public static let distantFuture = XONTime(second: Int64.max, attosecond: UInt64.max)
//    public static let zero = XONTime(second: 0, attosecond: 0)
//}


typedef struct {
    ssize_t format;
    ssize_t length;
} XCTimeHeader_s;

typedef struct {
    ssize_t type;
    union {
        _Bool boolValue;
        XCMessageHeader_s message;
        XCNumberHeader_s number;
        XCTime_s time;
//        XCTimeHeader_s time;
//        int64_t timeval;
        
        // XONTypeData, XONTypeString, XONTypeOrderedMap, XONTypeArray
        ssize_t count;
    } value;
} XCValueHeader_s;

static inline XCValueHeader_s XCValueHeaderMake(void) {
    XCValueHeader_s h = { 0 };
    return h;
}

typedef enum {
    XCTimeFormatInvalid = 0x0,

    XCTimeFormatDistantPast = 0x1,
    
    XCTimeFormatDistantFuture = 0x2,
        
    XCTimeFormatZero = 0x3,
    
    XCTimeFormatSecond = 0x4,

    XCTimeFormatMillisecond = 0x5,

    XCTimeFormatMicrosecond = 0x6,

    XCTimeFormatNanosecond = 0x7,

    
    // 0 字节  为0
} XCTimeFormat_e;


// hasDecimal

typedef enum {
    
    // const
    // s, ms, us, large
    
    XCTimeLayoutInvalid = 0x0,

    XCTimeLayoutDistantPast = 0x1,
    
    XCTimeLayoutDistantFuture = 0x2,
    
    XCTimeLayoutZero = 0x3,
    
    // unit3+len4
    
    // varint 60/7
    // 16 second: 0 - 8; 3; large; 16
    // hasSS: totalLen
    
    // second: [8, 16)
    // millisecond: [16, 24)
    // microsecond: [24, 32)
    
    // 0 字节  为0
} XCTimeLayout_e;

// 5 + 8
// 1 + 4,

// secendlen4, sslen4;

// 3bit SS, 5bitlength


extern ssize_t XCHeaderMaxLength(void);

// 8 16

extern XONError_e XCDecodeHeader(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCValueHeader_s * _Nonnull header);
extern XONError_e XCDecodeFieldKeyOffset(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t * _Nonnull offset);
extern XONError_e XCDecodeNumber64(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t format, ssize_t count, XCNumberValue_s * _Nonnull number);
extern XONError_e XCDecodeTime64(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count, int64_t * _Nonnull v);

extern XONError_e XCencodeNull(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location);

extern XONError_e XCEncodeBool(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, _Bool value);

extern XONError_e XCEncodeNumberUInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value);
extern XONError_e XCEncodeNumberSInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value);
extern XONError_e XCEncodeNumberDouble(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, double value);

extern XONError_e XCEncodeTimeInvalid(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location);
extern XONError_e XCEncodeTimeDistantPast(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location);
extern XONError_e XCEncodeTimeDistantFuture(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location);


extern XONError_e XCEncodeTime(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t second, uint64_t attosecond);

//// s
//extern XONError_e XCEncodeTimeSecond(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value);
//
//// ms
//extern XONError_e XCEncodeTimeMillisecond(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value);
//// μs
//extern XONError_e XCEncodeTimeMicrosecond(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value);

extern XONError_e XCEncodeFieldKeyOffset(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t offset);

/// type >= 0
extern XONError_e XCEncodeMessageHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count, int64_t type);

extern XONError_e XCEncodeArrayHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XONError_e XCEncodeDataHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XONError_e XCEncodeStringHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);


extern XONError_e XCEncodeBody(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, const void * _Nonnull data, ssize_t count);


typedef XONError_e (*XCVarintEncode_f)(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value);
typedef XONError_e (*XCVarintDecode_f)(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t * _Nonnull value);

#endif /* XCoreCoder_h */
