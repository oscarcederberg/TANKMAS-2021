package data;

import data.Content;
import states.rooms.RoomState;

import io.newgrounds.NG;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.events.ResultType;
import io.newgrounds.utils.MedalList;

import utils.Log;
import utils.BitArray;
import utils.MultiCallback;

import flixel.FlxG;
import flixel.util.FlxSave;

import haxe.Int64;
import haxe.Json;
import haxe.PosInfos;

class Save
{
    static var emptyData:SaveData = cast {}
    
    static var save:FlxSave;
    static var data:SaveData;
    static var data2020:SaveData2020;
    static var medals2020:ExternalMedalList;
    static public var showName(get, set):Bool;
    
    static public function init(callback:(ResultType<String>)->Void)
    {
        #if DISABLE_SAVE
            data = emptyData;
        #else
            NG.core.saveSlots.loadAllFiles
            (
                function (result)
                {
                    switch (result)
                    {
                        case SUCCESS: onCloudSavesLoaded(callback);
                        case FAIL(error): callback(result);
                    }
                }
            );
        #end
    }
    
    static function onCloudSavesLoaded(callback:(ResultType<String>)->Void)
    {
        #if CLEAR_SAVE
        createInitialData();
        flush();
        #else
        if (NG.core.saveSlots[1].isEmpty())
        {
            createInitialData();
            mergeLocalSave();
            flush();
        }
        else
            data = Json.parse(NG.core.saveSlots[1].contents);
        #end
        
        log("presents: " + data.presents);
        log("seen days: " + data.days);
        log("seen skins: " + data.skins);
        log("skin: " + data.skin);
        log("instrument: " + data.instrument);
        log("instruments seen: " + data.seenInstruments);
        log("saved session: " + data.showName);
        log("saved order: " + (data.cafeOrder == null ? "random" : data.cafeOrder));
        
        function setInitialInstrument()
        {
            var instrument = getInstrument();
            if (instrument != null)
                Instrument.setCurrent();
        }
        
        if (Content.isInitted)
            setInitialInstrument();
        else
            Content.onInit.addOnce(setInitialInstrument);
        
        #if LOAD_2020_SKINS
        load2020Data(callback);
        #else
        callback(SUCCESS);
        #end
    }
    
    static function createInitialData()
    {
        data = cast {};
        data.presents        = new BitArray();
        data.days            = new BitArray();
        data.skins           = new BitArray();
        data.seenInstruments = new BitArray();
        data.skin            = 0;
        data.instrument      = -1;
        data.showName        = false;
        data.seenYeti        = false;
        data.cafeOrder       = null;
    }
    
    static function mergeLocalSave()
    {
        var save = new FlxSave();
        if (save.bind("advent2021", "GeoKureli") && save.isEmpty() == false)
        {
            for (field in Reflect.fields(save.data))
                Reflect.setField(data, field, Reflect.field(save.data, field));
            
            save.erase();
        }
    }
    
    static function parseLocalSave(data:SaveData)
    {
        if (BitArray.isOldFormat(data.presents))
            data.presents = BitArray.fromOldFormat(cast data.presents);
            
        if (BitArray.isOldFormat(data.days))
            data.days = BitArray.fromOldFormat(cast data.days);
        
        if (BitArray.isOldFormat(data.skins))
            data.skins = BitArray.fromOldFormat(cast data.skins);
        
        if (BitArray.isOldFormat(data.seenInstruments))
            data.seenInstruments = BitArray.fromOldFormat(cast data.seenInstruments);
        
        if (data.instrument < -1 && data.seenInstruments.countTrue() > 0)
        {
            // fix an old glitch where i deleted instrument save
            var i = 0;
            while (!data.seenInstruments[i] && i < 32)
                i++;
            
            data.instrument = i;
        }
    }
    
   static function load2020Data(callback:(ResultType<String>)->Void)
    {
        var callbacks = new ResultMultiCallback<String>(callback, "2020data");
        
        var advent2020 = NG.core.externalApps.add(APIStuff.APIID_2020);
        var medalCallback = callbacks.add("medals");
        advent2020.medals.loadList((result)->
            {
                switch (result)
                {
                    case SUCCESS:
                        medalCallback(SUCCESS); 
                        medals2020 = advent2020.medals;
                    case FAIL(error):
                        medalCallback(FAIL(error.toString()));
                }
            }
        );
        
        var saveCallback = callbacks.add("saves");
        advent2020.saveSlots.loadAllFiles
        (
            function (result)
            {
                switch (result)
                {
                    case FAIL(_):
                    case SUCCESS:
                        var slot = advent2020.saveSlots[1];
                        if (slot.isEmpty() == false)
                            data2020 = Json.parse(slot.contents);
                }
                
                saveCallback(result);
            }
        );
    }
    
