## ICU for iOS and Mac OS X (Intel & Apple Silicon M1) & Catalyst - arm64 / x86_64

Supported version: 71.1

This repo provides a universal script for building static ICU libraries for use in iOS and Mac OS X applications. The repo contains "icu" submodule that is taken from https://github.com/unicode-org/icu . The repo branches correspond to the suitable branches of ICU repo. E.g. "71" branch corresponds to "maint/maint-71" branch.

## Prerequisites
  1) Xcode must be installed because xcodebuild is used to create xcframeworks
  2) ```xcode-select -p``` must point to Xcode app developer directory (by default e.g. /Applications/Xcode.app/Contents/Developer). If it points to CommandLineTools directory you should execute:
  ```sudo xcode-select --reset``` or ```sudo xcode-select -s /Applications/Xcode.app/Contents/Developer```
  
## How to build?
 - Manually
```
    # clone the repo
    git clone -b 71.1.2 --recursive https://github.com/apotocki/icu4c-iosx
    
    # build libraries
    cd icu4c-iosx
    scripts/build.sh

    # have fun, the result artifacts  will be located in 'product' folder.
```    
 - Use cocoapods. Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'icu4c-iosx', '~> 71.1'
    # or optionally more precisely
    # pod 'icu4c-iosx', :git => 'https://github.com/apotocki/icu4c-iosx', :tag => '~> 71.1', :submodules => 'true'
```    
install new dependency:
```
   pod install --verbose
```

## As an advertisement…
ICU library built by this project were used in my iOS application on App Store:

[<table align="center" border=0 cellspacing=0 cellpadding=0><tr><td><img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70"/></td><td><a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br>HEX File Viewer & Editor</td><tr></table>]()

This app is designed for viewing and editing files at byte or character level.
  
You can support my open-source development by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

Feedbacks are also welcome!
