# friday again garfie baby
dumb dipshit fnf engine

very experimental

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

### **step 3:** making lime work
this engine uses a custom lime fork, for extra features and patches
that regular lime doesn't have, so we need to run this before compiling:

```sh
haxelib run lime rebuild <platform>
```
replace <platform> with whatever OS you're running on, such as
`windows`, `mac`, `linux`, etc

### **step 4:** actually compiling the thing
```sh
haxelib run lime test <platform>
```
replace <platform> with whatever OS you're running on, such as
`windows`, `mac`, `linux`, etc

### **step 5:** there is no step 5
that's it, you compiled the game (hopefully)