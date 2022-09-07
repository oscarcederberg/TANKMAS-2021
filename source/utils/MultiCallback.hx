package utils;

import io.newgrounds.objects.events.ResultType;

class MultiCallback
{
    public var callback:()->Void;
    public var logId:String = null;
    public var length(default, null) = 0;
    public var numRemaining(default, null) = 0;
    
    var unfired = new Map<String, ()->Void>();
    var fired = new Array<String>();
    
    public function new (callback:()->Void, logId:String = null)
    {
        this.callback = callback;
        this.logId = logId;
    }
    
    public function add(id = "untitled")
    {
        id = '$length:$id';
        length++;
        numRemaining++;
        var func:()->Void = null;
        func = function ()
        {
            if (unfired.exists(id))
            {
                unfired.remove(id);
                fired.push(id);
                numRemaining--;
                
                if (logId != null)
                    log('fired $id, $numRemaining remaining');
                
                if (numRemaining == 0)
                {
                    if (logId != null)
                        log('all callbacks fired');
                    callback();
                }
            }
            else
                log('already fired $id');
        }
        unfired[id] = func;
        return func;
    }
    
    inline function log(msg):Void
    {
        if (logId != null)
            trace('$logId: $msg');
    }
    
    public function getFired() return fired.copy();
    public function getUnfired() return [for (id in unfired) id];
}

class ResultMultiCallback<T>
{
    public var callback:(ResultType<T>)->Void;
    public var logId:String = null;
    public var length(default, null) = 0;
    public var numRemaining(default, null) = 0;
    
    var finalResult:ResultType<T> = SUCCESS;
    var unfired = new Map<String, (ResultType<T>)->Void>();
    var fired = new Array<String>();
    
    public function new (callback:(ResultType<T>)->Void, ?logId:String)
    {
        this.callback = callback;
        this.logId = logId;
    }
    
    public function add(id = "untitled")
    {
        id = '$length:$id';
        length++;
        numRemaining++;
        var func:(ResultType<T>)->Void = null;
        func = function (result)
        {
            if (unfired.exists(id))
            {
                unfired.remove(id);
                fired.push(id);
                numRemaining--;
                
                switch(result)
                {
                    case FAIL(error) if (finalResult.match(SUCCESS)):
                        finalResult = result;
                    case _://nothing
                }
                
                if (logId != null)
                    log('fired $id, $numRemaining remaining');
                
                if (numRemaining == 0)
                {
                    if (logId != null)
                        log('all callbacks fired');
                    callback(finalResult);
                }
            }
            else
                log('already fired $id');
        }
        unfired[id] = func;
        return func;
    }
    
    inline function log(msg):Void
    {
        if (logId != null)
            trace('$logId: $msg');
    }
    
    public function getFired() return fired.copy();
    public function getUnfired() return [for (id in unfired) id];
}