package states.rooms;

import props.Character;
import js.html.CharacterData;
import data.Skins;
import props.Notif;
import data.Manifest;
import states.OgmoState;
import data.Calendar;
import data.Game;
import data.Content;
import props.Cabinet;
import ui.Prompt;

import flixel.FlxG;
import flixel.math.FlxMath;

class PicosShopState extends RoomState
{
    var changingRoom:OgmoDecal;
    var changingRoomNotif:Notif;
    var pico:Character; 
    
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();

        pico = new Character("pico", foreground.getByName("pico"));
        addHoverTextTo(foreground.getByName("pico"), "TALK", () -> pico.talk());
        
        changingRoom = foreground.getByName("changing-room-door");
        changingRoom.setBottomHeight(16);
        addHoverTextTo(changingRoom, "CHANGE CLOTHES", onOpenDresser);
        changingRoomNotif = new Notif();
        changingRoomNotif.x = changingRoom.x + (changingRoom.width - changingRoomNotif.width) / 2;
        changingRoomNotif.y = changingRoom.y + changingRoom.height - changingRoom.frameHeight;
        changingRoomNotif.animate();
        topGround.add(changingRoomNotif);
        
        if (!Skins.checkHasUnseen())
            changingRoomNotif.kill();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
    
    function onOpenDresser()
    {
        changingRoomNotif.visible = false;
        var dressUp = new DressUpSubstate();
        dressUp.closeCallback = function()
        {
            player.settings.applyTo(player);
        }
        openSubState(dressUp);
    }
}