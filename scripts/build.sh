#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
ICU_VER=maint/maint-72
################## SETUP END
DEVSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
SIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

ICU_VER_NAME=icu4c-${ICU_VER//\//-}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
INSTALL_DIR="$BUILD_DIR/product"
ICU4C_FOLDER=icu/icu4c

if [ "$HOST_ARC" = "arm64" ]; then
	BUILD_ARC=arm
    FOREIGN_ARC=x86_64
    FOREIGN_BUILD_ARC=x86_64
else
	BUILD_ARC=$HOST_ARC
    FOREIGN_ARC=arm64
    FOREIGN_BUILD_ARC=arm
fi


#explicit 72.1
pushd icu
git pull
git checkout $ICU_VER
#git reset --hard 131146a5f43955eee68693e1e627df13da1ae384
popd

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
        ./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=$BUILD_ARC-apple-darwin --build=$3-apple --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ $5 -Wl,-dead_strip -lstdc++"

        make -j$THREAD_COUNT
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
    generic_double_build catalyst "-isysroot $MACSYSROOT --target=apple-ios13.4-macabi"
    # "--target=arm-apple-ios13.4-macabi" "--target=x86_64-apple-ios13.4-macabi" "-L$MACSYSROOT/System/iOSSupport/usr/lib/"
}

