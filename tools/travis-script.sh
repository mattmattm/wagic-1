#!/bin/sh -e

# let's dump some info to debug a bit
echo ls = `ls`
echo pwd = `pwd`
# computing potential release name
echo TRAVIS_PULL_REQUEST = $TRAVIS_PULL_REQUEST
echo TRAVIS_BRANCH = $TRAVIS_BRANCH

if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
if [ "$TRAVIS_BRANCH" = "alphas" ]; then
    export RELEASE_NAME="alpha-${TRAVIS_BUILD_NUMBER}"
else if [ "$TRAVIS_BRANCH" = "master" ]; then
    export RELEASE_NAME="latest-master"
fi
fi
fi

echo RELEASE_NAME = $RELEASE_NAME

if [ "$TRAVIS_OS_NAME" = "linux" ]; then
    # updating versions with the TRAVIS build numbers
    cd projects/mtg/
    ant update > error.txt
    cd ../..
fi

# we create resource package
cd projects/mtg/bin/Res
python createResourceZip.py
# if we let the zip here, Wagic will use it in the testsuite
# and we'll get 51 failed test cases
mv core_*.zip ../../../../core.zip
cd ../../../..

# we're building a PSP binary here
if [ "$BUILD_TYPE" = "PSP" ]; then
    mkdir build_psp
    cd build_psp
    cmake -DCMAKE_TOOLCHAIN_FILE=../CMakeModules/psp.toolchain.cmake ..
    make -j8
    cd ..
fi

# we're building an Android binary here
if [ "$BUILD_TYPE" = "ANDROID" ]; then
    mkdir build_android
    cd build_android
    cmake -DCMAKE_TOOLCHAIN_FILE=../CMakeModules/android.toolchain.cmake -DANDROID_NATIVE_API_LEVEL=android-10
    make -j8
    cd ..
fi

# we're building a Qt version with GUI here
if [ "$BUILD_TYPE" = "Qt" ]; then
    mkdir build_qt_widget
    cd build_qt_widget
    cmake -Dbackend_qt_widget=ON -Dbackend_qt_console=OFF ..
    make -j4 wagic
    cd ..

    # let's try an Intel linux binary in debug text-mode-only
    mkdir build_qt_console
    cd build_qt_console
    cmake -Dbackend_qt_console=ON ..
    make -j4 wagic
    cd ..

    # Now we run the testsuite (Res needs to be in the working directory)
    cd projects/mtg
    ./../../build_qt_console/bin/wagic
    cd ../..
fi

# we're building a SDL version
if [ "$BUILD_TYPE" = "SDL" ]; then
    mkdir build_SDL
    cd build_SDL
    cmake -Dbackend_sdl=ON ..
    make -j4 wagic
    cd ..
fi

# Let's launch de iOS cross-compilation
if [ "$BUILD_TYPE" = "iOS" ]; then
    cd projects/mtg/iOS
    make -j 4 package
    cd ../../..
fi
