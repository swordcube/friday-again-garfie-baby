#if !macro
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;

import flixel.group.FlxContainer;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteContainer;
import flixel.group.FlxSpriteGroup;

import flixel.math.FlxMath;
import flixel.sound.FlxSound;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import flixel.util.FlxColor;

import funkin.backend.Conductor;
import funkin.backend.Controls;
import funkin.backend.Logs;
import funkin.backend.Options;

import funkin.backend.assets.Cache;
import funkin.backend.assets.Paths;

import funkin.ui.Cursor;

import funkin.utilities.CoolUtil;
import funkin.utilities.Constants;
import funkin.utilities.WindowUtil;

import haxe.Json;
import json2object.JsonParser;
import json2object.JsonWriter;

import openfl.utils.Assets as OpenFLAssets;

using StringTools;
using funkin.utilities.CoolUtil;
using funkin.utilities.ArrayUtil;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.GlobalScript;
#end

#end