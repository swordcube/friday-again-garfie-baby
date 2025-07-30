package funkin.states.editors;

import haxe.io.Path;

import sys.io.File;
import sys.FileSystem;

import flixel.text.FlxText;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

import flixel.animation.FlxAnimation;

import funkin.backend.Main;

import funkin.ui.*;
import funkin.ui.dropdown.*;

import funkin.gameplay.character.Character;
import funkin.gameplay.character.CharacterData;

import funkin.states.menus.MainMenuState;

// this is more of a offset editor than a character editor
// but i'll get to that later when i'm not lazy

@:access(funkin.gameplay.character.Character)
class CharacterEditor extends UIState {
    public var ghostCharacter:Character;
    public var character:Character;
    
    public var camFollow:FlxObject;
    public var cameraMarker:FlxSprite;

    public var panningCamera:Bool = false;
    public var draggingOffsets:Bool = false;
    public var lastMouseVisible:Bool = false;

    public var lastCamPos:FlxPoint = FlxPoint.get(0, 0);

    public var curMousePos:FlxPoint = FlxPoint.get(0, 0);
    public var lastMousePos:FlxPoint = FlxPoint.get(0, 0);
    
    public var camUI:FlxCamera;
    public var grpAnims:FlxTypedContainer<FlxText>;

    public var curSelected:Int = 0;
    public var animList:Array<String> = [];

    public var ghostAnimName:String;

    public var selectCharacterButton:Button;
    public var saveButton:Button;
    public var setGhostButton:Button;

    override function create():Void {
        super.create();
        FlxG.camera.bgColor = FlxColor.GRAY;
        
        #if FLX_MOUSE
        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;
        #end
        camUI = new FlxCamera();
        camUI.bgColor = 0;
        FlxG.cameras.add(camUI, false);

        Main.statsDisplay.visible = false; // it gets in the way

        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        
        cameraMarker = new FlxSprite().loadGraphic(Paths.image("editors/marker"));
        add(cameraMarker);

        grpAnims = new FlxTypedContainer<FlxText>();
        grpAnims.cameras = [camUI];
        add(grpAnims);
        
        var contentPack:String = Paths.getEnabledContentPacks().first();
        if(contentPack == null || contentPack.length == 0)
            contentPack = "default";

        changeCharacter(Constants.DEFAULT_CHARACTER, contentPack.substr(contentPack.lastIndexOf("/") + 1));
        FlxG.camera.follow(camFollow, LOCKON, 1);

        selectCharacterButton = new Button(FlxG.width - 5, 5, "Select Character", 0, 0, showSelectCharacterMenu);
        selectCharacterButton.x -= selectCharacterButton.width;
        selectCharacterButton.cameras = [camUI];
        add(selectCharacterButton);
        
        saveButton = new Button(FlxG.width - 5, FlxG.height - 5, "Save Character", 0, 0, saveCharacter);
        saveButton.x -= saveButton.width;
        saveButton.y -= saveButton.height;
        saveButton.cameras = [camUI];
        add(saveButton);

        setGhostButton = new Button(FlxG.width - 5, saveButton.y - (saveButton.height + 5), "Set As Ghost", 0, 0, setAsGhost);
        setGhostButton.x -= setGhostButton.width;
        setGhostButton.cameras = [camUI];
        add(setGhostButton);
    }

