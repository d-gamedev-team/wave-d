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
    Sound sound = decodeWAV("my_wav_file.wav");
    writefln("channels = %s", sf.numChannels);
    writefln("samplerate = %s", sf.sampleRate);
    writefln("samples = %s", sf.data.length);

    sound.encodeWAV("copy.wav");
}

```
