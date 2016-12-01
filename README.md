## What's this?

wave-d is a tiny library to load/save WAV audio files.


## Licenses

See UNLICENSE.txt


## Usage


```d

import std.stdio;
import waved;

void main()
{
    // Loads a WAV file in memory
    Sound input = decodeWAV("my_wav_file.wav");
    writefln("channels = %s", input.channels);
    writefln("samplerate = %s", input.sampleRate);
    writefln("samples = %s", input.samples.length);

    // Only keep the first channel (left)
    input = input.makeMono(); 

    // Multiply the left channel by 2 in-place
    foreach(i; 0..input.lengthInFrames)
        input.sample(0, i) *= 2.0f;

    // Duplicate the left channel, saves a two channels WAV file out of it
    float[][] channels = [input.channel(0), input.channel(0)];
    Sound(input.sampleRate, channels).encodeWAV("amplified-2x.wav");
}

```
