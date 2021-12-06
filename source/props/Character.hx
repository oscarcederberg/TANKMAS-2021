package props;

import ui.Prompt;
import data.NGio;
import flixel.FlxG;
import states.OgmoState.OgmoDecal;
import data.Dialogue;

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
        this.dialogueBuffer = new List();
    }

    public function talk(){        
        if(dialogueBuffer.isEmpty()){
            populateDialogueBuffer();
        }

        var text = dialogueBuffer.pop();
        Prompt.showOKInterrupt(text);
    }

    private function populateDialogueBuffer(){
        var messageIndex:Int;
        var myWeightedArray = this.weightedArray;
        var currentDay = NGio.ngDate.getDate();
        var messages:Array<String> = []; 
        
        while(true){
            messageIndex = FlxG.random.weightedPick(myWeightedArray);
            messages = dialogues[messageIndex].text;

            if(currentDay >= dialogues[messageIndex].fromDay && currentDay <= dialogues[messageIndex].toDay){
                break;
            }else{
                myWeightedArray[messageIndex] = 0;
            }
        }

        for(message in messages){
            dialogueBuffer.add(message);
        }
    }
}