package funkin.backend;

#if DISCORD_ALLOWED
import sys.thread.Thread;
import flixel.util.typeLimit.OneOfTwo;

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordRPC {
    public static var thread(default, null):Thread;
    public static var threadActive(default, null):Bool = true;
    public static var stopThread(default, null):Bool = false;

    public static var appID(default, set):String;

    public static function init():Void {
        appID = "1370975492257349775";
        thread = Thread.create(() -> {
            while(true) {
                if(!threadActive)
                    break;

                while(!stopThread) {
                    if(_pendingActivity != null && _currentActivity != _pendingActivity) {
                        final dp:DiscordRichPresence = new DiscordRichPresence();
                        dp.state = new cpp.ConstCharStar(cast(_pendingActivity.state, String));
                        dp.details = new cpp.ConstCharStar(cast(_pendingActivity.details, String));
                        dp.startTimestamp = _pendingActivity.startTimestamp;
                        dp.endTimestamp = _pendingActivity.endTimestamp;
                        dp.largeImageKey = new cpp.ConstCharStar(cast(_pendingActivity.largeImageKey, String));
                        dp.largeImageText = new cpp.ConstCharStar(cast(_pendingActivity.largeImageText, String));
                        dp.smallImageKey = new cpp.ConstCharStar(cast(_pendingActivity.smallImageKey, String));
                        dp.smallImageText = new cpp.ConstCharStar(cast(_pendingActivity.smallImageText, String));
                        dp.partyId = new cpp.ConstCharStar(cast(_pendingActivity.partyId, String));
                        dp.partySize = _pendingActivity.partySize;
                        dp.partyMax = _pendingActivity.partyMax;
                        dp.partyPrivacy = _pendingActivity.partyPrivacy;
                        dp.matchSecret = new cpp.ConstCharStar(cast(_pendingActivity.matchSecret, String));
                        dp.joinSecret = new cpp.ConstCharStar(cast(_pendingActivity.joinSecret, String));
                        dp.spectateSecret = new cpp.ConstCharStar(cast(_pendingActivity.spectateSecret, String));
                        Discord.UpdatePresence(cpp.RawConstPointer.addressOf(dp));

                        _currentActivity = _pendingActivity;
                        _pendingActivity = null;
                    }
                    #if DISCORD_DISABLE_IO_THREAD
                    Discord.UpdateConnection();
                    #end
                    Discord.RunCallbacks();
                    
                    Sys.sleep(1);
                }
                Sys.sleep(1);
            }
        });
        FlxG.stage.window.onClose.add(() -> {
            if(threadActive) {
                shutdown();
                threadActive = false;
            }
        });
    }

    public static function shutdown():Void {
        if(!threadActive || stopThread)
            return;
        
        stopThread = true;
        Discord.Shutdown();
    }

    public static function changePresence(details:String, state:String, ?smallImageKey:String):Void {
        changePresenceAdvanced({
            state: state,
            details: details,
            smallImageKey: smallImageKey
        });
    }

    public static function changePresenceAdvanced(activity:Activity):Void {
        if(activity == null) {
            Logs.error('Cannot use invalid Discord Presence data!');
            return;
        }
        _pendingActivity = activity;
    }

    public static function getCurrentPresence():Activity {
        return _currentActivity;
    }
    
    //----------- [ Private API ] -----------//

    private static var _pendingActivity:Activity;
    private static var _currentActivity:Activity;
    
    private static function set_appID(newAppID:String):String {
        if(!threadActive) {
            appID = newAppID;
            return appID;
        }
        if(appID != newAppID) {
            if(appID != null)
                Discord.Shutdown();
            
            appID = newAppID;
            
            final handlers:DiscordEventHandlers = new DiscordEventHandlers();
            handlers.ready = cpp.Function.fromStaticFunction(onReady);
            handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
            handlers.errored = cpp.Function.fromStaticFunction(onError);
            Discord.Initialize(appID, cpp.RawPointer.addressOf(handlers), false, null);

            // force activity to update asap
            _pendingActivity = _currentActivity;
            _currentActivity = null;

            stopThread = false;
        }
        return appID;
    }

    private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		final user:cpp.Star<DiscordUser> = cast cpp.ConstPointer.fromRaw(request).ptr;

        var fullUser:String = cast(user.username, String);
        var discriminator:String = cast(user.discriminator, String);
        
        if(discriminator != "0")
            fullUser += '#${discriminator}';

		Logs.traceColored([
			{text: "[Discord] ", fgColor: BLUE},
			{text: "Connected to User " + user.globalName + " ("},
			{text: fullUser, fgColor: GRAY},
			{text: ")"}
		], TRACE);
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		final finalMsg:String = cast(message, String);
		Logs.traceColored([
			{text: "[Discord] ", fgColor: BLUE},
			{text: "Disconnected ("},
			{text: '${errorCode}: ${finalMsg}', fgColor: RED},
			{text: ")"}
		], TRACE);

        if(threadActive) {
            shutdown();
            threadActive = false;
        }
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		final finalMsg:String = cast(message, String);
		Logs.traceColored([
			{text: "[Discord] ", fgColor: BLUE},
			{text: 'Error ($errorCode: $finalMsg)', fgColor: RED}
		], ERROR);

        if(threadActive) {
            shutdown();
            threadActive = false;
        }
	}
}

typedef Activity = {
	var ?state:String; /* max 128 bytes */
	var ?details:String; /* max 128 bytes */
	var ?startTimestamp:OneOfTwo<Int, haxe.Int64>;
	var ?endTimestamp:OneOfTwo<Int, haxe.Int64>;
	var ?largeImageKey:String; /* max 32 bytes */
	var ?largeImageText:String; /* max 128 bytes */
	var ?smallImageKey:String; /* max 32 bytes */
	var ?smallImageText:String; /* max 128 bytes */
	var ?partyId:String; /* max 128 bytes */
	var ?partySize:Int;
	var ?partyMax:Int;
	var ?partyPrivacy:Int;
	var ?matchSecret:String; /* max 128 bytes */
	var ?joinSecret:String; /* max 128 bytes */
	var ?spectateSecret:String; /* max 128 bytes */
	var ?instance:#if cpp OneOfTwo<Int, cpp.Int8> #else Int #end;
}
#else
class DiscordRPC {
    public static var thread:Dynamic;
    public static var threadActive:Bool = true;

    public static var appID:String;

    public static function init():Void {}
    public static function shutdown():Void {}

    public static function changePresence(details:String, state:String, ?smallImageKey:String):Void {}
    public static function changePresenceAdvanced(activity:Dynamic):Void {}
}
#end