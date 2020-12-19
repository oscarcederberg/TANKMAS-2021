package states;


import openfl.display.MovieClip;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.events.AsyncErrorEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.utils.Assets;

import ui.Controls;

import flixel.FlxG;

private typedef PlayStatusData = { code:String, duration:Float, position:Float, speed:Float }
private typedef MetaData = { width:Int, height:Int, duration:Float }

class VideoSubstate extends flixel.FlxSubState
{
    var ui:VideoUi;
    var aReleased = false;
    
    public function new(path:String)
    {
        super();
        
        ui = new VideoUi(path);
    }
    
    override function create()
    {
        super.create();
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.pause();
        
        FlxG.stage.addChild(ui);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        ui.update(elapsed);
        
        if (Controls.released.A)
            aReleased = true;
        
        var pressedPause = FlxG.mouse.justPressed || (aReleased && Controls.justPressed.A);
        if (pressedPause)
            ui.togglePause();
        
        var pressedExit = Controls.justPressed.B || ui.requestedExit;
        if (pressedExit)
            close();
    }
    
    override function close()
    {
        FlxG.mouse.useSystemCursor = true;
        FlxG.mouse.visible = true;
        FlxG.stage.removeChild(ui);
        ui.destroy();
        
        super.close();
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.resume();
    }
}

class VideoUi extends openfl.display.Sprite
{
    public var isPaused = false;
    public var requestedExit = false;
    public var onComplete:()->Void;
    
    var netStream:NetStream;
    var video:Video;
    var path:String;
    var backBtn:BackButton;
    var moveTimer = 2.0;
    
    public function new(path:String)
    {
        this.path = path;
        super();
        
        FlxG.mouse.useSystemCursor = true;
        addChild(video = new Video());
        backBtn = new BackButton(()->requestedExit = true);
        addChild(backBtn);
        
        var netConnection = new NetConnection();
        netConnection.connect(null);
        
        netStream = new NetStream(netConnection);
        netStream.client =
            { onMetaData  : onMetaData
            , onPlayStatus: onPlayStatus
            };
        netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, (e)->trace("error loading video"));
        netConnection.addEventListener(NetStatusEvent.NET_STATUS,
            function onNetStatus(event)
            {
                trace("net status:" + haxe.Json.stringify(event.info));
                if (event.info.code == "NetStream.Play.Complete")
                    onVideoComplete();
            }
        );
        
        netStream.play(path);
        isPaused = false;
    }
    
    public function update(elapsed:Float)
    {
        backBtn.update(elapsed);
        if (moveTimer > 0)
        {
            moveTimer -= elapsed;
            if (moveTimer <= 0)
                backBtn.visible = false;
        }
        
        if (FlxG.mouse.justMoved || FlxG.mouse.pressed || isPaused)
        {
            backBtn.visible = true;
            moveTimer = 2.0;
        }
    }
    
    function onMetaData(data:MetaData)
    {
        trace(haxe.Json.stringify(data));
        
        video.attachNetStream(netStream);
        video.width = video.videoWidth;
        video.height = video.videoHeight;
        
        if (video.videoWidth / FlxG.stage.stageWidth > video.videoHeight / FlxG.stage.stageHeight)
        {
            video.width = FlxG.stage.stageWidth;
            video.height = FlxG.stage.stageWidth * video.videoHeight / video.videoWidth;
        }
        else
        {
            video.height = FlxG.stage.stageHeight;
            video.width = FlxG.stage.stageHeight * video.videoWidth / video.videoHeight;
        }
    }
    
    function onPlayStatus(data:PlayStatusData)
    {
        
    }
    
    function onVideoComplete()
    {
        if (onComplete != null)
            onComplete();
    }
    
    public function pause()
    {
        netStream.pause();
        isPaused = true;
    }
    
    public function resume()
    {
        netStream.resume();
        isPaused = false;
    }
    
    public function togglePause()
    {
        isPaused ? resume() : pause();
    }
    
    public function destroy()
    {
        netStream.dispose();
    }
}


private class BackButton extends openfl.display.Sprite
{
    inline static var WIDTH = 27;
    inline static var HEIGHT = 30;
    
    override function get_width():Float return scrollRect.width;
    override function get_height():Float return scrollRect.height;
    
    var frame:Int = 0;
    var callback:()->Void;
    
    public function new(callback:()->Void)
    {
        this.callback = callback;
        super();
        addChild(new Bitmap(Assets.getBitmapData("assets/images/ui/buttons/back.png")));
        scaleX = scaleY = 2;
        scrollRect = new Rectangle(0, 0, WIDTH, HEIGHT);
        useHandCursor = true;
        buttonMode = true;
    }
    
    public function update(elapsed:Float):Void
    {
        var mouseX = this.mouseX - WIDTH * frame;
        var isMouseOver = mouseX > 0 && mouseX < WIDTH && mouseY > 0 && mouseY < HEIGHT;
        if (FlxG.mouse.justPressed && isMouseOver)
            setFrame(1);
        else if (!FlxG.mouse.pressed && frame == 1)
        {
            setFrame(0);
            if (isMouseOver)
                callback();
        }
    }
    
    function setFrame(frame:Int)
    {
        var rect = scrollRect;
        rect.x = rect.width * frame;
        scrollRect = rect;
        this.frame = frame;
    }
    
    public function destroy()
    {
        callback = null;
        removeChildren();
    }
}