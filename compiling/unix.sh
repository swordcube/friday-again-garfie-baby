#!/bin/sh
# This is for compiling a release build with crash handling.

# If your mod is in development, you should use this build instead, as it will
# a few extra debugging tools for mod development.

clear
echo "--==[ Compiling Dev Build | Linux/macOS ]==--"
haxelib run lime test linux -DTEST_BUILD