package;

import flixel.FlxG;
import flixel.FlxGame;

import ui.Controls;

import openfl.display.Sprite;

#if ADVENT
import utils.OverlayGlobal as Global;
#else
import utils.Global;
#end

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(480, 270, BootState));
	}
}

class BootState extends flixel.FlxState
{
	override function create()
	{
		super.create();
		
		Controls.init();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		Global.switchState(new #if SHARE RecordIntroState #else yeti.PlayState #end());
	}
}