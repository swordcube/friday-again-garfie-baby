package funkin.backend;

#if DISCORD_ALLOWED
import sys.thread.Thread;
import discord.GameSDK;

class DiscordRPC {
    public static var thread(default, null):Thread;
    public static var threadActive(default, null):Bool = true;

    public static var appID(default, set):String;

    public static function init():Void {
        appID = "1370975492257349775";
        thread = Thread.create(() -> {
            while(true) {
                if(!threadActive)
                    break;

                final result:Result = GameSDK.runCallbacks();
                if(result != Ok)
                    Logs.error('Error running Discord callbacks: ${result}');
                
                Sys.sleep(0.5);
            }
        });
    }

    public static function shutdown():Void {
        threadActive = false;
        GameSDK.shutdown();
    }

    public static function changePresence(details:String, state:String, ?smallImageKey:String):Void {
        changePresenceAdvanced({
            state: state,
            details: details,
            assets: {
                smallImage: smallImageKey
            }
        });
    }

    public static function changePresenceAdvanced(activity:Activity):Void {
        if(activity == null) {
            Logs.error('Cannot use invalid Discord Presence data!');
            return;
        }
        GameSDK.updateActivity(activity);
    }
    
    //----------- [ Private API ] -----------//
    
    private static function set_appID(newAppID:String):String {
        if(appID != newAppID) {
            if(appID != null)
                GameSDK.shutdown();
            
            appID = newAppID;
            
            final result:Result = GameSDK.create(appID);
            if(result != Ok)
                Logs.error('Error initializing Discord RPC: ${result}');
        }
        return appID;
    }
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