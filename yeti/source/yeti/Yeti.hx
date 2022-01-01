package yeti;

import flixel.util.FlxSignal;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.math.FlxVelocity;
import flixel.math.FlxVector;
import flixel.addons.display.FlxNestedSprite;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

typedef YetiState = Float->Void;

class Yeti extends FlxSprite
{
	var acl:Float = 15.5;
	var maxAcl:Float = 115.75;

	public var oldState:YetiState;
	public var state(default, set):YetiState;

	var playerRef:FlxSprite;
	var target:FlxPoint;

	var sliceTime:Float = 0;
	var timed:Float = 23;

	public function new(x:Float = 0, y:Float = 0, player:FlxSprite)
	{
		super(x, y);
		loadGraphic(Global.asset("assets/images/yeti.png"), true, 48, 64);
		setFacingFlip(LEFT, false, false);
		setFacingFlip(RIGHT, true, false);

		var fps = 20;
		animation.add('hunt', [0, 1, 2, 3, 4], fps);
		animation.add('freeze', [12, 13, 14, 15, 16, 17, 18, 19], fps, false);
		animation.add('thaw', [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35], fps, false);
		animation.add('idle', [36, 37, 38, 39, 40, 41, 42, 43], fps);
		animation.finishCallback = finishAnim;
		animation.play('freeze');

		setSize(18, 28);
		offset.set(14, 19);
		drag.set(500, 500);

		state = waitForStart;

		playerRef = player;
		target = playerRef.getMidpoint(target);
	}

	override function update(elapsed:Float)
	{
		state(elapsed);
		super.update(elapsed);
	}

	public function hunt(elapsed:Float)
	{
		animation.play('hunt');
		facing = velocity.x < 0 ? LEFT : RIGHT;

		sliceTime += elapsed;

		if (sliceTime <= timed)
		{
			sliceTime = 0;
			target.put();

			target = playerRef.getMidpoint();
		}

		var toPlyrVec:FlxVector = FlxVector.get(target.x - (x + (width / 2)), target.y - (y + (height / 2)));
		FlxVelocity.accelerateFromAngle(this, toPlyrVec.radians, acl, maxAcl, false);
		toPlyrVec.put();
	}

	public function waitForStart(elapsed:Float)
	{
		acceleration.set(0, 0);
	}

	function set_state(v:YetiState)
	{
		oldState = state;

		if (v == waitForStart)
		{
			acl += 5.5;
			maxAcl += 1.35;

			timed += 3.5;
		}

		return state = v;
	}

	function finishAnim(name:String)
	{
		if (name == 'freeze')
		{
			animation.stop();
			FlxTween.color(this, 0.5, FlxColor.WHITE, FlxColor.BLUE, {
				// onComplete: (_) -> state = waitForStart
			});
		}
		else if (name == 'thaw')
		{
			FlxTween.color(this, 0.05, FlxColor.BLUE, FlxColor.WHITE, {
				onComplete: (_) -> state = hunt
			});
		}
	}
}
