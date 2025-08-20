#!/bin/sh
clear

# make sure these are killed
# otherwise i get an OutOfMemory error for some reason
killall java
# killall adb

# build
export NO_ASTC_COMPRESSION=0
haxelib run lime build android

# wait for emulator
echo Press enter once you have the Android Studio emulator fully booted up
echo or press CTRL+C if there\'s a compile error above this
read -n 1 -s -r -p ""
echo

# run on emulator
export NO_ASTC_COMPRESSION=1
haxelib run lime run android -simulator