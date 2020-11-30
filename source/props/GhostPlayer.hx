package props;

import ui.Font;
import flixel.text.FlxBitmapText;
import flixel.math.FlxPoint;

import io.colyseus.serializer.schema.Schema;

class GhostPlayer extends Player
{
    var key:String;
    var name:String;
    var nameText:FlxBitmapText;
    
    public function new(key:String, name:String, x = 0.0, y = 0.0, settings)
    {
        this.key = key;
        super(x, y, settings);
        
        targetPos = FlxPoint.get(this.x, this.y);
        nameText = new FlxBitmapText();
        nameText.alignment = CENTER;
        updateNameText(name);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        updateMovement(false, false, false, false, false);
    }
    
    override function draw()
    {
        super.draw();
        if (nameText.visible)
        {
            nameText.x = x + (width - nameText.width) / 2;
            nameText.y = y + height - frameHeight - nameText.height;
            nameText.draw();
        }
    }
    
    public function onChange(changes:Array<DataChange>)
    {
        trace('avatar changes[$key] ' 
            + ([for (change in changes) outputChange(change)].join(", "))
        );
        
        var oldState = state;
        var newPos = FlxPoint.get(x + width / 2, y + height / 2);
        var isMoving = false;
        
        for (change in changes)
        {
            switch (change.field)
            {
                case "x":
                    newPos.x = Std.int(change.value);
                    isMoving = true;
                case "y":
                    newPos.y = Std.int(change.value);
                    isMoving = true;
                case "skin":
                    settings.skin = change.value;
                    setSkin(change.value);
                case "state":
                    state = change.value;
                case "name":
                    updateNameText(change.value);
            }
        }
        
        if (state != oldState && oldState == Joining)
        {
            x = newPos.x;
            y = newPos.y;
            targetPos = FlxPoint.get(x, y);
        }
        else if (isMoving)
        {
            trace('moving to $newPos');
            setTargetPos(newPos);
        }
        newPos.put();
    }
    
    function updateNameText(name:String)
    {
        nameText.text = name == null ? "" : name;
        nameText.visible = name != null;
        this.name = name;
    }
    
    inline function outputChange(change:DataChange)
    {
        return change.field + ":" + change.previousValue + "->" + change.value;
    }
}