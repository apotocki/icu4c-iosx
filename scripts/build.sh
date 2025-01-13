#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
ICU_VER=maint/maint-76
MACOSX_VERSION_ARM=12.3
MACOSX_VERSION_X86_64=10.13
IOS_VERSION=13.4
IOS_SIM_VERSION=13.4
CATALYST_VERSION=13.4
TVOS_VERSION=13.0
TVOS_SIM_VERSION=13.0
WATCHOS_VERSION=11.0
WATCHOS_SIM_VERSION=11.0
################## SETUP END
IOSSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
IOSSIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
XROSSYSROOT=$XCODE_ROOT/Platforms/XROS.platform/Developer
XROSSIMSYSROOT=$XCODE_ROOT/Platforms/XRSimulator.platform/Developer
TVOSSYSROOT=$XCODE_ROOT/Platforms/AppleTVOS.platform/Developer
TVOSSIMSYSROOT=$XCODE_ROOT/Platforms/AppleTVSimulator.platform/Developer
WATCHOSSYSROOT=$XCODE_ROOT/Platforms/WatchOS.platform/Developer
WATCHOSSIMSYSROOT=$XCODE_ROOT/Platforms/WatchSimulator.platform/Developer

BUILD_PLATFORMS_ALL="macosx,macosx-arm64,macosx-x86_64,macosx-both,ios,iossim,iossim-arm64,iossim-x86_64,iossim-both,catalyst,catalyst-arm64,catalyst-x86_64,catalyst-both,xros,xrossim,xrossim-arm64,xrossim-x86_64,xrossim-both,tvos,tvossim,tvossim-both,tvossim-arm64,tvossim-x86_64,watchos,watchossim,watchossim-both,watchossim-arm64,watchossim-x86_64"

