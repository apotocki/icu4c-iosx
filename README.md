## ICU for iOS, watchOS, tvOS, visionOS, macOS, Catalyst, Simulators - Intel(x86_64) / Apple Silicon(arm64)

Supported versions: 77.1

This repo provides a universal script for building static ICU libraries for use in iOS, watchOS, tvOS, visionOS, and macOS applications. The actual ICU library version is taken from https://github.com/unicode-org/icu . The branches of the repository generally correspond to the branches of the ICU repository. E.g. "77" branch corresponds to "maint/maint-77" branch.

# Prerequisites
  1) Xcode must be installed as xcodebuild is used to create xcframeworks
  2) ```xcode-select -p``` must point to the Xcode app developer directory (by default e.g. /Applications/Xcode.app/Contents/Developer). If it points to the CommandLineTools directory you should run:
  ```sudo xcode-select --reset``` or ```sudo xcode-select -s /Applications/Xcode.app/Contents/Developer```
  
# Build Manually
```
    # clone the repo
    git clone -b 77 https://github.com/apotocki/icu4c-iosx
    
    # build libraries
    cd icu4c-iosx
    scripts/build.sh

    # have fun, the result artifacts  will be located in 'product' folder.
```
# Selecting Platforms and Architectures
build.sh without arguments will build xcframeworks for iOS, macOS, and also for watchOS, tvOS, visionOS if their SDKs are installed on the system. It will also build xcframeworks for their simulators with the architecture (arm64 or x86_64) depending on the current host.
If you are interested in a specific set of platforms and architectures, you can specify them explicitly using the -p argument, for example:
```
scripts/build.sh -p=ios,iossim-x86_64
# builts xcframeworks only for iOS and iOS Simulator with x86_64 architecture
```
Here is a list of all possible values for '-p' option:
```
macosx,macosx-arm64,macosx-x86_64,macosx-both,ios,iossim,iossim-arm64,iossim-x86_64,iossim-both,catalyst,catalyst-arm64,catalyst-x86_64,catalyst-both,xros,xrossim,xrossim-arm64,xrossim-x86_64,xrossim-both,tvos,tvossim,tvossim-both,tvossim-arm64,tvossim-x86_64,watchos,watchossim,watchossim-both,watchossim-arm64,watchossim-x86_64
```
Suffix '-both' means that xcframeworks will be built for both arm64 and x86_64 architectures.
The platform names for macosx and simulators without an architecture suffix (e.g. macosx, iossim, tvossim) mean that xcframeworks are only built for the current host architecture.

# ICU Data Archive
The build.sh script builds the following xcframeworks: icudata, icui18n, icuio, and icuuc.
By default, 'icudata' is built with the --with-data-packaging=static option (see https://unicode-org.github.io/icu/userguide/icu_data/). So all the metadata (locales, tables, etc) is placed into icudata library making it quite large (~32MB). Since xcframework may contain libraries for multiple platforms and architectures this metadata is duplicated multiple times wasting space. Therefore, ICU allows to move the metadata to a separate platform-independent file that must be loaded during the library initialization. To activate this option you can specify -d=archive :
```
scripts/build.sh -p=ios,iossim-x86_64 -d=archive
# builts xcframeworks for iOS and iOS Simulator with x86_64 architecture
# datafile path is product/share/icu/77.1/icudt77l.dat
```
In that case, during the ICU initialization procedure you have to specify ICU data directory before u_init() call:

```
#include <unicode/putil.h>

... // somewhere in ICU initialization procedure before u_init call
u_setDataDirectory("PATH TO THE DIRECTORY WHERE icudt77l.dat is located");

u_init(code)
...
```

## ICU Data Filtering
ICU metadata is a rather large set of different locales, tables, rules and so on. It's very likely that you won't need all of them in your application. Fortunately, we can filter the data we need when building the icudata library by specifying the filter with the -f option:
```
scripts/build.sh -p=ios,iossim-x86_64 -f=path_to_filter.json
# builts xcframeworks for iOS and iOS Simulator with x86_64 architecture
```
The format of the filter is described at https://unicode-org.github.io/icu/userguide/icu_data/buildtool.html

## Rebuild option
To rebuild the library without using the results of previous builds, use the --rebuild option
```
scripts/build.sh -p=ios,iossim-x86_64 --rebuild

```

# Build Using Cocoapods.
Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'icu4c-iosx', '~> 77.1'
    
    # or optionally more precisely
    # pod 'icu4c-iosx', :git => 'https://github.com/apotocki/icu4c-iosx', :tag => '77.1.0'
```    
install new dependency:
```
   pod install --verbose
```

## As advertising...
The ICU libraries that have been built by this project are being used in my iOS application on the App Store:

[<table align="center" border=0 cellspacing=0 cellpadding=0><tr><td><img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70"/></td><td><a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br>HEX File Viewer & Editor</td><tr></table>]()

This application is designed to view and edit files at the byte or character level; calculate different hashes, encode/decode, and compress/decompress desired byte regions.
  
You can support my open-source development by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

Feedback is welcome!
