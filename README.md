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
    git clone -b 71.1.1 --recursive https://github.com/apotocki/icu4c-iosx
    
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
