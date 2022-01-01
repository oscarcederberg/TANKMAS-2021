package yeti;

import ui.Controls;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxAssets;
import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxNestedSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;

class PlayState extends FlxState
{
	var yeti:Yeti;
	var loseJingle:FlxSound = new FlxSound();

	var player:Player;

	var board:FlxNestedSprite;
	var spots:FlxTypedGroup<Icicle>;

	var tileSeq:Array<LightColor> = [];
	var allColors:Array<LightColor> = [RED, BLUE, GREEN];
	var seqMax:Int = 2;
	var seqTimer:FlxTimer = new FlxTimer();

	var score:Int = 0;
	var multiplier:Int = 1;
	var scoreText:FlxText;

	var lightsShown:Int = 0;
	var lightShowTime:Float = 0.5;

	var iSpot:Int = 0;

	var dead:Bool = false;

	override function create()
	{
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Global.asset('assets/music/play_theme.mp3'), 0.35);

		loseJingle.loadEmbedded(Global.asset("assets/sounds/lose_jingle.mp3"), false, false);

		var bg = new FlxSprite(Global.asset('assets/images/bg.png'));
		add(bg);

		spots = new FlxTypedGroup<Icicle>();
		add(spots);

		player = new Player();
		add(player);

		yeti = new Yeti(0, 0, player);
		yeti.screenCenter();
		add(yeti);

		board = new FlxNestedSprite(0, -20, Global.asset('assets/images/board.png'));
		board.screenCenter(X);
		for (i in 0...3)
		{
			var s = new Display(switch i
			{
				case 0: RED;
				case 1: BLUE;
				case 2: GREEN;
				default: RED;
			});
			s.relativeX = switch i
			{
				case 0: 10;
				case 1: 24;
				case 2: 38;
				default: 0;
			};
			s.relativeY = 10;

			board.add(s);
			s.visible = false;
		}
		add(board);

		scoreText = new FlxText(Global.width - 16, 0, 0, 'score: ${score}\n bonus: ${multiplier}');
		scoreText.x = Global.width - (scoreText.width + 5);
		add(scoreText);

		FlxTween.tween(board, {y: 0}, 1.8, {
			onComplete: (_) -> pickSequence(),
			ease: FlxEase.elasticInOut
		});

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (!dead)
		{
			FlxSpriteUtil.bound(yeti, 0, Global.width, 0, Global.height);
			FlxSpriteUtil.bound(player, 0, Global.width, 0, Global.height);

			scoreText.text = 'score: ${score}\nbonus: ${multiplier}';

			FlxG.overlap(player, spots, executeSpotOverlap, processSpotOverlap);
			FlxG.overlap(player, yeti, executeYetiKill, function(p:Player, y:Yeti)
			{
				return y.state == y.hunt;
			});
		}

		if (dead && Controls.pressed.A)
			resetState();
		
