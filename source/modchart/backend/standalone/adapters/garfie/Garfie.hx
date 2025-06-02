package modchart.backend.standalone.adapters.garfie;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;

import funkin.backend.Options;
import funkin.backend.Conductor;

import funkin.gameplay.notes.Note;
import funkin.gameplay.notes.NoteSplash;

import funkin.gameplay.notes.HoldTail;
import funkin.gameplay.notes.HoldTrail;
import funkin.gameplay.notes.HoldTiledSprite;

import funkin.gameplay.notes.HoldGradient;
import funkin.gameplay.notes.HoldCover;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.StrumLine;

import funkin.states.PlayState;
import funkin.utilities.Constants;

import modchart.backend.standalone.IAdapter;

using funkin.utilities.ArrayUtil;

class Garfie implements IAdapter {
    private var __fCrochet:Float = 0;

    public function new() {}

    public function onModchartingInitialization() {}

    public function isTapNote(sprite:FlxSprite) {
        return sprite is Note;
    }

    // Song related
    public function getSongPosition():Float {
        return Conductor.instance.playhead;
    }

    public function getCurrentBeat():Float {
        return Conductor.instance.curDecBeat;
    }

    public function getCurrentCrochet():Float {
        return Conductor.instance.beatLength;
    }

    public function getBeatFromStep(step:Float):Float {
        return Conductor.instance.getBeatAtTime(Conductor.instance.getTimeAtStep(step));
    }

    public function arrowHit(arrow:FlxSprite) {
        if (arrow is Note) {
            final note:Note = cast arrow;
            return note.wasHit;
        }
        if (arrow is HoldTiledSprite) {
            final trail:HoldTiledSprite = cast arrow;
            return trail.holdTrail.note.wasHit;
        }
        if (arrow is HoldTail) {
            final tail:HoldTail = cast arrow;
            return tail.holdTrail.note.wasHit;
        }
        return false;
    }

    public function isHoldEnd(arrow:FlxSprite) {
        if(arrow is HoldTail) {
            return true; // hopefully this works?
        }
        return false;
    }

    public function getLaneFromArrow(arrow:FlxSprite) {
        if (arrow is Strum) {
            final strum:Strum = cast arrow;
            return strum.direction;
        }
        if (arrow is Note) {
            final note:Note = cast arrow;
            return note.direction;
        }
        if (arrow is HoldTiledSprite) {
            final trail:HoldTiledSprite = cast arrow;
            return trail.holdTrail.note.direction;
        }
        if (arrow is HoldTail) {
            final tail:HoldTail = cast arrow;
            return tail.holdTrail.note.direction;
        }
        if (arrow is NoteSplash) {
            final splash:NoteSplash = cast arrow;
            return splash.direction;
        }
        if (arrow is HoldGradient) {
            final gradient:HoldGradient = cast arrow;
            return gradient.direction;
        }
        if (arrow is HoldCover) {
            final cover:HoldCover = cast arrow;
            return cover.direction;
        }
        return arrow.ID;
    }

    public function getPlayerFromArrow(arrow:FlxSprite) {
        if (arrow is Strum) {
            final strum:Strum = cast arrow;
            return strum.strumLine == PlayState.instance.playerStrums ? 1 : 0;
        }
        if (arrow is Note) {
            final castedNote:Note = cast arrow;
            return castedNote.strumLine == PlayState.instance.playerStrums ? 1 : 0;
        }
        if (arrow is HoldTiledSprite) {
            final trail:HoldTiledSprite = cast arrow;
            return trail.holdTrail.note.strumLine == PlayState.instance.playerStrums ? 1 : 0;
        }
        if (arrow is HoldTail) {
            final tail:HoldTail = cast arrow;
            return tail.holdTrail.note.strumLine == PlayState.instance.playerStrums ? 1 : 0;
        }
        if (arrow is NoteSplash) {
            final splash:NoteSplash = cast arrow;
            return splash.strumLine == PlayState.instance.playerStrums ? 1 : 0;
        }
        if (arrow is HoldGradient) {
            final gradient:HoldGradient = cast arrow;
            return gradient.strumLine == PlayState.instance.playerStrums ? 1 : 0;
        }
        if (arrow is HoldCover) {
            final cover:HoldCover = cast arrow;
            return cover.strumLine == PlayState.instance.playerStrums ? 1 : 0;
        }
        return PlayState.instance.playerStrums.members.contains(arrow) ? 1 : 0;
    }

