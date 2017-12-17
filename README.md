# Remote Band

### Description
This is a GarageBand wrapper that maps the transport buttons of MIDI device to the respective GarageBand functions.

### Settings
In the ``RemoteBandViewController.m`` modify the ``NSDictionary`` object called ``mapMIDI`` and insert your hash command obtained by
```objc
NSLog(@"Command Hash: %@", command.data.description);
```
The ``mapMIDI`` object is:
```objc
    NSDictionary *mapMIDI = @{
        @"<b00f0e45>": @(kVK_ANSI_R), //record
        @"<b00f0e44>": @(kVK_Space), //play
        @"<b00f0e43>": @(kVK_Return), //stop
        @"<b00f0d43>": @(kVK_RightArrow),
        @"<b00f0d41>": @(kVK_LeftArrow),
        @"<b00f0d44>": @(kVK_UpArrow),
        @"<b00f0d40>": @(kVK_DownArrow),
        @"<b00f0d42>": @(kVK_DownArrow),
    };
```
For each GarageBand hotkey, the relative hash command (the button pressed on the MIDI device) is mapped.

### Build
For the build process follow this steps:

* Install **MIKMIDI** library (thanks [MIKMIDI] :blush: )
```sh
cd remote-band
git submodule init && git submodule update
```
* Open ``remote-band.xcodeproj``
* Press ``Build`` or ``⌘+B``
* Press ``Run`` or ``⌘+R``

An icon should appear on the status bar. Done :thumbsup:

### Use
If the MIDI device is not automatically added, click on the status bar icon to open the ``remote-band`` app and choose the correct device on the list.


### Credits
* [MIKMIDI]
* Icon made by [Freepik] from [www.flaticon.com] is licensed under [CC BY 3.0]

[Freepik]:http://www.freepik.com
[www.flaticon.com]:http://www.flaticon.com
[CC BY 3.0]:http://creativecommons.org/licenses/by/3.0/
[MIKMIDI]:https://github.com/mixedinkey-opensource/MIKMIDI