		super.update(elapsed);
	}
	
	function resetState()
	{
		FlxG.sound.music = null;
		loseJingle.stop();
		Global.resetState();
	}

	function executeYetiKill(player:Player, y:Yeti)
	{
		if (!loseJingle.playing)
		{
			FlxG.sound.music.stop();

			forEach((child) ->
			{
				child.active = false;
				FlxTween.cancelTweensOf(child);
			}, true);

			var msg = "YOU WERE DISEMBOWELED BY THE YETI\n" + switch (Controls.mode)
			{
				case Touch: "(tap to try again)"; // not implemented
				case Keys: "(Z to try again)";
				case Gamepad: "(A to try again)";
			}
			var loseText:FlxText = new FlxText(0, 0, 0, msg, 16);
			loseText.alignment = CENTER;
			loseText.scale.set(0.1, 0.1);
			loseText.visible = false;
			loseText.screenCenter();
			loseText.color = tileSeq[iSpot];
			add(loseText);
			#if ADVENT
			data.NGio.postPlayerHiscore("yeti", score);
			#end

			FlxTween.tween(loseText, {'scale.x': 1, 'scale.y': 1}, 0.4, {
				onStart: (_) ->
				{
					loseText.visible = dead = true;
				},
				// onUpdate: (_) -> if (Controls.pressed.A) resetState(),
				ease: FlxEase.quadIn
			});

			loseJingle.play();
		}
	}

	function executeSpotOverlap(p:Player, s:Icicle)
	{
		s.allowCollisions = NONE;
		s.animation.finishCallback = (n) ->
		{
			if (n == 'shatter')
				s.kill();
			if (spots.getFirstAlive() == null)
			{
				FlxG.sound.play(Global.asset('assets/sounds/win_jingle.mp3'), 0.5);
				yeti.animation.play('freeze', true);
				score += multiplier;
				#if ADVENT
				if (score > 40)
					data.NGio.unlockMedalByName('yeti_doctorate');
				else if (score > 30)
					data.NGio.unlockMedalByName('yeti_masters_degree');
				else if (score > 15)
					data.NGio.unlockMedalByName('yeti_degree');
				#end
				lightShowTime += 0.05;
				multiplier++;

				returnBoard();
			}
		}
		s.animation.play('shatter');
		FlxG.sound.play(Global.asset('assets/sounds/shatter.mp3'), 1);
		iSpot++;
	}

	function processSpotOverlap(p:Player, s:Icicle):Bool
	{
		if (s.clr == tileSeq[iSpot] && s.index == iSpot)
		{
			return true;
		}
		else
		{
			if (seqMax > 1)
				seqMax--;
			lightShowTime -= 0.05;

			tileSeq = [];
			multiplier = 1;
			returnBoard();
			for (i in spots)
				i.kill();

			return false;
		}
	}

	function pickSequence()
	{
		FlxG.random.shuffle(allColors);
		// tileSeq = [];

		for (i in (tileSeq.length - 1)...seqMax)
			tileSeq.push(FlxG.random.getObject(allColors));

		if (seqMax < 26)
			seqMax++;

		playBoard();
	}

	function playBoard(?_:FlxTimer)
	{
		for (light in board.children)
		{
			var l:Display = cast light;
			if (l.clr == tileSeq[lightsShown] && !light.visible)
			{
				l.sf.play(true);
				l.visible = true;
				break;
			}
		}

		seqTimer.start(lightShowTime, (_) ->
		{
			for (i in board.children)
				if (i.visible)
					i.visible = false;

			if (lightsShown < tileSeq.length)
				seqTimer.start(lightShowTime, playBoard);
			else
			{
				seqTimer.start(lightShowTime, (_) ->
				{
					for (i in board.children)
						i.visible = false;
					lightsShown = 0;

					lightShowTime -= 0.05;
					FlxTween.tween(board, {y: -board.width}, 1.75, {
						onComplete: (_) -> boardFinished(),
						ease: FlxEase.elasticIn
					});
				});
			}
		});

		lightsShown++;
	}

	function boardFinished()
	{
		yeti.animation.play('thaw', true);
		var dupls:Int = 0;
		var prevClr:LightColor = tileSeq[0];

		var colorInsts = [RED => 0, BLUE => 0, GREEN => 0];

		for (i in 0...tileSeq.length)
		{
			colorInsts[tileSeq[i]]++;
			if (i > 0 && tileSeq[i] == prevClr)
				dupls++;
			else
				dupls = 0;

			var vi:Null<Int> = if (dupls != 0) colorInsts[tileSeq[i]] else if (dupls == 0 && colorInsts[tileSeq[i]] <= 1) null else colorInsts[tileSeq[i]];

			var spt = spots.recycle(Icicle, () -> new Icicle(FlxG.random.int(0, 15) * 30, FlxG.random.int(0, 8) * 30, i, vi));
			if (spt.used)
			{
				spt.setPosition((FlxG.random.int(0, 15) * 30), (FlxG.random.int(0, 8) * 30));
				spt.index = i;
				spt.txt.text = vi != null ? Std.string(vi) : ' ';
			}

			spt.color = spt.clr = tileSeq[i];
			spots.add(spt);
			spt.animation.finishCallback = (n:String) -> if (n == 'emerge') spt.allowCollisions = ANY;
			spt.animation.play('emerge');
			prevClr = tileSeq[i];
		}
	}

	function returnBoard()
	{
		if (spots.getFirstAlive() == null)
			yeti.state = yeti.waitForStart;

		iSpot = 0;
		FlxTween.tween(board, {y: 0}, 0.8, {
			onComplete: (_) -> pickSequence(),
			ease: FlxEase.elasticInOut
		});
	}
}

class Display extends FlxNestedSprite
{
	public var clr:LightColor;
	public var sf:FlxSound;

	public function new(clr:LightColor)
	{
		super(0, 0, Global.asset('assets/images/circle_display.png'));
		color = this.clr = clr;
		sf = new FlxSound().loadEmbedded(Global.asset('assets/sounds/lights/${clr}.mp3'));
		sf.volume = 0.55;
	}
}

class Icicle extends FlxNestedSprite
{
	public var index:Int;
	public var clr:LightColor;
	public var used:Bool = false;

	public var txt:FlxNestedText;

	public function new(x:Float, y:Float, ?index:Int, ?visualIndex:Int)
	{
		super(x, y);
		loadGraphic(Global.asset('assets/images/icicle.png'), true, 30, 30);
		animation.add('emerge', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 15, false);
		animation.add('shatter', [10, 11, 12, 13, 14], 15, false);
		this.index = index;
		setSize(16, 16);
		centerOffsets(true);

		txt = new FlxNestedText(0, 0, 0, visualIndex != null ? Std.string(visualIndex) : ' ', 8);
		txt.relativeX = (width / 2) - (txt.width / 2);
		txt.relativeY = (height / 2) - (txt.height / 2);
		add(txt);
	}

	override function kill()
	{
		used = true;
		super.kill();
	}
}

enum abstract LightColor(FlxColor) to FlxColor
{
	var RED = FlxColor.RED;
	var BLUE = FlxColor.BLUE;
	var GREEN = FlxColor.GREEN;

	@:to function toString()
	{
		return switch (this)
		{
			case RED: 'red';
			case BLUE: 'blue';
			case GREEN: 'green';
			default: 'unmatched';
		}
	}
}
