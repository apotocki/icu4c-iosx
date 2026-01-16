## ICU for iOS, watchOS, tvOS, visionOS, macOS, Mac Catalyst, and Simulators - Intel(x86_64) / Apple Silicon(arm64)

This repository provides a universal build script for creating **static ICU libraries** for iOS, watchOS, tvOS, visionOS, macOS, and Mac Catalyst.

The ICU source code is taken from the official Unicode ICU repository:
https://github.com/unicode-org/icu

Repository branches generally correspond to ICU maintenance branches. For example, the `78` branch corresponds to the `maint/maint-78` branch in the ICU repository.

### Supported ICU Versions

- [78.2](https://github.com/apotocki/icu4c-iosx/tree/78.2.0)
- [78.1](https://github.com/apotocki/icu4c-iosx/tree/78.1.2)
- [77.1](https://github.com/apotocki/icu4c-iosx/tree/77.1.1)
- [76.1](https://github.com/apotocki/icu4c-iosx/tree/76.1.5)
- [75.1](https://github.com/apotocki/icu4c-iosx/tree/75.1.4)
- [74.2](https://github.com/apotocki/icu4c-iosx/tree/74.2.9)
- [74.1](https://github.com/apotocki/icu4c-iosx/tree/74.1.0)
- [73.2](https://github.com/apotocki/icu4c-iosx/tree/73.2.1)
- [73.1](https://github.com/apotocki/icu4c-iosx/tree/73.1.0)
- [72.1](https://github.com/apotocki/icu4c-iosx/tree/72.1.1)
- [71.1](https://github.com/apotocki/icu4c-iosx/tree/71.1.5)
- [70.1](https://github.com/apotocki/icu4c-iosx/tree/70.1.1)
- [69.1](https://github.com/apotocki/icu4c-iosx/tree/69.1.2)
- [68.2](https://github.com/apotocki/icu4c-iosx/tree/68.2.1)
- [62.2](https://github.com/apotocki/icu4c-iosx/tree/62.2.1)

---

## Prerequisites

1. **Xcode** must be installed, as `xcodebuild` is used to create XCFrameworks.
2. `xcode-select -p` must point to the Xcode developer directory (for example, `/Applications/Xcode.app/Contents/Developer`).

    If it points to the CommandLineTools directory, run one of the following commands:
    ```bash
    sudo xcode-select --reset
    # or
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    ```
  
---

## Build Manually

```bash
# Clone the repository
git clone https://github.com/apotocki/icu4c-iosx
    
# Build libraries
cd icu4c-iosx
scripts/build.sh
```

The resulting artifacts will be located in the `product` directory.

---

## Selecting Platforms and Architectures

Running `build.sh` without arguments builds XCFrameworks for **iOS** and **macOS**, and also for **watchOS**, **tvOS**, and **visionOS** if their SDKs are installed. Simulator XCFrameworks are built for the current host architecture (`arm64` or `x86_64`).

To build a specific set of platforms or architectures, use the `-p` option:

```bash
scripts/build.sh -p=ios,iossim-x86_64
# Builds XCFrameworks only for iOS and the iOS Simulator (x86_64)
```

### Available `-p` Values

```text
macosx,macosx-arm64,macosx-x86_64,macosx-both,
ios,iossim,iossim-arm64,iossim-x86_64,iossim-both,
catalyst,catalyst-arm64,catalyst-x86_64,catalyst-both,
xros,xrossim,xrossim-arm64,xrossim-x86_64,xrossim-both,
tvos,tvossim,tvossim-arm64,tvossim-x86_64,tvossim-both,
watchos,watchossim,watchossim-arm64,watchossim-x86_64,watchossim-both
```

- The `-both` suffix builds XCFrameworks for both `arm64` and `x86_64`.
- Platform names without an architecture suffix (for example, `macosx`, `iossim`) build only for the current host architecture.

---

## ICU Data Archive

The `build.sh` script builds the following XCFrameworks:

- `icudata`
- `icui18n`
- `icuio`
- `icuuc`

By default, `icudata` is built with `--with-data-packaging=static` (see the ICU data documentation). All ICU metadata (locales, tables, rules, etc.) is embedded directly into the `icudata` library, making it relatively large (~32 MB).

Because an XCFramework may include multiple platforms and architectures, this metadata is duplicated several times, increasing the overall size. ICU allows this data to be moved into a separate, platform-independent archive that is loaded at runtime.

To enable this option, use `-d=archive`:

```bash
scripts/build.sh -p=ios,iossim-x86_64 -d=archive
# Builds XCFrameworks for iOS and the iOS Simulator (x86_64)
# Data file path: product/share/icu/78.2/icudt78l.dat
```

During ICU initialization, you must specify the ICU data directory **before** calling `u_init()`:

```c
#include <unicode/putil.h>

u_setDataDirectory("PATH_TO_DIRECTORY_CONTAINING_icudt78l.dat");

u_init(code);
```

---

## ICU Data Filtering

ICU metadata includes a large collection of locales, tables, and rules. In most applications, only a subset of this data is required.

You can reduce the size of `icudata` by applying a data filter using the `-f` option:

```bash
scripts/build.sh -p=ios,iossim-x86_64 -f=path_to_filter.json
# Builds XCFrameworks for iOS and the iOS Simulator (x86_64)
```

The filter format is described in the official ICU documentation:
https://unicode-org.github.io/icu/userguide/icu_data/buildtool.html

---

## Rebuild Option

To rebuild the libraries without using artifacts from previous builds, use the `--rebuild` option:

```bash
scripts/build.sh -p=ios,iossim-x86_64 --rebuild
```

---

## Build Using CocoaPods

Add the following to your `Podfile`:

```ruby
use_frameworks!
pod 'icu4c-iosx'
    
# Or explicitly reference the repository
# pod 'icu4c-iosx', :git => 'https://github.com/apotocki/icu4c-iosx'
```

Install the dependency:

```bash
   pod install --verbose
```

---

## Used in Production

The ICU libraries built by this project are used in my iOS application available on the App Store:

[<table align="center" border=0 cellspacing=0 cellpadding=0><tr><td><img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70"/></td><td><a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br>HEX File Viewer & Editor</td><tr></table>]()

PotoHEX is designed for viewing and editing files at the byte or character level, calculating hashes, encoding/decoding data, and compressing/decompressing selected byte ranges.

If you find this project useful, you can support my open-source work by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

---

Feedback is welcome!