    public function getHoldLength(item:FlxSprite):Float {
        if (item is Note) {
            final note:Note = cast item;
            return note.length;
        }
        if (item is HoldTiledSprite) {
            final trail:HoldTiledSprite = cast item;
            return trail.holdTrail.note.length;
        }
        if (item is HoldTail) {
            final tail:HoldTail = cast item;
            return tail.holdTrail.note.length;
        }
        return 0;
    }

    public function getHoldParentTime(arrow:FlxSprite) {
        if (arrow is HoldTiledSprite) {
            final trail:HoldTiledSprite = cast arrow;
            return trail.holdTrail.note.time;
        }
        if (arrow is HoldTail) {
            final tail:HoldTail = cast arrow;
            return tail.holdTrail.note.time;
        }
        final note:Note = cast arrow;
        return note.time;
    }

    // im so fucking sorry for those conditionals
    // what conditionals ? -swordcube
    public function getKeyCount(?player:Int = 0):Int {
        return Constants.KEY_COUNT;
    }

    public function getPlayerCount():Int {
        return Math.floor(Constants.KEY_COUNT / 2);
    }

    public function getTimeFromArrow(arrow:FlxSprite) {
        if (arrow is Note) {
            final note:Note = cast arrow;
            return note.time;
        }
        if (arrow is HoldTiledSprite) {
            final trail:HoldTiledSprite = cast arrow;
            return trail.holdTrail.note.time;
        }
        if (arrow is HoldTail) {
            final tail:HoldTail = cast arrow;
            return tail.holdTrail.note.time + tail.holdTrail.note.length;
        }
        return 0;
    }

    public function getHoldSubdivisions(hold:FlxSprite):Int {
        return 3;
    }

    public function getDownscroll():Bool {
        return Options.downscroll;
    }

    public function getDefaultReceptorX(lane:Int, player:Int):Float {
        return __getStrumGroupFromPlayer(player).members[lane].x;
    }

    public function getDefaultReceptorY(lane:Int, player:Int):Float {
        final r = __getStrumGroupFromPlayer(player).members[lane];
        return getDownscroll() ? FlxG.height - r.height - r.y : r.y;
    }

    public function getArrowCamera():Array<FlxCamera>
        return [PlayState.instance.camHUD];

    public function getCurrentScrollSpeed():Float {
        var scrollSpeed:Float = PlayState.instance.currentChart.meta.game.scrollSpeed.get(PlayState.instance.currentDifficulty);
        switch(Options.gameplayModifiers.get("scrollType")) {
            case "multiplicative", "mult":
                final mult:Float = cast Options.gameplayModifiers.get("scrollSpeed");
                scrollSpeed *= mult;
                
            case "constant", "cmod":
                final value:Float = cast Options.gameplayModifiers.get("scrollSpeed");
                scrollSpeed = value;

            case "xmod", "bpm":
                final bpm:Float = PlayState.instance.currentChart.meta.song.timingPoints.first()?.bpm ?? 100.0;
                scrollSpeed = bpm / 60.0;
        }
        return scrollSpeed * .45;
    }

    // 0 receptors
    // 1 tap arrows
    // 2 hold arrows
    // 3 lane attachments
    public function getArrowItems() {
        final pspr:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []]];
        final strums = [PlayState.instance.opponentStrums, PlayState.instance.playerStrums];
        for (i in 0...strums.length) {
            strums[i].strums.forEachAlive(strumNote -> {
                if (pspr[i] == null)
                    pspr[i] = [];

                pspr[i][0].push(strumNote);
            });
            strums[i].notes.forEachAlive(note -> {
                pspr[i][1].push(note);
                pspr[i][2].push(note.holdTrail.strip);
                pspr[i][2].push(note.holdTrail.tail);
            });
            strums[i].splashes.forEachAlive(spr -> {
                pspr[i][3].push(spr);
            });
            strums[i].holdGradients.forEachAlive(spr -> {
                pspr[i][3].push(spr);
            });
            strums[i].holdCovers.forEachAlive(spr -> {
                pspr[i][3].push(spr);
            });
        }
        return pspr;
    }

    private function __getStrumGroupFromPlayer(player:Int):flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<Strum> {
        return (player == 1) ? PlayState.instance.playerStrums.strums : PlayState.instance.opponentStrums.strums;
    }
}