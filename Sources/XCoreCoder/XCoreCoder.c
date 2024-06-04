
#include "XCoreCoder.h"
#include <stdio.h>
#include <math.h>
#include <strings.h>
#include <limits.h>

#ifndef MIN
#define MIN(a, b) (((a)<(b))?(a):(b))
#endif /* MIN */
#ifndef MAX
#define MAX(a, b) (((a)>(b))?(a):(b))
#endif  /* MAX */

char * _Nonnull const XONErrorDomain = "XON";

#ifndef XAssert
#define XAssert(cond, desc) {\
    if (!(cond)) {\
        fprintf(stderr, "[%s error] %s\n", __func__, desc);\
        abort();\
    }\
}
#endif

#if DEBUG

#ifndef XDebugAssert
#define XDebugAssert(cond, desc) {\
    if (!(cond)) {\
        fprintf(stderr, "[%s error] %s\n", __func__, desc);\
        abort();\
    }\
}
#endif

#else

#ifndef XDebugAssert
#define XDebugAssert(cond, desc)
#endif

#endif

static inline uint64_t XCSInt64ZigzagEncode(int64_t value) {
    uint64_t tmp = *((uint64_t *)&value);
    return (tmp << UINT64_C(1)) ^ (0 - (tmp >> UINT64_C(63)));
}
static inline int64_t XCSInt64ZigzagDecode(uint64_t data) {
    return (int64_t)((data >> UINT64_C(1)) ^ (0 - (data & UINT64_C(1))));
}

/// require length >= 0 && length <= 8
static inline uint64_t __XCDecodeTrimLeadingZeroByteIntFromBuffer(const uint8_t * _Nonnull buffer, ssize_t length) {
    uint64_t v = 0;
    for (ssize_t i=0; i<length; i++) {
        v = (v << 8) + buffer[i];
    }
    return v;
}

/// require buffer.capacity >= 8
static inline ssize_t __XCEncodeTrimLeadingZeroByteIntToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    // 63-7=56
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)(value >> 56);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 48);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 40);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 32);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 24);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 16);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 8);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    return used;
}

static inline ssize_t XCUInt64LeadingZeroBitCount(uint64_t x) {
    if (0 == x) {
        return 64;
    }
    int32_t r = 0;
    if (0 == (x & UINT64_C(0xFFFFFFFF00000000))) {
        x <<= 32;
        r += 32;
    }
    if (0 == (x & UINT64_C(0xFFFF000000000000))) {
        x <<= 16;
        r += 16;
    }
    if (0 == (x & UINT64_C(0xFF00000000000000))) {
        x <<= 8;
        r += 8;
    }
    if (0 == (x & UINT64_C(0xF000000000000000))) {
        x <<= 4;
        r += 4;
    }
    if (0 == (x & UINT64_C(0xC000000000000000))) {
        x <<= 2;
        r += 2;
    }
    if (0 == (x & UINT64_C(0x8000000000000000))) {
        x <<= 1;
        r += 1;
    }
    return r;
}
static inline int32_t XCUInt64TrailingZeroBitCount(uint64_t x) {
    if (0 == x) {
        return 64;
    }
    int32_t r = 0;
    if (0 == (x & UINT64_C(0xFFFFFFFF))) {
        x >>= 32;
        r += 32;
    }
    if (0 == (x & UINT64_C(0xFFFF))) {
        x >>= 16;
        r += 16;
    }
    if (0 == (x & UINT64_C(0xFF))) {
        x >>= 8;
        r += 8;
    }
    if (0 == (x & UINT64_C(0xF))) {
        x >>= 4;
        r += 4;
    }
    if (0 == (x & UINT64_C(0x3))) {
        x >>= 2;
        r += 2;
    }
    if (0 == (x & UINT64_C(0x1))) {
        x >>= 1;
        r += 1;
    }
    return r;
}


static inline void XCDecodeTypeLayout(uint8_t byte, uint8_t * _Nonnull type, uint8_t * _Nonnull layout) {
    *layout = (byte & 0x1F);
    *type = (XONType_e)(byte >> 5);
}

