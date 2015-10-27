#!/bin/sh
### Modified from http://blog.csdn.net/favormm/article/details/6772097
set -xe

DEVELOPER=`xcode-select -print-path`
DEST=`pwd .`"/opencore-amr-iOS"

ARCHS="i386 x86_64 armv7 armv7s arm64"
LIBS="libopencore-amrnb.a libopencore-amrwb.a"
# Note that AMR-NB is for narrow band http://en.wikipedia.org/wiki/Adaptive_Multi-Rate_audio_codec
# for AMR-WB encoding, refer to http://sourceforge.net/projects/opencore-amr/files/vo-amrwbenc/
# or AMR Codecs as Shared Libraries http://www.penguin.cz/~utx/amr

mkdir -p $DEST

for arch in $ARCHS; do
	make clean
	IOSMV=" -miphoneos-version-min=6.0"
	case $arch in
	arm*)
		if [ $arch == "arm64" ]
		then
			IOSMV=" -miphoneos-version-min=7.0"
		fi
		echo "Building opencore-amr for iPhoneOS $arch ****************"
        SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
        CC="$(xcrun --sdk iphoneos -f clang)"
        CXX="$(xcrun --sdk iphoneos -f clang++)"
        CPP="$(xcrun -sdk iphonesimulator -f clang++)"
        CFLAGS="-isysroot $SDKROOT -arch $arch $IOSMV -isystem $SDKROOT/usr/include -fembed-bitcode"
        CXXFLAGS=$CFLAGS
        CPPFLAGS=$CFLAGS
        export CC CXX CFLAGS CXXFLAGS CPPFLAGS

		./configure \
		--host=arm-apple-darwin \
		--prefix=$DEST \
		--disable-shared \
        --enable-static
		;;
	*)
		IOSMV=" -mios-simulator-version-min=6.0"
		echo "Building opencore-amr for iPhoneSimulator $arch *****************"
        SDKROOT="$(xcodebuild -version -sdk iphonesimulator Path)"
        CC="$(xcrun -sdk iphoneos -f clang)"
        CXX="$(xcrun -sdk iphonesimulator -f clang++)"
        CPP="$(xcrun -sdk iphonesimulator -f clang++)"
        CFLAGS="-isysroot $SDKROOT -arch $arch $IOSMV -isystem $SDKROOT/usr/include -fembed-bitcode"
        CXXFLAGS=$CFLAGS
        CPPFLAGS=$CFLAGS
        export CC CXX CFLAGS CXXFLAGS CPPFLAGS

		./configure \
		--prefix=$DEST \
		--disable-shared \
        --enable-static
		;;
	esac
    make > /dev/null
    make install
    make clean
	for i in $LIBS; do
		mv $DEST/lib/$i $DEST/lib/$i.$arch
	done
done

echo "Merge into universal binary."

for i in $LIBS; do
	input=""
	for arch in $ARCHS; do
		input="$input $DEST/lib/$i.$arch"
	done
	xcrun lipo -create -output $DEST/lib/$i $input
done



