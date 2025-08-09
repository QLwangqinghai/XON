
#ifndef XCoreCoder_h
#define XCoreCoder_h

#include <stdlib.h>
#include <stdbool.h>

#define XATTOSECOND_PER_SECOND 1000000000000000000LL

#define XONTypeLength 1

extern char * _Nonnull const XONErrorDomain;

typedef enum {
    XCTypeSimpleValue = 0,
    
    /// Type - Count - Value 9
    XCTypeString = 1,

    /// Type - Count - Value 9
    XCTypeData,

    /// Type - Count - Value[(offst, Item)] 9
    XCTypeMessage,

    /// Type - Count - Value[Item] 9
    XCTypeArray,
} XCType_e;

typedef enum {
    XCSimpleValueError = 0,
    XCSimpleValueNil = 1,
    
    XCSimpleValueBoolFalse = 2,
    /// Type - Value 2
    XCSimpleValueBoolTrue = 3,
    
    XCSimpleValueTimeZero = 4,
    XCSimpleValueTimeInvalid,
    XCSimpleValueTimeDistantFuture,
    XCSimpleValueTimeDistantPast,
    XCSimpleValueTimeSecond,
    XCSimpleValueTimeScientificNotation,
    
    // 8  / 9 / 10
    
    XCSimpleValueNumberNAN = 10,
    XCSimpleValueNumberPositiveInfinity,
    XCSimpleValueNumberNegativeInfinity,
    XCSimpleValueNumberZero,
    // number 最长18字节
    // number 18个 [14, 31]
    
    
} XCSimpleValue_e;


typedef enum {
    XONErrorNone = 0,
    
    XONErrorContent = -1,
    XONErrorCount = -2,
    XONErrorNotEnough = -3,
    XONErrorNotSupport = -4,
    
    XONErrorNotImplemented = -0xa,
    
    XONErrorVarInt = -0x5,
        
    /// 非法编码
    XONErrorType = -0x6,
    XONErrorLayout = -0x7,

    XONErrorMessageFieldKeyOffset = -0x8,
    XONErrorNumberOutOfRange = -0x9,
    
    XONErrorTimeContent = -0x12,
    XONErrorNumberContent = -0x13,
    XONErrorMessageIndexOffset = -0x14,
    XONErrorStringContent = -0x15,
    XONErrorArrayContent = -0x16,
    XONErrorMessageContent = -0x17,
    
    XONErrorFieldNotFound = -0x1a
} XONError_e;

typedef enum {
    XCNumberTypeNone = 0x0,
    XCNumberTypeSInt,
    XCNumberTypeUInt,
    XCNumberTypeFloat64,
} XCNumberType_e;

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
    ssize_t format;
    ssize_t length;
} XCNumberHeader_s;

///
//typedef struct {
//    int64_t exponent;
//    uint64_t signAndSignificand;
//} XCNumberNormalContent_s;
typedef struct {
    int32_t exponent;
    uint32_t sign;
    uint64_t significandHigh;
    uint64_t significandLow;
} XCNumberNormalContent_s;

typedef struct {
    int64_t second;
    
    /// normal: [0, XATTOSECOND_PER_SECOND-1]
    uint64_t attosecond;
} XTimestamp_s;

static inline bool XTimestampIsInvalid(XTimestamp_s timestamp) {
    if (timestamp.attosecond >= XATTOSECOND_PER_SECOND) {
        if (timestamp.attosecond == UINT64_MAX && (timestamp.second == INT64_MAX || timestamp.second == INT64_MIN)) {
            return false;
        } else {
            return true;
        }
    } else {
        return false;
    }
}

static inline bool XTimestampIsEqual(XTimestamp_s lhs, XTimestamp_s rhs) {
    if (XTimestampIsInvalid(lhs) && XTimestampIsInvalid(rhs)) {
        return true;
    } else {
        return lhs.second == rhs.second && lhs.attosecond == rhs.attosecond;
    }
}

static inline XTimestamp_s XTimestampInvalidDefault(void) {
    XTimestamp_s time = {
        .second = INT64_MIN,
        .attosecond = UINT64_MAX - 1,
    };
    return time;
}

static inline XTimestamp_s XTimestampDistantPast(void) {
    XTimestamp_s time = {
        .second = INT64_MIN,
        .attosecond = UINT64_MAX,
    };
    return time;
}

static inline XTimestamp_s XTimestampDistantFuture(void) {
    XTimestamp_s time = {
        .second = INT64_MAX,
        .attosecond = UINT64_MAX,
    };
    return time;
}

static inline XTimestamp_s XTimestampZero(void) {
    XTimestamp_s time = {
        .second = 0,
        .attosecond = 0,
    };
    return time;
}

typedef struct {
    ssize_t format;
    ssize_t length;
} XTimestampHeader_s;

typedef struct {
    XCType_e type;
    unsigned int layout;
} XCValueHeader_s;