static inline XONError_e __XCDecodeUInt63Varint(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t * _Nonnull value) {
    ssize_t used = 0;
    uint64_t tmp = 0;
    if (*location >= capacity - used) {
        return XONErrorNotEnough;
    }
    uint8_t byte = bytes[*location + used];
    used += 1;
    tmp = byte & 0x7f;
    if (byte == 0x80) {
        return XONErrorVarInt;
    } else if (byte & 0x80) {
        while (*location < capacity - used) {
            if (used >= 9) {
                return XONErrorVarInt;
            }
            uint8_t byte = bytes[*location + used];
            used += 1;
            tmp = (tmp << 7) + (byte & 0x7f);
            if ((byte & 0x80) == 0) {
                *value = tmp;
                *location += used;
                return XONErrorNone;
            }
        }
        return XONErrorNotEnough;
    } else {
        *value = tmp;
        *location += 1;
        return XONErrorNone;
    }
}
static inline ssize_t __XCEncodeUInt63VarintLength(uint64_t value) {
    uint64_t x = (value >> 7) << 8;
    
    if (0 == x) {
        return 1;
    } else {
        ssize_t length = 9;
        if (0 == (x & UINT64_C(0xFFFFFFF000000000))) {
            x <<= 28;
            length -= 4;
        }
        if (0 == (x & UINT64_C(0xFFFC000000000000))) {
            x <<= 14;
            length -= 2;
        }
        if (0 == (x & UINT64_C(0xFE00000000000000))) {
            x <<= 7;
            length -= 1;
        }
        return length;
    }
}

static inline XONError_e __XCEncodeUInt63Varint(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    ssize_t length = __XCEncodeUInt63VarintLength(value);
    if (*location + length > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t * buffer = bytes + *location;
    *location += length;
    while (length > 1) {
        length -= 1;
        *buffer = (uint8_t)((value >> (7 * length)) | 0x80);
        buffer += 1;
    }
    *buffer = (uint8_t)(value & 0x7f);
    return XONErrorNone;
}

/// require buffer.capacity >= 9
static inline ssize_t __XCEncodeUInt63VarintToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    // 63-7=56
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 56) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 49) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 42) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 35) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }

    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;
    return used;
}

/// require buffer.capacity >= 5
static inline ssize_t __XCEncodeUInt32VarintToBuffer(uint8_t * _Nonnull buffer, uint32_t value) {
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }

    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;
    return used;
}



//static inline XONError_e __XCEncodeUInt63Varint(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
//    XDebugAssert(bytes, "");
//
//    uint8_t buffer[8] = { 0 };
//    // 63-7=56
//    ssize_t used = 0;
//
//    uint8_t byte = (uint8_t)((value >> 56) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    byte = (uint8_t)((value >> 49) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    byte = (uint8_t)((value >> 42) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    byte = (uint8_t)((value >> 35) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    byte = (uint8_t)((value >> 28) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    byte = (uint8_t)((value >> 21) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    byte = (uint8_t)((value >> 14) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    byte = (uint8_t)((value >> 7) | 0x80);
//    if (used > 0 || 0x80 != byte) {
//        buffer[used] = byte;
//        used += 1;
//    }
//    if (*location >= capacity - used - 1) {
//        return XONErrorNotEnough;
//    }
//    memcpy(bytes + *location, buffer, used);
//    bytes[*location + used] = (uint8_t)(value & 0x7f);
//    *location += used + 1;
//    return XONErrorNone;
//}

XONError_e __XCEncodeUInt64Varint_old(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    ssize_t length = (64 - XCUInt64LeadingZeroBitCount(value) + 6) / 7;
    if (length == 0) {
        length = 1;
    }
    if (*location + length > capacity) {
        return XONErrorNotEnough;
    }
    ssize_t lastOffset = length - 1;
    for (ssize_t offset=0; offset<lastOffset; offset++) {
        bytes[*location + offset] = (uint8_t)((value >> ((lastOffset - offset) * 7)) | 0x80);
    }
    bytes[*location + lastOffset] = (uint8_t)(value & 0x7f);
    *location += length;
    return XONErrorNone;
}

XONError_e __XCEncodeUInt64Varint_old2(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    uint8_t buffer[16] = { 0 };
    ssize_t used = 0;
    for (ssize_t shift = 63; shift>0; shift-=7) {
        uint8_t byte = (uint8_t)((value >> shift) | 0x80);
        if (used > 0 || 0x80 != byte) {
            buffer[used] = byte;
            used += 1;
        }
    }
    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;
    
    if (*location >= capacity - used) {
        return XONErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, used);
    *location += used;
    return XONErrorNone;
}

static inline ssize_t __XCEncodeUInt64VarintToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 63) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 56) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 49) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 42) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 35) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;

    return used;
}

static inline XONError_e __XCEncodeUInt64Varint(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    
    uint8_t buffer[16] = { 0 };
    // 63-7=56
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 63) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 56) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 49) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 42) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 35) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;

    if (*location >= capacity - used) {
        return XONErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, used);
    *location += used;
    return XONErrorNone;
}

