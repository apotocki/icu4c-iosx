#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
ICU_VER=maint/maint-75
#MACOSX_VERSION_ARM=12.3
#MACOSX_VERSION_X86_64=10.13
IOS_VERSION=13.4
IOS_SIM_VERSION=13.4
CATALYST_VERSION=13.4
################## SETUP END
IOSSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
IOSSIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
XROSSYSROOT=$XCODE_ROOT/Platforms/XROS.platform/Developer
XROSSIMSYSROOT=$XCODE_ROOT/Platforms/XRSimulator.platform/Developer

ICU_VER_NAME=icu4c-${ICU_VER//\//-}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
INSTALL_DIR="$BUILD_DIR/product"
ICU4C_FOLDER=icu/icu4c

if [ "$HOST_ARC" = "arm64" ]; then
	BUILD_ARC=arm
    FOREIGN_ARC=x86_64
    FOREIGN_BUILD_ARC=x86_64
    FOREIGN_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_X86_64}" ] && FOREIGN_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_X86_64"
    NATIVE_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_ARM}" ] && NATIVE_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_ARM"
else
	BUILD_ARC=$HOST_ARC
    FOREIGN_ARC=arm64
    FOREIGN_BUILD_ARC=arm
    FOREIGN_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_ARM}" ] && FOREIGN_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_ARM"
    NATIVE_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_X86_64}" ] && NATIVE_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_X86_64"
fi

if [ -z "${WITH_DATA_PACKAGING}" ]; then
    WITH_DATA_PACKAGING="static" # archive
fi
echo "USING WITH_DATA_PACKAGING: $WITH_DATA_PACKAGING"

if [ ! -d icu ]; then
	echo downloading icu ...
	git clone --depth 1 -b $ICU_VER https://github.com/unicode-org/icu icu
fi

#explicit 75.1
pushd icu
git fetch --depth=1 origin 7750081bda4b3bc1768ae03849ec70f67ea10625
git reset --hard 7750081bda4b3bc1768ae03849ec70f67ea10625
popd

COMMON_CONFIGURE_ARGS="--enable-static --disable-shared prefix=$INSTALL_DIR --with-data-packaging=$WITH_DATA_PACKAGING"

# (type, arc, build-arc, cflags, ldflags)
generic_build()
{
    if [ ! -f $ICU_VER_NAME-$1-$2-build.success ]; then
        echo preparing build folder $ICU_VER_NAME-$1-$2-build ...
        if [ -d $ICU_VER_NAME-$1-$2-build ]; then
            rm -rf $ICU_VER_NAME-$1-$2-build
        fi
        cp -r $ICU4C_FOLDER $ICU_VER_NAME-$1-$2-build
        echo "building icu ($1 $2)..."
        pushd $ICU_VER_NAME-$1-$2-build/source

        COMMON_CFLAGS="-arch $2 $4"

        ./configure $COMMON_CONFIGURE_ARGS --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --host=$BUILD_ARC-apple-darwin --build=$3-apple --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ $5 -Wl,-dead_strip -lstdc++"

        make -j$THREAD_COUNT
        if [ ! $WITH_DATA_PACKAGING = "static" ]; then
            cp stubdata/libicudata.a lib/
        fi
        popd
        touch $ICU_VER_NAME-$1-$2-build.success
    fi
}

# (type, coomon_cflags, arm-cflags, x86_64-cflags, ldflags)
generic_double_build()
{
    if [ ! -f $ICU_VER_NAME-$1-build.success ]; then
        echo preparing build folder $ICU_VER_NAME-$1-build ...
        if [ -d $ICU_VER_NAME-$1-build ]; then
            rm -rf $ICU_VER_NAME-$1-build
        fi
        mkdir -p $ICU_VER_NAME-$1-build/source/lib

        generic_build $1 arm64 arm "$2 $3" "$5"
        generic_build $1 x86_64 x86_64 "$2 $4" "$5"

        lipo -create $ICU_VER_NAME-$1-arm64-build/source/lib/libicudata.a $ICU_VER_NAME-$1-x86_64-build/source/lib/libicudata.a -output $ICU_VER_NAME-$1-build/source/lib/libicudata.a
        lipo -create $ICU_VER_NAME-$1-arm64-build/source/lib/libicui18n.a $ICU_VER_NAME-$1-x86_64-build/source/lib/libicui18n.a -output $ICU_VER_NAME-$1-build/source/lib/libicui18n.a
        lipo -create $ICU_VER_NAME-$1-arm64-build/source/lib/libicuio.a $ICU_VER_NAME-$1-x86_64-build/source/lib/libicuio.a -output $ICU_VER_NAME-$1-build/source/lib/libicuio.a
        lipo -create $ICU_VER_NAME-$1-arm64-build/source/lib/libicuuc.a $ICU_VER_NAME-$1-x86_64-build/source/lib/libicuuc.a -output $ICU_VER_NAME-$1-build/source/lib/libicuuc.a
    
        touch $ICU_VER_NAME-$1-build.success
    fi
}

