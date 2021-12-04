package props;

import flixel.FlxG;
import states.OgmoState.OgmoDecal;
import data.Dialogue;
import data.Dialogue.DialogueContent;

class Character{
    public var name:String;
    public var decal:OgmoDecal;
    public var dialogues:DialogueContent;
    private var weightedArray:Array<Float>;
    public var dialogueBuffer:List<String>;

    public function new(name:String, decal:OgmoDecal){
        this.name = name;
        this.decal = decal;
        this.dialogues = Dialogue.contentByCharacter.get(name);
        
        this.weightedArray = [for (message in this.dialogues) message.weight];
        this.dialogueBuffer = new List<>();
    }

    public function talk(){
        if(dialogueBuffer.isEmpty()){
            var messageIndex = FlxG.random.weightedPick(weightedArray);
            var messages = dialogues[messageIndex].text;
            for(message in messages){
                dialogueBuffer.add(message);
            }
        }
    }
}