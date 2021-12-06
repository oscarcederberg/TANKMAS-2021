package data;

import haxe.Json;
import openfl.utils.Assets;

class Dialogue{
    public static var characters:Array<String> = ["pico"];
    public static var contentByCharacter:Map<String, DialogueContent>;

    public static function init(){
        contentByCharacter = new Map();
        for(character in characters){
            var content:DialogueContent = Json.parse(Assets.getText('assets/data/dialogue/$character.json'));
            contentByCharacter.set(character, content);
        }
    }
}

typedef DialogueContent = Array<DialogueMessage>;

typedef DialogueMessage = {
    var text:Array<String>;
    var weight:Float;
    var fromDay:Int;
    var toDay:Int;
}