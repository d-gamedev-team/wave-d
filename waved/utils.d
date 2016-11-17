module waved.utils;

import std.file,
       std.range,
       std.traits,
       std.string,
       std.format;


/// The simple structure currently used in wave-d. Expect changes about this.
struct Sound
{
    int sampleRate;  /// Sample rate.

    deprecated("Use channels instead") alias numChannels = channels;
    int channels; /// Number of interleaved channels in data.

    deprecated("Use samples instead") alias data = samples;
    float[] samples;    /// data layout: machine endianness, interleaved channels. Contains numChannels * lengthInFrames() samples.

    /// Build with interleaved data.
    this(int sampleRate, int channels, float[] samples)
    {
        this.sampleRate = sampleRate;
        this.channels = channels;
        this.samples = samples;
    }

    /// Build with channel data. Interleave them.
    /// channels must have the same length.
    this(int sampleRate, float[][] planarSamples)
    {
        assert(planarSamples.length > 0);
        int N = cast(int)planarSamples[0].length;
        this.sampleRate = sampleRate;
        this.channels = cast(int)(planarSamples.length);        
        this.samples = new float[N * channels];
        foreach (chan; 0..channels)
        {
            assert(planarSamples[chan].length == N);
            foreach (frame; 0..N)
            {
                sample(chan, frame) = planarSamples[chan][frame];
            }
        }
    }

    /// Returns: Length in number of frames.
    int lengthInFrames() pure const nothrow
    {
        return cast(int)(samples.length) / channels;
    }

    /// Returns: Length in seconds.
    double lengthInSeconds() pure const nothrow
    {
        return lengthInFrames() / cast(double)sampleRate;
    }

    /// Direct sample access.
    ref inout(float) sample(int chan, int frame) pure inout nothrow @nogc
    {
        assert(cast(uint)chan < channels);
        return samples[frame * channels + chan];
    }

    /// Allocates a new array and put deinterleaved channel samples inside.
    float[] channel(int chan) pure const nothrow
    {
        int N = lengthInFrames();
        float[] c = new float[N];
        foreach(frame; 0..N)
            c[frame] = this.sample(chan, frame);
        return c;
    }

    /// Returns: Another Sound with one channel (left).
    Sound makeMono() pure const nothrow
    {
        assert(channels > 0);
        Sound output;
        output.sampleRate = this.sampleRate;
        output.samples = new float[this.lengthInFrames()];
        output.channels = 1;
        for (int i = 0; i < this.lengthInFrames(); ++i)
        {
            output.sample(0, i) = this.sample(0, i); // take left only
        }
        return output;
    }
}

/// The one type of Exception thrown in this library
final class WavedException : Exception
{
    @safe pure nothrow this(string message, string file =__FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(message, file, line, next);
    }
}

package:

template IntegerLargerThan(int numBytes) if (numBytes >= 1 && numBytes <= 8)
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
    {
        // make sure the sign bit is extended to the top in case of a larger result value
        Signed!T signedResult = cast(Signed!T)result;
        enum bits = 8 * (T.sizeof - NumBytes);
        static if (bits > 0)
        {
            signedResult = signedResult << bits;
            signedResult = signedResult >> bits; // signed right shift, replicates sign bit
        }
        return signedResult;
    }
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
            ubyte b = (u >> ( (NumBytes - 1 - i) * 8) ) & 255;
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
void writeBE(T, R)(ref R output, T n) if (isOutputRange!(R, ubyte))
{
    writeInteger!(R, T.sizeof, false)(output, n);
}

// Writes a little endian integer to output.
void writeLE(T, R)(ref R output, T n) if (isOutputRange!(R, ubyte))
{
    writeInteger!(R, T.sizeof, true)(output, n);
}


alias pop24bitsLE(R) = popInteger!(R, 3, true, true);


// read/write 32-bits float

union float_uint
{
    float f;
    uint i;
}

float popFloatLE(R)(ref R input) if (isInputRange!R)
{
    float_uint fi;
    fi.i = popLE!uint(input);
    return fi.f;
}

void writeFloatLE(R)(ref R output, float x) if (isOutputRange!(R, ubyte))
{
    float_uint fi;
    fi.f = x;
    writeLE!uint(output, fi.i);
}


// read/write 64-bits float

union double_ulong
{
    double d;
    ulong i;
}

float popDoubleLE(R)(ref R input) if (isInputRange!R)
{
    double_ulong du;
    du.i = popLE!ulong(input);
    return du.d;
}

void writeDoubleLE(R)(ref R output, double x) if (isOutputRange!(R, ubyte))
{
    double_ulong du;
    du.d = x;
    writeLE!ulong(output, du.i);
}

// Reads RIFF chunk header.
void getRIFFChunkHeader(R)(ref R input, out uint chunkId, out uint chunkSize) if (isInputRange!R)
{
    chunkId = popBE!uint(input);
    chunkSize = popLE!uint(input);
}

// Writes RIFF chunk header (you have to count size manually for now...).
void writeRIFFChunkHeader(R)(ref R output, uint chunkId, size_t chunkSize) if (isOutputRange!(R, ubyte))
{
    writeBE!uint(output, cast(uint)(chunkId));
    writeLE!uint(output, cast(uint)(chunkSize));
}

template RIFFChunkId(string id)
{
    static assert(id.length == 4);
    uint RIFFChunkId = (cast(ubyte)(id[0]) << 24) 
                     | (cast(ubyte)(id[1]) << 16)
                     | (cast(ubyte)(id[2]) << 8)
                     | (cast(ubyte)(id[3]));
}
