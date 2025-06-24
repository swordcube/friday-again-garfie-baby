# it's me burgerballs, deploying the codebase bomb

KABOOOOOOOOOOM!!!!


# friday again garfie baby
dumb dipshit fnf engine

very experimental, gonna be used for sword's cubical saturday, which is
my (currently unreleased) mod

so expect some code specific to it later on (will be wrapped under the SCS define)

# compiling guide
### **step 1:** install dependencies
get vs build tools 2022 on windows, install the desktop development with c++ package, and you're done

for linux, install luajit, vlc, and g++ if you don't have any of those already

### **step 2:** installing the libs

install hmm if not installed already:
```sh
haxelib install hmm
```

then use hmm to install the libs:
```sh
haxelib run hmm install
```

this might take a while cuz hmm is stupid and clones
the ENTIRE repo history for every git haxelib

i tried to fix it but i don't care anymore actually

### **step 3:** making lime work
this engine uses a custom lime fork, for extra features and patches
that regular lime doesn't have, so we need to run this before compiling:

```sh
haxelib run lime rebuild <platform>
```
replace `<platform>` with whatever OS you're running on, such as
`windows`, `mac`, `linux`, etc

note that you may have to update lime along with the other haxelibs
installed earlier sometimes, which means you might have to do this step again when you update your haxelibs!

if ***absolutely nothing*** happens when running the command, it's just because
there's nothing to recompile yet!

### **step 4:** actually compiling the thing
if you wanna compile a build WITHOUT the assets in it, instead
pointing to the source assets folder (for quicker testing):
```sh
haxelib run lime test <platform> -DTEST_BUILD
```

if you wanna compile a build WITH the assets in it, instead
pointing to the export assets folder (meant for release builds of mods and such):
```sh
haxelib run lime test <platform>
```
replace `<platform>` with whatever OS you're running on, such as
`windows`, `mac`, `linux`, etc

### **step 5:** there is no step 5
that's it, you compiled the game (hopefully)
