package data;


import io.newgrounds.NG;
import data.Calendar;
import flixel.FlxSprite;

import openfl.utils.Assets;

import haxe.Json;
using StringTools;

class Skins
{
    static var byIndex:Array<SkinData>;
    static var sorted:Array<SkinData>;
    
    static function init()
    {
        if (byIndex != null)
            throw "Skins already initted";
        
        byIndex = Json.parse(Assets.getText("assets/data/skins.json"));
        byIndex.pop();//custom
        sorted = byIndex.copy();
        for (i in 0...byIndex.length)
        {
            byIndex[i].index = i;
            byIndex[i].unlocked = #if UNLOCK_ALL_SKINS true #else false #end;
        }
        
        checkUnlocks();
    }
    
    static public function checkUnlocks()
    {
        for (data in byIndex)
        {
            if (!data.unlocked)
                data.unlocked = checkUser(data.users) || checkUnlockCondition(data.unlocksBy);
        }
        
        sorted.sort(function (a, b)
            {
                if (a.unlocked == b.unlocked)
                    return a.index - b.index;
                return (a.unlocked ? 0 : 1) - (b.unlocked ? 0 : 1);
            }
        );
    }
    
    static function checkUser(users:Array<String>)
    {
        return users != null && NGio.isLoggedIn && users.contains(NGio.userName.toLowerCase());
    }
    
    static function checkUnlockCondition(data:String)
    {
        if (data == null)
            return false;
        
        if (data.indexOf(",") != -1)
        {
            // check many
            var conditions = data.split(",");
            while (conditions.length > 0)
            {
                if (checkUnlockCondition(conditions.shift()))
                    return true;
            }
            return false;
        }
        
        // check lone
        return switch(data.split(":"))
        {
            case ["login"    ]: NGio.isLoggedIn;
            case ["free"     ]: true;
            case ["supporter"]: NGio.isLoggedIn && NG.core.user.supporter;
            case [_]: throw "Unhandled unlockBy:" + data;
            case ["day"  , day  ]: Save.countDaysSeen() >= Std.parseInt(day);
            case ["medal", medal]: NGio.hasDayMedal(Std.parseInt(medal));
            default: throw "Unhandled unlockBy:" + data;
        }
    }
    
    static public function getData(id:Int)
    {
        if (byIndex == null)
            init();
        
        if (id < 0 || byIndex.length <= id)
            throw "Invalid id:" + id;
        
        return byIndex[id];
    }
    
    static public function getDataSorted(id:Int)
    {
        if (sorted == null)
            init();
        
        if (id < 0 || sorted.length <= id)
            throw "Invalid id:" + id;
        
        return sorted[id];
    }
    
    static public function getLength()
    {
        if (byIndex == null)
            init();
        
        return byIndex.length;
    }
}

typedef SkinDataRaw =
{
    var id:String;
    var proper:String;
    var description:String;
    var unlocksBy:String;
    var frames:Null<Int>;
    var fps:Null<Int>;
    var offsetX:Null<Float>;
    var offsetY:Null<Float>;
    var users:Null<Array<String>>;
}

typedef SkinDataPlus = SkinDataRaw &
{
    var index:Int;
    var unlocked:Bool;
}

@:forward
abstract SkinData(SkinDataPlus) from SkinDataPlus to SkinDataPlus
{
    public var path(get, never):String;
    inline function get_path() return 'assets/images/player/${this.id}.png';
    
    public function loadTo(sprite:FlxSprite)
    {
        sprite.loadGraphic(path);
        if (this.frames != null && this.frames > 1)
        {
            sprite.loadGraphic(path, true, Std.int(sprite.frameWidth / this.frames), sprite.frameHeight);
            sprite.animation.add("default", [for (i in 0...this.frames) i], this.fps != null ? this.fps : 8);
            sprite.animation.play("default");
        }
    }
}