    override function update(elapsed:Float):Void {
        if(FlxG.keys.justPressed.ESCAPE)
            exit();

        if(!UIUtil.isHoveringAnyComponent() && !UIUtil.isAnyComponentFocused()) {
            // animation selection
            if(FlxG.keys.justPressed.W)
                changeSelection(-1);
    
            if(FlxG.keys.justPressed.S)
                changeSelection(1);
    
            if(FlxG.keys.justPressed.SPACE)
                character.playAnim(character.animation.name, DANCE, true);
    
            // camera panning
            if(FlxG.keys.pressed.I || FlxG.keys.pressed.K)
                camFollow.y += elapsed * 30 * ((FlxG.keys.pressed.I) ? -1 : 1);
            
            if(FlxG.keys.pressed.J || FlxG.keys.pressed.L)
                camFollow.x += elapsed * 30 * ((FlxG.keys.pressed.J) ? -1 : 1);
    
            // camera zooming
            if(FlxG.keys.justPressed.Q)
                FlxG.camera.zoom -= 0.1 * FlxG.camera.zoom;
    
            if(FlxG.keys.justPressed.E)
                FlxG.camera.zoom += 0.1 * FlxG.camera.zoom;
    
            // animation offsetting
            if(FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT) {
                final amount:Float = (FlxG.keys.pressed.SHIFT) ? 10 : 1;
                if(FlxG.keys.justPressed.UP)
                    addOffsetToCurAnim(0, -amount);
    
                if(FlxG.keys.justPressed.DOWN)
                    addOffsetToCurAnim(0, amount);
    
                if(FlxG.keys.justPressed.LEFT)
                    addOffsetToCurAnim(-amount, 0);
    
                if(FlxG.keys.justPressed.RIGHT)
                    addOffsetToCurAnim(amount, 0);
            }
            // camera panning (via middle click dragging)
            final pointer = MouseUtil.getPointer();
            if(MouseUtil.isJustPressedMiddle()) {
                panningCamera = true;
                lastCamPos.set(camFollow.x, camFollow.y);
                pointer.getGamePosition(lastMousePos);
            }
            if(MouseUtil.isJustReleasedMiddle())
                panningCamera = false;
            
            if(panningCamera && MouseUtil.wasJustMoved()) {
                pointer.getGamePosition(curMousePos);
                camFollow.setPosition(
                    lastCamPos.x - ((curMousePos.x - lastMousePos.x) / FlxG.camera.zoom),
                    lastCamPos.y - ((curMousePos.y - lastMousePos.y) / FlxG.camera.zoom)  
                );
            } else {
                // animation offsetting (via mouse dragging)
                if(MouseUtil.isJustPressed()) {
                    draggingOffsets = true;
                    lastCamPos.set(character.animation.curAnim.offset.x, character.animation.curAnim.offset.y); // reuse lastCamPos because i don't care fuck you
                    pointer.getGamePosition(lastMousePos);
                }
                if(MouseUtil.isJustReleased())
                    draggingOffsets = false;
                
                if(draggingOffsets && MouseUtil.wasJustMoved()) {
                    pointer.getGamePosition(curMousePos);
                    setOffsetForCurAnim(
                        Std.int(lastCamPos.x - ((curMousePos.x - lastMousePos.x) / character.scale.x / FlxG.camera.zoom)),
                        Std.int(lastCamPos.y - ((curMousePos.y - lastMousePos.y) / character.scale.y / FlxG.camera.zoom))
                    );
                }
                // camera zooming (via mouse wheel)
                FlxG.camera.zoom += MouseUtil.getWheel() * (0.1 * FlxG.camera.zoom);
            }
        }
        super.update(elapsed);
    }

    public function addOffsetToCurAnim(x:Float, y:Float):Void {
        // we subtract because it works in reverse 👍
        final anim:FlxAnimation = character.animation.getByName(animList[curSelected]);
        anim.offset.subtract(x, y);
        
        final arrayOffset:Array<Float> = character.data.animations.get(animList[curSelected]).offset;
        arrayOffset[0] -= x;
        arrayOffset[1] -= y;

        if(animList[curSelected] == ghostAnimName) {
            final ghostAnim:FlxAnimation = ghostCharacter.animation.getByName(ghostAnimName);
            ghostAnim.offset.subtract(x, y);
            
            final ghostArrayOffset:Array<Float> = ghostCharacter.data.animations.get(ghostAnimName).offset;
            ghostArrayOffset[0] -= x;
            ghostArrayOffset[1] -= y;
        }
        grpAnims.members[curSelected].text = '> ${animList[curSelected]} [${anim.offset.x}, ${anim.offset.y}]';
    }

    public function setOffsetForCurAnim(x:Float, y:Float):Void {
        final anim:FlxAnimation = character.animation.getByName(animList[curSelected]);
        anim.offset.set(x, y);

        final arrayOffset:Array<Float> = character.data.animations.get(animList[curSelected]).offset;
        arrayOffset[0] = x;
        arrayOffset[1] = y;

        if(animList[curSelected] == ghostAnimName) {
            final ghostAnim:FlxAnimation = ghostCharacter.animation.getByName(ghostAnimName);
            ghostAnim.offset.set(x, y);

            final ghostArrayOffset:Array<Float> = ghostCharacter.data.animations.get(ghostAnimName).offset;
            ghostArrayOffset[0] = x;
            ghostArrayOffset[1] = y;
        }
        grpAnims.members[curSelected].text = '> ${animList[curSelected]} [${anim.offset.x}, ${anim.offset.y}]';
    }

    public function showSelectCharacterMenu():Void {
        final items:Array<DropDownItemType> = [];
        final characters:Array<String> = [];

        Paths.iterateDirectory("gameplay/characters", (path:String) -> {
            if(!FileSystem.isDirectory(path))
                return;

            final character:String = Path.withoutDirectory(path);
            if(characters.contains(character))
                return;

            final contentPack:String = Paths.getContentPackFromPath(path) ?? "default";
            items.push(Button((contentPack != "default") ? '${contentPack}:${character}' : character, null, () -> changeCharacter(character, contentPack)));
        });
        final dropdown:DropDown = new DropDown(selectCharacterButton.x, selectCharacterButton.y + selectCharacterButton.height, 0, 0, items);
        dropdown.cameras = selectCharacterButton.cameras;

        if(dropdown.x + dropdown.width > selectCharacterButton.x + selectCharacterButton.width)
            dropdown.x = selectCharacterButton.x - (dropdown.width - selectCharacterButton.width);

        add(dropdown);
    }