static inline XONError_e __XCDecodeUInt64Varint(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t * _Nonnull value) {
    int32_t used = 0;
    uint64_t tmp = 0;
    if (*location >= capacity - used) {
        return XONErrorNotEnough;
    }
    uint8_t byte = bytes[*location + used];
    used += 1;
    tmp = byte & 0x7f;
    if (byte == 0x80) {
        return XONErrorVarInt;
    } else if (byte & 0x80) {
        while (*location < capacity - used) {
            if (used >= 10) {
                return XONErrorVarInt;
            }
            
            uint8_t byte = bytes[*location + used];
            used += 1;
            
            tmp = (tmp << 7) | (byte & 0x7f);
            if ((byte & 0x80) == 0) {
                if (used == 10 && bytes[*location] != 0x81) {
                    return XONErrorVarInt;
                }
                *value = tmp;
                *location += used;
                return XONErrorNone;
            }
        }
        return XONErrorNotEnough;
    } else {
        *value = tmp;
        *location += 1;
        return XONErrorNone;
    }
}


static inline XONError_e __XCDecodeHeaderCount(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint8_t layout, uint64_t * _Nonnull value) {
    uint64_t count = 0;
    if (layout == 31) {
        XONError_e result = __XCDecodeUInt64Varint(bytes, capacity, location, &count);
        if (result != XONErrorNone) {
            return result;
        }
        if (count > UINT64_MAX - 31) {
            return XONErrorCount;
        }
        count += 31;
    } else {
        count = layout;
    }
    *value = count;
    return XONErrorNone;
}

static inline ssize_t __XCEncodeSignAndSignificandToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    ssize_t used = 0;
    uint64_t tmp = value;
    while (0 != tmp) {
        buffer[used] = (uint8_t)(tmp >> 56);
        used += 1;
        tmp = tmp << 8;
    }
    return used;
}

static inline XONError_e __XCDecodeSignAndSignificand(const uint8_t * _Nonnull bytes, ssize_t length, uint64_t * _Nonnull _value) {
    uint64_t value = 0;
    if (length > 0) {
        uint64_t v = 0;
        for (ssize_t i=0; i<length; i++) {
            v = bytes[i];
            value |= v << ((7 - i) * 8);
        }
        if (v == 0) {
            return XONErrorNumberContent;
        }
    }
    *_value = value;
    return XONErrorNone;
}

static inline XCNumberNormalContent_s __XCEncodeIntNumberInternal(uint64_t sign, uint64_t v) {
    XCNumberNormalContent_s content = {};
    uint64_t leadingZeroCount = XCUInt64LeadingZeroBitCount(v);
    int64_t e = leadingZeroCount + 1;
    uint64_t m = v << e;
    content.exponent = 64 - e;
    content.signAndSignificand = sign | (m >> 1);
    return content;
}

/// f: f != nan && f != inf && f != 0
static inline XCNumberNormalContent_s _XCEncodeNumberFloat64(double f) {
    XCNumberNormalContent_s number = {};
    uint64_t bits = *(uint64_t *)&(f);
    uint64_t sign = bits & (UINT64_C(1) << 63);
    uint64_t te = (bits & UINT64_C(0x7FF0000000000000)) >> 52;
    int64_t e = (int64_t)te - 1023;
    
    XDebugAssert(e < 1024, "");
    XDebugAssert(e >= -1023, "");

    if (e == 1024) {// nan inf
        abort();
    } else if (e == -1023) {
        // subnormal numbers
        uint64_t m = (bits & UINT64_C(0xFFFFFFFFFFFFF)) << UINT64_C(12);
        XDebugAssert(0 != m, "");
        uint64_t shift = XCUInt64LeadingZeroBitCount(m) + 1;
        XDebugAssert(shift <= 52, "");
        m = m << shift;
        number.exponent = -1022 - shift;
        number.signAndSignificand = sign | (m >> 1);
    } else {
        // e: [1, 2046]
        uint64_t m = (bits & UINT64_C(0xFFFFFFFFFFFFF)) << UINT64_C(11);
        number.exponent = e;
        number.signAndSignificand = sign | m;
    }
    return number;
}

/// number != 0
static inline XCNumberNormalContent_s _XCEncodeNumberUInt64(uint64_t number) {
    XDebugAssert(number != 0, "");
    return __XCEncodeIntNumberInternal(0, number);
}

/// number != 0
static inline XCNumberNormalContent_s _XCEncodeNumberSInt64(int64_t value) {
    XDebugAssert(value != 0, "");
    uint64_t v = value > 0 ? value : value * (-1);
    uint64_t sign = value > 0 ? 0 : UINT64_C(1) << UINT64_C(63);
    return __XCEncodeIntNumberInternal(sign, v);
}

