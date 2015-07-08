# remote-band

### Description
This is a GarageBand wrapper that maps the transport buttons of MIDI device to the respective GarageBand functions.

### Settings
In the ``RemoteBandViewController.m`` modify the ``NSDictionary`` object called ``mapMIDI`` and insert your hash command obtained by
```sh
NSLog(@"Command Hash: %@", command.data.description);
```
The ``mapMIDI`` object is:
```sh
 NSDictionary *mapMIDI = @{
        @"Record"   : @"<b00f0e45>",
        @"Play"     : @"<b00f0e44>",
        @"Stop"     : @"<b00f0e43>",
        @"Right"    : @"<b00f0d43>",
        @"Left"     : @"<b00f0d41>",
        @"Up"       : @"<b00f0d44>",
        @"Down"     : @"<b00f0d40>",
        @"Center"   : @"<b00f0d42>"
    };
```
For each GarageBand actions, the relative hash command (the button pressed on the MIDI device) is mapped.

### Build
For the build process follow this steps:

* Install **MIKMIDI** library (thanks [MIKMIDI] :blush: )
```sh
cd remote-band
git submodule add https://github.com/mixedinkey-opensource/MIKMIDI.git Frameworks/MIKMIDI
```
* Open ``remote-band.xcodeproj``
* Press ``Build`` or ``⌘+B``
* Press ``Run`` or ``⌘+R``

An icon (like this: ![alt tag](http://edoardospadoni.it/remote-band/controlIcon.png)) should appear on the status bar. Done :thumbsup:

### Use
If the MIDI device is not automatically added, click on the status bar icon to open the ``remote-band`` app and choose the correct device on the list.


### Credits
* [MIKMIDI]
* Icon made by [Freepik] from [www.flaticon.com] is licensed under [CC BY 3.0]

[Freepik]:http://www.freepik.com
[www.flaticon.com]:http://www.flaticon.com
[CC BY 3.0]:http://creativecommons.org/licenses/by/3.0/
[MIKMIDI]:https://github.com/mixedinkey-opensource/MIKMIDI