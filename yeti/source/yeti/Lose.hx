package yeti;

import ui.Controls;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxState;

class Lose extends FlxState 
{
    var lostTxt:FlxText;
    
    override function create() 
    {
		var msg = "YOU WERE DISEMBOWELED BY THE YETI\n"
            + switch (Controls.mode)
            {
                case Touch: "(tap to try again)"
                case Keys: "(Z to try again)"
                case Gamepad: "(A to try again)"
            }
        lostTxt = new FlxText(0, 0, 0, msg, 16);
        lostTxt.alignment = CENTER;
        lostTxt.color = FlxColor.LIME;
        lostTxt.screenCenter();
        add(lostTxt);
        
        super.create();
    }

    override function update(elapsed:Float) 
    {
        if (Controls.pressed.A)
            Global.switchState(new PlayState());
        
        super.update(elapsed);
    }
}