ICU_VER_NAME=icu4c-${ICU_VER//\//-}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
INSTALL_DIR="$BUILD_DIR/product"
ICU4C_FOLDER=icu/icu4c

if [[ "$HOST_ARC" == "arm64" ]]; then
	BUILD_ARC=arm
    FOREIGN_ARC=x86_64
    FOREIGN_BUILD_ARC=x86_64
    FOREIGN_BUILD_FLAGS="" && [[ ! -z "${MACOSX_VERSION_X86_64}" ]] && FOREIGN_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_X86_64"
    NATIVE_BUILD_FLAGS="" && [[ ! -z "${MACOSX_VERSION_ARM}" ]] && NATIVE_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_ARM"
else
	BUILD_ARC=$HOST_ARC
    FOREIGN_ARC=arm64
    FOREIGN_BUILD_ARC=arm
    FOREIGN_BUILD_FLAGS="" && [[ ! -z "${MACOSX_VERSION_ARM}" ]] && FOREIGN_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_ARM"
    NATIVE_BUILD_FLAGS="" && [[ ! -z "${MACOSX_VERSION_X86_64}" ]] && NATIVE_BUILD_FLAGS="-mmacosx-version-min=$MACOSX_VERSION_X86_64"
fi

BUILD_PLATFORMS="macosx,ios,iossim,catalyst,tvos,tvossim,watchos,watchossim"
[[ -d $XROSSYSROOT/SDKs/XROS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xros"
[[ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xrossim"
[[ -d $TVOSSYSROOT/SDKs/AppleTVOS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvos"
[[ -d $TVOSSIMSYSROOT/SDKs/AppleTVSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvossim"
[[ -d $WATCHOSSYSROOT/SDKs/WatchOS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchos"
[[ -d $WATCHOSSIMSYSROOT/SDKs/WatchSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchossim"

ICU_BUILD_FOLDER=$ICU_VER_NAME-macosx-$HOST_ARC-build

if [[ -z "${WITH_DATA_PACKAGING}" ]]; then
    WITH_DATA_PACKAGING="static" # archive
fi

# parse command line
for i in "$@"; do
  case $i in
    -p=*|--platforms=*)
      BUILD_PLATFORMS="${i#*=},"
      shift # past argument=value
      ;;
    -d=*|--data=*)
      WITH_DATA_PACKAGING="${i#*=}"
      shift # past argument with no value
      ;;
    -f*|--filter=*)
      WITH_DATA_FILTER="${i#*=}"
      shift # past argument with no value
      ;;
    --rebuild)
      REBUILD=true
      shift # past argument with no value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

[[ "$BUILD_PLATFORMS" == *"macosx-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,macosx-arm64,macosx-x86_64"
[[ "$BUILD_PLATFORMS" == *"iossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,iossim-arm64,iossim-x86_64"
[[ "$BUILD_PLATFORMS" == *"catalyst-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,catalyst-arm64,catalyst-x86_64"
[[ "$BUILD_PLATFORMS" == *"xrossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xrossim-arm64,xrossim-x86_64"
[[ "$BUILD_PLATFORMS" == *"tvossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvossim-arm64,tvossim-x86_64"
[[ "$BUILD_PLATFORMS" == *"watchossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchossim-arm64,watchossim-x86_64"
[[ "$BUILD_PLATFORMS," == *"macosx,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,macosx-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"iossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,iossim-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"catalyst,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,catalyst-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"xrossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xrossim-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"tvossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvossim-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"watchossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchossim-$HOST_ARC"

BUILD_PLATFORMS=" ${BUILD_PLATFORMS//,/ } "

for i in $BUILD_PLATFORMS; do :;
if [[ ! ",$BUILD_PLATFORMS_ALL," == *",$i,"* ]]; then
    echo "Unknown platform '$i'"
    exi1 1
fi
done

if [[ $WITH_DATA_FILTER ]]; then
    [[ ! "$WITH_DATA_FILTER" == "/"* ]] && [[ -f $BUILD_DIR/$WITH_DATA_FILTER ]] && WITH_DATA_FILTER=$BUILD_DIR/$WITH_DATA_FILTER
    if [[ ! -f $WITH_DATA_FILTER ]]; then
        echo "File '$WITH_DATA_FILTER' is not found."
        exi1 1
    fi
fi

[[ $WITH_DATA_FILTER ]] && [[ $WITH_DATA_PACKAGING == "archive" ]] && EXPORTED_DATA_FILTER=$WITH_DATA_FILTER

if [[ $WITH_DATA_PACKAGING == archive ]] || [[ $WITH_DATA_PACKAGING == archive2 ]]; then
    if [[ ! -f $INSTALL_DIR/share/icu/*/icudt*.dat ]]; then
        # need to rebuild host libs
        [[ -f $ICU_BUILD_FOLDER.success ]] && rm $ICU_BUILD_FOLDER.success
    fi
fi 

echo "USING WITH_DATA_PACKAGING: $WITH_DATA_PACKAGING"

if [[ ! -d icu ]]; then
	echo downloading icu ...
	git clone --depth 1 -b $ICU_VER https://github.com/unicode-org/icu icu
fi

#explicit 76.1
pushd icu
git fetch --depth=1 origin 8eca245c7484ac6cc179e3e5f7c1ea7680810f39
git reset --hard 8eca245c7484ac6cc179e3e5f7c1ea7680810f39
popd


COMMON_CONFIGURE_ARGS="--enable-static --disable-shared"
if [[ $WITH_DATA_PACKAGING == "static" ]]; then
    COMMON_CONFIGURE_ARGS="$COMMON_CONFIGURE_ARGS --with-data-packaging=static"
else
    COMMON_CONFIGURE_ARGS="$COMMON_CONFIGURE_ARGS --with-data-packaging=archive"
fi

# (type, arc, build-arc, cflags, ldflags)
generic_build()
{
    if [[ $REBUILD == true ]] || [[ ! -f $ICU_VER_NAME-$1-$2-build.success ]]; then
        echo preparing build folder $ICU_VER_NAME-$1-$2-build ...
        [[ -d $ICU_VER_NAME-$1-$2-build ]] && rm -rf $ICU_VER_NAME-$1-$2-build

        cp -r $ICU4C_FOLDER $ICU_VER_NAME-$1-$2-build
        echo "building icu ($1 $2)..."
        pushd $ICU_VER_NAME-$1-$2-build/source

        COMMON_CFLAGS="-arch $2 $4"

        ICU_DATA_FILTER_FILE=$EXPORTED_DATA_FILTER ./configure $COMMON_CONFIGURE_ARGS --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --host=$BUILD_ARC-apple-darwin --build=$3-apple --with-cross-build=$BUILD_DIR/$ICU_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ $5 -Wl,-dead_strip -lstdc++"
        
        make -j$THREAD_COUNT
        [[ ! $WITH_DATA_PACKAGING == "static" ]] && cp stubdata/libicudata.a lib/

        popd
        touch $ICU_VER_NAME-$1-$2-build.success
    fi
}

LIBS_TO_BUILD="icudata icui18n icuio icuuc"
build_libs()
{
    [[ -d $ICU_VER_NAME-$1-build ]] && rm -rf $ICU_VER_NAME-$1-build
    mkdir -p $ICU_VER_NAME-$1-build/source/lib

    if [[ "$BUILD_PLATFORMS" == *$1-arm64* ]]; then
        if [[ "$BUILD_PLATFORMS" == *$1-x86_64* ]]; then
            for i in $LIBS_TO_BUILD; do :;
                lipo -create $ICU_VER_NAME-$1-arm64-build/source/lib/lib$i.a $ICU_VER_NAME-$1-x86_64-build/source/lib/lib$i.a -output $ICU_VER_NAME-$1-build/source/lib/lib$i.a
            done
        else
            for i in $LIBS_TO_BUILD; do :;
                cp $ICU_VER_NAME-$1-arm64-build/source/lib/lib$i.a $ICU_VER_NAME-$1-build/source/lib/
            done
        fi
    elif [[ "$BUILD_PLATFORMS" == *$1-x86_64* ]]; then
        for i in $LIBS_TO_BUILD; do :;
            cp $ICU_VER_NAME-$1-x86_64-build/source/lib/lib$i.a $ICU_VER_NAME-$1-build/source/lib/
        done
    fi
}

# (type, coomon_cflags, arm-cflags, x86_64-cflags, ldflags)
generic_double_build()
{
    [[ "$BUILD_PLATFORMS" == *$1-arm64* ]] && generic_build $1 arm64 arm "$2 $3" "$5"
    [[ "$BUILD_PLATFORMS" == *$1-x86_64* ]] && generic_build $1 x86_64 x86_64 "$2 $4" "$5"
    build_libs $1
}

build_catalyst_libs()
{
    CFLAGS="-isysroot $MACSYSROOT --target=apple-ios$CATALYST_VERSION-macabi"
    generic_double_build catalyst "$CFLAGS"
}

build_iossim_libs()
{
    CFLAGS="-isysroot $IOSSIMSYSROOT/SDKs/iPhoneSimulator.sdk -mios-simulator-version-min=$IOS_SIM_VERSION "
    generic_double_build iossim "$CFLAGS"
}

build_xrossim_libs()
{
    CFLAGS="-isysroot $XROSSIMSYSROOT/SDKs/XRSimulator.sdk "
    generic_double_build xrossim "$CFLAGS"
}

build_tvossim_libs()
{
    CFLAGS="-isysroot $TVOSSIMSYSROOT/SDKs/AppleTVSimulator.sdk -target arm64-apple-tvos$TVOS_SIM_VERSION-simulator"
    generic_double_build tvossim "$CFLAGS"
}

build_watchossim_libs()
{
    CFLAGS="-isysroot $WATCHOSSIMSYSROOT/SDKs/WatchSimulator.sdk -target arm64-apple-watchos$WATCHOS_SIM_VERSION-simulator"
    generic_double_build watchossim "$CFLAGS"
}

build_data_file()
{
    [[ -d icudata ]] && rm -rf icudata
    [[ -d icutmp ]] && rm -rf icutmp
    
    mkdir icudata && cp $INSTALL_DIR/share/icu/*/icudt*.dat icudata/
    DATAFILE_NAME=$(basename $INSTALL_DIR/share/icu/*/icudt*.dat)

    PYTHON=$( which python3 )
    PYTHONPATH=$ICU_BUILD_FOLDER/source/python $PYTHON -m icutools.databuilder --mode unix-exec --src_dir "$ICU_BUILD_FOLDER/source/data" --filter_file $WITH_DATA_FILTER --tool_dir $INSTALL_DIR/bin --verbose
    [[ ! -d $INSTALL_DIR/data ]] && mkdir -p $INSTALL_DIR/data
    [[ -f $INSTALL_DIR/data/$DATAFILE_NAME ]] && rm $INSTALL_DIR/data/$DATAFILE_NAME
    $INSTALL_DIR/bin/icupkg -tl -s icudata -a "icutmp/icudata.lst" new $INSTALL_DIR/data/$DATAFILE_NAME
}

################### BUILD FOR MAC OSX
if [[ $REBUILD == true ]] || [[ ! -f $ICU_BUILD_FOLDER.success ]]; then
    echo preparing build folder $ICU_BUILD_FOLDER ...
    [[ -d $ICU_BUILD_FOLDER ]] && rm -rf $ICU_BUILD_FOLDER

    cp -r $ICU4C_FOLDER $ICU_BUILD_FOLDER

    echo "building icu (mac osx)..."
    pushd $ICU_BUILD_FOLDER/source

    [[ ! -d $INSTALL_DIR ]] && mkdir -p $INSTALL_DIR
    
    ICU_DATA_FILTER_FILE=$EXPORTED_DATA_FILTER CFLAGS="$NATIVE_BUILD_FLAGS" CXXFLAGS="--std=c++17 $NATIVE_BUILD_FLAGS" ./runConfigureICU MacOSX $COMMON_CONFIGURE_ARGS prefix=$INSTALL_DIR sbindir=$INSTALL_DIR/bin

    make -j$THREAD_COUNT
    make install
    [[ ! $WITH_DATA_PACKAGING == static ]] && cp stubdata/libicudata.a $INSTALL_DIR/lib/ && cp stubdata/libicudata.a lib/
    
    popd
    touch $ICU_BUILD_FOLDER.success
fi

[[ $WITH_DATA_PACKAGING == archive2 ]] && [[ $WITH_DATA_FILTER ]] && build_data_file

[[ "$BUILD_PLATFORMS" == *macosx-$FOREIGN_ARC* ]] && generic_build macosx $FOREIGN_ARC $FOREIGN_BUILD_ARC $FOREIGN_BUILD_FLAGS

[[ "$BUILD_PLATFORMS" == *macosx* ]] && build_libs macosx

[[ "$BUILD_PLATFORMS" == *catalyst* ]] && build_catalyst_libs

[[ "$BUILD_PLATFORMS" == *iossim* ]] && build_iossim_libs

[[ "$BUILD_PLATFORMS" == *xrossim* ]] && build_xrossim_libs

[[ "$BUILD_PLATFORMS" == *tvossim* ]] && build_tvossim_libs

[[ "$BUILD_PLATFORMS" == *watchossim* ]] && build_watchossim_libs

[[ "$BUILD_PLATFORMS" == *"ios "* ]] && generic_build ios arm64 arm "-fembed-bitcode -isysroot $IOSSYSROOT/SDKs/iPhoneOS.sdk -mios-version-min=$IOS_VERSION"

[[ "$BUILD_PLATFORMS" == *"xros "* ]] && generic_build xros arm64 arm "-fembed-bitcode -isysroot $XROSSYSROOT/SDKs/XROS.sdk"

[[ "$BUILD_PLATFORMS" == *"tvos "* ]] && generic_build tvos arm64 arm "-fembed-bitcode -isysroot $TVOSSYSROOT/SDKs/AppleTVOS.sdk -target arm64-apple-tvos$TVOS_VERSION"

[[ "$BUILD_PLATFORMS" == *"watchos "* ]] && generic_build watchos arm64 arm "-fembed-bitcode -isysroot $WATCHOSSYSROOT/SDKs/WatchOS.sdk -target arm64-apple-watchos$WATCHOS_VERSION"

[[ -d $INSTALL_DIR/frameworks ]] && rm -rf $INSTALL_DIR/frameworks
mkdir -p $INSTALL_DIR/frameworks

build_xcframework()
{
    LIBARGS=
    [[ "$BUILD_PLATFORMS" == *macosx* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-macosx-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *catalyst* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-catalyst-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *iossim* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-iossim-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *xrossim* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-xrossim-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *tvossim* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-tvossim-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *watchossim* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-watchossim-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *"ios "* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-ios-arm64-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *"xros "* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-xros-arm64-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *"tvos "* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-tvos-arm64-build/source/lib/lib$1.a"
    [[ "$BUILD_PLATFORMS" == *"watchos "* ]] && LIBARGS="$LIBARGS -library $ICU_VER_NAME-watchos-arm64-build/source/lib/lib$1.a"

    xcodebuild -create-xcframework $LIBARGS -output $INSTALL_DIR/frameworks/$1.xcframework
}

for i in $LIBS_TO_BUILD; do :;
    build_xcframework $i
done
