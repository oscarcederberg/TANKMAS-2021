package states;

import data.Calendar;
import data.NGio;
import data.Save;
import data.PlayerSettings;
import data.Skins;
import ui.Button;
import ui.Controls;
import ui.Prompt;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

import openfl.utils.Assets;

import haxe.Json;

class DressUpSubstate extends flixel.FlxSubState
{
    inline static var BAR_MARGIN = 8;
    inline static var SIDE_GAP = 48;
    inline static var SPACING = 28;
    
    var sprites = new FlxTypedSpriteGroup<SkinDisplay>();
    var current = -1;
    var nameText = new FlxBitmapText();
    var descText = new FlxBitmapText();
    var arrowLeft:Button;
    var arrowRight:Button;
    var ok:OkButton;
    #if LOAD_2020_SKINS
    var play2020:LoadButton;
    #end
    // prevents instant selection
    var wasAReleased = false;
    
    /** Currently, only used if a new skin was seen. */
    var flushOnExit = false;
    
    /** Used to diable input */
    var showingPrompt = false;
    
    var currentSprite(get, never):SkinDisplay;
    inline function get_currentSprite() return sprites.members[current];
    var currentSkin(get, never):SkinData;
    inline function get_currentSkin() return sprites.members[current].data;
    
    override function create()
    {
        super.create();

        camera = new FlxCamera().copyFrom(camera);
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera, false);
        
        var bg = new FlxSprite();
        add(bg);
        add(sprites);
        
        var instructions = new FlxBitmapText();
        instructions.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        instructions.text = "Select an avatar!\nThis is how other players will see you";
        instructions.screenCenter(X);
        instructions.y = 32;
        instructions.scrollFactor.set(0, 0);
        instructions.alignment = CENTER;
        instructions.scale.set(2, 2);
        add(instructions);
        
        createSkinsList();
        
        var top:Float = FlxG.height;
        var bottom:Float = 0;
        for (sprite in sprites)
        {
            top = Math.min(top, sprite.y);
            bottom = Math.max(bottom, sprite.y + sprite.height);
        }
        
        top -= BAR_MARGIN;
        
        nameText.text = currentSkin.proper;
        nameText.screenCenter(X);
        nameText.y = top - nameText.height;
        nameText.scrollFactor.set(0, 0);
        top -= nameText.height + BAR_MARGIN;
        add(nameText);
        
        descText.text = currentSkin.description;
        descText.alignment = CENTER;
        descText.fieldWidth = Std.int(FlxG.width * .75);
        descText.width = descText.fieldWidth;
        descText.height = 1000;
        descText.wordWrap = true;
        descText.screenCenter(X);
        descText.y = bottom + BAR_MARGIN;
        descText.scrollFactor.set(0, 0);
        bottom += descText.height + BAR_MARGIN * 2;
        add(descText);
        
        if (!FlxG.onMobile)
        {
            var keysText = new FlxBitmapText();
            keysText.text = "Arrow Keys to Select, Space to confrim";
            keysText.x = 10;
            keysText.y = FlxG.height - keysText.height;
            keysText.scrollFactor.set(0, 0);
            keysText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            add(keysText);
        }
        
        bg.y = top;
        bg.makeGraphic(FlxG.width, Std.int(bottom - top), 0xFF555555);
        bg.scrollFactor.set(0, 0);
        
        add(arrowLeft  = new Button(0, 0, toPrev, "assets/images/ui/leftArrow.png"));
        arrowLeft.x  = (FlxG.width - arrowLeft.width  - SIDE_GAP - SPACING) / 2;
        arrowLeft.y  = bg.y + (bg.height - arrowLeft.height ) / 2;
        arrowLeft.scrollFactor.set(0, 0);
        add(arrowRight = new Button(0, 0, toNext, "assets/images/ui/rightArrow.png"));
        arrowRight.x = (FlxG.width - arrowRight.width + SIDE_GAP + SPACING) / 2;
        arrowRight.y = bg.y + (bg.height - arrowRight.height) / 2;
        arrowRight.scrollFactor.set(0, 0);
        add(ok = new OkButton(0, 0, select));
        ok.screenCenter(X);
        ok.y = bottom + BAR_MARGIN;
        ok.scrollFactor.set(0, 0);
        
        #if LOAD_2020_SKINS
        add(play2020 = new LoadButton(0, 0, load2020));
        play2020.screenCenter(X);
        play2020.y = bottom + BAR_MARGIN;
        play2020.scrollFactor.set(0, 0);
        play2020.visible = false;
        #end
        