static inline XONError_e __XCDecodeNumberValue(int64_t exponent, uint64_t signAndSignificand, XCNumberValue_s * _Nonnull number) {
    uint64_t sign = signAndSignificand & (UINT64_C(1) << 63);
    uint64_t m = signAndSignificand & (UINT64_MAX >> 1);
    uint64_t m2 = (UINT64_C(1) << 63) | m;
    int64_t trailingZerosCount = XCUInt64TrailingZeroBitCount(m2);
    if (exponent > -1023 && exponent < 1024) {
        if (trailingZerosCount >= 11) {
            uint64_t e = exponent + 1023;
            uint64_t bits = sign | (e << 52) | (m >> 11);
            number->type = XCNumberTypeFloat64;
            number->value.f = *(double *)&(bits);
            return XONErrorNone;
        } else {
            uint64_t m2 = (UINT64_C(1) << 63) | m;
            if (exponent >= 0 && exponent <= 63 && 63 - exponent <= trailingZerosCount) {
                uint64_t value = m2 >> (63 - exponent);
                // 1 exponent=0
                // 2 exponent=1 1
                uint64_t sint64Min = UINT64_C(1) << 63;
                if (sign) {// 负数
                    if (value == sint64Min) {
                        number->type = XCNumberTypeSInt;
                        number->value.s = INT64_MIN;
                        return XONErrorNone;
                    } else if (value < sint64Min) {
                        int64_t sv = value;
                        sv *= -1;
                        number->type = XCNumberTypeSInt;
                        number->value.s = sv;
                        return XONErrorNone;
                    } else {
                        number->type = XCNumberTypeNone;
                        number->value.u = 0;
                        return XONErrorNumberOutOfRange;
                    }
                } else {
                    if (value < sint64Min) {
                        int64_t sv = value;
                        number->type = XCNumberTypeSInt;
                        number->value.s = sv;
                    } else {
                        number->type = XCNumberTypeUInt;
                        number->value.u = value;
                    }
                    return XONErrorNone;
                }
            } else {
                number->type = XCNumberTypeNone;
                number->value.u = 0;
                return XONErrorNumberOutOfRange;
            }
        }
    } else if (exponent >= 1024) {
        number->type = XCNumberTypeNone;
        number->value.u = 0;
        return XONErrorNumberOutOfRange;
    } else { // number.e <= -1023
        int64_t shift = -1022 - exponent + 11;
        if (trailingZerosCount >= shift) {
            uint64_t bits = sign | (m2 >> shift);
            number->type = XCNumberTypeFloat64;
            number->value.f = *(double *)&(bits);
            return XONErrorNone;
        } else {
            number->type = XCNumberTypeNone;
            number->value.u = 0;
            return XONErrorNumberOutOfRange;
        }
    }
}

ssize_t XCHeaderMaxLength(void) {
    return 24;
}

