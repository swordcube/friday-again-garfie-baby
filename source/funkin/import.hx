#if !macro
import haxe.Json;
import openfl.utils.Assets as OpenFLAssets;

import json2object.JsonParser;
import json2object.JsonWriter;

import flixel.FlxG;

import flixel.FlxBasic;
import flixel.FlxObject;

import flixel.FlxSprite;
import flixel.FlxCamera;

import flixel.FlxState;
import flixel.FlxSubState;

import flixel.group.FlxGroup;
import flixel.group.FlxContainer;

import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteContainer;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import funkin.assets.Paths;
import funkin.assets.Cache;

import funkin.backend.Logs;

import funkin.backend.Options;
import funkin.backend.Controls;

import funkin.backend.Conductor;
import funkin.backend.ModManager;

import funkin.utilities.Typedefs;
import funkin.utilities.Constants;

using StringTools;
using funkin.utilities.ArrayUtil;
#end