#!/bin/sh
clear

# make sure these are killed
# otherwise i get an OutOfMemory error for some reason
killall java
# killall adb

# build
haxelib run lime build android

# wait for phone
echo Press enter once you are ready to test on your physical phone
echo or press CTRL+C if there\'s a compile error above this
echo
echo If you decide to continue, make sure your phone is connected thru ADB!
echo USB or Wireless debugging will both work, but Wireless may take longer to install.
read -n 1 -s -r -p ""
echo

# run on phone
haxelib run lime run android