    static function flush(?callback:(ResultType<Error>)->Void)
    {
        if (data != emptyData)
            NG.core.saveSlots[1].save(Json.stringify(data), callback);
    }
    
    static public function resetPresents()
    {
        data.presents = new BitArray();
        flush();
    }
    
    static public function presentOpened(id:String)
    {
        var index = Content.getPresentIndex(id);
        
        if (index < 0)
            throw "invalid present id:" + id;
        
        if (data.presents[index] == false)
        {
            data.presents[index] = true;
            flush();
        }
    }
    
    static public function hasOpenedPresent(id:String)
    {
        var index = Content.getPresentIndex(id);
        
        if (index < 0)
            throw "invalid present id:" + id;
        
        return data.presents[index];
    }
    
    inline static public function hasOpenedPresentByDay(day:Int)
    {
        return data.presents[day - 1];
    }
    
    static public function countPresentsOpened(id:String)
    {
        return data.presents.countTrue();
    }
    
    static public function anyPresentsOpened()
    {
        return !noPresentsOpened();
    }
    
    static public function noPresentsOpened()
    {
        return data.presents.getLength() == 0;
    }
    
    static public function daySeen(day:Int)
    {
        day--;//saves start at 0
        if (data.days[day] == false)
        {
            data.days[day] = true;
            flush();
        }
    }
    
    static public function debugForgetDay(day:Int)
    {
        day--;//saves start at 0
        data.days[day] = false;
        data.presents[day] = false;
        flush();
    }
    
    static public function hasSeenDay(day:Int)
    {
        //saves start at 0
        return data.days[day - 1];
    }
    
    static public function countDaysSeen()
    {
        return data.days.countTrue();
    }
    
    static public function skinSeen(index:Int)
    {
        #if !(UNLOCK_ALL_SKINS)
        if (data.skins[index] == false)
        {
            data.skins[index] = true;
            flush();
        }
        #end
    }
    
    static public function hasSeenskin(index:Int)
    {
        return data.skins[index];
    }
    
    static public function countSkinsSeen()
    {
        return data.skins.countTrue();
    }
    
    static public function setSkin(id:Int)
    {
        PlayerSettings.user.skin = data.skin = id;
        flush();
    }
    
    static public function getSkin()
    {
        return data.skin;
    }
    
    static public function setInstrument(type:InstrumentType)
    {
        if (type == null || type == getInstrument()) return;
        
        PlayerSettings.user.instrument = type;
        data.instrument = Content.instruments[type].index;
        flush();
        Instrument.setCurrent();
    }
    
    static public function getOrder()
    {
        return data.cafeOrder;
    }
    
    static public function setOrder(order:Order)
    {
        if (data.cafeOrder != order)
        {
            data.cafeOrder = order;
            flush();
        }
    }
    
    static public function getInstrument()
    {
        if (data.instrument < 0) return null;
        return Content.instrumentsByIndex[data.instrument].id;
    }
    
    static public function instrumentSeen(type:InstrumentType)
    {
        if (type == null) return;
        
        data.seenInstruments[Content.instruments[type].index] = true;
        flush();
    }
    
    static public function seenInstrument(type:InstrumentType)
    {
        if (type == null) return true;
        
        return data.seenInstruments[Content.instruments[type].index];
    }
    
    inline static function get_showName() return data.showName;
    static function set_showName(value:Bool)
    {
        if (data.showName != value)
        {
            data.showName = value;
            flush();
        }
        return value;
    }
    
    inline static public function toggleShowName()
        return showName = !showName;
    
    inline static public function seenYeti()
    {
        return data.seenYeti;
    }
    
    inline static public function yetiSeen()
    {
        if (data.seenYeti == false)
        {
            data.seenYeti = true;
            flush();
        }
    }
    
    /* --- --- --- --- 2020 --- --- --- --- */
    
    static public function hasSave2020()
    {
        return data2020 != null;
    }
    
    static public function hasMedal2020(id:Int)
    {
        if (medals2020 == null)
            return false;
        
        return medals2020[id].unlocked;
    }
    
    static public function hasSeenDay2020(day:Int)
    {
        if (data2020 == null)
            return false;
        // zero based
        return data2020.days[day - 1];
    }
    
    static public function countDaysSeen2020()
    {
        if (data2020 == null)
            return 0;
        
        return data2020.days.countTrue();
    }
    
    inline static function log(msg, ?info:PosInfos) Log.save(msg, info);
}

typedef SaveData2020 =
{
    var presents:BitArray;
    var days:BitArray;
    var skins:BitArray;
    var skin:Int;
    var instrument:Int;
    var seenInstruments:BitArray;
}

typedef SaveData = SaveData2020 &
{
    var showName:Bool;
    var cafeOrder:Order;
    var seenYeti:Bool;
}