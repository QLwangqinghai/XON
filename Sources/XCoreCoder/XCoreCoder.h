
#ifndef XCoreCoder_h
#define XCoreCoder_h

#include <stdlib.h>
#include <stdbool.h>

#define XATTOSECOND_PER_SECOND 1000000000000000000LL

#define XONTypeLength 1

extern char * _Nonnull const XONErrorDomain;


#define XONTypeConstant 0

typedef enum {
    
    /// TypeCode = 0, layout = 0,
    XONTypeNil = 0x0,

    XONTypeBool = -0x1,
    
    XONTypeNumber = 0x1,
    
    XONTypeTime = 0x2,
    
    /// Type - Count - Value
    XONTypeString = 0x3,

    /// Type - Count - Value
    XONTypeData = 0x4,

    /// Type - Count - Values
    XONTypeMessage = 0x5,

    /// Type - Count - Values
    XONTypeArray = 0x6,
    
} XONType_e;

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

typedef enum {
    XCNumberFormatFloat = 0x0,
    XCNumberFormatNan = 0x1,
    XCNumberFormatPositiveInfinity = 0x2,
    XCNumberFormatNegativeInfinity = 0x3,
    XCNumberFormatZero = 0x4,
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
    ssize_t format;
    ssize_t length;
} XCNumberHeader_s;

///
typedef struct {
    int64_t exponent;
    uint64_t signAndSignificand;
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

typedef struct {
    ssize_t format;
    ssize_t length;
} XTimestampHeader_s;

typedef struct {
    ssize_t type;
    union {
        _Bool boolValue;
        XCNumberHeader_s number;
        XTimestamp_s time;
        // XONTypeData, XONTypeString, XONTypeArray, XONTypeMessage
        ssize_t count;
    } value;
} XCValueHeader_s;

static inline XCValueHeader_s XCValueHeaderMake(void) {
    XCValueHeader_s h = { 0 };
    return h;
}

typedef enum {
    XTimestampLayoutInvalid = 0x0,
    XTimestampLayoutDistantPast = 0x1,
    XTimestampLayoutDistantFuture = 0x2,
    XTimestampLayoutZero = 0x3,
} XTimestampLayout_e;

extern ssize_t XCHeaderMaxLength(void);

extern XONError_e XCDecodeHeader(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCValueHeader_s * _Nonnull header);
extern XONError_e XCDecodeFieldKeyOffset(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t * _Nonnull offset);
extern XONError_e XCDecodeNumber64(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t format, ssize_t count, XCNumberValue_s * _Nonnull number);

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
