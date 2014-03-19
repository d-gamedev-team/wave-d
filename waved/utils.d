module waved.utils;

import std.file,
       std.range,
       std.traits,
       std.string,
       std.format;


/// The simple structure currently used in wave-d. Expect changes about this.
struct Sound
{
    int sampleRate;
    int numChannels;
    float[] data; // data layout: machine endianness, interleaved channels
}

/// The one type of Exception thrown in this library
final class WavedException : Exception
{
    this(string msg)
    {
        super(msg);
    }
}


private template IntegerLargerThan(int numBytes) if (numBytes >= 1 && numBytes <= 8)
{
    static if (numBytes == 1)
        alias IntegerLargerThan = ubyte;
    else static if (numBytes == 2)
        alias IntegerLargerThan = ushort;
    else static if (numBytes <= 4)
        alias IntegerLargerThan = uint;
    else
        alias IntegerLargerThan = ulong;
}

ubyte popUbyte(R)(ref R input) if (isInputRange!R)
{
    if (input.empty)
        throw new WavedException("Expected a byte, but end-of-input found.");

    ubyte b = input.front;
    input.popFront();
    return b;
}

void skipBytes(R)(ref R input, int numBytes) if (isInputRange!R)
{
    for (int i = 0; i < numBytes; ++i)
        popUbyte(input);
}

// Generic integer parsing
auto popInteger(R, int NumBytes, bool WantSigned, bool LittleEndian)(ref R input) if (isInputRange!R)
{
    alias T = IntegerLargerThan!NumBytes;

    T result = 0;

    static if (LittleEndian)
    {
        for (int i = 0; i < NumBytes; ++i)
            result |= ( cast(T)(popUbyte(input)) << (8 * i) );
    }
    else
    {
        for (int i = 0; i < NumBytes; ++i)
            result = (result << 8) | popUbyte(input);
    }

    static if (WantSigned)
        return cast(Signed!T)result;
    else
        return result;
}

// Generic integer writing
void writeInteger(R, int NumBytes, bool LittleEndian)(ref R output, IntegerLargerThan!NumBytes n) if (isOutputRange!(R, ubyte))
{
    alias T = IntegerLargerThan!NumBytes;

    auto u = cast(Unsigned!T)n;

    static if (LittleEndian)
    {
        for (int i = 0; i < NumBytes; ++i)
        {
            ubyte b = (u >> (i * 8)) & 255;
            output.put(b);
        }
    }
    else
    {
        for (int i = 0; i < NumBytes; ++i)
        {
            ubyte b = (u >> ( (numBytes - 1 - i) * 8) ) & 255;
            output.put(b);
        }
    }
}

// Reads a big endian integer from input.
T popBE(T, R)(ref R input) if (isInputRange!R)
{
    return popInteger!(R, T.sizeof, isSigned!T, false)(input);
}

// Reads a little endian integer from input.
T popLE(T, R)(ref R input) if (isInputRange!R)
{
    return popInteger!(R, T.sizeof, isSigned!T, true)(input);
}

// Writes a big endian integer to output.
void writeBE(int NumBytes, R)(ref R output, IntegerLargerThan!NumBytes n) if (isOutputRange!(R, ubyte))
{
    writeInteger!(R, T.sizeof, false)(output, n);
}

// Writes a little endian integer to output.
void writeLE(int NumBytes, R)(ref R output, IntegerLargerThan!NumBytes n) if (isOutputRange!(R, ubyte))
{
    popInteger!(R, T.sizeof, true)(output, n);
}


alias pop24bitsLE(R) = popInteger!(R, 3, false, true);

float popFloatLE(R)(ref R input) if (isInputRange!R)
{
    union float_uint
    {
        float f;
        uint i;
    }
    float_uint fi;
    fi.i = popLE!uint(input);
    return fi.f;
}

float popDoubleLE(R)(ref R input) if (isInputRange!R)
{
    union double_ulong
    {
        double d;
        ulong i;
    }
    double_ulong du;
    du.i = popLE!ulong(input);
    return du.d;
}

// Reads RIFF chunk header.
void getChunkHeader(R)(ref R input, out uint chunkId, out uint chunkSize) if (isInputRange!R)
{
    chunkId = popBE!uint(input);
    chunkSize = popLE!uint(input);
}

template RIFFChunkId(string id)
{
    static assert(id.length == 4);
    uint RIFFChunkId = (cast(ubyte)(id[0]) << 24) 
                     | (cast(ubyte)(id[1]) << 16)
                     | (cast(ubyte)(id[2]) << 8)
                     | (cast(ubyte)(id[3]));
}