    public function changeCharacter(characterID:String, ?loaderID:String):Void {
        Paths.forceContentPack = loaderID;

        if(ghostCharacter != null) {
            remove(ghostCharacter, true);
            ghostCharacter.destroy();
        }
        ghostCharacter = new Character(characterID, false, true);
        ghostCharacter.isPlayer = ghostCharacter.data.isPlayer;
        ghostCharacter.color = FlxColor.BLACK;
        ghostCharacter.alpha = 0.4;
        insert(members.indexOf(camFollow), ghostCharacter);

        if(character != null) {
            remove(character, true);
            character.destroy();
        }
        character = new Character(characterID, false, true);
        character.isPlayer = character.data.isPlayer;
        insert(members.indexOf(camFollow), character);
        
        ghostAnimName = character.data.danceSteps.first() ?? "idle";
        ghostCharacter.playAnim(ghostAnimName, DANCE);
        ghostCharacter.animation.finish();

        final pos:FlxPoint = character.getCameraPosition();
        camFollow.setPosition(pos.x, pos.y);
        cameraMarker.setPosition(pos.x - (cameraMarker.width * 0.5), pos.y - (cameraMarker.height * 0.5));
        pos.put();

        reloadAnimList();
        var stateStr:String = 'Editing ${characterID}';
        if(loaderID != null)
            stateStr += ' (${loaderID})';
        
        DiscordRPC.changePresence("Character Editor", stateStr);
    }

    public function saveCharacter():Void {
        File.saveContent(Paths.json('gameplay/characters/${character.characterID}/config'), CharacterData.stringify(character.data));
    }

    public function setAsGhost():Void {
        ghostAnimName = animList[curSelected];

        final ghostAnim:FlxAnimation = ghostCharacter.animation.getByName(ghostAnimName);
        ghostAnim.offset.copyFrom(character.animation.getByName(ghostAnimName).offset);

        ghostCharacter.playAnim(ghostAnimName, DANCE);
        ghostCharacter.animation.finish();
    }

    public function reloadAnimList():Void {
        animList.clear();

        while(grpAnims.length != 0) {
            final first:FlxText = grpAnims.members.first();
            if(first != null) {
                grpAnims.remove(first, true);
                first.destroy();
            }
        }
        grpAnims.clear();
        
        for(animName in character.animation.getNameList()) {
            final anim:FlxAnimation = character.animation.getByName(animName);
            if(anim == null)
                continue;
            
            final lastText:FlxText = grpAnims.members.last();
            final text:FlxText = new FlxText(5, 5 + ((lastText != null) ? lastText.y + (lastText.height - 8) : 0), 0, '${animName} [${anim.offset.x}, ${anim.offset.y}]');
            text.setFormat(Paths.font("fonts/vcr"), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
            text.borderSize = 2;
            grpAnims.add(text);

            animList.push(animName);
        }
        curSelected = animList.indexOf(character.animation.name);
        changeSelection(0, true);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        curSelected = FlxMath.wrap(curSelected + by, 0, grpAnims.length - 1);

        for(i in 0...grpAnims.length) {
            final anim:FlxAnimation = character.animation.getByName(animList[i]);
            if(curSelected == i) {
                grpAnims.members[i].color = FlxColor.CYAN;
                grpAnims.members[i].text = '> ${animList[i]} [${anim.offset.x}, ${anim.offset.y}]';
            }
            else {
                grpAnims.members[i].color = FlxColor.WHITE;
                grpAnims.members[i].text = '${animList[i]} [${anim.offset.x}, ${anim.offset.y}]';
            }
        }
        character.playAnim(animList[curSelected], DANCE, true);
    }

    public function exit():Void {
        FlxG.switchState(MainMenuState.new);
        FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
    }

    override function destroy():Void {
        Paths.forceContentPack = null;

        FlxG.camera.bgColor = FlxColor.BLACK;
        Main.statsDisplay.visible = true;

        lastCamPos = FlxDestroyUtil.put(lastCamPos);

        curMousePos = FlxDestroyUtil.put(curMousePos);
        lastMousePos = FlxDestroyUtil.put(lastMousePos);

        #if FLX_MOUSE
        FlxG.mouse.visible = lastMouseVisible;
        #end
        super.destroy();
    }
}