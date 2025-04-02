#!/bin/sh
# This is for compiling a release build without crash handling.
# If you're sure your mod is in a stable state, you should release this build instead!

clear
echo "--==[ Compiling Final Build | Linux/macOS ]==--"
haxelib run lime test windows -DNO_CRASH_HANDLER