XONError_e XCDecodeHeader(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCValueHeader_s * _Nonnull header) {
    XAssert(bytes, "");
    XAssert(header, "");
    XAssert(location, "");

    bzero(header, sizeof(XCValueHeader_s));
    if (*location >= capacity) {
        return XONErrorNotEnough;
    }
    XONError_e result = 0;
    uint8_t byte = bytes[*location];
    uint8_t type = 0;
    uint8_t layout = 0;
    XCDecodeTypeLayout(byte, &type, &layout);
    *location += 1;

    switch ((XONType_e)type) {
        case XONTypeNil: {
            if (layout == 0) {
                header->type = XONTypeNil;
                return XONErrorNone;
            } else if (layout == 1) {
                header->type = XONTypeBool;
                header->value.boolValue = true;
                return XONErrorNone;
            } else if (layout == 2) {
                header->type = XONTypeBool;
                header->value.boolValue = false;
                return XONErrorNone;
            } else {
                return XONErrorLayout;
            }
        }
        case XONTypeNumber: {
            header->type = type;
            if (layout == 0) {
                header->value.number.format = XCNumberFormatFloat;
                uint64_t count = 0;
                result = __XCDecodeUInt63Varint(bytes, capacity, location, &count);
                if (result != XONErrorNone) {
                    return result;
                }
                if (count > SSIZE_MAX) {
                    return XONErrorCount;
                }
                if (*location > capacity - count) {
                    return XONErrorCount;
                }
                header->value.number.length = (ssize_t)count;
            } else if (layout <= XCNumberFormatZero) {
                header->value.number.format = layout;
                header->value.number.length = 0;
            } else {
                header->value.number.format = XCNumberFormatFloat;
                header->value.number.length = layout - XCNumberFormatZero;
            }
            return XONErrorNone;
        }
        case XONTypeTime: {
            header->type = type;
            if (layout & 0x10) {
                // Decimal time
                uint8_t length = layout & 0xf;
                if (*location >= capacity) {
                    return XONErrorNotEnough;
                }
                uint8_t byte = bytes[*location];
                *location += 1;
                uint8_t decimalLength = (byte >> 4) + 1;
                uint8_t decimalExponent = byte & 0xf;
                if (*location > capacity - length - decimalLength) {
                    return XONErrorCount;
                }
                if (length > 8 || decimalLength > 8) {
                    return XONErrorNotImplemented;
                }
                uint64_t svalue = __XCDecodeTrimLeadingZeroByteIntFromBuffer(bytes + *location, length);
                uint64_t avalue = __XCDecodeTrimLeadingZeroByteIntFromBuffer(bytes + *location + length, decimalLength);
                if (avalue == 0) {
                    return XONErrorTimeContent;
                }
                if (decimalExponent != 15 && (avalue % 10 == 0)) {
                    return XONErrorTimeContent;
                }
                
                // 18 60
                static uint64_t scales[16] = {
                    1,
                    10,
                    100,
                    1000,
                    10000,
                    100000,
                    1000000,
                    10000000,
                    100000000,
                    1000000000ULL,
                    10000000000ULL,
                    100000000000ULL,
                    1000000000000ULL,
                    10000000000000ULL,
                    100000000000000ULL,
                    1000000000000000ULL,
                };
                
                uint64_t scale = scales[decimalExponent];

                if (avalue >= XATTOSECOND_PER_SECOND / scale) {
                    return XONErrorTimeContent;
                }
                header->value.time.second = XCSInt64ZigzagDecode(svalue);
                header->value.time.attosecond = avalue * scale;
                *location += length + decimalLength;
                return XONErrorNone;
            } else {
                // Integer time
                switch (layout) {
                    case XTimestampLayoutInvalid: {
                        header->value.time = XTimestampInvalidDefault();
                    }
                        return XONErrorNone;
                    case XTimestampLayoutDistantPast: {
                        header->value.time = XTimestampDistantPast();
                    }
                        return XONErrorNone;
                    case XTimestampLayoutDistantFuture: {
                        header->value.time = XTimestampDistantFuture();
                    }
                        return XONErrorNone;
                    default: {
                        uint8_t length = layout - XTimestampLayoutZero;
                        if (*location > capacity - length) {
                            return XONErrorCount;
                        }
                        if (length > 8) {
                            return XONErrorNotImplemented;
                        }
                        uint64_t svalue = __XCDecodeTrimLeadingZeroByteIntFromBuffer(bytes + *location, length);
                        *location += length;
                        header->value.time.second = XCSInt64ZigzagDecode(svalue);
                        header->value.time.attosecond = 0;
                        return XONErrorNone;
                    }
                }
            }
        }
            break;
        case XONTypeString:
        case XONTypeData:
        case XONTypeArray:
        case XONTypeMessage: {
            uint64_t count = 0;
            result = __XCDecodeHeaderCount(bytes, capacity, location, layout, &count);
            if (result != XONErrorNone) {
                return result;
            }
            if (*location > capacity - count) {
                return XONErrorNotEnough;
            }
            header->type = type;
            header->value.count = count;
            return XONErrorNone;
        }
        default: {
            return XONErrorType;
        }
    }
    return XONErrorNone;
}

XONError_e XCDecodeNumber64(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t format, ssize_t count, XCNumberValue_s * _Nonnull number) {
    switch (format) {
        case XCNumberFormatZero: {
            number->type = XCNumberTypeFloat64;
            number->value.f = __XCDoubleZero();
            return XONErrorNone;
        }
        case XCNumberFormatNan: {
            number->type = XCNumberTypeFloat64;
            number->value.f = __XCDoubleNan();
            return XONErrorNone;
        }
        case XCNumberFormatPositiveInfinity: {
            number->type = XCNumberTypeFloat64;
            number->value.f = __XCDoublePositiveInfinity();
            return XONErrorNone;
        }
        case XCNumberFormatNegativeInfinity: {
            number->type = XCNumberTypeFloat64;
            number->value.f = __XCDoubleNegativeInfinity();
            return XONErrorNone;
        }
        case XCNumberFormatFloat: {
            // e: varint64 ; signAndSignificand
            ssize_t len = count;
            ssize_t startIndex = *location;
            if (*location > capacity - len) {
                return XONErrorNotEnough;
            }
            uint64_t ev = 0;
            XONError_e result = __XCDecodeUInt64Varint(bytes, *location + len, location, &ev);
            if (result != XONErrorNone) {
                return result;
            }
            ssize_t usingLength = *location - startIndex;
            int64_t exponent = XCSInt64ZigzagDecode(ev);
            uint64_t signAndSignificand = 0;
            result = __XCDecodeSignAndSignificand(bytes + *location, len - usingLength, &signAndSignificand);
            if (result != XONErrorNone) {
                return result;
            }
            *location += len - usingLength;
            return __XCDecodeNumberValue(exponent, signAndSignificand, number);
        }
        default: {
            return XONErrorNumberContent;
        }
    }
}