        hiliteCurrent();
    }
    
    public function createSkinsList()
    {
        for (i in 0...Skins.getLength())
        {
            var data = Skins.getDataSorted(i);
            var sprite = new SkinDisplay(data);
            sprites.add(sprite);
            sprite.scale.set(2, 2);
            sprite.updateHitbox();
            sprite.scrollFactor.set(0, 0);
            
            sprite.x = SPACING * i;
            if (data.offset != null)
                sprite.offset.set(data.offset.x, data.offset.y);
            
            if (data.index == PlayerSettings.user.skin)
            {
                current = i;
                sprite.x += SIDE_GAP;
                camera.follow(sprite);
            }
            else if (i > current && current > -1)
                sprite.x += SIDE_GAP * 2;
            
            sprite.y = (FlxG.height - sprites.members[0].height) / 2;
            
            if (!data.unlocked)
                sprite.color = FlxColor.BLACK;
        }
    }
    
    public function resetSkinsList()
    {
        current = -1;
        sprites.x = 0;
        
        while(sprites.length > 0)
            sprites.remove(sprites.members[0], true);
        
        createSkinsList();
        hiliteCurrent();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (showingPrompt)
            return;
        
        if (!wasAReleased && Controls.released.A)
            wasAReleased = true;
        
        if (Controls.justPressed.RIGHT)
            toNext();
        if (Controls.justPressed.LEFT)
            toPrev();
        if (Controls.justPressed.A && wasAReleased)
            select();
        if (Controls.justPressed.B)
            close();
    }
    
    function toNext():Void
    {
        if(current >= sprites.length - 1)
            return;
        
        unhiliteCurrent();
        currentSprite.x -= SIDE_GAP;
        current++;
        currentSprite.x -= SIDE_GAP;
        hiliteCurrent();
    }
    
    function toPrev():Void
    {
        if(current <= 0)
            return;
        
        unhiliteCurrent();
        currentSprite.x += SIDE_GAP;
        current--;
        currentSprite.x += SIDE_GAP;
        hiliteCurrent();
    }
    
    function unhiliteCurrent()
    {
        currentSprite.unseen.visible
            = currentSkin.unlocked && !Save.hasSeenSkin(currentSkin.index);
    }
    
    function hiliteCurrent()
    {
        sprites.x = (current+1) * -SPACING - BAR_MARGIN*2 + (FlxG.width - currentSprite.width) / 2;
        
        #if LOAD_2020_SKINS play2020.visible = false; #end
        if (currentSkin.unlocked)
        {
            nameText.text = currentSkin.proper;
            descText.text = currentSkin.description;
            ok.active = true;
            ok.alpha = 1;
            if (Save.hasSeenSkin(currentSkin.index) == false && Calendar.isDebugDay == false)
            {
                Save.skinSeen(currentSkin.index, false);
                flushOnExit = true;
            }
        }
        else
        {
            nameText.text = "???";
            final KEEP_PLAYING = "Keep playing every day to unlock";
            final LOGIN = "Log in to Newgrounds to unlock this";
            descText.text = KEEP_PLAYING;
            if (currentSkin.year == 2020)
            {
                #if LOAD_2020_SKINS play2020.visible = true; #end
                if (Save.hasSave2020())
                    descText.text = "Play more Tankmas ADVENTure 2020 to unlock this";
                else
                    descText.text = "Play Tankmas ADVENTure 2020 to unlock this";
            }
            else if (currentSkin.unlocksBy != null)
            {
                descText.text = switch (currentSkin.unlocksBy.split(":"))
                {
                    case ["login"    ]: LOGIN;
                    case ["medal", day]: NGio.isLoggedIn ? KEEP_PLAYING : LOGIN;
                    case ["supporter"]: "Become a newgrounds supporter to unlock this";
                    default: KEEP_PLAYING;
                }
            }
            ok.active = false;
            ok.alpha = 0.5;
        }
        ok.visible = #if LOAD_2020_SKINS !play2020.visible #else true #end;
        nameText.screenCenter(X);
        descText.screenCenter(X);
    }
    
    function select():Void
    {
        #if LOAD_2020_SKINS
        if (play2020.visible)
        {
            load2020();
            return;
        }
        #end
        
        if (currentSkin.unlocked)
        {
            Save.setSkin(currentSkin.index);
            close();
        }
    }

    override function close()
    {
        FlxG.cameras.remove(camera);
        if (flushOnExit)
            Save.flush();
        
        super.close();
    }
    
    #if LOAD_2020_SKINS
    function load2020()
    {
        var prompt = new Prompt();
        add(prompt);
        
        showingPrompt = true;
        function removePrompt()
        {
            showingPrompt = false;
            remove(prompt);
        }
        
        var url = "https://www.newgrounds.com/portal/view/773236";
        prompt.setupYesNo
        ( 'Open Tankmas2020?\n${prettyUrl(url)}'
        ,   function onYes()
            {
                FlxG.openURL(url);
                
                var firstTimePlaying = Save.hasSave2020() == false;
                if (firstTimePlaying)
                    prompt.setupTextOnly("Checking for Tankmas 2020 data, be sure to load the bedroom");
                else
                    prompt.setupTextOnly("Checking for any new skins...");
                
                NGio.update2020SkinData((outcome)->switch (outcome)
                {
                    case SUCCESS:
                        var oldSkinsCount = Skins.numUnlocked;
                        Skins.checkUnlocks(false);
                        resetSkinsList();
                        if (firstTimePlaying)
                            prompt.setupOk("Load Successful, Enjoy!", removePrompt);
                        else
                        {
                            final newSkins = Skins.numUnlocked - oldSkinsCount;
                            if (newSkins == 0)
                                prompt.setupOk("No new skins unlocked.", removePrompt);
                            else
                                prompt.setupOk('$newSkins new skins unlocked!', removePrompt);
                        }
                    case FAIL(error):
                        prompt.setupOk("Could not find 2020 save data, please try again", removePrompt);
                });
            }
        , function onNo() removePrompt()
        );
    }
    
    static function prettyUrl(url:String)
    {
        if (url.indexOf("://") != -1)
            url = url.split("://").pop();
        
        return url.split("default.aspx").join("");
    }
    #end
}

class SkinDisplay extends FlxSprite
{
    public final data:SkinData;
    public final unseen:FlxSprite;
    
    public function new (data:SkinData, x = 0.0, y = 0.0)
    {
        this.data = data;
        super(x, y);
        
        data.loadTo(this);
        unseen = new FlxSprite("assets/images/ui/new.png");
        unseen.visible = data.unlocked && !Save.hasSeenSkin(data.index);
    }
    
    override function draw()
    {
        super.draw();
        if (unseen.visible)
        {
            unseen.x = x + offset.x + 10 + (width - unseen.width) / 2;
            unseen.y = y;
            unseen.draw();
        }
    }
}