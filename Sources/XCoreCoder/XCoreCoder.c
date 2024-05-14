
#include "XCoreCoder.h"
#include <stdio.h>
#include <math.h>
#include <strings.h>
#include <limits.h>


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

static inline void XCEncodeTypeLayout(uint8_t * _Nonnull byte, uint8_t type, uint8_t layout) {
    uint8_t v = (type << 5) | (layout & 0x1f);
    *byte = v;
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
static inline ssize_t __XCEncodeUInt31VarintToBuffer(uint8_t * _Nonnull buffer, uint32_t value) {
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



static inline XONError_e __XCEncodeUInt63Varint(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    
    uint8_t buffer[8] = { 0 };
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
    if (*location >= capacity - used - 1) {
        return XONErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, used);
    bytes[*location + used] = (uint8_t)(value & 0x7f);
    *location += used + 1;
    return XONErrorNone;
}

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

static inline XONError_e __XCEncodeHeaderCount(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XONType_e type, ssize_t count) {
    if (count < 0) {
        return XONErrorCount;
    }
    if (count >= 31) {
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, type, 31);
        
        uint8_t buffer[16] = { 0 };
        buffer[0] = header;
        uint64_t varint = count - 31;
        ssize_t length = 1 + __XCEncodeUInt63VarintToBuffer(buffer + 1, varint);
        
        if (*location > capacity - length) {
            return XONErrorNotEnough;
        }
        memcpy(bytes + *location, buffer, length);
        *location += length;
        return XONErrorNone;
    } else {
        if (*location > capacity - 1) {
            return XONErrorNotEnough;
        }
        uint8_t layout = (uint8_t)count;
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, type, layout);
        bytes[*location] = header;
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
                        return XONErrorNumberOutOfBounds;
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
                return XONErrorNumberOutOfBounds;
            }
        }
    } else if (exponent >= 1024) {
        number->type = XCNumberTypeNone;
        number->value.u = 0;
        return XONErrorNumberOutOfBounds;
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
            return XONErrorNumberOutOfBounds;
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
            uint8_t length = 0;
            uint8_t decimalLength = 0;
            uint8_t decimalExponent = 0;
            if (layout & 0x10) {
                // Decimal time
                length = layout & 0xf;
                if (*location >= capacity) {
                    return XONErrorNotEnough;
                }
                uint8_t byte = bytes[*location];
                *location += 1;
                decimalLength = byte >> 4;
                decimalExponent = byte & 0xf;
            } else {
                // Integer time
                switch (layout) {
                    case XCTimeLayoutInvalid: {
                        header->value.time = __XCTimeInvalidDefault();
                    }
                        return XONErrorNone;
                    case XCTimeLayoutDistantPast: {
                        header->value.time = __XCTimeDistantPast();
                    }
                        return XONErrorNone;
                    case XCTimeLayoutDistantFuture: {
                        header->value.time = __XCTimeDistantFuture();
                    }
                        return XONErrorNone;
                    default: {
                        length = layout - XCTimeLayoutZero;
                    }
                        break;
                }
            }
            if (*location > capacity - length - decimalLength) {
                return XONErrorCount;
            }
            if (length > 8 || decimalLength > 8) {
                return XONErrorNotImplemented;
            }
            uint64_t svalue = __XCDecodeTrimLeadingZeroByteIntFromBuffer(bytes + *location, length);
            uint64_t avalue = __XCDecodeTrimLeadingZeroByteIntFromBuffer(bytes + *location + length, decimalLength);
            
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
            if (avalue != 0 && decimalExponent != 15 && (avalue % 10 == 0)) {
                return XONErrorTimeContent;
            }
            if (avalue >= XCAttosecondPerSecond / scale) {
                return XONErrorTimeContent;
            }
            header->value.time.second = XCSInt64ZigzagDecode(svalue);
            header->value.time.attosecond = avalue * scale;
            *location += length + decimalLength;
            return XONErrorNone;
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

XONError_e XCDecodeTime64(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count, int64_t * _Nonnull v) {
    if (count <= 0 || count > 8) {
        return XONErrorTimeContent;
    }
    if (*location > capacity - count) {
        return XONErrorNotEnough;
    }
    
    uint64_t encodedValue = __XCDecodeTrimLeadingZeroByteIntFromBuffer(bytes + *location, count);
    *v = XCSInt64ZigzagDecode(encodedValue);
    return XONErrorNone;
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

XONError_e XCEncodeFieldKeyOffset(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint32_t offset) {
    if (offset <= 0) {
        return XONErrorMessageIndexOffset;
    }
    uint8_t buffer[24] = { 0 };
    uint32_t value = offset - 1;
    ssize_t length = __XCEncodeUInt31VarintToBuffer(buffer, value);
    if (*location > capacity - length) {
        return XONErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, length);
    *location += length;
    return XONErrorNone;
}

XONError_e XCencodeNull(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location) {
    if (*location + 1 > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNil, 0);
    bytes[*location] = header;
    *location += 1;
    return XONErrorNone;
}

XONError_e XCEncodeBool(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, _Bool value) {
    if (*location + 1 > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNil, value ? 1 : 2);
    bytes[*location] = header;
    *location += 1;
    return XONErrorNone;
}

static inline XONError_e __XCEncodeNumberByte(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCNumberNormalContent_s value) {
    uint8_t buffer[24] = { 0 };
    ssize_t length = 1;
    length += __XCEncodeUInt64VarintToBuffer(buffer + length, XCSInt64ZigzagEncode(value.exponent));
    length += __XCEncodeSignAndSignificandToBuffer(buffer + length, value.signAndSignificand);
    
    if (*location > capacity - length) {
        return XONErrorNotEnough;
    }
    uint8_t layout = length + XCNumberFormatZero - 1;
    if (layout >= 16) {
        return XONErrorLayout;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNumber, layout);
    buffer[0] = header;
    
    memcpy(bytes + *location, buffer, length);
    *location += length;
    return XONErrorNone;
}

static inline XONError_e __XCEncodeNumberHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint8_t layout) {
    if (*location + 1 > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeNumber, layout);
    bytes[*location] = header;
    *location += 1;
    return XONErrorNone;
}
XONError_e XCEncodeNumberUInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    if (0 == value) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberFormatZero);
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberUInt64(value);
        return __XCEncodeNumberByte(bytes, capacity, location, data);
    }
}
XONError_e XCEncodeNumberSInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value) {
    if (0 == value) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberFormatZero);
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberSInt64(value);
        return __XCEncodeNumberByte(bytes, capacity, location, data);
    }
}
XONError_e XCEncodeNumberDouble(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, double value) {
    if (value == __XCDoubleZero()) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberFormatZero);
    } else if (isnan(value)) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberFormatNan);
    } else if (isinf(value)) {
        if (value < 0) {
            return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberFormatNegativeInfinity);
        } else {
            return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberFormatPositiveInfinity);
        }
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberFloat64(value);
        return __XCEncodeNumberByte(bytes, capacity, location, data);
    }
}