XONError_e XCDecodeFieldKeyOffset(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t * _Nonnull offset) {
    XAssert(bytes, "");
    XAssert(location, "");
    XAssert(offset, "");
    uint64_t v = 0;
    XONError_e error = __XCDecodeUInt63Varint(bytes, capacity, location, &v);
    if (XONErrorNone != error) {
        return error;
    }
    if (v >= UINT32_MAX) {
        return XONErrorMessageFieldKeyOffset;
    }
    v += 1;
    *offset = (int32_t)v;
    return XONErrorNone;
}

#pragma mark - encode


static inline void XCEncodeTypeLayout(uint8_t * _Nonnull byte, uint8_t type, uint8_t layout) {
    uint8_t v = (type << 5) | (layout & 0x1f);
    *byte = v;
}
static inline uint8_t XCNullByte(void) {
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNil, 0);
    return header;
}
static inline uint8_t XCBoolByte(_Bool value) {
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNil, value ? 1 : 2);
    return header;
}

static inline void XCEncodeBufferExpandCapacity(XCEncodeBuffer_s * _Nonnull buffer, ssize_t size) {
    if (buffer->capacity < size) {
        XCEncodeBufferReserveCapacity(buffer, size);
    }
}

XONError_e XCEncodeFieldKeyOffset(XCEncodeBuffer_s * _Nonnull buffer, uint32_t offset) {
    if (offset <= 0) {
        return XONErrorMessageIndexOffset;
    }
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 5);
    uint32_t value = offset - 1;
    ssize_t length = __XCEncodeUInt32VarintToBuffer(buffer->bytes + buffer->location, value);
    buffer->location += length;
    return XONErrorNone;
}

XONError_e XCEncodeNull(XCEncodeBuffer_s * _Nonnull buffer) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
    buffer->bytes[buffer->location] = XCNullByte();
    buffer->location += 1;
    return XONErrorNone;
}

XONError_e XCEncodeBool(XCEncodeBuffer_s * _Nonnull buffer, _Bool value) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
    buffer->bytes[buffer->location] = XCBoolByte(value);
    buffer->location += 1;
    return XONErrorNone;
}

static inline XONError_e __XCEncodeNumberByte(XCEncodeBuffer_s * _Nonnull buffer, XCNumberNormalContent_s value) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 20);
    ssize_t length = 1;
    length += __XCEncodeUInt64VarintToBuffer(buffer->bytes + buffer->location + length, XCSInt64ZigzagEncode(value.exponent));
    length += __XCEncodeSignAndSignificandToBuffer(buffer->bytes + buffer->location + length, value.signAndSignificand);
    uint8_t layout = length + XCNumberFormatZero - 1;
    if (layout >= 16) {
        return XONErrorLayout;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNumber, layout);
    buffer->bytes[buffer->location] = header;
    buffer->location += length;
    return XONErrorNone;
}

static inline XONError_e __XCEncodeNumberHeader(XCEncodeBuffer_s * _Nonnull buffer, uint8_t layout) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNumber, layout);
    buffer->bytes[buffer->location] = header;
    buffer->location += 1;
    return XONErrorNone;
}
XONError_e XCEncodeNumberUInt64(XCEncodeBuffer_s * _Nonnull buffer, uint64_t value) {
    if (0 == value) {
        return __XCEncodeNumberHeader(buffer, XCNumberFormatZero);
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberUInt64(value);
        return __XCEncodeNumberByte(buffer, data);
    }
}
XONError_e XCEncodeNumberSInt64(XCEncodeBuffer_s * _Nonnull buffer, int64_t value) {
    if (0 == value) {
        return __XCEncodeNumberHeader(buffer, XCNumberFormatZero);
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberSInt64(value);
        return __XCEncodeNumberByte(buffer, data);
    }
}
XONError_e XCEncodeNumberDouble(XCEncodeBuffer_s * _Nonnull buffer, double value) {
    if (value == __XCDoubleZero()) {
        return __XCEncodeNumberHeader(buffer, XCNumberFormatZero);
    } else if (isnan(value)) {
        return __XCEncodeNumberHeader(buffer, XCNumberFormatNan);
    } else if (isinf(value)) {
        if (value < 0) {
            return __XCEncodeNumberHeader(buffer, XCNumberFormatNegativeInfinity);
        } else {
            return __XCEncodeNumberHeader(buffer, XCNumberFormatPositiveInfinity);
        }
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberFloat64(value);
        return __XCEncodeNumberByte(buffer, data);
    }
}

