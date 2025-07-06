# it's me burgerballs, deploying the codebase bomb

KABOOOOOOOOOOM!!!!


# friday again garfie baby
dumb dipshit fnf engine

very experimental, gonna be used for sword's cubical saturday, which is
my (currently unreleased) mod

so expect some code specific to it later on (will be wrapped under the SCS define)

# 🖥️ compiling guide
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

# ❓ the qna of all time
### Why not use Psych, Codename, or V-Slice?
There's a few reasons for this, and i'll give a reason for each engine individually

These *aren't* **objective** opinions on each engine, rather these are specifically my personal reasons
for not using them

---

**Psych:**
I personally haven't ever particularly enjoyed Psych's modding system,
it's perfectly okay, but it feels janky (in my opinion), especially it's HScript system

It's Lua scripting is entirely callback based (setProperty, getProperty, etc), which
isn't ideal for me

No hate for anyone that uses it of course, I just have personally have never really
cared/enjoyed using it outside of messing around with dumb little oneshot scripts

---

**Codename:**
I *was* using Codename for SCS at one point, but the below should explain why I stopped using the engine:

Codename is better regarding scripting, since it uses pure HScript, thus allowing
you to create sprites directly without the need of callbacks (new FlxSprite(), new FlxText(), etc)

~~However it has been getting noticably worse with how much lag spikes it has, it's really
been a hinderance on the development of SCS~~
- This is an issue with the CNE version of SCS it seems, as playtesting without scripts from the charter stops the lag spikes. No clue what script is causing them in the first place, oh well

It's codebase is also slightly overcomplicated, but it's no where near as bad
as V-Slice, which will be talked about shortly

It also has some Week 6 jank leftover that feels like it's being worked around
instead of being more properly addressed

Those things are more-so small inconvieniences than anything, but a BIG reason for me ditching
Codename like this is because of a bad apple who was in the dev team (Ne_Eo), long story short
they did a lot of bad things, as well as being generally sketchy

There is a doc out there about them but I can't be asked to link it right now

I do have hopes for Codename to get better though, as these issues seem to have been
mainly caused by that bad apple in the dev team, and they have been kicked from the team

But it's too late for me to go back to Codename at this point, since i started making this engine before all of this started to get resolved 🔥🔥🔥

---

**V-Slice:**
Again this is all going to be **subjective**, but I need to get this off my chest

So you know how I said Codename's codebase was kinda overcomplicated?

***It's So Much Worse.***

The code itself looks like it's doing way more than it has any right to, and said code is hard to find because it's contained within some random folder that might not even relate to the thing you're looking for!

Variable names can also change and become over-complicated for no reason seemingly at random:
- One of the recent Funkin' updates (think it was 0.6.0??) changed the naming of option pages to option **codexes**??

...not to mention the modding has some major problems as of Funkin' v0.6.4,
some of which being:

- Mods stop loading entirely if the API version no longer matches the game version,
  this should be handled by warning the user instead of not loading the mod!!

- Performance gets exponentially worse the more mods you have installed, even if they
  were to be entirely blank mods with nothing but metadata

- All scripts are *always global*, which means you have to specifically make workarounds
  to stop them from running outside of Gameplay and such, it gets really annoying

- Freeplay takes *incredibly* long to load at times, I once had to wait like 10 seconds for it to load I Wish I Was Joking
  - This was only with 5 mods, I'd imagine this gets exponentially worse similarly to problem 2

- The way data is generally handled in V-Slice is done with "registries", which I could see being useful if more was done with these registries than generally acting as over-complicated caches