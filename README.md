## What's this?

wave-d is a tiny library to load WAV audio files.


## Licenses

See UNLICENSE.txt


## Licenses

See UNLICENSE.txt


```d

import std.stdio;
import waved;

void main()
{
    SoundFile sf = decodeWAVE("my_wav_file.wav");
    writefln("channels = %s", sf.numChannels);
    writefln("samplerate = %s", sf.sampleRate);
    writefln("samples = %s", sf.data.length);
}

```
