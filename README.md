# XON
Simple data interchange format

## Types

Type(3Bit)  | Layout(5Bit) | Sublayout | Meaning | Used For | Note
------------- | ------------- | ---------- | ---------- | ---------- | ----------
0      | 0  | none | null | null
0      | true=>1, false=>2  | none |  Bool | Bool
1      | largeNumber=>0, NaN=>1, +INF=>2, -INF=>3, zero=>4, length[1, 27] => [5, 31] | none | Number | int8, uint8, int16, uint16, int32, uint32, int64, uint64, float, double | Coding consistency： Convert numbers to  IEEE 754 floating-point numbers,  INT64\_MIN < e < INT64\_MAX
2      | InvalidTime=>0x0, DistantPast(-INF)=>0x1, DistantFuture(INF)=>0x2, LengthOfTime(in seconds)=>[0x3, 0xf]   | none | Time | Integer time in seconds
2      | (layout & 0x10) == 0x10, LengthOfTime(in seconds)=>[0x10, 0x1f]  | 8Bit Fractional Part Info |  Time | Decimal time in seconds
3      | count[0, 30] => [0, 30], if (count>=31) layout=31  | layout==31, count = Varint63Decoding \+ 31 |  String | String(Utf8Encoding) | 0 <= count <= INT64\_MAX
4      | count[0, 30] => [0, 30], if (count>=31) layout=31  | layout==31, count = Varint63Decoding + 31 |  Bytes | | 0 <= count <= INT64\_MAX
5      | count[0, 30] => [0, 30], if (count>=31) layout=31  | layout==31, count = Varint63Decoding + 31 |  Message | Map\<UInt32, Value\>  | 0 <= count <= UINT32\_MAX - 1, Map traversal order is based on key from small to large
6      | count[0, 30] => [0, 30], if (count>=31) layout=31  | layout==31, count = Varint63Decoding + 31 |  Array | Array\<Value\> | 0 <= count <= INT64\_MAX

### null

bytes = [0x0];


### Bool

- true
 bytes = [0x1]

- false
 bytes = [0x2]

### Number

- Support: NaN, +INF, -INF

- Coding consistency

	encode((float)1.0) == encode((double)1.0) == encode((uint)1) == encode((int)1) == encode((uint8)1) == encode((int8)1) == encode((uint16)1) == encode((int16)1) == encode((uint32)1) == encode((int32)1) == encode((uint64)1) == encode((int64)1)
	
### Time

- The timing is accurate to attoseconds.
- invalidTime
- distantPast
- distantFuture




