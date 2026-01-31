
#ifndef XCoreCoder_h
#define XCoreCoder_h

#include <stdlib.h>
#include <stdbool.h>

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
    
    // Microsecond
    XCSimpleValueTimeInvalid = 4,
    XCSimpleValueTime0 = 5,
    XCSimpleValueTime1,
    XCSimpleValueTime2,
    XCSimpleValueTime3,
    XCSimpleValueTime4,
    XCSimpleValueTime5,
    XCSimpleValueTime6,
    XCSimpleValueTime7,
    XCSimpleValueTime8 = 13,
    
    XCSimpleValueUndefine14,

    XCSimpleValueNumberLarge = 15,
    XCSimpleValueNumberNAN = 16,
    XCSimpleValueNumberPositiveInfinity = 17,
    XCSimpleValueNumberNegativeInfinity = 18,
    XCSimpleValueNumberZero = 19,
    // number 12个 [20, 31]
    
    // number（sint128, uint128, float128） 最长只需要18字节
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

typedef struct {
    int32_t exponent;
    uint32_t sign;
    uint64_t significandHigh;
    uint64_t significandLow;
} XCNumberNormalContent_s;


// microsecond
typedef int64_t XTimestamp;

static inline bool XTimestampIsInvalid(XTimestamp timestamp) {
    return timestamp == INT64_MAX;
}

static inline XTimestamp XTimestampInvalidDefault(void) {
    return INT64_MIN;
}

static inline XTimestamp XTimestampDistantPast(void) {
    return INT64_MIN + 1;
}

static inline XTimestamp XTimestampDistantFuture(void) {
    return INT64_MAX;
}

static inline XTimestamp XTimestampZero(void) {
    return 0;
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
extern XONError_e XCDecodeTime(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count, XTimestamp * _Nonnull time);
extern XONError_e XCDecodeCount(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, unsigned int layout, ssize_t * _Nonnull receiver);

extern XONError_e XCDecodeFieldKeyOffset(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t * _Nonnull offset);

extern XONError_e XCNumberToFloat64(const XCNumberNormalContent_s * _Nonnull content, double * _Nonnull value);
extern XONError_e XCNumberToSInt64(const XCNumberNormalContent_s * _Nonnull content, int64_t * _Nonnull value);
extern XONError_e XCNumberToUInt64(const XCNumberNormalContent_s * _Nonnull content, uint64_t * _Nonnull value);

extern void test(void);
//extern XONError_e XCDecodeNumber64(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t format, ssize_t count, XCNumberValue_s * _Nonnull number);

#pragma mark - EncodeBuffer

struct __XONEncodeBuffer;
typedef struct __XONEncodeBuffer XONEncodeBuffer_s;
struct __XONEncodeBuffer {
    void * _Nullable context;
    uint8_t * _Nullable bytes;
    ssize_t capacity;
    ssize_t location;
    void (* _Nonnull reserveCapacity)(XONEncodeBuffer_s * _Nonnull buffer, ssize_t minCapacity);
    void (* _Nonnull fitSize)(XONEncodeBuffer_s * _Nonnull buffer);
    void (* _Nonnull deallocator)(XONEncodeBuffer_s * _Nonnull buffer);
};

static inline void XONEncodeBufferReserveCapacity(XONEncodeBuffer_s * _Nonnull buffer, ssize_t minCapacity) {
    buffer->reserveCapacity(buffer, minCapacity);
}
static inline void XONEncodeBufferFitSize(XONEncodeBuffer_s * _Nonnull buffer) {
    buffer->fitSize(buffer);
}
static inline void XONEncodeBufferDeallocate(XONEncodeBuffer_s * _Nonnull buffer) {
    buffer->deallocator(buffer);
}

// TODO: 预算长度
extern void _XONEncodeBufferDefaultRealloc(XONEncodeBuffer_s * _Nonnull buffer, ssize_t minCapacity);
extern void _XONEncodeBufferDefaultDealloc(XONEncodeBuffer_s * _Nonnull buffer);
extern void _XONEncodeBufferDefaultFitSize(XONEncodeBuffer_s * _Nonnull buffer);

static inline XONEncodeBuffer_s XONEncodeBufferMakeDefault(void) {
    XONEncodeBuffer_s buffer = {
        .context = NULL,
        .bytes = NULL,
        .capacity = 0,
        .location = 0,
        .reserveCapacity = _XONEncodeBufferDefaultRealloc,
        .fitSize = _XONEncodeBufferDefaultFitSize,
        .deallocator = _XONEncodeBufferDefaultDealloc,
    };
    return buffer;
}

#pragma mark - Encode

extern XONError_e XONEncodeNull(XONEncodeBuffer_s * _Nonnull buffer);
extern XONError_e XONEncodeBool(XONEncodeBuffer_s * _Nonnull buffer, _Bool value);

extern XONError_e XONEncodeNumberUInt64(XONEncodeBuffer_s * _Nonnull buffer, uint64_t value);
extern XONError_e XONEncodeNumberSInt64(XONEncodeBuffer_s * _Nonnull buffer, int64_t value);
extern XONError_e XONEncodeNumberDouble(XONEncodeBuffer_s * _Nonnull buffer, double value);

extern XONError_e XONEncodeTime(XONEncodeBuffer_s * _Nonnull buffer, XTimestamp microsecond);

extern XONError_e XONEncodeFieldKeyOffset(XONEncodeBuffer_s * _Nonnull buffer, uint32_t offset);
extern XONError_e XONEncodeMessageHeader(XONEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XONEncodeArrayHeader(XONEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XONEncodeDataHeader(XONEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XONEncodeStringHeader(XONEncodeBuffer_s * _Nonnull buffer, ssize_t count);
extern XONError_e XONEncodeBody(XONEncodeBuffer_s * _Nonnull buffer, const void * _Nonnull data, ssize_t count);

#endif /* XCoreCoder_h */
