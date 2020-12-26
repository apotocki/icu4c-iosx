## ICU for iOS and Mac OS X - arm64 / x86_64

Supported version: 68

This repo provides a universal script for building static ICU libraries for use in iOS and Mac OS X applications. The repo contains "icu" submodule that is taken from https://github.com/unicode-org/icu . The repo branches correspond to the suitable branches of ICU repo. E.g. "68" branch corresponds to "maint/maint-68" branch.

## How to build?
 - Manually
```
    # clone the repo
    git clone -b 68 --recurse-submodules --remote-submodules https://github.com/apotocki/icu4c-iosx
    
    # build libraries
    cd icu4c-iosx
    scripts/build.sh

    # have fun, the result artifacts  will be located in 'product' folder.
```    
 - Use cocoapods. Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'icu4c-iosx'
    # or optionally more precisely
    # pod 'icu4c-iosx', :git => 'https://github.com/apotocki/icu4c-iosx', :branch => '68', :submodules => 'true'
```    
install new dependency:
```
   pod install --verbose
```    
 ## Troubleshooting.
  In case of error "ARCHS[@]: unbound variable" during the building of your XCode project:
  1) Open: Pods -> Build Settings.
  2) Select target 'icu4c-iosx'
  3) Find VALID_ARCHS variable and set appropriate value. E.g. "arm64 X86_64"
