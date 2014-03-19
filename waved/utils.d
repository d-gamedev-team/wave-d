module waved.utils;

import std.file,
       std.range,
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


package
{
    ubyte popByte(R)(ref R input) if (isInputRange!R)
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
            popByte(input);
    }

    uint popUintBE(R)(ref R input) if (isInputRange!R)
    {
        ubyte b0 = popByte(input);
        ubyte b1 = popByte(input);
        ubyte b2 = popByte(input);
        ubyte b3 = popByte(input);
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
    }

    uint popUintLE(R)(ref R input) if (isInputRange!R)
    {
        ubyte b0 = popByte(input);
        ubyte b1 = popByte(input);
        ubyte b2 = popByte(input);
        ubyte b3 = popByte(input);
        return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
    }

    int popIntLE(R)(ref R input) if (isInputRange!R)
    {
        return cast(int)(popUintLE(input));
    }

    uint pop24bitsLE(R)(ref R input) if (isInputRange!R)
    {
        ubyte b0 = popByte(input);
        ubyte b1 = popByte(input);
        ubyte b2 = popByte(input);
        return (b2 << 16) | (b1 << 8) | b0;
    }

    ushort popUshortLE(R)(ref R input) if (isInputRange!R)
    {
        ubyte b0 = popByte(input);
        ubyte b1 = popByte(input);
        return (b1 << 8) | b0;
    }

    short popShortLE(R)(ref R input) if (isInputRange!R)
    {
        return cast(short)popUshortLE(input);
    }

    ulong popUlongLE(R)(ref R input) if (isInputRange!R)
    {
        ulong b0 = popByte(input);
        ulong b1 = popByte(input);
        ulong b2 = popByte(input);
        ulong b3 = popByte(input);
        ulong b4 = popByte(input);
        ulong b5 = popByte(input);
        ulong b6 = popByte(input);
        ulong b7 = popByte(input);
        return (b7 << 56) | (b6 << 48) | (b5 << 40) | (b4 << 32) | (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
    }

    float popFloatLE(R)(ref R input) if (isInputRange!R)
    {
        union float_uint
        {
            float f;
            uint i;
        }
        float_uint fi;
        fi.i = popUintLE(input);
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
        du.i = popUlongLE(input);
        return du.d;
    }

    // read RIFF chunk header
    void getChunkHeader(R)(ref R input, out uint chunkId, out uint chunkSize) if (isInputRange!R)
    {
        chunkId = popUintBE(input);
        chunkSize = popUintLE(input);
    }

    template RIFFChunkId(string id)
    {
        static assert(id.length == 4);
        uint RIFFChunkId = (cast(ubyte)(id[0]) << 24) 
            | (cast(ubyte)(id[1]) << 16)
            | (cast(ubyte)(id[2]) << 8)
            | (cast(ubyte)(id[3]));
    }
}