XONError_e XCEncodeTimeInvalid(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location) {
    if (*location + 1 > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XCTimeLayoutInvalid);
    bytes[*location] = header;
    *location += 1;
    return XONErrorNone;
}
XONError_e XCEncodeTimeDistantPast(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location) {
    if (*location + 1 > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XCTimeLayoutDistantPast);
    bytes[*location] = header;
    *location += 1;
    return XONErrorNone;
}
XONError_e XCEncodeTimeDistantFuture(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location) {
    if (*location + 1 > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XCTimeLayoutDistantFuture);
    bytes[*location] = header;
    *location += 1;
    return XONErrorNone;
}
XONError_e __XCEncodeTimeZero(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location) {
    if (*location + 1 > capacity) {
        return XONErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XONTypeTime, XCTimeLayoutZero);
    bytes[*location] = header;
    *location += 1;
    return XONErrorNone;
}

XONError_e XCEncodeTime(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t second, uint64_t attosecond) {
    uint8_t buffer[24] = { 0 };
    if (attosecond >= XCAttosecondPerSecond) {
        if (attosecond == UINT64_MAX && (second == INT64_MAX || second == INT64_MIN)) {
            if (second == INT64_MIN) {
                return XCEncodeTimeDistantPast(bytes, capacity, location);
            } else if (second == INT64_MAX) {
                return XCEncodeTimeDistantFuture(bytes, capacity, location);
            } else {
                return XCEncodeTimeInvalid(bytes, capacity, location);
            }
        } else {
            return XCEncodeTimeInvalid(bytes, capacity, location);
        }
    } else {
        if (0 == attosecond) {
            uint8_t header = 0;
            uint64_t encodedBytes = XCSInt64ZigzagEncode(second);
            ssize_t slength = __XCEncodeTrimLeadingZeroByteIntToBuffer(buffer + 1, encodedBytes);
            if (*location > capacity - slength - 1) {
                return XONErrorNotEnough;
            }
            XCEncodeTypeLayout(&header, XONTypeTime, XCTimeLayoutZero + slength);
            buffer[0] = header;
            ssize_t length = 1 + slength;
            memcpy(bytes + *location, buffer, length);
            *location += length;
            return XONErrorNone;
        } else {
            uint8_t header = 0;
            uint64_t encodedBytes = XCSInt64ZigzagEncode(second);
            ssize_t slength = __XCEncodeTrimLeadingZeroByteIntToBuffer(buffer + 2, encodedBytes);
            XCEncodeTypeLayout(&header, XONTypeTime, 0x10 + slength);
            buffer[0] = header;
            
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

            ssize_t alength = __XCEncodeTrimLeadingZeroByteIntToBuffer(buffer + 2 + slength, avalue);
            // 4
            ssize_t length = 2 + slength + alength;
            if (*location > capacity - length) {
                return XONErrorNotEnough;
            }
            buffer[1] = (alength << 4) | e;
            memcpy(bytes + *location, buffer, length);
            *location += length;
            return XONErrorNone;
        }
    }
}

XONError_e XCEncodeMessageHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    if (count < 0) {
        return XONErrorCount;
    }
    uint8_t buffer[24] = { 0 };
    ssize_t length = 1;
    if (count >= 31) {
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, XONTypeMessage, 31);
        buffer[0] = header;
        uint64_t varint = count - 31;
        length += __XCEncodeUInt63VarintToBuffer(buffer + length, varint);
    } else {
        uint8_t layout = (uint8_t)count;
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, XONTypeMessage, layout);
        buffer[0] = header;
    }
    
    if (*location > capacity - length) {
        return XONErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, length);
    *location += length;
    return XONErrorNone;
}

XONError_e XCEncodeArrayHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XONTypeArray, count);
}

XONError_e XCEncodeDataHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XONTypeData, count);
}

XONError_e XCEncodeStringHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XONTypeString, count);
}

XONError_e XCEncodeBody(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, const void * _Nonnull data, ssize_t count) {
    if (count < 0) {
        return XONErrorCount;
    }
    if (*location + count > capacity) {
        return XONErrorNotEnough;
    }
    memcpy(bytes + *location, data, count);
    *location += count;
    return XONErrorNone;
}

