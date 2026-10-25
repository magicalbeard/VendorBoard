/*
 * VendorBoard - Fallout 76 map-screen vendor board.
 * Copyright (C) 2026 MagicalBeard (Patrick Leedom)
 * Based on HUD-PlayerList by MsZelia (GPL-3.0), https://github.com/MsZelia/HUD-PlayerList
 *
 * This program is free software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details: https://www.gnu.org/licenses/gpl-3.0.txt
 */
package
{
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.GlobalFunc;
   import com.adobe.serialization.json.JSONDecoder;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.TimerEvent;
   import flash.filters.BitmapFilterQuality;
   import flash.filters.DropShadowFilter;
   import flash.geom.Rectangle;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import scaleform.gfx.Extensions;
   import scaleform.gfx.TextFieldEx;

   public class VendorBoard extends MovieClip
   {

      public static const VERSION:String = "1.2";

      private var baseCfg:Object = null;

      private var vendorOrder:Object = {};

      private var vendorOrderByName:Object = {};

      private var activitySort:int = 0;

      private var measureTf:TextField = null;

      private var toastTf:TextField = null;

      private var toastBg:Sprite = null;

      private var toastUntil:int = 0;

      private static const CATEGORY_ORDER:Array = ["MODS_WEAPON4","MODS_ARMOR4","MODS_PA4","MODS_WEAPON3","MODS_ARMOR3","MODS_PA3","MODS_WEAPON2","MODS_ARMOR2","MODS_PA2","MODS_WEAPON1","MODS_ARMOR1","MODS_PA1","MODS","WEAPON4","WEAPON3","WEAPON2","WEAPON1","WEAPON0","ARMOR4","ARMOR3","ARMOR2","ARMOR1","ARMOR0","APPAREL","PLAN","STIMPAK","MEDS","FOOD","DRINK","AMMO","EXPLOSIVE","JUNK","MISC"];

      private static const CATEGORY_GROUP:Object = {"vb_bm":["MODS_WEAPON4","MODS_ARMOR4","MODS_PA4","MODS_WEAPON3","MODS_ARMOR3","MODS_PA3","MODS_WEAPON2","MODS_ARMOR2","MODS_PA2","MODS_WEAPON1","MODS_ARMOR1","MODS_PA1","MODS"],
         "vb_bi":["WEAPON4","ARMOR4","WEAPON3","ARMOR3","WEAPON2","ARMOR2","WEAPON1","ARMOR1","WEAPON0","ARMOR0","APPAREL"],
         "vb_bo":["PLAN","STIMPAK","MEDS","FOOD","DRINK","AMMO","EXPLOSIVE","JUNK","MISC"]};

      private var badgeList:Array = null;

      private var sortIndex:int = 0;

      private var exactCost:Object = {};

      private var calib:Array = [];
      
      private var keysLine:TextField = null;
      
      private static const SCORE_GROUPS:Object = {"mods4":["MODS_WEAPON4","MODS_ARMOR4","MODS_PA4"],"items4":["WEAPON4","ARMOR4"],"items3":["WEAPON3","ARMOR3"],"apparel":["APPAREL"]};
      
      private var colTitles:Object = null;
      
      private var vendorsByName:Object = {};
      
      private var legend:TextField = null;

      private var hudTools:SharedHUDTools = null;

      private var ov:Object = {};

      private var ovLoaded:Boolean = false;

      private var ovDirty:Boolean = false;

      private var storage:Object = null;
      
      private var dbg:Object = {};

      private static const STAR:String = String.fromCharCode(172);

      private static const HDR_L:String = String.fromCharCode(187) + String.fromCharCode(187) + "  ";

      private static const HDR_R:String = "  " + String.fromCharCode(171) + String.fromCharCode(171);

      private static const CATEGORY_INDEX:Object = {
         "APPAREL":0,"ARMOR0":1,"ARMOR1":2,"ARMOR2":3,"ARMOR3":4,"ARMOR4":5,
         "WEAPON0":6,"WEAPON1":7,"WEAPON2":8,"WEAPON3":9,"WEAPON4":10,"MODS":11,
         "MODS_WEAPON1":12,"MODS_WEAPON2":13,"MODS_WEAPON3":14,"MODS_WEAPON4":15,
         "MODS_ARMOR1":16,"MODS_ARMOR2":17,"MODS_ARMOR3":18,"MODS_ARMOR4":19,
         "MODS_PA1":20,"MODS_PA2":21,"MODS_PA3":22,"MODS_PA4":23,
         "STIMPAK":24,"MEDS":25,"FOOD":26,"DRINK":27,"AMMO":28,"EXPLOSIVE":29,"JUNK":30,"PLAN":31,"MISC":32
      };

      private static const COMPASS:Array = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"];

      private static const MAP_DISTANCE_CONST:Number = 5005;

      private static const KEYS:Object = {
         "F1":112,"F2":113,"F3":114,"F4":115,"F5":116,"F6":117,"F7":118,"F8":119,"F9":120,"F10":121,"F11":122,"F12":123,
         "NUMPAD0":96,"NUMPAD1":97,"NUMPAD2":98,"NUMPAD3":99,"NUMPAD4":100,"NUMPAD5":101,"NUMPAD6":102,"NUMPAD7":103,"NUMPAD8":104,"NUMPAD9":105,
         "NUMPAD*":106,"NUMPAD+":107,"NUMPAD-":109,"NUMPAD.":110,"NUMPAD/":111,
         "INSERT":45,"DELETE":46,"HOME":36,"END":35,"PAGEUP":33,"PAGEDOWN":34,"PAUSE":19,"SCROLLLOCK":145,
         "-":189,"=":187,"[":219,"]":221,";":186,"'":222,",":188,".":190,"/":191,"`":192,"\\":220
      };

      private var topLevel:* = null;

      private var cfg:Object = null;

      private var cfgLoader:URLLoader = null;

      private var cfgText:String = "";

      private var cfgTimer:Timer = null;

      private var refreshTimer:Timer = null;

      private var keyTimer:Timer = null;

      private var hudMode:String = "";

      private var vendors:Object = {};

      private var visited:Object = {};

      private var keyWasDown:Object = {};

      private var keyRegistered:Object = {};

      private var forceShow:Boolean = false;

      private var hidden:Boolean = false;

      private var presetIndex:int = 0;

      private var presetFlashUntil:int = 0;

      private var rows:Array = [];

      private var header:TextField = null;

      private var status:TextField = null;

      private var panel:Sprite = null;

      private var lastError:String = "";

      private var api:Object = null;

      public function VendorBoard()
      {
         super();
         addEventListener(Event.ADDED_TO_STAGE,this.onAdded);
      }

      private function onAdded(e:Event) : void
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.onAdded);
         try
         {
            this.topLevel = stage.getChildAt(0);
         }
         catch(err:Error)
         {
            this.topLevel = null;
         }
         if(this.topLevel == null || getQualifiedClassName(this.topLevel) != "HUDMenu")
         {
            return;
         }
         this.baseCfg = this.defaultConfig();
         this.cfg = this.buildCfg();
         try
         {
            this.hudTools = new SharedHUDTools("VendorBoard");
            this.hudTools.RegisterMenu(this.onBuildMenu,this.onSelectMenu);
         }
         catch(errMenu:Error)
         {
            this.hudTools = null;
         }
         this.panel = new Sprite();
         addChild(this.panel);
         this.header = this.makeField();
         this.keysLine = this.makeField();
         this.toastBg = new Sprite();
         addChild(this.toastBg);
         this.toastTf = this.makeField();
         this.toastBg.visible = false;
         this.toastTf.visible = false;
         this.colTitles = {"level":this.makeField(),"name":this.makeField(),"dist":this.makeField(),"vendor":this.makeField()};
         this.legend = this.makeField();
         this.status = this.makeField();
         this.cfgLoader = new URLLoader();
         this.cfgLoader.addEventListener(Event.COMPLETE,this.onConfigLoaded);
         this.cfgLoader.addEventListener(IOErrorEvent.IO_ERROR,this.onConfigError);
         this.loadConfig();
         try
         {
            BSUIDataManager.Subscribe("HUDModeData",this.onHudMode);
            BSUIDataManager.Subscribe("RecentActivitiesData",this.onRecentActivities);
            this.hudMode = String(BSUIDataManager.GetDataFromClient("HUDModeData").data.hudMode);
         }
         catch(err2:Error)
         {
            this.lastError = "subscribe: " + err2.message;
         }
         this.cfgTimer = new Timer(10000);
         this.cfgTimer.addEventListener(TimerEvent.TIMER,this.onConfigTick);
         this.cfgTimer.start();
         this.refreshTimer = new Timer(1000);
         this.refreshTimer.addEventListener(TimerEvent.TIMER,this.onRefresh);
         this.refreshTimer.start();
         this.keyTimer = new Timer(120);
         this.keyTimer.addEventListener(TimerEvent.TIMER,this.onKeyTick);
         this.keyTimer.start();
         this.render();
      }

      // ------------------------------------------------------------------ config

      private function defaultConfig() : Object
      {
         return {
            "origin":"screen",
            "x":20,
            "y":200,
            "font":"$MAIN_Font_Bold",
            "textSize":16,
            "rowSpacing":0,
            "textShadow":true,
            "background":true,
            "backgroundColor":"0x0b0a08",
            "backgroundAlpha":0.4,
            "padding":6,
            "columns":{"level":40,"name":130,"distance":100,"cost":50,"vendor":600,"vendorMax":900},
            "vendorGrow":false,
            "minRows":0,
            "fixedWidth":true,
            "showHeader":true,
            "showKeys":true,
            "showFilters":true,
            "viewMode":"expanded",
            "pillWrap":true,
            "compact":{
               "textSize":13,
               "smallTextSize":11,
               "nameMaxChars":10,
               "columns":{"level":30,"name":70,"cost":40,"vendor":320},
               "badgeStyle":"pill",
               "pillGap":3,
               "pillPad":8,
               "wrapRows":12,
               "showFilters":false,
               "showKeys":false
            },
            "toastSeconds":2.5,
            "confirmStyle":"both",
            "smallTextSize":13,
            "scaleColumns":true,
            "hideEmptyShops":true,
            "hudMenu":true,
            "rememberChoices":false,
            "sortIndex":0,
            "hotkeys":true,
            "useFlyoutCost":false,
            "sortKey":"F3",
            "sorts":[
               {"name":"BEST","keys":["local","best","level","name"],"hint":"player level + shop stock"},
               {"name":"LEVEL HIGH","keys":["local","level","name"]},
               {"name":"LEVEL LOW","keys":["local","levelAsc","name"]},
               {"name":"CLOSEST","keys":["local","cost","distance","name"]},
               {"name":"NAME","keys":["local","name"]},
               {"name":"GAME LIST","keys":["local","game","name"],"hint":"map activity list order"}
            ],
            "headerLabel":"SERVER",
            "serverCapacity":24,
            "showColumnTitles":true,
            "columnTitles":{"level":"LVL","name":"PLAYER","distance":"DIST","cost":"COST","vendor":"SHOP"},
            "showLegend":true,
            "wrapRows":0,
            "columnRows":12,
            "showDistance":false,
            "showDirection":false,
            "showCost":true,
            "caps":{"perUnit":84,"min":1,"freeForTeam":true,"prefix":"","suffix":"c"},
            "showLevel":true,
            "maxRows":30,
            "hideVisited":false,
            "visitedAlpha":0.6,
            "visitedPillColor":"0x6b675e",
            "visitedTint":0.35,
            "visitedRadius":25,
            "refreshMs":1000,
            "hudModes":["MapMenu"],
            "allowOverlay":false,
            "debug":false,
            "showKey":"",
            "viewKey":"F4",
            "presetKey":"F2",
            "colors":{
               "header":"0xecc86c","count":"0x9fd79a","countFull":"0xff6b6b","local":"0x3b7bff","remote":"0xf2f0cc",
               "friend":"0x7fd1ae","teamLeader":"0xffb347","teamMember":"0xffcf80","wanted":"0xff5252","hidden":"0xb39ddb",
               "visited":"0x8f8a74","distance":"0xc8b98a","highlight":"0xf6cd60","status":"0x8fd3e8"
            },
            "badgeStyle":"pill",
            "pillTextColor":"0x1c1711",
            "pillAlpha":0.92,
            "pillRadius":7,
            "pillGap":5,
            "pillPad":14,
            "pillOverflowColor":"0x8a8373",
            "badges":[
               {"id":"MODS_WEAPON4","label":"4{star}W","color":"0xf6cd60"},
               {"id":"MODS_ARMOR4","label":"4{star}A","color":"0xf6cd60"},
               {"id":"MODS_PA4","label":"4{star}PA","color":"0xf6cd60"},
               {"id":"MODS_WEAPON3","label":"3{star}W","color":"0xe0b48c"},
               {"id":"MODS_ARMOR3","label":"3{star}A","color":"0xe0b48c"},
               {"id":"MODS_PA3","label":"3{star}PA","color":"0xe0b48c"},
               {"id":"WEAPON4","label":"Wep4{star}","color":"0xff9f6e"},
               {"id":"ARMOR4","label":"Arm4{star}","color":"0xff9f6e"},
               {"id":"WEAPON3","label":"Wep3{star}","color":"0xe0b48c"},
               {"id":"ARMOR3","label":"Arm3{star}","color":"0xe0b48c"},
               {"id":"PLAN","label":"Plan","color":"0x9fd79a"},
               {"id":"APPAREL","label":"Aprl","color":"0xc9a7ff"},
               {"id":"MODS","label":"Mods","color":"0xa09a84"}
            ],
            "score":{
               "MODS_WEAPON4":{"weight":10,"cap":40},"MODS_ARMOR4":{"weight":10,"cap":40},"MODS_PA4":{"weight":10,"cap":40},
               "WEAPON4":{"weight":4,"cap":20},"ARMOR4":{"weight":4,"cap":20},
               "WEAPON3":{"weight":2,"cap":10},"ARMOR3":{"weight":2,"cap":10},
               "APPAREL":{"weight":1,"cap":8}
            },
            "levelScore":{"divisor":100,"cap":10},
            "highlightScore":6,
            "presets":[
               {"name":"DEFAULT (USER)"},
               {"name":"EVERYTHING","vendorsOnly":true,"badges":"all"},
               {"name":"INTERESTING (BETA)","minScore":6,"vendorsOnly":true},
               {"name":"MODS ONLY","anyOf":["MODS_WEAPON4","MODS_ARMOR4","MODS_PA4","MODS_WEAPON3","MODS_ARMOR3","MODS_PA3","MODS_WEAPON2","MODS_ARMOR2","MODS_PA2","MODS_WEAPON1","MODS_ARMOR1","MODS_PA1","MODS"],"badges":["MODS_WEAPON4","MODS_ARMOR4","MODS_PA4","MODS_WEAPON3","MODS_ARMOR3","MODS_PA3","MODS_WEAPON2","MODS_ARMOR2","MODS_PA2","MODS_WEAPON1","MODS_ARMOR1","MODS_PA1","MODS"]},
               {"name":"4-STAR MODS","anyOf":["MODS_WEAPON4","MODS_ARMOR4","MODS_PA4"],"badges":["MODS_WEAPON4","MODS_ARMOR4","MODS_PA4"]},
               {"name":"WEAPONS & ARMOR","anyOf":["WEAPON4","ARMOR4","WEAPON3","ARMOR3","WEAPON2","ARMOR2","WEAPON1","ARMOR1","WEAPON0","ARMOR0"],"badges":["WEAPON4","ARMOR4","WEAPON3","ARMOR3","WEAPON2","ARMOR2","WEAPON1","ARMOR1","WEAPON0","ARMOR0"]},
               {"name":"APPAREL","anyOf":["APPAREL"],"badges":["APPAREL"]},
               {"name":"PLAN SHOPS","minCount":{"PLAN":50},"badges":["PLAN"]},
               {"name":"AID","anyOf":["STIMPAK","MEDS","FOOD","DRINK"],"badges":["STIMPAK","MEDS","FOOD","DRINK"]},
               {"name":"AMMO & EXPLOSIVES","anyOf":["AMMO","EXPLOSIVE"],"badges":["AMMO","EXPLOSIVE"]},
               {"name":"JUNK & MISC","anyOf":["JUNK","MISC"],"badges":["JUNK","MISC"]},
               {"name":"ALL + EMPTY VENDORS","badges":"all","includeEmpty":true},
               {"name":"FRIENDS","friendsOnly":true}
            ],
            "nameMaxChars":14,
            "preset":0
         };
      }

      private function loadConfig() : void
      {
         try
         {
            this.cfgLoader.load(new URLRequest("../VendorBoard.json"));
         }
         catch(err:Error)
         {
         }
      }

      private function onConfigError(e:Event) : void
      {
         this.lastError = "no VendorBoard.json (using defaults)";
      }

      private function onConfigLoaded(e:Event) : void
      {
         var text:String = String(e.target.data);
         var parsed:Object = null;
         var key:String = null;
         if(text == this.cfgText)
         {
            return;
         }
         try
         {
            parsed = new JSONDecoder(text,false).getValue();
         }
         catch(err:Error)
         {
            this.lastError = "config parse: " + err.message;
            return;
         }
         if(parsed == null)
         {
            return;
         }
         this.cfgText = text;
         var merged:Object = this.defaultConfig();
         for(key in parsed)
         {
            if((key == "colors" || key == "columns" || key == "columnTitles" || key == "caps") && parsed[key] != null)
            {
               for(var sub:String in parsed[key])
               {
                  merged[key][sub] = parsed[key][sub];
               }
            }
            else
            {
               merged[key] = parsed[key];
            }
         }
         this.baseCfg = merged;
         this.cfg = this.buildCfg();
         this.presetIndex = int(merged.preset);
         this.sortIndex = int(merged.sortIndex);
         this.lastError = "";
         this.applyOverrides();
         this.applyTimers();
         this.render();
      }

      private function onConfigTick(e:TimerEvent) : void
      {
         this.loadConfig();
      }

      private function applyTimers() : void
      {
         var ms:int = int(this.cfg.refreshMs);
         if(ms < 250)
         {
            ms = 250;
         }
         if(this.refreshTimer != null && this.refreshTimer.delay != ms)
         {
            this.refreshTimer.delay = ms;
         }
      }

      // ------------------------------------------------------------------ data

      private function onHudMode(e:FromClientDataEvent) : void
      {
         try
         {
            this.hudMode = String(e.data.hudMode);
         }
         catch(err:Error)
         {
         }
         this.render();
      }

      private function onRecentActivities(e:FromClientDataEvent) : void
      {
         try
         {
            if(e.data != null)
            {
               this.ingestActivities(e.data.recentActivities);
            }
         }
         catch(err:Error)
         {
            this.lastError = "vendors: " + err.message;
         }
      }

      private function ingestActivities(list:Object) : void
      {
         var i:int = 0;
         var rec:Object = null;
         var vend:int = 0;
         var next:Object = {};
         var byName:Object = {};
         var order:Object = {};
         var orderByName:Object = {};
         var info:Object = null;
         var key:String = null;
         if(list == null)
         {
            return;
         }
         while(i < list.length)
         {
            rec = list[i];
            i++;
            if(rec == null)
            {
               continue;
            }
            if(rec.vendingCategoryCounts != null && rec.mapMarkerId != null)
            {
               next[String(rec.mapMarkerId)] = rec.vendingCategoryCounts;
               info = {"rev":list.length - i,"name":this.activityName(rec),"time":Number(rec.time)};
               if(this.dbg.act0 == null)
               {
                  this.dbg.act0 = info.name + "/" + String(rec.time) + "/" + String(rec.name);
               }
               order[String(rec.mapMarkerId)] = info;
               vend++;
               if(rec.description != null)
               {
                  key = String(rec.description).split("|")[0].split("<")[0].replace(/^\s+|\s+$/g,"");
                  byName[key] = rec.vendingCategoryCounts;
                  orderByName[key] = info;
               }
            }
         }
         this.vendors = next;
         this.vendorsByName = byName;
         this.vendorOrder = order;
         this.vendorOrderByName = orderByName;
         this.dbg.acts = list.length;
         this.dbg.vend = vend;
         if(list.length > 0 && list[0] != null)
         {
            this.dbg.actKeys = this.keysOf(list[0]);
         }
      }

      // what the map's list sorts on: the entry name with the localized "Vendor" type prefix stripped
      private function activityName(rec:Object) : String
      {
         var s:String = rec.name != null ? String(rec.name) : "";
         var prefix:String = "";
         if(rec.playerName != null && String(rec.playerName).length > 0)
         {
            return String(rec.playerName).split("<")[0];
         }
         if(rec.description != null && String(rec.description).length > 0)
         {
            return String(rec.description).split("|")[0].split("<")[0].replace(/^\s+|\s+$/g,"");
         }
         try
         {
            if(s.charAt(0) == "$")
            {
               s = String(GlobalFunc.LocalizeFormattedString(s));
            }
            prefix = String(GlobalFunc.LocalizeFormattedString("$World_Activity_Type_Vendor"));
            if(prefix.length > 0 && s.toUpperCase().indexOf(prefix.toUpperCase()) == 0)
            {
               s = s.slice(prefix.length + 1);
            }
            if(s.charAt(0) == " ")
            {
               s = s.slice(1);
            }
         }
         catch(err:Error)
         {
         }
         return s;
      }

      private function gameOrder(a:Object, b:Object) : int
      {
         var r:int = 0;
         if(a.act == null && b.act == null)
         {
            return 0;
         }
         if(a.act == null)
         {
            return 1;
         }
         if(b.act == null)
         {
            return -1;
         }
         if(this.activitySort == 1)
         {
            r = a.act.time < b.act.time ? -1 : (a.act.time > b.act.time ? 1 : 0);
         }
         else
         {
            r = int(String(a.act.name).localeCompare(String(b.act.name)));
         }
         if(r == 0)
         {
            r = a.act.rev - b.act.rev;
         }
         return r;
      }

      private function keysOf(o:Object) : String
      {
         var k:String = null;
         var out:Array = [];
         for(k in o)
         {
            out.push(k);
         }
         out.sort();
         return out.join(",");
      }

      private function onRefresh(e:TimerEvent) : void
      {
         this.storageTick();
         if(this.isVisibleNow())
         {
            this.render();
         }
         else
         {
            this.setBoardVisible(false);
         }
         this.toastTick();
      }

      private function collect() : Object
      {
         var markers:Array = null;
         var i:int = 0;
         var m:Object = null;
         var name:String = null;
         var players:Array = [];
         var camps:Object = {};
         var seen:Object = {};
         var me:Object = null;
         var account:Object = null;
         var charInfo:Object = null;
         var maxPlayers:int = int(this.cfg.serverCapacity) > 0 ? int(this.cfg.serverCapacity) : 24;
         var p:Object = null;
         this.dbg.camps = 0;
         this.dbg.campsAll = 0;
         this.dbg.campOnly = 0;
         this.dbg.zero = 0;
         this.dbg.camp0 = null;
         this.dbg.ply0 = null;
         try
         {
            markers = BSUIDataManager.GetDataFromClient("MapMenuData").data.MarkerData;
         }
         catch(err:Error)
         {
            markers = null;
         }
         try
         {
            account = BSUIDataManager.GetDataFromClient("AccountInfoData").data;
            charInfo = BSUIDataManager.GetDataFromClient("CharacterInfoData").data;
            if(account != null && account.isOnPrivateWorld === true)
            {
               maxPlayers = 8;
            }
         }
         catch(err2:Error)
         {
         }
         if(this.cfg.useFlyoutCost === true)
         {
            try
            {
               var fly:Object = BSUIDataManager.GetDataFromClient("MapMenuFlyoutData").data;
               if(fly != null && fly.markerID != null && fly.fastTravelCost != null && Number(fly.fastTravelCost) >= 0)
               {
                  this.exactCost[String(fly.markerID)] = int(fly.fastTravelCost);
               }
            }
            catch(err5:Error)
            {
            }
         }
         try
         {
            var ra:Object = BSUIDataManager.GetDataFromClient("RecentActivitiesData").data;
            if(ra != null)
            {
               this.activitySort = ra.sortStyle != null ? int(ra.sortStyle) : 0;
               this.ingestActivities(ra.recentActivities);
            }
         }
         catch(err4:Error)
         {
            this.dbg.raErr = err4.message;
         }
         if(markers == null)
         {
            return {"players":players,"me":null,"max":maxPlayers};
         }
         i = 0;
         while(i < markers.length)
         {
            m = markers[i];
            i++;
            if(m == null)
            {
               continue;
            }
            try
            {
               if(m.markerType == "YourCampMarker")
               {
                  if(m.isLocalPlayersCamp !== true)
                  {
                     this.dbg.campsAll = int(this.dbg.campsAll) + 1;
                  }
                  if(m.isVending === true && m.isLocalPlayersCamp !== true && m.owningPlayerName != null)
                  {
                     camps[String(m.owningPlayerName).split("<")[0]] = {"markerId":m.markerID,"x":Number(m.x),"y":Number(m.y)};
                     this.dbg.camps = int(this.dbg.camps) + 1;
                     if(this.dbg.camp0 == null)
                     {
                        this.dbg.camp0 = String(m.owningPlayerName) + "#" + String(m.markerID);
                     }
                  }
                  if(this.dbg.campKeys == null)
                  {
                     this.dbg.campKeys = this.keysOf(m);
                  }
                  continue;
               }
               if(m.markerType == "PlayerLocal" && !(m.playerLevel > 0))
               {
                  me = {"x":Number(m.x),"y":Number(m.y)};
                  name = account != null && account.name != null ? String(account.name) : "You";
                  if(!seen[name])
                  {
                     seen[name] = true;
                     players.push({"name":name,"level":charInfo != null ? int(charInfo.level) : 0,"type":"PlayerLocal","bounty":charInfo != null ? int(charInfo.bounty) : 0,"isFriend":false,"x":Number(m.x),"y":Number(m.y),"local":true});
                  }
                  continue;
               }
               if(m.playerLevel > 0)
               {
                  name = String(m.text).split("<")[0];
                  if(seen[name])
                  {
                     continue;
                  }
                  seen[name] = true;
                  p = {"name":name,"level":int(m.playerLevel),"type":String(m.markerType),"bounty":int(m.bounty),"isFriend":m.isFriend === true,"x":Number(m.x),"y":Number(m.y),"local":m.markerType == "PlayerLocal"};
                  if(p.local)
                  {
                     me = {"x":p.x,"y":p.y};
                  }
                  players.push(p);
               }
            }
            catch(err3:Error)
            {
            }
         }
         this.dbg.matched = 0;
         this.dbg.markers = markers.length;
         i = 0;
         while(i < players.length)
         {
            p = players[i];
            i++;
            p.camp = camps[p.name];
            p.counts = p.camp != null ? this.vendors[String(p.camp.markerId)] : null;
            p.act = p.camp != null ? this.vendorOrder[String(p.camp.markerId)] : null;
            if(p.counts == null && this.vendorsByName[p.name] != null)
            {
               p.counts = this.vendorsByName[p.name];
               p.act = this.vendorOrderByName[p.name];
            }
            if(p.counts != null)
            {
               this.dbg.matched = int(this.dbg.matched) + 1;
               if(this.badgeItems(p.counts).length == 0)
               {
                  this.dbg.zero = int(this.dbg.zero) + 1;
               }
            }
            else if(p.camp != null)
            {
               this.dbg.campOnly = int(this.dbg.campOnly) + 1;
            }
            if(!p.local && this.dbg.ply0 == null)
            {
               this.dbg.ply0 = p.name;
            }
            p.score = this.scoreOf(p.counts,int(p.level));
            p.dist = -1;
            p.dir = "";
            if(me != null)
            {
               var target:Object = p.camp != null ? p.camp : p;
               var dx:Number = Number(target.x) - me.x;
               var dy:Number = Number(target.y) - me.y;
               p.dist = int(Math.sqrt(dx * dx + dy * dy) * MAP_DISTANCE_CONST);
               var deg:Number = (450 + Math.atan2(dy,dx) * 180 / Math.PI) % 360;
               p.dir = COMPASS[int(Math.round(deg / 22.5)) % 16];
               if(p.camp != null && p.dist < Number(this.cfg.visitedRadius))
               {
                  this.visited[p.name] = true;
               }
               p.cost = this.capsFor(p);
               p.costExact = false;
               if(p.camp != null && this.exactCost[String(p.camp.markerId)] != null)
               {
                  p.costExact = true;
                  if(p.cost > 0 && this.exactCost[String(p.camp.markerId)] > 0)
                  {
                     this.calibrate(p.dist / Number(this.exactCost[String(p.camp.markerId)]));
                  }
                  p.cost = int(this.exactCost[String(p.camp.markerId)]);
               }
            }
            p.visited = this.visited[p.name] === true;
         }
         return {"players":players,"me":me,"max":maxPlayers};
      }

      private function calibrate(ratio:Number) : void
      {
         var sorted:Array = null;
         var med:Number = 0;
         if(!(ratio > 20 && ratio < 400))
         {
            return;
         }
         this.calib.push(ratio);
         if(this.calib.length > 40)
         {
            this.calib.shift();
         }
         if(this.calib.length >= 3)
         {
            sorted = this.calib.concat();
            sorted.sort(Array.NUMERIC);
            med = Number(sorted[int(sorted.length / 2)]);
            if(this.ov.perUnit == null || Math.abs(Number(this.ov.perUnit) - med) >= 1)
            {
               this.ov.perUnit = Math.round(med * 10) / 10;
               this.ovDirty = true;
            }
         }
      }

      private function capsFor(p:Object) : int
      {
         var c:Object = this.cfg.caps;
         var per:Number = this.ov.perUnit != null && Number(this.ov.perUnit) > 0 ? Number(this.ov.perUnit) : (c != null && Number(c.perUnit) > 0 ? Number(c.perUnit) : 84);
         var caps:int = 0;
         if(p.dist < 0)
         {
            return -1;
         }
         if(c != null && c.freeForTeam !== false && (p.type == "TeamLeader" || p.type == "TeamMember"))
         {
            return 0;
         }
         caps = int(Math.round(p.dist / per));
         if(c != null && c.min != null && caps < int(c.min))
         {
            caps = int(c.min);
         }
         return caps;
      }

      private function costText(p:Object) : String
      {
         var c:Object = this.cfg.caps;
         if(p.local || p.cost < 0)
         {
            return "";
         }
         if(p.cost == 0)
         {
            return "free";
         }
         return (p.costExact === true ? "" : "~") + String(c != null && c.prefix != null ? c.prefix : "") + String(p.cost) + String(c != null && c.suffix != null ? c.suffix : "c");
      }

      private function scoreOf(counts:Object, level:int) : Number
      {
         var id:String = null;
         var idx:int = 0;
         var rule:* = undefined;
         var weight:Number = 0;
         var cap:Number = 0;
         var part:Number = 0;
         var total:Number = 0;
         var ls:Object = this.cfg.levelScore;
         if(ls != null && Number(ls.divisor) > 0)
         {
            part = level / Number(ls.divisor);
            if(ls.cap != null && part > Number(ls.cap))
            {
               part = Number(ls.cap);
            }
            total += part;
         }
         if(counts == null || this.cfg.score == null)
         {
            return total;
         }
         for(id in this.cfg.score)
         {
            if(CATEGORY_INDEX[id] == null)
            {
               continue;
            }
            idx = int(CATEGORY_INDEX[id]);
            if(!(counts.length > idx && counts[idx] > 0))
            {
               continue;
            }
            rule = this.cfg.score[id];
            weight = rule is Number ? Number(rule) : Number(rule.weight);
            cap = rule is Number || rule.cap == null ? 0 : Number(rule.cap);
            part = weight * Number(counts[idx]);
            if(cap > 0 && part > cap)
            {
               part = cap;
            }
            total += part;
         }
         return total;
      }

      private function meetsMinCount(counts:Object, rule:Object) : Boolean
      {
         var id:String = null;
         var idx:int = 0;
         if(counts == null)
         {
            return false;
         }
         for(id in rule)
         {
            if(CATEGORY_INDEX[id] == null)
            {
               continue;
            }
            idx = int(CATEGORY_INDEX[id]);
            if(!(counts.length > idx && Number(counts[idx]) >= Number(rule[id])))
            {
               return false;
            }
         }
         return true;
      }

      private function hasAnyOf(counts:Object, ids:Array) : Boolean
      {
         var i:int = 0;
         var idx:int = 0;
         if(counts == null || ids == null)
         {
            return false;
         }
         while(i < ids.length)
         {
            if(CATEGORY_INDEX[ids[i]] != null)
            {
               idx = int(CATEGORY_INDEX[ids[i]]);
               if(counts.length > idx && counts[idx] > 0)
               {
                  return true;
               }
            }
            i++;
         }
         return false;
      }

      private function passesPreset(p:Object) : Boolean
      {
         var preset:Object = this.currentPreset();
         if(preset == null)
         {
            return true;
         }
         if(p.local)
         {
            // your own row carries no shop data; only the "everyone" preset lists it
            return preset.includeEmpty === true;
         }
         if(preset.includeEmpty !== true && (this.cfg.hideEmptyShops === true || this.isFixedPreset(preset)) && this.badgeItems(p.counts).length == 0)
         {
            return false;
         }
         if(preset.vendorsOnly === true && p.counts == null && !(preset.includeEmpty === true && p.camp != null))
         {
            return false;
         }
         if(preset.minScore != null && p.score < Number(preset.minScore))
         {
            return false;
         }
         if(preset.anyOf is Array && !this.hasAnyOf(p.counts,preset.anyOf as Array))
         {
            return false;
         }
         if(preset.minCount != null && !this.meetsMinCount(p.counts,preset.minCount))
         {
            return false;
         }
         if(preset.friendsOnly === true && !p.isFriend)
         {
            return false;
         }
         if(this.cfg.hideVisited === true && p.visited && !p.local)
         {
            return false;
         }
         return true;
      }

      private function currentPreset() : Object
      {
         var list:Array = this.cfg.presets as Array;
         if(list == null || list.length == 0)
         {
            return null;
         }
         if(this.presetIndex < 0 || this.presetIndex >= list.length)
         {
            this.presetIndex = 0;
         }
         return list[this.presetIndex];
      }

      private function sortPlayers(list:Array) : void
      {
         var keys:Array = this.currentSort().keys as Array;
         var board:VendorBoard = this;
         if(keys == null)
         {
            keys = ["local","best","level","name"];
         }
         list.sort(function(a:Object, b:Object):int
         {
            var i:int = 0;
            var k:String = null;
            var r:int = 0;
            while(i < keys.length)
            {
               k = String(keys[i]);
               i++;
               if(k == "local")
               {
                  r = int(b.local) - int(a.local);
               }
               else if(k == "best" || k == "score")
               {
                  r = b.score > a.score ? 1 : (b.score < a.score ? -1 : 0);
               }
               else if(k == "level")
               {
                  r = b.level - a.level;
               }
               else if(k == "levelAsc")
               {
                  r = a.level - b.level;
               }
               else if(k == "distance")
               {
                  r = (a.dist < 0 ? 999999 : a.dist) - (b.dist < 0 ? 999999 : b.dist);
               }
               else if(k == "cost")
               {
                  r = (a.cost < 0 ? 999999 : a.cost) - (b.cost < 0 ? 999999 : b.cost);
               }
               else if(k == "bounty")
               {
                  r = b.bounty - a.bounty;
               }
               else if(k == "friend")
               {
                  r = int(b.isFriend) - int(a.isFriend);
               }
               else if(k == "name")
               {
                  r = a.name.toLowerCase() < b.name.toLowerCase() ? -1 : (a.name.toLowerCase() > b.name.toLowerCase() ? 1 : 0);
               }
               else if(k == "game")
               {
                  r = board.gameOrder(a,b);
               }
               if(r != 0)
               {
                  return r;
               }
            }
            return 0;
         });
      }

      // ------------------------------------------------------------------ menu + remembered choices

      private function presetName(i:int) : String
      {
         var list:Array = this.cfg.presets as Array;
         if(list == null || i < 0 || i >= list.length || list[i] == null)
         {
            return "?";
         }
         return String(list[i].name);
      }

      private function currentSort() : Object
      {
         var list:Array = this.cfg.sorts as Array;
         if(list == null || list.length == 0)
         {
            return {"name":"BEST","keys":["local","best","level","name"],"hint":"player level + shop stock"};
         }
         if(this.sortIndex < 0 || this.sortIndex >= list.length)
         {
            this.sortIndex = 0;
         }
         return list[this.sortIndex];
      }

      private function sortKey() : String
      {
         return String(this.currentSort().name);
      }

      public function onBuildMenu(parentItem:String = null) : *
      {
         var i:int = 0;
         var list:Array = null;
         try
         {
            if(this.hudTools == null || this.cfg.hudMenu === false)
            {
               return;
            }
            if(parentItem == "VendorBoard")
            {
               // HUDTools stacks items upward: the last item added is drawn at the top, so each group is added
               // bottom-up and its header last. Groups top-down on screen: SYSTEM, UI, FILTERING.
               // --- FILTERING (bottom)
               this.hudTools.AddMenuItem("vb_bo","Badges: other",true,true,0);
               this.hudTools.AddMenuItem("vb_bi","Badges: items",true,true,0);
               this.hudTools.AddMenuItem("vb_bm","Badges: legendary mods",true,true,0);
               this.hudTools.AddMenuItem("vb_visited","Hide visited: " + (this.cfg.hideVisited === true ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_empty","Hide rows with no stock: " + (this.cfg.hideEmptyShops === true ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_score","Score: highlight at " + String(this.cfg.highlightScore),true,true,0);
               this.hudTools.AddMenuItem("vb_sort","Sort preset: " + this.sortKey(),true,true,0);
               this.hudTools.AddMenuItem("vb_filter","Filter preset: " + this.presetName(this.presetIndex),true,true,0);
               this.hudTools.AddMenuItem("vb_hdr_filtering",HDR_L + "FILTERING" + HDR_R,false,false,0);
               // --- UI
               this.hudTools.AddMenuItem("vb_toggle",this.hidden ? "Show board" : "Hide board",true,false,250);
               this.hudTools.AddMenuItem("vb_keys","Hotkeys line: " + (this.cfg.showKeys === true ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_filters","Filter list: " + (this.cfg.showFilters === true ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_legend","Legend: " + (this.cfg.showLegend === true ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_pos","Position " + int(this.cfg.x) + " / " + int(this.cfg.y),true,true,0);
               this.hudTools.AddMenuItem("vb_cols","Two columns: " + (int(this.cfg.wrapRows) > 0 ? "ON (" + int(this.cfg.wrapRows) + " rows each)" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_sts","Small text size: " + int(this.cfg.smallTextSize),true,true,0);
               this.hudTools.AddMenuItem("vb_ts","Text size: " + int(this.cfg.textSize),true,true,0);
               this.hudTools.AddMenuItem("vb_view","View: " + (this.viewMode() == "compact" ? "COMPACT (switch to expanded)" : "EXPANDED (switch to compact)"),true,false,250);
               this.hudTools.AddMenuItem("vb_hdr_ui",HDR_L + "UI" + HDR_R,false,false,0);
               // --- SYSTEM (top)
               this.hudTools.AddMenuItem("vb_debug","Debug line: " + (this.cfg.debug === true ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_reload","Reload config (forget menu choices)",true,false,250);
               this.hudTools.AddMenuItem("vb_hdr_system",HDR_L + "SYSTEM" + HDR_R,false,false,0);
            }
            else if(parentItem == "vb_filter")
            {
               list = this.cfg.presets as Array;
               while(list != null && i < list.length)
               {
                  this.hudTools.AddMenuItem("vb_preset_" + i,(i == this.presetIndex ? "> " : "   ") + this.presetName(i),true,false,250);
                  i++;
               }
            }
            else if(parentItem == "vb_score")
            {
               this.hudTools.AddMenuItem("vb_hl_down","Highlight threshold --",true,false,250);
               this.hudTools.AddMenuItem("vb_hl_up","Highlight threshold ++",true,false,250);
               this.hudTools.AddMenuItem("vb_sg_mods4","Count 4" + STAR + " mods: " + (this.groupOn("mods4") ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_sg_items4","Count 4" + STAR + " items: " + (this.groupOn("items4") ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_sg_items3","Count 3" + STAR + " items: " + (this.groupOn("items3") ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_sg_apparel","Count apparel: " + (this.groupOn("apparel") ? "ON" : "OFF"),true,false,250);
               this.hudTools.AddMenuItem("vb_sg_level","Count player level: " + (this.ov.levelOff === true ? "OFF" : "ON"),true,false,250);
            }
            else if(CATEGORY_GROUP[parentItem] != null)
            {
               list = CATEGORY_GROUP[parentItem] as Array;
               while(i < list.length)
               {
                  this.hudTools.AddMenuItem("vb_bt_" + list[i],(this.badgeOn(String(list[i])) ? "ON  " : "off  ") + String(this.defaultBadge(String(list[i])).label).split("{star}").join(STAR) + "  (" + String(list[i]) + ")",true,false,250);
                  i++;
               }
            }
            else if(parentItem == "vb_ts")
            {
               this.hudTools.AddMenuItem("vb_ts_0","Reset to default",true,false,250);
               this.hudTools.AddMenuItem("vb_ts_m","--",true,false,250);
               this.hudTools.AddMenuItem("vb_ts_p","++",true,false,250);
            }
            else if(parentItem == "vb_sts")
            {
               this.hudTools.AddMenuItem("vb_sts_0","Reset to default",true,false,250);
               this.hudTools.AddMenuItem("vb_sts_m","--",true,false,250);
               this.hudTools.AddMenuItem("vb_sts_p","++",true,false,250);
            }
            else if(parentItem == "vb_pos")
            {
               this.hudTools.AddMenuItem("vb_mv_u","Move up 10",true,false,250);
               this.hudTools.AddMenuItem("vb_mv_d","Move down 10",true,false,250);
               this.hudTools.AddMenuItem("vb_mv_l","Move left 10",true,false,250);
               this.hudTools.AddMenuItem("vb_mv_r","Move right 10",true,false,250);
               this.hudTools.AddMenuItem("vb_mv_U","Move up 50",true,false,250);
               this.hudTools.AddMenuItem("vb_mv_D","Move down 50",true,false,250);
               this.hudTools.AddMenuItem("vb_mv_0","Reset position to json",true,false,250);
            }
            else if(parentItem == "vb_sort")
            {
               list = this.cfg.sorts as Array;
               while(list != null && i < list.length)
               {
                  this.hudTools.AddMenuItem("vb_sort_" + i,(i == this.sortIndex ? "> " : "   ") + String(list[i].name),true,false,250);
                  i++;
               }
            }
         }
         catch(err:Error)
         {
            this.lastError = "menu: " + err.message;
         }
      }

      public function onSelectMenu(selectItem:String) : *
      {
         var list:Array = null;
         var n:int = 0;
         try
         {
            if(selectItem == null)
            {
               return;
            }
            if(selectItem.indexOf("vb_preset_") == 0)
            {
               list = this.cfg.presets as Array;
               n = int(selectItem.substr(10));
               if(list != null && n >= 0 && n < list.length)
               {
                  this.presetIndex = n;
                  this.ov.preset = n;
                  this.presetFlashUntil = getTimer() + 2500;
                  this.toast("filter preset " + this.presetName(n));
               }
            }
            else if(selectItem.indexOf("vb_sort_") == 0)
            {
               this.sortIndex = int(selectItem.substr(8));
               this.ov.sortIndex = this.sortIndex;
               this.toast("sort preset " + this.sortKey());
            }
            else if(selectItem.indexOf("vb_bt_") == 0)
            {
               this.toggleBadge(selectItem.substr(6));
               this.toast("badge " + String(this.defaultBadge(selectItem.substr(6)).label).split("{star}").join(STAR) + " " + (this.badgeOn(selectItem.substr(6)) ? "ON" : "OFF"));
            }
            else if(selectItem.indexOf("vb_ts_") == 0 || selectItem.indexOf("vb_sts_") == 0)
            {
               this.adjustTextSize(selectItem);
            }
            else if(selectItem.indexOf("vb_mv_") == 0)
            {
               this.nudge(selectItem.substr(6));
               this.toast("position " + int(this.cfg.x) + " / " + int(this.cfg.y));
            }
            else if(selectItem == "vb_empty")
            {
               this.cfg.hideEmptyShops = this.cfg.hideEmptyShops !== true;
               this.ov.hideEmptyShops = this.cfg.hideEmptyShops;
               this.toast("hide rows with no stock " + (this.cfg.hideEmptyShops === true ? "ON" : "OFF"));
            }
            else if(selectItem == "vb_hl_up" || selectItem == "vb_hl_down")
            {
               this.ov.highlightScore = Math.max(0,Number(this.cfg.highlightScore) + (selectItem == "vb_hl_up" ? 1 : -1));
               this.cfg.highlightScore = this.ov.highlightScore;
               this.toast("highlight threshold " + String(this.cfg.highlightScore));
            }
            else if(selectItem.indexOf("vb_sg_") == 0)
            {
               this.toggleGroup(selectItem.substr(6));
               this.toast("score " + selectItem.substr(6) + " " + (selectItem.substr(6) == "level" ? (this.ov.levelOff === true ? "OFF" : "ON") : (this.groupOn(selectItem.substr(6)) ? "ON" : "OFF")));
            }
            else if(selectItem == "vb_visited")
            {
               this.cfg.hideVisited = this.cfg.hideVisited !== true;
               this.ov.hideVisited = this.cfg.hideVisited;
               this.toast("hide visited " + (this.cfg.hideVisited === true ? "ON" : "OFF"));
            }
            else if(selectItem == "vb_toggle")
            {
               this.hidden = !this.hidden;
               this.ov.hidden = this.hidden;
               this.toast(this.hidden ? "board hidden" : "board shown");
            }
            else if(selectItem == "vb_debug")
            {
               this.cfg.debug = this.cfg.debug !== true;
               this.ov.debug = this.cfg.debug;
               this.toast("debug line " + (this.cfg.debug === true ? "ON" : "OFF"));
            }
            else if(selectItem == "vb_cols")
            {
               this.ov.twoColumns = int(this.cfg.wrapRows) <= 0;
               this.applyOverrides();
               this.toast("two columns " + (int(this.cfg.wrapRows) > 0 ? "ON" : "OFF"));
            }
            else if(selectItem == "vb_view")
            {
               this.ov.viewMode = this.viewMode() == "compact" ? "expanded" : "compact";
               this.applyOverrides();
               this.toast("view " + String(this.ov.viewMode).toUpperCase());
            }
            else if(selectItem == "vb_legend")
            {
               this.cfg.showLegend = this.cfg.showLegend !== true;
               this.ov.showLegend = this.cfg.showLegend;
               this.toast("legend " + (this.cfg.showLegend === true ? "ON" : "OFF"));
            }
            else if(selectItem == "vb_filters")
            {
               this.cfg.showFilters = this.cfg.showFilters !== true;
               this.ov.showFilters = this.cfg.showFilters;
               this.toast("filter list " + (this.cfg.showFilters === true ? "ON" : "OFF"));
            }
            else if(selectItem == "vb_keys")
            {
               this.cfg.showKeys = this.cfg.showKeys !== true;
               this.ov.showKeys = this.cfg.showKeys;
               this.toast("hotkeys line " + (this.cfg.showKeys === true ? "ON" : "OFF"));
            }
            else if(selectItem == "vb_reload")
            {
               this.ov = {};
               this.cfgText = "";
               this.loadConfig();
            }
            else
            {
               return;
            }
            this.ovDirty = true;
            this.render();
         }
         catch(err:Error)
         {
            this.lastError = "menu select: " + err.message;
         }
      }

      private function groupOn(group:String) : Boolean
      {
         return this.ov["off_" + group] !== true;
      }

      private function toggleGroup(group:String) : void
      {
         if(group == "level")
         {
            this.ov.levelOff = this.ov.levelOff !== true;
         }
         else
         {
            this.ov["off_" + group] = this.ov["off_" + group] !== true;
         }
         this.cfgText = "";
         this.loadConfig();
      }

      private function nudge(dir:String) : void
      {
         var x:Number = this.ov.x != null ? Number(this.ov.x) : Number(this.cfg.x);
         var y:Number = this.ov.y != null ? Number(this.ov.y) : Number(this.cfg.y);
         if(dir == "0")
         {
            delete this.ov.x;
            delete this.ov.y;
            this.cfgText = "";
            this.loadConfig();
            return;
         }
         if(dir == "u")
         {
            y -= 10;
         }
         else if(dir == "d")
         {
            y += 10;
         }
         else if(dir == "U")
         {
            y -= 50;
         }
         else if(dir == "D")
         {
            y += 50;
         }
         else if(dir == "l")
         {
            x -= 10;
         }
         else if(dir == "r")
         {
            x += 10;
         }
         this.ov.x = x;
         this.ov.y = y;
         this.cfg.x = x;
         this.cfg.y = y;
      }

      // board origin in stage coordinates. origin "screen": x/y are measured from the visible screen's top-left
      // corner (Scaleform's visibleRect), so the same numbers work on 16:9 and ultrawide. "stage": raw coordinates.
      private function origin() : Object
      {
         var r:Rectangle = null;
         var ox:Number = Number(this.cfg.x);
         var oy:Number = Number(this.cfg.y);
         if(this.cfg.origin != "stage")
         {
            try
            {
               r = Extensions.visibleRect;
            }
            catch(err:Error)
            {
               r = null;
            }
            if(r != null)
            {
               ox += r.x;
               oy += r.y;
            }
         }
         return {"x":ox,"y":oy};
      }

      private function toast(message:String) : void
      {
         var size:Number = Number(this.cfg.textSize) + 2;
         var w:Number = 0;
         var h:Number = size + 12;
         var style:String = String(this.cfg.confirmStyle);
         if(style == "hud" || style == "both")
         {
            try
            {
               GlobalFunc.ShowHUDMessage("VendorBoard: " + message);
            }
            catch(errHud:Error)
            {
            }
         }
         if(style == "hud")
         {
            return;
         }
         try
         {
            this.styleField(this.toastTf,this.color("highlight"),"left",size);
            this.toastTf.text = "VendorBoard: " + message;
            w = this.toastTf.textWidth + 24;
            var org:Object = this.origin();
            this.toastTf.x = Number(org.x) + 12;
            this.toastTf.y = Number(org.y) - h - 10;
            this.toastTf.width = w;
            this.toastTf.height = h;
            this.toastBg.graphics.clear();
            this.toastBg.graphics.beginFill(uint(parseInt(String(this.cfg.backgroundColor))),0.85);
            this.toastBg.graphics.drawRoundRect(Number(org.x),this.toastTf.y - 2,w + 24,h + 4,8,8);
            this.toastBg.graphics.endFill();
            this.toastBg.visible = true;
            this.toastTf.visible = true;
            this.visible = true;
            this.toastUntil = getTimer() + int(Number(this.cfg.toastSeconds) * 1000);
         }
         catch(err:Error)
         {
         }
      }

      private function toastTick() : void
      {
         if(this.toastTf != null && this.toastTf.visible && getTimer() >= this.toastUntil)
         {
            this.toastTf.visible = false;
            this.toastBg.visible = false;
            this.toastBg.graphics.clear();
         }
      }

      private function copyObj(o:Object) : Object
      {
         var out:Object = {};
         var k:String = null;
         for(k in o)
         {
            out[k] = o[k];
         }
         return out;
      }

      private function viewMode() : String
      {
         if(this.ov != null && this.ov.viewMode != null)
         {
            return String(this.ov.viewMode);
         }
         return this.baseCfg != null && this.baseCfg.viewMode != null ? String(this.baseCfg.viewMode) : "expanded";
      }

      // working config = base (defaults + json) with the "compact" block merged in when that view is active
      private function buildCfg() : Object
      {
         var out:Object = {};
         var k:String = null;
         var sub:String = null;
         var over:Object = null;
         for(k in this.baseCfg)
         {
            out[k] = this.baseCfg[k];
         }
         out.columns = this.copyObj(this.baseCfg.columns);
         out.score = this.baseCfg.score != null ? this.copyObj(this.baseCfg.score) : null;
         out.viewMode = this.viewMode();
         if(out.viewMode == "compact" && this.baseCfg.compact != null)
         {
            over = this.baseCfg.compact;
            for(k in over)
            {
               if(k == "columns" && over.columns != null)
               {
                  for(sub in over.columns)
                  {
                     out.columns[sub] = over.columns[sub];
                  }
               }
               else if(k != "viewMode")
               {
                  out[k] = over[k];
               }
            }
         }
         return out;
      }

      private function adjustTextSize(item:String) : void
      {
         var small:Boolean = item.indexOf("vb_sts_") == 0;
         var op:String = item.charAt(item.length - 1);
         var key:String = small ? "smallTextSize" : "textSize";
         var cur:int = int(this.cfg[key]);
         var defaults:Object = this.defaultConfig();
         if(op == "0")
         {
            // the mod's built-in default for the view on screen (16/13 expanded, 13/11 compact)
            this.ov[key] = int(this.viewMode() == "compact" && defaults.compact != null && defaults.compact[key] != null ? defaults.compact[key] : defaults[key]);
         }
         else
         {
            this.ov[key] = Math.max(small ? 7 : 8,cur + (op == "p" ? 1 : -1));
         }
         this.ovDirty = true;
         this.applyOverrides();
         this.toast((small ? "small text size " : "text size ") + int(this.cfg[key]));
      }

      private function applyOverrides() : void
      {
         var g:String = null;
         var ids:Array = null;
         var i:int = 0;
         if(this.baseCfg != null)
         {
            this.cfg = this.buildCfg();
         }
         if(this.ov == null)
         {
            return;
         }
         if(this.ov.highlightScore != null)
         {
            this.cfg.highlightScore = Number(this.ov.highlightScore);
         }
         if(this.ov.x != null)
         {
            this.cfg.x = Number(this.ov.x);
         }
         if(this.ov.y != null)
         {
            this.cfg.y = Number(this.ov.y);
         }
         this.badgeList = null;
         if(this.ov.levelOff === true)
         {
            this.cfg.levelScore = null;
         }
         for(g in SCORE_GROUPS)
         {
            if(this.ov["off_" + g] === true && this.cfg.score != null)
            {
               ids = SCORE_GROUPS[g] as Array;
               i = 0;
               while(i < ids.length)
               {
                  delete this.cfg.score[ids[i]];
                  i++;
               }
            }
         }
         if(this.ov.preset != null)
         {
            this.presetIndex = int(this.ov.preset);
         }
         if(this.ov.sortIndex != null)
         {
            this.sortIndex = int(this.ov.sortIndex);
         }
         if(this.ov.hideEmptyShops != null)
         {
            this.cfg.hideEmptyShops = this.ov.hideEmptyShops === true;
         }
         if(this.ov.hideVisited != null)
         {
            this.cfg.hideVisited = this.ov.hideVisited === true;
         }
         if(this.ov.debug != null)
         {
            this.cfg.debug = this.ov.debug === true;
         }
         if(this.ov.showLegend != null)
         {
            this.cfg.showLegend = this.ov.showLegend === true;
         }
         if(this.ov.showFilters != null)
         {
            this.cfg.showFilters = this.ov.showFilters === true;
         }
         if(this.ov.textSize != null)
         {
            this.cfg.textSize = int(this.ov.textSize);
         }
         if(this.ov.smallTextSize != null)
         {
            this.cfg.smallTextSize = int(this.ov.smallTextSize);
         }
         if(this.ov.twoColumns != null)
         {
            this.cfg.wrapRows = this.ov.twoColumns === true ? (int(this.cfg.wrapRows) > 0 ? int(this.cfg.wrapRows) : (int(this.cfg.columnRows) > 0 ? int(this.cfg.columnRows) : 12)) : 0;
         }
         if(this.ov.showKeys != null)
         {
            this.cfg.showKeys = this.ov.showKeys === true;
         }
         if(this.ov.hidden != null)
         {
            this.hidden = this.ov.hidden === true;
         }
      }

      private function encodeOverrides() : String
      {
         return this.encodeObj(this.ov,0);
      }

      private function encodeObj(o:Object, depth:int) : String
      {
         var k:String = null;
         var v:* = undefined;
         var parts:Array = [];
         for(k in o)
         {
            v = o[k];
            if(v is String)
            {
               parts.push("\"" + k + "\":\"" + String(v).replace(/"/g,"") + "\"");
            }
            else if(v is Number || v is Boolean)
            {
               parts.push("\"" + k + "\":" + String(v));
            }
            else if(v != null && !(v is Array) && depth < 2)
            {
               parts.push("\"" + k + "\":" + this.encodeObj(v,depth + 1));
            }
         }
         return "{" + parts.join(",") + "}";
      }

      private function storageTick() : void
      {
         var a:Object = this.xscalApi();
         var stored:* = null;
         var parsed:Object = null;
         if(a == null || this.cfg.rememberChoices !== true)
         {
            this.ovDirty = false;
            return;
         }
         try
         {
            if(a.modStorage == null)
            {
               return;
            }
            this.storage = a.modStorage;
            if(!this.ovLoaded)
            {
               this.ovLoaded = true;
               if(!Boolean(this.storage.register("vendorboard")))
               {
                  return;
               }
               stored = this.storage.load();
               if(stored !== false && stored != null && String(stored).length > 1)
               {
                  parsed = new JSONDecoder(String(stored),true).getValue();
                  if(parsed != null)
                  {
                     this.ov = parsed;
                     this.applyOverrides();
                  }
               }
            }
            if(this.ovDirty)
            {
               this.ovDirty = false;
               if(Boolean(this.storage.register("vendorboard")))
               {
                  this.storage.save(this.encodeOverrides());
               }
            }
         }
         catch(err:Error)
         {
            this.lastError = "storage: " + err.message;
         }
      }

      // ------------------------------------------------------------------ keys

      private function keyCode(name:*) : int
      {
         var s:String = null;
         if(name is Number)
         {
            return int(name);
         }
         if(name == null)
         {
            return 0;
         }
         s = String(name).toUpperCase().replace(/\s+/g,"");
         if(s.length == 0)
         {
            return 0;
         }
         if(KEYS[s] != null)
         {
            return int(KEYS[s]);
         }
         if(s.length == 1)
         {
            return s.charCodeAt(0);
         }
         return 0;
      }

      private function xscalApi() : Object
      {
         if(this.api != null)
         {
            return this.api;
         }
         try
         {
            if(this.topLevel != null && this.topLevel.__SFCodeObj != null && this.topLevel.__SFCodeObj.call != null)
            {
               this.api = this.topLevel.__SFCodeObj;
            }
         }
         catch(err:Error)
         {
         }
         return this.api;
      }

      private function keyHeld(code:int) : Boolean
      {
         var a:Object = this.xscalApi();
         if(a == null || code <= 0)
         {
            return false;
         }
         try
         {
            if(this.keyRegistered[String(code)] !== true)
            {
               a.call("Input.RegisterKey",code);
               this.keyRegistered[String(code)] = true;
            }
            return Boolean(a.call("Input.IsKeyPressed",code));
         }
         catch(err:Error)
         {
         }
         return false;
      }

      private function unregisterKeys() : void
      {
         var k:String = null;
         var a:Object = this.xscalApi();
         var any:Boolean = false;
         for(k in this.keyRegistered)
         {
            any = true;
            break;
         }
         if(!any)
         {
            return;
         }
         if(a != null)
         {
            for(k in this.keyRegistered)
            {
               try
               {
                  a.call("Input.UnregisterKey",int(k));
               }
               catch(err:Error)
               {
               }
            }
         }
         this.keyRegistered = {};
      }

      private function onKeyTick(e:TimerEvent) : void
      {
         var i:int = 0;
         var list:Array = this.cfg.presets as Array;
         this.toastTick();
         if(this.cfg.hotkeys === false || (!this.isVisibleNow() && !this.isModeVisible()))
         {
            this.unregisterKeys();
            this.keyWasDown = {};
            return;
         }
         this.pollKey("show",this.keyCode(this.cfg.showKey));
         this.pollKey("view",this.keyCode(this.cfg.viewKey));
         this.pollKey("preset",this.keyCode(this.cfg.presetKey));
         this.pollKey("sort",this.keyCode(this.cfg.sortKey));
         while(list != null && i < list.length)
         {
            if(list[i] != null && list[i].key != null)
            {
               this.pollKey("preset:" + i,this.keyCode(list[i].key));
            }
            i++;
         }
      }

      private function pollKey(action:String, code:int) : void
      {
         var down:Boolean = this.keyHeld(code);
         if(down && this.keyWasDown[action] !== true)
         {
            this.doAction(action);
         }
         this.keyWasDown[action] = down;
      }


      private function doAction(action:String) : void
      {
         var list:Array = null;
         var n:int = 0;
         if(action.indexOf("preset:") == 0)
         {
            list = this.cfg.presets as Array;
            n = int(action.substr(7));
            if(list != null && n >= 0 && n < list.length)
            {
               this.presetIndex = n;
               this.presetFlashUntil = getTimer() + 2500;
               this.ov.preset = n;
               this.ovDirty = true;
            }
            this.render();
            return;
         }
         if(action == "view")
         {
            // expanded -> compact -> hidden -> expanded
            if(this.hidden)
            {
               this.hidden = false;
               this.ov.viewMode = "expanded";
            }
            else if(this.viewMode() == "compact")
            {
               this.hidden = true;
            }
            else
            {
               this.ov.viewMode = "compact";
            }
            this.ov.hidden = this.hidden;
            this.ovDirty = true;
            this.applyOverrides();
         }
         else if(action == "show")
         {
            if(this.isModeVisible())
            {
               this.hidden = !this.hidden;
            }
            else if(this.cfg.allowOverlay === true)
            {
               this.forceShow = !this.forceShow;
            }
            this.ov.hidden = this.hidden;
            this.ovDirty = true;
         }
         else if(action == "sort")
         {
            list = this.cfg.sorts as Array;
            if(list != null && list.length > 0)
            {
               this.sortIndex = (this.sortIndex + 1) % list.length;
               this.ov.sortIndex = this.sortIndex;
               this.ovDirty = true;
            }
         }
         else if(action == "preset")
         {
            list = this.cfg.presets as Array;
            if(list != null && list.length > 0)
            {
               this.presetIndex = (this.presetIndex + 1) % list.length;
               this.presetFlashUntil = getTimer() + 2500;
               this.ov.preset = this.presetIndex;
               this.ovDirty = true;
            }
         }
         this.render();
      }

      // ------------------------------------------------------------------ rendering

      private function isModeVisible() : Boolean
      {
         var modes:Array = this.cfg.hudModes as Array;
         return modes != null && modes.indexOf(this.hudMode) >= 0;
      }

      private function isVisibleNow() : Boolean
      {
         if(this.hudMode == "Loading" || this.hudMode == "MainMenu")
         {
            return false;
         }
         if(this.isModeVisible())
         {
            return !this.hidden;
         }
         return this.cfg.allowOverlay === true && this.forceShow;
      }

      private function color(name:String) : uint
      {
         var v:* = this.cfg.colors != null ? this.cfg.colors[name] : null;
         if(v == null)
         {
            return 16777215;
         }
         return uint(v is String ? parseInt(String(v)) : v);
      }

      private function hex(c:uint) : String
      {
         var s:String = c.toString(16);
         while(s.length < 6)
         {
            s = "0" + s;
         }
         return "#" + s;
      }

      private function makeField() : TextField
      {
         var tf:TextField = new TextField();
         tf.multiline = false;
         tf.wordWrap = false;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.autoSize = TextFieldAutoSize.NONE;
         addChild(tf);
         return tf;
      }

      private function styleField(tf:TextField, colorValue:uint, align:String = "left", size:Number = 0) : void
      {
         var fmt:TextFormat = new TextFormat(String(this.cfg.font),size > 0 ? size : Number(this.cfg.textSize),colorValue);
         fmt.align = align;
         tf.defaultTextFormat = fmt;
         tf.setTextFormat(fmt);
         tf.filters = this.cfg.textShadow === true ? [new DropShadowFilter(2,45,0,1,1,1,1,BitmapFilterQuality.HIGH)] : [];
         tf.alpha = 1;
      }

      private function rowAt(i:int) : Object
      {
         var r:Object = null;
         while(this.rows.length <= i)
         {
            r = {"level":this.makeField(),"name":this.makeField(),"dist":this.makeField(),"vendor":this.makeField(),"pills":new Sprite(),"pillTfs":[]};
            addChild(r.pills);
            this.rows.push(r);
         }
         return this.rows[i];
      }

      private function setBoardVisible(flag:Boolean) : void
      {
         this.panel.visible = flag;
         if(!flag)
         {
            this.panel.graphics.clear();
            this.header.visible = false;
            this.keysLine.visible = false;
            this.legend.visible = false;
            this.status.visible = false;
            if(this.colTitles != null)
            {
               this.colTitles.level.visible = false;
               this.colTitles.name.visible = false;
               this.colTitles.dist.visible = false;
               this.colTitles.vendor.visible = false;
            }
            this.hideRowsFrom(0);
         }
         this.visible = true;
      }

      private function hideRowsFrom(i:int) : void
      {
         var r:Object = null;
         while(i < this.rows.length)
         {
            r = this.rows[i];
            r.level.visible = false;
            r.name.visible = false;
            r.dist.visible = false;
            r.vendor.visible = false;
            r.pills.visible = false;
            i++;
         }
      }

      private function shortName(name:String) : String
      {
         var max:int = int(this.cfg.nameMaxChars);
         if(max > 3 && name.length > max)
         {
            return name.substr(0,max - 1) + String.fromCharCode(8230);
         }
         return name;
      }

      private function typeColor(p:Object) : uint
      {
         if(p.local)
         {
            return this.color("local");
         }
         if(p.type == "MostWanted" || p.bounty > 0)
         {
            return this.color("wanted");
         }
         if(p.isFriend)
         {
            return this.color("friend");
         }
         if(p.type == "TeamLeader")
         {
            return this.color("teamLeader");
         }
         if(p.type == "TeamMember")
         {
            return this.color("teamMember");
         }
         return this.color("remote");
      }

      private function defaultBadge(id:String) : Object
      {
         var m:Array = id.match(/^(MODS_WEAPON|MODS_ARMOR|MODS_PA|WEAPON|ARMOR)(\d)$/);
         var tier:int = 0;
         var kind:String = null;
         var colors:Object = {"4":"0xf6cd60","3":"0xe0b48c","2":"0xd6c9a8","1":"0xcfc6b0","0":"0xc8b98a"};
         var names:Object = {"APPAREL":"Aprl","MODS":"Mods","PLAN":"Plan","STIMPAK":"Stim","MEDS":"Meds","FOOD":"Food","DRINK":"Drink","AMMO":"Ammo","EXPLOSIVE":"Expl","JUNK":"Junk","MISC":"Misc"};
         if(m != null)
         {
            kind = String(m[1]);
            tier = int(m[2]);
            if(kind == "MODS_WEAPON")
            {
               return {"id":id,"label":tier + "{star}W","color":colors[String(tier)]};
            }
            if(kind == "MODS_ARMOR")
            {
               return {"id":id,"label":tier + "{star}A","color":colors[String(tier)]};
            }
            if(kind == "MODS_PA")
            {
               return {"id":id,"label":tier + "{star}PA","color":colors[String(tier)]};
            }
            if(kind == "WEAPON")
            {
               return {"id":id,"label":tier > 0 ? "Wep" + tier + "{star}" : "Wep","color":tier == 4 ? "0xff9f6e" : colors[String(tier)]};
            }
            return {"id":id,"label":tier > 0 ? "Arm" + tier + "{star}" : "Arm","color":tier == 4 ? "0xff9f6e" : colors[String(tier)]};
         }
         return {"id":id,"label":names[id] != null ? names[id] : id,"color":id == "PLAN" ? "0x9fd79a" : (id == "APPAREL" ? "0xc9a7ff" : (id == "MODS" ? "0xa09a84" : "0x9fc7c1"))};
      }

      private function badgeOn(id:String) : Boolean
      {
         var i:int = 0;
         var list:Array = this.userBadges();
         while(i < list.length)
         {
            if(list[i].id == id)
            {
               return true;
            }
            i++;
         }
         return false;
      }

      private function isFixedPreset(preset:Object) : Boolean
      {
         return preset != null && (preset.badges == "all" || preset.badges is Array);
      }

      private function effectiveBadges() : Array
      {
         var i:int = 0;
         var id:String = null;
         var out:Array = [];
         var seen:Object = {};
         var preset:Object = this.currentPreset();
         var presetBadges:Array = null;
         if(this.badgeList != null)
         {
            return this.badgeList;
         }
         if(this.isFixedPreset(preset))
         {
            presetBadges = preset.badges == "all" ? CATEGORY_ORDER : preset.badges as Array;
            while(i < presetBadges.length)
            {
               id = String(presetBadges[i]);
               if(CATEGORY_INDEX[id] != null && !seen[id])
               {
                  out.push(this.defaultBadge(id));
                  seen[id] = true;
               }
               i++;
            }
         }
         else
         {
            out = this.userBadges();
         }
         out.sort(this.badgeRank);
         this.badgeList = out;
         return out;
      }

      private function userBadges() : Array
      {
         var i:int = 0;
         var id:String = null;
         var out:Array = [];
         var seen:Object = {};
         var list:Array = this.cfg.badges as Array;
         var off:Object = this.ov.badgeOff != null ? this.ov.badgeOff : {};
         var on:Object = this.ov.badgeOn != null ? this.ov.badgeOn : {};
         while(list != null && i < list.length)
         {
            if(list[i] != null && CATEGORY_INDEX[list[i].id] != null && off[list[i].id] !== true)
            {
               out.push(list[i]);
               seen[list[i].id] = true;
            }
            i++;
         }
         i = 0;
         while(i < CATEGORY_ORDER.length)
         {
            id = String(CATEGORY_ORDER[i]);
            if(on[id] === true && !seen[id] && off[id] !== true)
            {
               out.push(this.defaultBadge(id));
               seen[id] = true;
            }
            i++;
         }
         return out;
      }

      private function badgeRank(a:Object, b:Object) : int
      {
         var ra:int = CATEGORY_ORDER.indexOf(String(a.id));
         var rb:int = CATEGORY_ORDER.indexOf(String(b.id));
         return ra < rb ? -1 : (ra > rb ? 1 : 0);
      }

      private function toggleBadge(id:String) : void
      {
         if(this.ov.badgeOff == null)
         {
            this.ov.badgeOff = {};
         }
         if(this.ov.badgeOn == null)
         {
            this.ov.badgeOn = {};
         }
         if(this.badgeOn(id))
         {
            this.ov.badgeOff[id] = true;
            delete this.ov.badgeOn[id];
         }
         else
         {
            this.ov.badgeOn[id] = true;
            delete this.ov.badgeOff[id];
         }
         this.badgeList = null;
      }

      private function badgeItems(counts:Object) : Array
      {
         var i:int = 0;
         var b:Object = null;
         var idx:int = 0;
         var out:Array = [];
         var list:Array = this.effectiveBadges();
         if(counts == null || list == null)
         {
            return out;
         }
         while(i < list.length)
         {
            b = list[i];
            i++;
            if(b == null || CATEGORY_INDEX[b.id] == null)
            {
               continue;
            }
            idx = int(CATEGORY_INDEX[b.id]);
            if(counts.length > idx && counts[idx] > 0)
            {
               out.push({"label":this.cfg.viewMode == "compact" ? this.compactLabel(String(b.id)) : String(b.label != null ? b.label : b.id).split("{star}").join(STAR),"count":int(counts[idx]),"color":uint(b.color is String ? parseInt(String(b.color)) : b.color)});
            }
         }
         return out;
      }

      private function rowSpans(p:Object) : Array
      {
         var items:Array = this.rowPills(p);
         var i:int = 0;
         var out:Array = [];
         while(i < items.length)
         {
            if(i > 0)
            {
               out.push("  ");
            }
            if(int(items[i].count) < 0)
            {
               out.push(this.span(items[i].color,String(items[i].label)));
            }
            else if(this.cfg.viewMode == "compact")
            {
               out.push(this.span(items[i].color,items[i].label + ":" + items[i].count));
            }
            else
            {
               out.push(this.span(items[i].color,items[i].label + " " + items[i].count));
            }
            i++;
         }
         return out;
      }

      private function rowPills(p:Object) : Array
      {
         var items:Array = this.badgeItems(p.counts);
         var preset:Object = this.currentPreset();
         if(items.length == 0 && !p.local)
         {
            items.push({"label":p.counts != null || p.camp != null ? "empty shop" : "no shop","count":-1,"color":uint(parseInt(String(this.cfg.pillOverflowColor)))});
         }
         return items;
      }

      // a + (b - a) * k per channel; k = 0 gives a, 1 gives b
      private function mixColor(a:uint, b:uint, k:Number) : uint
      {
         var r:int = int(((a >> 16) & 255) + (((b >> 16) & 255) - ((a >> 16) & 255)) * k);
         var g:int = int(((a >> 8) & 255) + (((b >> 8) & 255) - ((a >> 8) & 255)) * k);
         var bl:int = int((a & 255) + ((b & 255) - (a & 255)) * k);
         return uint((r << 16) | (g << 8) | bl);
      }

      private function measureText(s:String) : Number
      {
         var fmt:TextFormat = new TextFormat(String(this.cfg.font),Number(this.cfg.textSize),0);
         if(this.measureTf == null)
         {
            this.measureTf = new TextField();
            this.measureTf.multiline = false;
            this.measureTf.wordWrap = false;
            this.measureTf.autoSize = "left";
         }
         this.measureTf.defaultTextFormat = fmt;
         this.measureTf.text = s;
         this.measureTf.setTextFormat(fmt);
         return this.measureTf.textWidth;
      }

      private function drawPills(r:Object, items:Array, rowH:Number, maxW:Number, muted:Boolean) : Number
      {
         var i:int = 0;
         var tf:TextField = null;
         var w:Number = 0;
         var x:Number = 0;
         var gap:Number = Number(this.cfg.pillGap);
         var radius:Number = Number(this.cfg.pillRadius);
         var textColor:uint = uint(parseInt(String(this.cfg.pillTextColor)));
         var fmt:TextFormat = null;
         var n:int = items.length;
         var reserve:Number = 0;
         var label:String = null;
         var color:uint = 0;
         var overflow:Boolean = false;
         var wrap:Boolean = this.cfg.pillWrap === true && maxW > 0;
         var pad:Number = Number(this.cfg.pillPad) > 0 ? Number(this.cfg.pillPad) : 14;
         var line:int = 0;
         var widest:Number = 0;
         if(maxW > 0 && n > 1 && !wrap)
         {
            reserve = this.measureText("+" + n) + pad + gap;
         }
         r.pills.graphics.clear();
         r.pillLines = 1;
         while(i < n)
         {
            while(r.pillTfs.length <= i)
            {
               tf = new TextField();
               tf.multiline = false;
               tf.wordWrap = false;
               tf.selectable = false;
               tf.mouseEnabled = false;
               r.pills.addChild(tf);
               r.pillTfs.push(tf);
            }
            tf = r.pillTfs[i];
            fmt = new TextFormat(String(this.cfg.font),Number(this.cfg.textSize),textColor);
            fmt.align = "center";
            tf.defaultTextFormat = fmt;
            tf.filters = [];
            label = int(items[i].count) < 0 ? String(items[i].label) : items[i].label + " " + items[i].count;
            color = muted ? this.mixColor(uint(parseInt(String(this.cfg.visitedPillColor))),uint(items[i].color),Number(this.cfg.visitedTint)) : uint(items[i].color);
            w = this.measureText(label) + pad;
            if(wrap)
            {
               if(x > 0 && x + w > maxW)
               {
                  line++;
                  x = 0;
               }
            }
            else if(maxW > 0 && x + w > maxW - (i < n - 1 ? reserve : 0))
            {
               label = "+" + (n - i);
               color = uint(parseInt(String(this.cfg.pillOverflowColor)));
               w = this.measureText(label) + pad;
               overflow = true;
            }
            tf.text = label;
            tf.setTextFormat(fmt);
            tf.x = x;
            tf.y = line * rowH;
            tf.width = w;
            tf.height = rowH;
            tf.visible = true;
            r.pills.graphics.beginFill(color,Number(this.cfg.pillAlpha));
            r.pills.graphics.drawRoundRect(x,line * rowH + 2,w,rowH - 4,radius,radius);
            r.pills.graphics.endFill();
            x += w + gap;
            if(x - gap > widest)
            {
               widest = x - gap;
            }
            i++;
            if(overflow)
            {
               break;
            }
         }
         r.pillLines = line + 1;
         while(i < r.pillTfs.length)
         {
            r.pillTfs[i].visible = false;
            i++;
         }
         return widest;
      }

      // two-letter tokens for the compact view; colour (legend) carries the family
      private function compactLabel(id:String) : String
      {
         var custom:Object = this.cfg.compactLabels;
         if(custom != null && custom[id] != null)
         {
            return String(custom[id]);
         }
         var m:Array = id.match(/^(MODS_WEAPON|MODS_ARMOR|MODS_PA|WEAPON|ARMOR)(\d)$/);
         var names:Object = {"APPAREL":"Ap","MODS":"Mo","PLAN":"Pl","STIMPAK":"St","MEDS":"Md","FOOD":"Fd","DRINK":"Dr","AMMO":"Am","EXPLOSIVE":"Ex","JUNK":"Jk","MISC":"Ms"};
         var kind:String = null;
         var tier:String = null;
         if(m != null)
         {
            kind = String(m[1]);
            tier = String(m[2]);
            if(kind == "MODS_WEAPON")
            {
               return tier + "W";
            }
            if(kind == "MODS_ARMOR")
            {
               return tier + "A";
            }
            if(kind == "MODS_PA")
            {
               return tier + "P";
            }
            if(kind == "WEAPON")
            {
               return tier == "0" ? "W" : "W" + tier;
            }
            return tier == "0" ? "A" : "A" + tier;
         }
         return names[id] != null ? String(names[id]) : id;
      }


      // widest the shop column may be: fixed at columns.vendor unless vendorGrow lets it grow to vendorMax
      private function vendorCap(cols:Object) : Number
      {
         if(this.cfg.fixedWidth === true && this.cfg.vendorGrow === true && cols.vendorMax != null)
         {
            return Number(cols.vendorMax);
         }
         return Number(cols.vendor);
      }

      private function scaledColumns(src:Object, k:Number) : Object
      {
         var out:Object = {};
         var key:String = null;
         for(key in src)
         {
            out[key] = src[key] is Number ? Math.round(Number(src[key]) * k) : src[key];
         }
         return out;
      }

      private function fit(tf:TextField, maxW:Number, current:Number) : Number
      {
         var w:Number = tf.textWidth + 10;
         if(w > maxW)
         {
            w = maxW;
         }
         return w > current ? w : current;
      }

      private function span(c:uint, s:String) : Object
      {
         return {"text":s,"color":c};
      }

      private function setSpans(tf:TextField, spans:Array) : void
      {
         var i:int = 0;
         var text:String = "";
         var pos:int = 0;
         var fmt:TextFormat = null;
         while(i < spans.length)
         {
            text += spans[i] is String ? String(spans[i]) : String(spans[i].text);
            i++;
         }
         tf.text = text;
         i = 0;
         while(i < spans.length)
         {
            if(spans[i] is String)
            {
               pos += String(spans[i]).length;
            }
            else
            {
               if(String(spans[i].text).length > 0)
               {
                  fmt = new TextFormat();
                  fmt.color = uint(spans[i].color);
                  tf.setTextFormat(fmt,pos,pos + String(spans[i].text).length);
               }
               pos += String(spans[i].text).length;
            }
            i++;
         }
      }

      // level 0: full; 1: without the sort hint; 2: also without the population count
      private function headerSpans(level:int, countColor:uint, total:int, max:int, preset:Object, shownCount:int) : Array
      {
         var out:Array = [];
         if(level < 2)
         {
            out.push(String(this.cfg.headerLabel) + " ",this.span(countColor,total + "/" + max),"   ");
         }
         out.push(this.span(this.color("distance"),"FILTER: "),(preset != null ? String(preset.name) : "ALL") + (shownCount < total ? " (" + shownCount + ")" : ""),"   ",this.span(this.color("distance"),"SORT: "),this.sortKey());
         if(level < 1 && this.currentSort().hint != null)
         {
            out.push(this.span(this.color("distance")," (" + String(this.currentSort().hint) + ")"));
         }
         return out;
      }

      private function legendSpans() : Array
      {
         return [this.span(this.color("header"),"Players: "),this.span(this.color("local"),"you"),"  ",this.span(this.color("friend"),"friend"),"  ",this.span(this.color("teamLeader"),"team"),"  ",this.span(this.color("wanted"),"wanted"),"  ",this.span(this.color("visited"),"visited"),
            "\n",this.span(this.color("header"),"Shop: "),
            this.span(this.refColor("MODS_WEAPON4"),"4" + STAR + " mods"),"  ",this.span(this.refColor("WEAPON4"),"4" + STAR + " items"),"  ",this.span(this.refColor("MODS_WEAPON3"),"3" + STAR),"  ",this.span(this.refColor("MODS_WEAPON2"),"2" + STAR),"  ",this.span(this.refColor("MODS_WEAPON1"),"1" + STAR),"  ",this.span(this.refColor("WEAPON0"),"plain gear"),"  ",
            this.span(this.refColor("MODS"),"mods (any)"),"  ",this.span(this.refColor("APPAREL"),"apparel"),"  ",this.span(this.refColor("PLAN"),"plans"),"  ",this.span(this.refColor("STIMPAK"),"aid / ammo / junk / misc")];
      }

      private function keySpans() : Array
      {
         var i:int = 0;
         var list:Array = this.cfg.presets as Array;
         var out:Array = [];
         var muted:uint = this.color("distance");
         var label:String = null;
         if(this.cfg.showFilters !== true)
         {
            list = null;
         }
         else
         {
            out.push(this.span(this.color("header"),"Filters: "));
         }
         while(list != null && i < list.length)
         {
            if(list[i] != null)
            {
               label = String(list[i].name);
               if(list[i].key != null)
               {
                  label = String(list[i].key) + " " + label;
               }
               if(i == this.presetIndex)
               {
                  out.push(this.span(this.color("highlight"),String.fromCharCode(187) + " " + label));
               }
               else
               {
                  out.push(this.span(this.color("remote"),label));
               }
               out.push("   ");
            }
            i++;
         }
         if(this.cfg.showKeys !== true)
         {
            return out;
         }
         if(out.length > 0)
         {
            out.push("\n");
         }
         out.push(this.span(this.color("header"),"Hotkeys: "));
         var parts:Array = [];
         if(this.keyCode(this.cfg.presetKey) > 0)
         {
            parts.push(String(this.cfg.presetKey) + " next filter preset");
         }
         if(this.keyCode(this.cfg.sortKey) > 0)
         {
            parts.push(String(this.cfg.sortKey) + " next sort preset");
         }
         if(this.keyCode(this.cfg.showKey) > 0)
         {
            parts.push(String(this.cfg.showKey) + " hide");
         }
         if(this.keyCode(this.cfg.viewKey) > 0)
         {
            parts.push(String(this.cfg.viewKey) + " expanded / compact / hide");
         }
         out.push(this.span(muted,parts.join("   ")));
         return out;
      }

      // reference colour of a category: json "badges" entry if present, else the built-in default (preset-independent)
      private function refColor(id:String) : uint
      {
         var i:int = 0;
         var list:Array = this.cfg.badges as Array;
         var b:Object = null;
         while(list != null && i < list.length)
         {
            if(list[i] != null && list[i].id == id && list[i].color != null)
            {
               return uint(list[i].color is String ? parseInt(String(list[i].color)) : list[i].color);
            }
            i++;
         }
         b = this.defaultBadge(id);
         return uint(b.color is String ? parseInt(String(b.color)) : b.color);
      }

      private function badgeColor(id:String) : uint
      {
         var i:int = 0;
         var list:Array = this.effectiveBadges();
         while(list != null && i < list.length)
         {
            if(list[i] != null && list[i].id == id)
            {
               return uint(list[i].color is String ? parseInt(String(list[i].color)) : list[i].color);
            }
            i++;
         }
         return this.color("remote");
      }

      private function debugLine() : String
      {
         var d:Object = this.dbg;
         var s:String = "markers=" + int(d.markers) + " acts=" + int(d.acts) + " vend=" + int(d.vend) + " campsAll=" + int(d.campsAll) + " campsVend=" + int(d.camps) + " matched=" + int(d.matched) + " campOnly=" + int(d.campOnly) + " zero=" + int(d.zero);
         if(d.camp0 != null)
         {
            s += " camp0=" + d.camp0;
         }
         if(d.ply0 != null)
         {
            s += " ply0=" + d.ply0;
         }
         if(d.raErr != null)
         {
            s += " raErr=" + d.raErr;
         }
         if(d.campKeys != null)
         {
            s += " camp{" + d.campKeys + "}";
         }
         if(d.act0 != null)
         {
            s += " sortStyle=" + this.activitySort + " act0=" + d.act0;
         }
         if(d.actKeys != null)
         {
            s += " act{" + d.actKeys + "}";
         }
         return s;
      }

      private function render() : void
      {
         var data:Object = null;
         var list:Array = null;
         var shown:Array = [];
         var i:int = 0;
         var p:Object = null;
         var r:Object = null;
         var y:Number = 0;
         var rowH:Number = 0;
         var x0:Number = 0;
         var cols:Object = null;
         var preset:Object = null;
         var countColor:uint = 0;
         var total:int = 0;
         var wLevel:Number = 0;
         var wName:Number = 0;
         var wDist:Number = 0;
         var wVendor:Number = 0;
         var totalW:Number = 0;
         var showLevel:Boolean = false;
         var showDist:Boolean = false;
         var statusText:String = "";
         if(this.cfg == null || this.panel == null)
         {
            return;
         }
         if(!this.isVisibleNow())
         {
            this.setBoardVisible(false);
            return;
         }
         this.setBoardVisible(true);
         this.badgeList = null;
         try
         {
            data = this.collect();
            list = data.players;
            total = list.length;
            this.sortPlayers(list);
            while(i < list.length)
            {
               if(this.passesPreset(list[i]))
               {
                  shown.push(list[i]);
               }
               i++;
            }
            if(shown.length > int(this.cfg.maxRows))
            {
               shown = shown.slice(0,int(this.cfg.maxRows));
            }
            cols = this.cfg.columns;
            if(this.cfg.scaleColumns === true && Number(this.cfg.textSize) > 0 && Number(this.cfg.textSize) != 16)
            {
               cols = this.scaledColumns(this.cfg.columns,Number(this.cfg.textSize) / 16);
            }
            showLevel = this.cfg.showLevel === true;
            showDist = this.cfg.showDistance === true || this.cfg.showCost === true;
            var org:Object = this.origin();
            x0 = Number(org.x) + Number(this.cfg.padding);
            y = Number(org.y) + Number(this.cfg.padding);
            rowH = Number(this.cfg.textSize) + 6 + Number(this.cfg.rowSpacing);
            preset = this.currentPreset();
            // pass 1: text + measure
            i = 0;
            while(i < shown.length)
            {
               p = shown[i];
               r = this.rowAt(i);
               this.styleField(r.level,p.visited && !p.local ? this.color("visited") : this.typeColor(p),"right");
               r.level.text = String(p.level);
               this.styleField(r.name,p.visited && !p.local ? this.color("visited") : this.typeColor(p));
               r.name.text = this.shortName(p.name) + (p.bounty > 0 ? " (" + p.bounty + "c)" : "") + (p.isFriend ? " [F]" : "");
               this.styleField(r.dist,this.color("distance"),this.cfg.showDistance === true ? "left" : "right");
               r.dist.text = p.local ? "" : (this.cfg.showDistance === true ? (p.dist >= 0 ? String(p.dist) + (this.cfg.showDirection === true ? " " + p.dir : "") : "") + (this.cfg.showCost === true ? "  " + this.costText(p) : "") : (this.cfg.showCost === true ? this.costText(p) : ""));
               r.level.width = Number(cols.level);
               r.name.width = Number(cols.name);
               r.dist.width = Number(cols.distance);
               wLevel = this.fit(r.level,Number(cols.level),wLevel);
               wName = this.fit(r.name,Number(cols.name),wName);
               wDist = this.fit(r.dist,this.cfg.showDistance === true ? Number(cols.distance) : Number(cols.cost != null ? cols.cost : 60),wDist);
               if(this.cfg.badgeStyle == "pill")
               {
                  r.vendor.htmlText = "";
                  p.pillW = this.drawPills(r,this.rowPills(p),rowH,this.vendorCap(cols),p.visited === true && !p.local);
                  p.rowPx = rowH * int(r.pillLines > 0 ? r.pillLines : 1);
                  if(p.pillW > wVendor)
                  {
                     wVendor = Math.min(p.pillW,this.vendorCap(cols));
                  }
               }
               else
               {
                  p.pillW = 0;
                  this.styleField(r.vendor,p.score >= Number(this.cfg.highlightScore) ? this.color("highlight") : this.color("remote"));
                  r.vendor.multiline = true;
                  r.vendor.wordWrap = this.cfg.fixedWidth === true;
                  r.vendor.width = Number(cols.vendor);
                  this.setSpans(r.vendor,this.rowSpans(p));
                  p.rowPx = r.vendor.text.length > 0 ? Math.max(rowH,r.vendor.textHeight + 2 + Number(this.cfg.rowSpacing)) : rowH;
                  if(r.vendor.text.length > 0)
                  {
                     wVendor = this.fit(r.vendor,Number(cols.vendor),wVendor);
                  }
               }
               i++;
            }
            if(this.cfg.fixedWidth === true)
            {
               wLevel = Number(cols.level);
               wName = Number(cols.name);
               wDist = this.cfg.showDistance === true ? Number(cols.distance) : Number(cols.cost != null ? cols.cost : 60);
               wVendor = this.cfg.vendorGrow === true ? Math.max(Number(cols.vendor),Math.min(wVendor,Number(cols.vendorMax != null ? cols.vendorMax : 900))) : Number(cols.vendor);
            }
            if(!showLevel)
            {
               wLevel = 0;
            }
            if(!showDist)
            {
               wDist = 0;
            }
            totalW = wLevel + wName + wDist + wVendor + (wLevel > 0 ? 6 : 0) + (wDist > 0 ? 6 : 0) + (wVendor > 0 ? 6 : 0);
            // side-by-side blocks are known now, so the header, titles and panel use the full width
            var wrapRows:int = int(this.cfg.wrapRows);
            var blocks:int = wrapRows > 0 ? int(Math.ceil(shown.length / wrapRows)) : 1;
            var blockW:Number = totalW;
            if(blocks > 1)
            {
               totalW = blocks * blockW + (blocks - 1) * 24;
            }
            if(this.cfg.showHeader === true)
            {
               countColor = total >= 0.9 * int(data.max) ? this.color("countFull") : this.color("count");
               this.styleField(this.header,this.color("header"));
               this.header.multiline = false;
               this.header.wordWrap = false;
               this.header.width = 4000;
               // one line, never wrapped or shortened: the panel widens a little when the header needs it
               this.setSpans(this.header,this.headerSpans(0,countColor,total,data.max,preset,shown.length));
               if(this.header.textWidth + 10 > totalW)
               {
                  if(blocks > 1)
                  {
                     blockW += (this.header.textWidth + 10 - totalW) / blocks;
                  }
                  totalW = this.header.textWidth + 10;
               }
               this.header.x = x0;
               this.header.y = y;
               this.header.width = totalW;
               this.header.height = rowH;
               this.header.visible = true;
               y += rowH;
            }
            else
            {
               this.header.visible = false;
            }

            if(this.cfg.showColumnTitles === true && shown.length > 0)
            {
               var ct:Object = this.cfg.columnTitles != null ? this.cfg.columnTitles : {};
               this.styleField(this.colTitles.level,this.color("header"),"right");
               this.colTitles.level.text = showLevel ? String(ct.level != null ? ct.level : "LVL") : "";
               this.styleField(this.colTitles.name,this.color("header"));
               this.colTitles.name.text = String(ct.name != null ? ct.name : "PLAYER");
               this.styleField(this.colTitles.dist,this.color("header"),this.cfg.showDistance === true ? "left" : "right");
               this.colTitles.dist.text = showDist ? String(this.cfg.showDistance === true ? (ct.distance != null ? ct.distance : "DIST") : (ct.cost != null ? ct.cost : "CAPS")) : "";
               this.styleField(this.colTitles.vendor,this.color("header"));
               this.colTitles.vendor.text = wVendor > 0 || this.cfg.fixedWidth === true ? String(ct.vendor != null ? ct.vendor : "SHOP") : "";
               wLevel = showLevel ? this.fit(this.colTitles.level,Number(cols.level),wLevel) : 0;
               wName = this.fit(this.colTitles.name,Number(cols.name),wName);
               if(showDist)
               {
                  wDist = this.fit(this.colTitles.dist,this.cfg.showDistance === true ? Number(cols.distance) : Number(cols.cost != null ? cols.cost : 60),wDist);
               }
               blockW = Math.max(blockW,wLevel + wName + wDist + wVendor + (wLevel > 0 ? 6 : 0) + (wDist > 0 ? 6 : 0) + (wVendor > 0 ? 6 : 0));
               totalW = blocks > 1 ? blocks * blockW + (blocks - 1) * 24 : Math.max(totalW,blockW);
               this.colTitles.level.x = x0;
               this.colTitles.level.y = y;
               this.colTitles.level.width = wLevel;
               this.colTitles.level.height = rowH;
               this.colTitles.level.visible = showLevel;
               this.colTitles.name.x = x0 + (showLevel ? wLevel + 6 : 0);
               this.colTitles.name.y = y;
               this.colTitles.name.width = wName;
               this.colTitles.name.height = rowH;
               this.colTitles.name.visible = true;
               this.colTitles.dist.x = this.colTitles.name.x + wName + (showDist ? 6 : 0);
               this.colTitles.dist.y = y;
               this.colTitles.dist.width = wDist;
               this.colTitles.dist.height = rowH;
               this.colTitles.dist.visible = showDist;
               this.colTitles.vendor.x = this.colTitles.dist.x + wDist + (wVendor > 0 ? 6 : 0);
               this.colTitles.vendor.y = y;
               this.colTitles.vendor.width = wVendor;
               this.colTitles.vendor.height = rowH;
               this.colTitles.vendor.visible = wVendor > 0;
               y += rowH;
            }
            else
            {
               this.colTitles.level.visible = false;
               this.colTitles.name.visible = false;
               this.colTitles.dist.visible = false;
               this.colTitles.vendor.visible = false;
            }
            // pass 2: layout (optionally wrapped into side-by-side blocks of wrapRows rows)
            var yTop:Number = y;
            var rowsInBlock:int = wrapRows > 0 ? wrapRows : shown.length;
            var bx:Number = 0;
            var yCur:Number = yTop;
            var maxBottom:Number = yTop;
            var rh:Number = rowH;
            i = 0;
            while(i < shown.length)
            {
               p = shown[i];
               r = this.rowAt(i);
               bx = x0 + (wrapRows > 0 ? int(i / wrapRows) * (blockW + 24) : 0);
               if(wrapRows > 0 ? i % wrapRows == 0 : i == 0)
               {
                  yCur = yTop;
               }
               y = yCur;
               rh = p.rowPx > 0 ? Number(p.rowPx) : rowH;
               yCur += rh;
               if(yCur > maxBottom)
               {
                  maxBottom = yCur;
               }
               r.level.visible = showLevel;
               r.level.x = bx;
               r.level.y = y;
               r.level.width = wLevel;
               r.level.height = rowH;
               r.name.x = bx + (showLevel ? wLevel + 6 : 0);
               r.name.y = y;
               r.name.width = wName;
               r.name.height = rowH;
               r.name.visible = true;
               r.dist.x = r.name.x + wName + (showDist ? 6 : 0);
               r.dist.y = y;
               r.dist.width = wDist;
               r.dist.height = rowH;
               r.dist.visible = showDist;
               r.vendor.x = r.dist.x + wDist + (wVendor > 0 ? 6 : 0);
               r.vendor.y = y;
               r.vendor.width = wVendor;
               r.vendor.height = rh;
               r.vendor.visible = wVendor > 0 && this.cfg.badgeStyle != "pill";
               r.pills.x = r.vendor.x;
               r.pills.y = y;
               r.pills.scrollRect = this.cfg.fixedWidth === true ? new Rectangle(0,0,wVendor,rh) : null;
               r.pills.visible = this.cfg.badgeStyle == "pill" && p.pillW > 0;
               if(this.cfg.fixedWidth === true)
               {
                  r.vendor.visible = this.cfg.badgeStyle != "pill" && r.vendor.text.length > 0;
                  r.colTitlesVendorW = wVendor;
               }
               r.pills.alpha = 1;
               if(p.visited && !p.local)
               {
                  r.level.alpha = Number(this.cfg.visitedAlpha);
                  r.name.alpha = Number(this.cfg.visitedAlpha);
                  r.dist.alpha = Number(this.cfg.visitedAlpha);
                  r.vendor.alpha = Number(this.cfg.visitedAlpha);
                  r.pills.alpha = Number(this.cfg.visitedAlpha);
               }
               i++;
            }
            y = Math.max(maxBottom,yTop + (blocks > 1 ? 0 : int(this.cfg.minRows)) * rowH);
            if(blocks > 1)
            {
               totalW = blocks * blockW + (blocks - 1) * 24;
            }
            this.hideRowsFrom(shown.length);
            var small:Number = Number(this.cfg.smallTextSize) > 0 ? Number(this.cfg.smallTextSize) : Number(this.cfg.textSize) - 3;
            if(this.cfg.showLegend === true)
            {
               this.styleField(this.legend,this.color("distance"),"left",small);
               this.legend.multiline = true;
               this.legend.wordWrap = true;
               this.legend.x = x0;
               this.legend.y = y + 3;
               this.legend.width = Math.max(totalW,360);
               this.setSpans(this.legend,this.legendSpans());
               this.legend.height = this.legend.textHeight + 6;
               this.legend.visible = true;
               y += this.legend.height + 3;
            }
            else
            {
               this.legend.visible = false;
            }
            if(this.cfg.showKeys === true || this.cfg.showFilters === true)
            {
               this.styleField(this.keysLine,this.color("distance"),"left",small);
               this.keysLine.multiline = true;
               this.keysLine.wordWrap = true;
               this.keysLine.x = x0;
               this.keysLine.y = y;
               this.keysLine.width = Math.max(totalW,360);
               this.setSpans(this.keysLine,this.keySpans());
               this.keysLine.height = this.keysLine.textHeight + 6;
               this.keysLine.visible = true;
               y += this.keysLine.height;
            }
            else
            {
               this.keysLine.visible = false;
            }
            if(this.cfg.debug === true)
            {
               statusText = this.debugLine();
            }
            else if(getTimer() < this.presetFlashUntil && preset != null)
            {
               statusText = "FILTER: " + String(preset.name);
            }
            else
            {
               statusText = this.lastError;
            }
            if(statusText.length > 0)
            {
               this.styleField(this.status,this.color("status"));
               this.status.multiline = true;
               this.status.wordWrap = true;
               this.status.x = x0;
               this.status.y = y;
               this.status.width = Math.max(totalW,360);
               this.status.text = statusText;
               this.status.height = this.status.textHeight + 6;
               this.status.visible = true;
               y += this.status.height;
            }
            else
            {
               this.status.visible = false;
            }
            this.panel.graphics.clear();
            if(this.cfg.background === true)
            {
               this.panel.graphics.beginFill(uint(parseInt(String(this.cfg.backgroundColor))),Number(this.cfg.backgroundAlpha));
               this.panel.graphics.drawRect(Number(org.x),Number(org.y),totalW + 2 * Number(this.cfg.padding),y - Number(org.y) + Number(this.cfg.padding));
               this.panel.graphics.endFill();
            }
         }
         catch(err:Error)
         {
            this.lastError = "render: " + err.message;
            try
            {
               this.styleField(this.status,this.color("status"));
               this.status.text = this.lastError;
               this.status.x = Number(this.origin().x);
               this.status.y = Number(this.origin().y);
               this.status.width = 600;
               this.status.height = 24;
               this.status.visible = true;
            }
            catch(err2:Error)
            {
            }
         }
      }
   }
}