build_sim_libs()
{
    CFLAGS="-isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -mios-simulator-version-min=13.4 "
    generic_double_build ios.sim "$CFLAGS"
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

    ./runConfigureICU MacOSX --enable-static --disable-shared prefix=$INSTALL_DIR CXXFLAGS="--std=c++17"
    make -j$THREAD_COUNT
    make install
    popd
    touch $ICU_BUILD_FOLDER.success
fi

generic_build macos $FOREIGN_ARC $FOREIGN_BUILD_ARC
if [ -d $ICU_VER_NAME-macos-build ]; then
    rm -rf $ICU_VER_NAME-macos-build
fi
mkdir -p $ICU_VER_NAME-macos-build/source/lib
lipo -create $INSTALL_DIR/lib/libicudata.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicudata.a -output $ICU_VER_NAME-macos-build/source/lib/libicudata.a
lipo -create $INSTALL_DIR/lib/libicui18n.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicui18n.a -output $ICU_VER_NAME-macos-build/source/lib/libicui18n.a
lipo -create $INSTALL_DIR/lib/libicuio.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicuio.a -output $ICU_VER_NAME-macos-build/source/lib/libicuio.a
lipo -create $INSTALL_DIR/lib/libicuuc.a $ICU_VER_NAME-macos-$FOREIGN_ARC-build/source/lib/libicuuc.a -output $ICU_VER_NAME-macos-build/source/lib/libicuuc.a

build_catalyst_libs
build_sim_libs

generic_build ios arm64 arm "-fembed-bitcode -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=13.4"

#COMMON_CFLAGS="-arch arm64 -fembed-bitcode -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=13.4 -I$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/include/"
#./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=arm-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/lib/ -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -Wl,-dead_strip -lstdc++"


#build_catalyst_libs_obs()
#{
#if [ ! -f $ICU_VER_NAME-catalyst-$1-build.success ]; then
#echo preparing build folder $ICU_VER_NAME-catalyst-$1-build ...
#if [ -d $ICU_VER_NAME-catalyst-$1-build ]; then
#    rm -rf $ICU_VER_NAME-catalyst-$1-build
#fi
#cp -r $ICU4C_FOLDER $ICU_VER_NAME-catalyst-$1-build
#echo "building icu (mac osx: Catalyst $1)..."
#pushd $ICU_VER_NAME-catalyst-$1-build/source
#
#COMMON_CFLAGS="-arch $1 --target=$2-apple-ios13.4-macabi -isysroot $MACSYSROOT -I$MACSYSROOT/System/iOSSupport/usr/include/ -isystem $MACSYSROOT/System/iOSSupport/usr/include -iframework $MACSYSROOT/System/iOSSupport/System/Library/Frameworks"
#./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=$BUILD_ARC-apple-darwin --build=$2-apple --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$MACSYSROOT/System/iOSSupport/usr/lib/ -Wl,-dead_strip -lstdc++"
#
#make -j$THREAD_COUNT
#popd
#touch $ICU_VER_NAME-catalyst-$1-build.success 
#fi
#}

#if [ ! -f $ICU_CATALYST_BUILD_FOLDER.success ]; then
#    echo preparing build folder $ICU_CATALYST_BUILD_FOLDER ...
#    if [ -d $ICU_CATALYST_BUILD_FOLDER ]; then
#        rm -rf $ICU_CATALYST_BUILD_FOLDER
#    fi
#    mkdir -p $ICU_CATALYST_BUILD_FOLDER/source/lib
#    build_catalyst_libs arm64 arm
#    build_catalyst_libs x86_64 x86_64
#    lipo -create $ICU_VER_NAME-catalyst-arm64-build/source/lib/libicudata.a $ICU_VER_NAME-catalyst-x86_64-build/source/lib/libicudata.a -output $ICU_CATALYST_BUILD_FOLDER/source/lib/libicudata.a
#    lipo -create $ICU_VER_NAME-catalyst-arm64-build/source/lib/libicui18n.a $ICU_VER_NAME-catalyst-x86_64-build/source/lib/libicui18n.a -output $ICU_CATALYST_BUILD_FOLDER/source/lib/libicui18n.a
#    lipo -create $ICU_VER_NAME-catalyst-arm64-build/source/lib/libicuio.a $ICU_VER_NAME-catalyst-x86_64-build/source/lib/libicuio.a -output $ICU_CATALYST_BUILD_FOLDER/source/lib/libicuio.a
#    lipo -create $ICU_VER_NAME-catalyst-arm64-build/source/lib/libicuuc.a $ICU_VER_NAME-catalyst-x86_64-build/source/lib/libicuuc.a -output $ICU_CATALYST_BUILD_FOLDER/source/lib/libicuuc.a
#    touch $ICU_VER_NAME-ios.sim-$1-build.success 
#fi

################### BUILD FOR SIM
#ICU_IOS_SIM_BUILD_FOLDER=$ICU_VER_NAME-ios.sim-build
#
#build_sim_libs_obs()
#{
#if [ ! -f $ICU_VER_NAME-ios.sim-$1-build.success ]; then
#echo preparing build folder $ICU_VER_NAME-ios.sim-$1-build ...
#if [ -d $ICU_VER_NAME-ios.sim-$1-build ]; then
#    rm -rf $ICU_VER_NAME-ios.sim-$1-build
#fi
#cp -r $ICU4C_FOLDER $ICU_VER_NAME-ios.sim-$1-build
#echo "building icu (iOS: iPhoneSimulator $1)..."
#pushd $ICU_VER_NAME-ios.sim-$1-build/source
#
#COMMON_CFLAGS="-arch $1 -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -mios-simulator-version-min=13.4 -I$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/include/"
#./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=$BUILD_ARC-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/lib/ -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -Wl,-dead_strip -lstdc++"
#
#make -j$THREAD_COUNT
#popd
#touch $ICU_VER_NAME-ios.sim-$1-build.success 
#fi
#}

#if [ ! -f $ICU_IOS_SIM_BUILD_FOLDER.success ]; then
#    if [ -d $ICU_IOS_SIM_BUILD_FOLDER ]; then
#        rm -rf $ICU_IOS_SIM_BUILD_FOLDER
#    fi
#    mkdir -p $ICU_IOS_SIM_BUILD_FOLDER/source/lib
#    
#    build_sim_libs arm64
#    build_sim_libs x86_64
#
#    lipo -create $ICU_VER_NAME-ios.sim-arm64-build/source/lib/libicudata.a $ICU_VER_NAME-ios.sim-x86_64-build/source/lib/libicudata.a -output $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicudata.a
#    lipo -create $ICU_VER_NAME-ios.sim-arm64-build/source/lib/libicui18n.a $ICU_VER_NAME-ios.sim-x86_64-build/source/lib/libicui18n.a -output $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicui18n.a
#    lipo -create $ICU_VER_NAME-ios.sim-arm64-build/source/lib/libicuio.a $ICU_VER_NAME-ios.sim-x86_64-build/source/lib/libicuio.a -output $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicuio.a
#    lipo -create $ICU_VER_NAME-ios.sim-arm64-build/source/lib/libicuuc.a $ICU_VER_NAME-ios.sim-x86_64-build/source/lib/libicuuc.a -output $ICU_IOS_SIM_BUILD_FOLDER/source/lib/libicuuc.a
#fi

################### BUILD FOR DEVICE
#ICU_IOS_BUILD_FOLDER=$ICU_VER_NAME-ios.dev-build
#if [ ! -f $ICU_IOS_BUILD_FOLDER.success ]; then
#echo preparing build folder $ICU_IOS_BUILD_FOLDER ...
#if [ -d $ICU_IOS_BUILD_FOLDER ]; then
#    rm -rf $ICU_IOS_BUILD_FOLDER
#fi
#cp -r $ICU4C_FOLDER $ICU_IOS_BUILD_FOLDER
#echo "building icu (iOS: iPhoneOS)..."
#pushd $ICU_IOS_BUILD_FOLDER/source
#
#COMMON_CFLAGS="-arch arm64 -fembed-bitcode -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=13.4 -I$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/include/"
#./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$INSTALL_DIR --host=arm-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/lib/ -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -Wl,-dead_strip -lstdc++"
#make -j$THREAD_COUNT
#popd
#touch $ICU_IOS_BUILD_FOLDER.success 
#fi

if [ -d $INSTALL_DIR/frameworks ]; then
    rm -rf $INSTALL_DIR/frameworks
fi
mkdir $INSTALL_DIR/frameworks

xcodebuild -create-xcframework -library $ICU_VER_NAME-macos-build/source/lib/libicudata.a -library $ICU_VER_NAME-catalyst-build/source/lib/libicudata.a -library $ICU_VER_NAME-ios.sim-build/source/lib/libicudata.a -library $ICU_VER_NAME-ios-arm64-build/source/lib/libicudata.a -output $INSTALL_DIR/frameworks/icudata.xcframework

xcodebuild -create-xcframework -library $ICU_VER_NAME-macos-build/source/lib/libicui18n.a -library $ICU_VER_NAME-catalyst-build/source/lib/libicui18n.a -library $ICU_VER_NAME-ios.sim-build/source/lib/libicui18n.a -library $ICU_VER_NAME-ios-arm64-build/source/lib/libicui18n.a -output $INSTALL_DIR/frameworks/icui18n.xcframework

xcodebuild -create-xcframework -library $ICU_VER_NAME-macos-build/source/lib/libicuio.a -library $ICU_VER_NAME-catalyst-build/source/lib/libicuio.a -library $ICU_VER_NAME-ios.sim-build/source/lib/libicuio.a -library $ICU_VER_NAME-ios-arm64-build/source/lib/libicuio.a -output $INSTALL_DIR/frameworks/icuio.xcframework

xcodebuild -create-xcframework -library $ICU_VER_NAME-macos-build/source/lib/libicuuc.a -library $ICU_VER_NAME-catalyst-build/source/lib/libicuuc.a -library $ICU_VER_NAME-ios.sim-build/source/lib/libicuuc.a -library $ICU_VER_NAME-ios-arm64-build/source/lib/libicuuc.a -output $INSTALL_DIR/frameworks/icuuc.xcframework