XONError_e XCEncodeTimeInvalid(XCEncodeBuffer_s * _Nonnull buffer) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XTimestampLayoutInvalid);
    buffer->bytes[buffer->location] = header;
    buffer->location += 1;
    return XONErrorNone;
}
XONError_e XCEncodeTimeDistantPast(XCEncodeBuffer_s * _Nonnull buffer) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XTimestampLayoutDistantPast);
    buffer->bytes[buffer->location] = header;
    buffer->location += 1;
    return XONErrorNone;
}
XONError_e XCEncodeTimeDistantFuture(XCEncodeBuffer_s * _Nonnull buffer) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XTimestampLayoutDistantFuture);
    buffer->bytes[buffer->location] = header;
    buffer->location += 1;
    return XONErrorNone;
}
XONError_e __XCEncodeTimeZero(XCEncodeBuffer_s * _Nonnull buffer) {
    XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XTimestampLayoutZero);
    buffer->bytes[buffer->location] = header;
    buffer->location += 1;
    return XONErrorNone;
}

XONError_e XCEncodeTime(XCEncodeBuffer_s * _Nonnull buffer, int64_t second, uint64_t attosecond) {
    if (attosecond >= XATTOSECOND_PER_SECOND) {
        XCEncodeBufferExpandCapacity(buffer, buffer->location + 1);
        if (attosecond == UINT64_MAX) {
            if (second == INT64_MIN) {
                return XCEncodeTimeDistantPast(buffer);
            } else if (second == INT64_MAX) {
                return XCEncodeTimeDistantFuture(buffer);
            } else {
                return XCEncodeTimeInvalid(buffer);
            }
        } else {
            return XCEncodeTimeInvalid(buffer);
        }
    } else {
        if (0 == attosecond) {
            XCEncodeBufferExpandCapacity(buffer, buffer->location + 9);
            uint8_t header = 0;
            uint64_t encodedBytes = XCSInt64ZigzagEncode(second);
            ssize_t slength = __XCEncodeTrimLeadingZeroByteIntToBuffer(buffer->bytes + buffer->location + 1, encodedBytes);
            XCEncodeTypeLayout(&header, XONTypeTime, XTimestampLayoutZero + slength);
            buffer->bytes[buffer->location] = header;
            buffer->location += 1 + slength;
            return XONErrorNone;
        } else {
            XCEncodeBufferExpandCapacity(buffer, buffer->location + 20);
            uint8_t header = 0;
            uint64_t encodedBytes = XCSInt64ZigzagEncode(second);
            ssize_t slength = __XCEncodeTrimLeadingZeroByteIntToBuffer(buffer->bytes + buffer->location + 2, encodedBytes);
            XCEncodeTypeLayout(&header, XONTypeTime, 0x10 + slength);
            buffer->bytes[buffer->location] = header;

            uint64_t avalue = attosecond;
            uint8_t e = 0;
            if (attosecond % 1000000000000000ULL == 0) {
                e = 15;
                avalue /= 1000000000000000ULL;
            } else {
                if (avalue % 100000000ULL == 0) {
                    avalue /= 100000000ULL;
                    e += 8;
                }
                if (avalue % 10000ULL == 0) {
                    avalue /= 10000ULL;
                    e += 4;
                }
                if (avalue % 100ULL == 0) {
                    avalue /= 100ULL;
                    e += 2;
                }
                if (avalue % 10ULL == 0) {
                    avalue /= 10ULL;
                    e += 1;
                }
            }

            ssize_t alength = __XCEncodeTrimLeadingZeroByteIntToBuffer(buffer->bytes + buffer->location + 2 + slength, avalue);
            // 4
            ssize_t length = 2 + slength + alength;
            buffer->bytes[buffer->location + 1] = ((alength - 1) << 4) | e;
            buffer->location += length;
            return XONErrorNone;
        }
    }
}


static inline XONError_e __XCEncodeHeaderCount(XCEncodeBuffer_s * _Nonnull buffer, XONType_e type, ssize_t count) {
    if (count < 0) {
        return XONErrorCount;
    }
    if (count >= 31) {
        XCEncodeBufferExpandCapacity(buffer, buffer->location + 10 + count);
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, type, 31);
        buffer->bytes[buffer->location] = header;
        uint64_t varint = count - 31;
        ssize_t length = 1 + __XCEncodeUInt63VarintToBuffer(buffer->bytes + buffer->location + 1, varint);
        buffer->location += length;
        return XONErrorNone;
    } else {
        XCEncodeBufferExpandCapacity(buffer, buffer->location + 1 + count);
        uint8_t layout = (uint8_t)count;
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, type, layout);
        buffer->bytes[buffer->location] = header;
        buffer->location += 1;
        return XONErrorNone;
    }
}