static inline XCValueHeader_s XCValueHeaderMake(void) {
    XCValueHeader_s h = { 0 };
    return h;
}

extern ssize_t XCHeaderMaxLength(void);

extern XONError_e XCDecodeHeader(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCValueHeader_s * _Nonnull header);
extern XONError_e XCDecodeNormalNumber(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t len, XCNumberNormalContent_s * _Nonnull content);
extern XONError_e XCDecodeTime(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, _Bool secondOnly, XTimestamp_s * _Nonnull time);
extern XONError_e XCDecodeCount(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, unsigned int layout, ssize_t * _Nonnull receiver);

extern XONError_e XCDecodeFieldKeyOffset(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t * _Nonnull offset);

extern XONError_e XCNumberToFloat64(const XCNumberNormalContent_s * _Nonnull content, double * _Nonnull value);
extern XONError_e XCNumberToSInt64(const XCNumberNormalContent_s * _Nonnull content, int64_t * _Nonnull value);
extern XONError_e XCNumberToUInt64(const XCNumberNormalContent_s * _Nonnull content, uint64_t * _Nonnull value);

extern void test(void);
//extern XONError_e XCDecodeNumber64(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t format, ssize_t count, XCNumberValue_s * _Nonnull number);

#pragma mark - EncodeBuffer

struct __XCEncodeBuffer;
typedef struct __XCEncodeBuffer XCEncodeBuffer_s;
struct __XCEncodeBuffer {
    void * _Nullable context;
    uint8_t * _Nullable bytes;
    ssize_t capacity;
    ssize_t location;
    void (* _Nonnull reserveCapacity)(XCEncodeBuffer_s * _Nonnull buffer, ssize_t minCapacity);
    void (* _Nonnull fitSize)(XCEncodeBuffer_s * _Nonnull buffer);
    void (* _Nonnull deallocator)(XCEncodeBuffer_s * _Nonnull buffer);
};

static inline void XCEncodeBufferReserveCapacity(XCEncodeBuffer_s * _Nonnull buffer, ssize_t minCapacity) {
    buffer->reserveCapacity(buffer, minCapacity);
}
static inline void XCEncodeBufferFitSize(XCEncodeBuffer_s * _Nonnull buffer) {
    buffer->fitSize(buffer);
}
static inline void XCEncodeBufferDeallocate(XCEncodeBuffer_s * _Nonnull buffer) {
    buffer->deallocator(buffer);
}

extern void _XCEncodeBufferDefaultRealloc(XCEncodeBuffer_s * _Nonnull buffer, ssize_t minCapacity);
extern void _XCEncodeBufferDefaultDealloc(XCEncodeBuffer_s * _Nonnull buffer);
extern void _XCEncodeBufferDefaultFitSize(XCEncodeBuffer_s * _Nonnull buffer);

static inline XCEncodeBuffer_s XCEncodeBufferMakeDefault(void) {
    XCEncodeBuffer_s buffer = {
        .context = NULL,
        .bytes = NULL,
        .capacity = 0,
        .location = 0,
        .reserveCapacity = _XCEncodeBufferDefaultRealloc,
        .fitSize = _XCEncodeBufferDefaultFitSize,
        .deallocator = _XCEncodeBufferDefaultDealloc,
    };
    return buffer;
}

#pragma mark - Encode


extern XONError_e XCEncodeNull(XCEncodeBuffer_s * _Nonnull buffer);
extern XONError_e XCEncodeBool(XCEncodeBuffer_s * _Nonnull buffer, _Bool value);

extern XONError_e XCEncodeNumberUInt64(XCEncodeBuffer_s * _Nonnull buffer, uint64_t value);
extern XONError_e XCEncodeNumberSInt64(XCEncodeBuffer_s * _Nonnull buffer, int64_t value);
extern XONError_e XCEncodeNumberDouble(XCEncodeBuffer_s * _Nonnull buffer, double value);

extern XONError_e XCEncodeTimeInvalid(XCEncodeBuffer_s * _Nonnull buffer);
extern XONError_e XCEncodeTimeZero(XCEncodeBuffer_s * _Nonnull buffer);
extern XONError_e XCEncodeTimeDistantPast(XCEncodeBuffer_s * _Nonnull buffer);
extern XONError_e XCEncodeTimeDistantFuture(XCEncodeBuffer_s * _Nonnull buffer);
extern XONError_e XCEncodeTime(XCEncodeBuffer_s * _Nonnull buffer, int64_t second, uint64_t attosecond);

extern XONError_e XCEncodeFieldKeyOffset(XCEncodeBuffer_s * _Nonnull buffer, uint32_t offset);
extern XONError_e XCEncodeMessageHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XCEncodeArrayHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XCEncodeDataHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XCEncodeStringHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XCEncodeBody(XCEncodeBuffer_s * _Nonnull buffer, const void * _Nonnull data, ssize_t count);

#endif /* XCoreCoder_h */
