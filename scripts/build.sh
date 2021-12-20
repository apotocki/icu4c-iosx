#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
ICU_VER=maint/maint-70
################## SETUP END
DEVSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
SIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

ICU_VER_NAME=icu4c-${ICU_VER//\//-}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
INSTALL_DIR="$BUILD_DIR/product"

if [ "$HOST_ARC" = "arm64" ]; then
	BUILD_ARC=arm
else
	BUILD_ARC=$HOST_ARC
fi
################### BUILD FOR MAC OSX
ICU_BUILD_FOLDER=$ICU_VER_NAME-build
ICU4C_FOLDER=icu/icu4c

#explicit 70.1
pushd icu
git reset --hard a56dde820dc35665a66f2e9ee8ba58e75049b668
popd

if [ ! -f $ICU_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_BUILD_FOLDER ...
if [ -d $ICU_BUILD_FOLDER ]; then
    rm -rf $ICU_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_BUILD_FOLDER

echo "building icu (mac osx)..."
pushd $ICU_BUILD_FOLDER/source

./runConfigureICU MacOSX --enable-static --disable-shared prefix=$INSTALL_DIR CXXFLAGS="--std=c++17"
make -j$THREAD_COUNT
make install
popd
touch $ICU_BUILD_FOLDER.success 
fi

################### BUILD FOR MAC Catalyst
ICU_CATALYST_BUILD_FOLDER=$ICU_VER_NAME-catalyst-build
if [ ! -f $ICU_CATALYST_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_CATALYST_BUILD_FOLDER ...
if [ -d $ICU_CATALYST_BUILD_FOLDER ]; then
    rm -rf $ICU_CATALYST_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_CATALYST_BUILD_FOLDER
echo "building icu (mac osx: Catalyst)..."
pushd $ICU_CATALYST_BUILD_FOLDER/source

COMMON_CFLAGS="-arch $HOST_ARC --target=$BUILD_ARC-apple-ios13-macabi -isysroot $MACSYSROOT -I$MACSYSROOT/System/iOSSupport/usr/include/ -isystem $MACSYSROOT/System/iOSSupport/usr/include -iframework $MACSYSROOT/System/iOSSupport/System/Library/Frameworks"
./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=$BUILD_ARC-apple-darwin --build=$BUILD_ARC-apple --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$MACSYSROOT/System/iOSSupport/usr/lib/ -isysroot $MACSYSROOT -Wl,-dead_strip -lstdc++"

make -j$THREAD_COUNT
popd
touch $ICU_CATALYST_BUILD_FOLDER.success 
fi

################### BUILD FOR SIM
ICU_IOS_SIM_BUILD_FOLDER=$ICU_VER_NAME-ios.sim-build
if [ ! -f $ICU_IOS_SIM_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_IOS_SIM_BUILD_FOLDER ...
if [ -d $ICU_IOS_SIM_BUILD_FOLDER ]; then
    rm -rf $ICU_IOS_SIM_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_IOS_SIM_BUILD_FOLDER
echo "building icu (iOS: iPhoneSimulator)..."
pushd $ICU_IOS_SIM_BUILD_FOLDER/source

COMMON_CFLAGS="-isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -I$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/include/"
./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=$BUILD_ARC-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/lib/ -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -Wl,-dead_strip -lstdc++"

make -j$THREAD_COUNT
popd
touch $ICU_IOS_SIM_BUILD_FOLDER.success 
fi

################### BUILD FOR DEV
ICU_IOS_BUILD_FOLDER=$ICU_VER_NAME-ios.dev-build
if [ ! -f $ICU_IOS_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_IOS_BUILD_FOLDER ...
if [ -d $ICU_IOS_BUILD_FOLDER ]; then
    rm -rf $ICU_IOS_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_IOS_BUILD_FOLDER
echo "building icu (iOS: iPhoneOS)..."
pushd $ICU_IOS_BUILD_FOLDER/source

COMMON_CFLAGS="-arch arm64 -fembed-bitcode-marker -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -I$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/include/"
./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=arm-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/lib/ -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -Wl,-dead_strip -lstdc++"
make -j$THREAD_COUNT
popd
touch $ICU_IOS_BUILD_FOLDER.success 
fi

if [ -d $INSTALL_DIR/frameworks ]; then
    rm -rf $INSTALL_DIR/frameworks
fi
mkdir $INSTALL_DIR/frameworks

xcodebuild -create-xcframework -library $INSTALL_DIR/lib/libicudata.a -library $ICU_CATALYST_BUILD_FOLDER/source/lib/libicudata.a -library $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicudata.a -library $ICU_IOS_BUILD_FOLDER/source/lib/libicudata.a -output $INSTALL_DIR/frameworks/icudata.xcframework

xcodebuild -create-xcframework -library $INSTALL_DIR/lib/libicui18n.a -library $ICU_CATALYST_BUILD_FOLDER/source/lib/libicui18n.a -library $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicui18n.a -library $ICU_IOS_BUILD_FOLDER/source/lib/libicui18n.a -output $INSTALL_DIR/frameworks/icui18n.xcframework

xcodebuild -create-xcframework -library $INSTALL_DIR/lib/libicuio.a -library $ICU_CATALYST_BUILD_FOLDER/source/lib/libicuio.a -library $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicuio.a -library $ICU_IOS_BUILD_FOLDER/source/lib/libicuio.a -output $INSTALL_DIR/frameworks/icuio.xcframework

xcodebuild -create-xcframework -library $INSTALL_DIR/lib/libicuuc.a -library $ICU_CATALYST_BUILD_FOLDER/source/lib/libicuuc.a -library $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicuuc.a -library $ICU_IOS_BUILD_FOLDER/source/lib/libicuuc.a -output $INSTALL_DIR/frameworks/icuuc.xcframework
