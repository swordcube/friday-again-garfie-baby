@REM This is for compiling a release build without crash handling.
@REM If you're sure your mod is in a stable state, you should release this build instead!

@echo off
cls
echo "--==[ Compiling Final Build | Windows ]==--"
haxelib run lime test windows -DNO_CRASH_HANDLER