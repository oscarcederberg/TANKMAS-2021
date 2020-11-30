package;

import states.rooms.RoomState;

class Main extends openfl.display.Sprite
{
	public static var initialRoom(default, null) = 
		#if debug
		RoomName.Bedroom;
		// (RoomName.Hallway:String) + ".0";
		// (RoomName.Entrance:String) + ".0";
		#else
		RoomName.Bedroom;
		#end
	public function new()
	{
		super();
		// addChild(new flixel.FlxGame(240, 135, states.BootState));
		addChild(new flixel.FlxGame(480, 270, states.BootState));
		// addChild(new flixel.FlxGame(960, 540, states.BootState));
	}
}