build_catalyst_libs()
{
    generic_double_build catalyst "-isysroot $MACSYSROOT --target=apple-ios$CATALYST_VERSION-macabi"
    # "--target=arm-apple-ios13.4-macabi" "--target=x86_64-apple-ios13.4-macabi" "-L$MACSYSROOT/System/iOSSupport/usr/lib/"
}

build_iossim_libs()
{
    CFLAGS="-isysroot $IOSSIMSYSROOT/SDKs/iPhoneSimulator.sdk -mios-simulator-version-min=$IOS_SIM_VERSION "
    generic_double_build ios.sim "$CFLAGS"
}

build_xrossim_libs()
{
    CFLAGS="-isysroot $XROSSIMSYSROOT/SDKs/XRSimulator.sdk "
    generic_double_build xros.sim "$CFLAGS"
}

################### BUILD FOR MAC OSX
ICU_BUILD_FOLDER=$ICU_VER_NAME-build
if [ ! -f $ICU_BUILD_FOLDER.success ]; then
    echo preparing build folder $ICU_BUILD_FOLDER ...
    if [ -d $ICU_BUILD_FOLDER ]; then
        rm -rf $ICU_BUILD_FOLDER
    fi
    cp -r $ICU4C_FOLDER $ICU_BUILD_FOLDER

    echo "building icu (mac osx)..."
    pushd $ICU_BUILD_FOLDER/source

    if [ ! -d $INSTALL_DIR ]; then
        mkdir -p $INSTALL_DIR
    fi

    CFLAGS="$NATIVE_BUILD_FLAGS" CXXFLAGS="--std=c++17 $NATIVE_BUILD_FLAGS" ./runConfigureICU MacOSX $COMMON_CONFIGURE_ARGS

    make -j$THREAD_COUNT
    make install
    if [ ! $WITH_DATA_PACKAGING = "static" ]; then
        cp stubdata/libicudata.a $INSTALL_DIR/lib/
    fi
    popd
    touch $ICU_BUILD_FOLDER.success
fi

generic_build macos $FOREIGN_ARC $FOREIGN_BUILD_ARC $FOREIGN_BUILD_FLAGS
if [ -d $ICU_VER_NAME-macos-build ]; then
    rm -rf $ICU_VER_NAME-macos-build
fi
mkdir -p $ICU_VER_NAME-macos-build/source/lib

lipo -create $INSTALL_DIR/lib/libicudata.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicudata.a -output $ICU_VER_NAME-macos-build/source/lib/libicudata.a
lipo -create $INSTALL_DIR/lib/libicui18n.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicui18n.a -output $ICU_VER_NAME-macos-build/source/lib/libicui18n.a
lipo -create $INSTALL_DIR/lib/libicuio.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicuio.a -output $ICU_VER_NAME-macos-build/source/lib/libicuio.a
lipo -create $INSTALL_DIR/lib/libicuuc.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicuuc.a -output $ICU_VER_NAME-macos-build/source/lib/libicuuc.a

build_catalyst_libs
build_iossim_libs

if [ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]; then
build_xrossim_libs
fi

generic_build ios arm64 arm "-fembed-bitcode -isysroot $IOSSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=$IOS_VERSION"

if [ -d $XROSSYSROOT ]; then
generic_build xros arm64 arm "-fembed-bitcode -isysroot $XROSSYSROOT/SDKs/XROS.sdk"
fi

if [ -d $INSTALL_DIR/frameworks ]; then
    rm -rf $INSTALL_DIR/frameworks
fi
mkdir $INSTALL_DIR/frameworks

create_xcframework()
{
    LIBARGS="-library $ICU_VER_NAME-macos-build/source/lib/lib$1.a \
        -library $ICU_VER_NAME-catalyst-build/source/lib/lib$1.a \
        -library $ICU_VER_NAME-ios.sim-build/source/lib/lib$1.a \
        -library $ICU_VER_NAME-ios-arm64-build/source/lib/lib$1.a"
        
    if [ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]; then
        LIBARGS="$LIBARGS -library $ICU_VER_NAME-xros.sim-build/source/lib/lib$1.a"
    fi
    if [ -d $XROSSYSROOT/SDKs/XROS.sdk ]; then
        LIBARGS="$LIBARGS -library $ICU_VER_NAME-xros-arm64-build/source/lib/lib$1.a"
    fi
    xcodebuild -create-xcframework $LIBARGS -output $INSTALL_DIR/frameworks/$1.xcframework
}

create_xcframework icudata
create_xcframework icui18n
create_xcframework icuio
create_xcframework icuuc
