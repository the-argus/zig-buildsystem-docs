# Arrays and Slices

Zig strongly types arrays and does not allow you to easily decompose them into
pointers as you would in C.

## Arrays

I highly recommend reading [the official zig documentation and examples for arrays](https://ziglang.org/documentation/master/#Arrays).
However, I will provide a summary/re-explanation here.

Generally, array types take the form of `[#]Type` where `#` is the length of the
array and `Type` is the type of the items in the array.

```zig
// array literal
const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
```
