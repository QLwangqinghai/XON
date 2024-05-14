
#ifndef XCoreCoder_h
#define XCoreCoder_h

#include <stdlib.h>
#include <stdbool.h>

#define XCAttosecondPerSecond 1000000000000000000LL

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
    int64_t exponent;
    uint64_t signAndSignificand;
} XCNumber_s;

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


typedef struct {
    ssize_t format;
    ssize_t length;
} XCTimeHeader_s;

typedef struct {
    ssize_t type;
    union {
        _Bool boolValue;
        XCNumberHeader_s number;
        XCTime_s time;
        // XONTypeData, XONTypeString, XONTypeArray, XONTypeMessage
        ssize_t count;
    } value;
} XCValueHeader_s;

static inline XCValueHeader_s XCValueHeaderMake(void) {
    XCValueHeader_s h = { 0 };
    return h;
}

typedef enum {
    XCTimeLayoutInvalid = 0x0,
    XCTimeLayoutDistantPast = 0x1,
    XCTimeLayoutDistantFuture = 0x2,
    XCTimeLayoutZero = 0x3,
} XCTimeLayout_e;

extern ssize_t XCHeaderMaxLength(void);

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


extern XONError_e XCEncodeFieldKeyOffset(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t offset);

/// type >= 0
extern XONError_e XCEncodeMessageHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XONError_e XCEncodeArrayHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XONError_e XCEncodeDataHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XONError_e XCEncodeStringHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);


extern XONError_e XCEncodeBody(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, const void * _Nonnull data, ssize_t count);


typedef XONError_e (*XCVarintEncode_f)(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value);
typedef XONError_e (*XCVarintDecode_f)(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t * _Nonnull value);

#endif /* XCoreCoder_h */
