module waved.detect;

import std.file,
       std.range,
       std.string,
       std.format;

import waved.utils,
       waved.wav;

/// Decodes a sound file.
/// Throws: WavedException on error.
Sound decodeSound(string filepath)
{
    auto bytes = cast(ubyte[]) std.file.read(filepath);
    return decodeSound(bytes);
}

Sound decodeSound(R)(R input) if (isForwardRange!R)
{
    R backup = input.save;

    string reasonNotBeingWAV;
    // Try each format successively.
    // to support this idea, every parser MUST be 100% validating. No "probing".
    try
    {
        return decodeWAV(input);
    }
    catch(WavedException e)
    {
        reasonNotBeingWAV = e.msg;
    }

    throw new WavedException(format("Unrecognized sound format. It isn't a WAV since it yielded '%s'.", reasonNotBeingWAV));
}


