@REM This is for compiling a release build with crash handling.

@REM If your mod is in development, you should use this build instead, as it will
@REM a few extra debugging tools for mod development.

@echo off
cls
echo "--==[ Compiling Dev Build | Windows ]==--"
haxelib run lime test windows -DTEST_BUILD