XONError_e XCEncodeMessageHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count) {
    return __XCEncodeHeaderCount(buffer, XONTypeMessage, count);
}

XONError_e XCEncodeArrayHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count) {
    return __XCEncodeHeaderCount(buffer, XONTypeArray, count);
}

XONError_e XCEncodeDataHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count) {
    return __XCEncodeHeaderCount(buffer, XONTypeData, count);
}

XONError_e XCEncodeStringHeader(XCEncodeBuffer_s * _Nonnull buffer, ssize_t count) {
    return __XCEncodeHeaderCount(buffer, XONTypeString, count);
}

XONError_e XCEncodeBody(XCEncodeBuffer_s * _Nonnull buffer, const void * _Nonnull data, ssize_t count) {
    if (count < 0) {
        return XONErrorCount;
    }
    XCEncodeBufferExpandCapacity(buffer, buffer->location + count);
    memcpy(buffer->bytes + buffer->location, data, count);
    buffer->location += count;
    return XONErrorNone;
}

#pragma mark - XCEncodeBuffer

static inline uint32_t clz32(uint32_t x) {
    if (0 == x) {
        return 32;
    }
    uint32_t r = 0;
    if (0 == (x & UINT32_C(0xFFFF0000))) {
        x <<= 16;
        r += 16;
    }
    if (0 == (x & UINT32_C(0xFF000000))) {
        x <<= 8;
        r += 8;
    }
    if (0 == (x & UINT32_C(0xF0000000))) {
        x <<= 4;
        r += 4;
    }
    if (0 == (x & UINT32_C(0xC0000000))) {
        x <<= 2;
        r += 2;
    }
    if (0 == (x & UINT32_C(0x80000000))) {
        x <<= 1;
        r += 1;
    }
    return r;
}

static inline uint64_t clz64(uint64_t x) {
    if (0 == x) {
        return 64;
    }
    uint64_t r = 0;
    if (0 == (x & UINT64_C(0xFFFFFFFF00000000))) {
        x <<= 32;
        r += 32;
    }
    if (0 == (x & UINT64_C(0xFFFF000000000000))) {
        x <<= 16;
        r += 16;
    }
    if (0 == (x & UINT64_C(0xFF00000000000000))) {
        x <<= 8;
        r += 8;
    }
    if (0 == (x & UINT64_C(0xF000000000000000))) {
        x <<= 4;
        r += 4;
    }
    if (0 == (x & UINT64_C(0xC000000000000000))) {
        x <<= 2;
        r += 2;
    }
    if (0 == (x & UINT64_C(0x8000000000000000))) {
        x <<= 1;
        r += 1;
    }
    return r;
}

size_t clz(size_t n) {
    if (sizeof(size_t) == 8) {
        return clz64(n);
    } else if (sizeof(size_t) == 4) {
        return clz32(n);
    } else {
        abort();
    }
}
ssize_t XCRoundUpSize(ssize_t minSize) {
    size_t size = MAX(0x1000, minSize);
    size_t leadingZeroBitCount = clz(size);
    size_t one = 1;
    if ((one << (sizeof(size_t) * 8 - 1 - leadingZeroBitCount)) != size) {
        size = one << (sizeof(size_t) * 8 - leadingZeroBitCount);
    }
    XAssert(size <= SSIZE_MAX, "");
    return size;
}

void _XCEncodeBufferDefaultRealloc(XCEncodeBuffer_s * _Nonnull buffer, ssize_t minCapacity) {
    XAssert(minCapacity >= 0, "");
    XAssert(buffer, "");
    ssize_t size = XCRoundUpSize(MAX(buffer->location, minCapacity));
    if (size != buffer->capacity) {
        void * ptr = realloc(buffer->context, size);
        XAssert(ptr, "");
        buffer->context = ptr;
        buffer->bytes = (uint8_t *)ptr;
        buffer->capacity = size;
    }
}
void _XCEncodeBufferDefaultDealloc(XCEncodeBuffer_s * _Nonnull buffer) {
    if (buffer->context) {
        free(buffer->context);
    }
    bzero(buffer, sizeof(XCEncodeBuffer_s));
}
void _XCEncodeBufferDefaultFitSize(XCEncodeBuffer_s * _Nonnull buffer) {
    XAssert(buffer, "");
    if (buffer->capacity > buffer->location) {
        void * ptr = realloc(buffer->context, buffer->location);
        XAssert(ptr, "");
        buffer->context = ptr;
        buffer->bytes = (uint8_t *)ptr;
        buffer->capacity = buffer->location;
    }
}
