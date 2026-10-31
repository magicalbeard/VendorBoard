/*
 * VendorBoard - Fallout 76 map-screen vendor board.
 * Copyright (C) 2026 MagicalBeard (Patrick Leedom)
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
   import flash.utils.Dictionary;

   // JSON reader / writer for the settings file. Objects remember their key order (in ORDER), so a file
   // written back keeps the user's order; the writer lays it out the way the shipped template does.
   public class SettingsJson
   {

      public static const ORDER:Dictionary = new Dictionary(true);

      public static const WIDTH:int = 120;

      private var s:String;

      private var p:int = 0;

      private var lenient:Boolean;

      public function SettingsJson(text:String, lenient:Boolean)
      {
         super();
         this.s = text;
         this.lenient = lenient;
      }

      // strict: plain JSON (what xScal's mod storage accepts). lenient: also // and /* */ comments and
      // trailing commas (the old Data\VendorBoard.json). Throws Error("line L, column C: ...").
      public static function parse(text:String, lenient:Boolean) : *
      {
         var r:SettingsJson = new SettingsJson(text,lenient);
         var v:* = undefined;
         if(text.charCodeAt(0) == 0xFEFF)
         {
            r.p = 1;
         }
         r.ws();
         v = r.value();
         r.ws();
         if(r.p < r.s.length)
         {
            r.fail("unexpected text after the end");
         }
         return v;
      }

      // The whole settings file: the template's keys in the template's order with its notes (blank lines
      // where the template has them), each value taken from doc when present, then any keys of doc the
      // template does not know. Notes in doc itself are dropped; the template's are always written fresh.
      public static function writeDoc(doc:Object, tpl:Object, breaks:Object, version:String) : String
      {
         var keys:Array = keysOf(tpl,null);
         var texts:Array = [];
         var blanks:Array = [];
         var seen:Object = {};
         var k:String = null;
         var i:int = 0;
         var first:Boolean = true;
         var out:String = "{\n";
         while(i < keys.length)
         {
            k = keys[i];
            seen[k] = true;
            blanks.push(breaks[k] === true);
            if(k == "version")
            {
               texts.push("  " + quote(k) + ": " + quote(version));
            }
            else if(k.indexOf("//") == 0 || !doc.hasOwnProperty(k))
            {
               texts.push(format(tpl[k],tpl[k],"  ","  " + quote(k) + ": "));
            }
            else
            {
               texts.push(format(doc[k],tpl[k],"  ","  " + quote(k) + ": "));
            }
            i++;
         }
         keys = keysOf(doc,null);
         i = 0;
         while(i < keys.length)
         {
            k = keys[i];
            if(!seen[k] && k.indexOf("//") != 0)
            {
               blanks.push(first);
               first = false;
               texts.push(format(doc[k],null,"  ","  " + quote(k) + ": "));
            }
            i++;
         }
         i = 0;
         while(i < texts.length)
         {
            out += (blanks[i] && i > 0 ? "\n" : "") + texts[i] + (i < texts.length - 1 ? "," : "") + "\n";
            i++;
         }
         return out + "}\n";
      }

      public static function keysOf(o:Object, tpl:Object) : Array
      {
         var out:Array = [];
         var seen:Object = {};
         var rest:Array = [];
         var k:String = null;
         var src:Array = ORDER[o] as Array;
         var i:int = 0;
         if(src == null && tpl != null && !(tpl is Array))
         {
            src = ORDER[tpl] as Array;
         }
         while(src != null && i < src.length)
         {
            k = String(src[i]);
            if(o.hasOwnProperty(k) && !seen[k])
            {
               out.push(k);
               seen[k] = true;
            }
            i++;
         }
         for(k in o)
         {
            if(!seen[k])
            {
               rest.push(k);
            }
         }
         rest.sort();
         return out.concat(rest);
      }

      public static function quote(str:String) : String
      {
         var out:String = "\"";
         var i:int = 0;
         var c:int = 0;
         var h:String = null;
         while(i < str.length)
         {
            c = str.charCodeAt(i);
            if(c == 34)
            {
               out += "\\\"";
            }
            else if(c == 92)
            {
               out += "\\\\";
            }
            else if(c == 10)
            {
               out += "\\n";
            }
            else if(c == 13)
            {
               out += "\\r";
            }
            else if(c == 9)
            {
               out += "\\t";
            }
            else if(c < 32)
            {
               h = c.toString(16);
               out += "\\u" + "0000".substr(h.length) + h;
            }
            else
            {
               out += str.charAt(i);
            }
            i++;
         }
         return out + "\"";
      }

      private static function isObj(v:*) : Boolean
      {
         return v != null && typeof v == "object" && !(v is Array);
      }

      private static function child(tpl:*, key:*) : *
      {
         if(tpl is Array)
         {
            return (tpl as Array).length == 0 ? null : (int(key) < (tpl as Array).length ? tpl[int(key)] : tpl[0]);
         }
         return isObj(tpl) && tpl.hasOwnProperty(String(key)) ? tpl[String(key)] : null;
      }

      // one-line form: { "a": 1, "b": [1, 2] }
      public static function inline(v:*, tpl:*) : String
      {
         var parts:Array = [];
         var keys:Array = null;
         var i:int = 0;
         if(v is Array)
         {
            while(i < v.length)
            {
               parts.push(inline(v[i],child(tpl,i)));
               i++;
            }
            return "[" + parts.join(", ") + "]";
         }
         if(isObj(v))
         {
            keys = keysOf(v,tpl);
            while(i < keys.length)
            {
               parts.push(quote(keys[i]) + ": " + inline(v[keys[i]],child(tpl,keys[i])));
               i++;
            }
            return parts.length == 0 ? "{}" : "{ " + parts.join(", ") + " }";
         }
         if(v is String)
         {
            return quote(String(v));
         }
         if(v is Number)
         {
            return isFinite(Number(v)) ? String(v) : "null";
         }
         if(v is Boolean)
         {
            return v ? "true" : "false";
         }
         return "null";
      }

      // `lead` (indent + "key": ) followed by the value, on one line when it fits, else spread out
      public static function format(v:*, tpl:*, indent:String, lead:String) : String
      {
         var one:String = inline(v,tpl);
         var inner:String = indent + "  ";
         var lines:Array = [];
         var keys:Array = null;
         var i:int = 0;
         var scalars:Boolean = true;
         var table:Boolean = true;
         if(lead.length + one.length <= WIDTH || !(v is Array || isObj(v)))
         {
            return lead + one;
         }
         if(v is Array)
         {
            while(i < v.length)
            {
               if(v[i] is Array || isObj(v[i]))
               {
                  scalars = false;
               }
               i++;
            }
            if(scalars)
            {
               return lead + "[\n" + wrap(itemsOf(v,null,tpl),inner) + "\n" + indent + "]";
            }
            i = 0;
            while(i < v.length)
            {
               lines.push(format(v[i],child(tpl,i),inner,inner));
               i++;
            }
            return lead + "[\n" + lines.join(",\n") + "\n" + indent + "]";
         }
         keys = keysOf(v,tpl);
         while(i < keys.length)
         {
            if(v[keys[i]] is Array || isObj(v[keys[i]]))
            {
               scalars = false;
            }
            if(!isObj(v[keys[i]]))
            {
               table = false;
            }
            i++;
         }
         if(scalars)
         {
            return lead + "{\n" + wrap(itemsOf(v,keys,tpl),inner) + "\n" + indent + "}";
         }
         if(table && keys.length > 1)
         {
            lines = tableRows(v,keys,tpl,inner);
            if(lines != null)
            {
               return lead + "{\n" + lines.join(",\n") + "\n" + indent + "}";
            }
         }
         lines = [];
         i = 0;
         while(i < keys.length)
         {
            lines.push(format(v[keys[i]],child(tpl,keys[i]),inner,inner + quote(keys[i]) + ": "));
            i++;
         }
         return lead + "{\n" + lines.join(",\n") + "\n" + indent + "}";
      }

      private static function itemsOf(v:*, keys:Array, tpl:*) : Array
      {
         var out:Array = [];
         var i:int = 0;
         if(keys == null)
         {
            while(i < v.length)
            {
               out.push(inline(v[i],child(tpl,i)));
               i++;
            }
            return out;
         }
         while(i < keys.length)
         {
            out.push(quote(keys[i]) + ": " + inline(v[keys[i]],child(tpl,keys[i])));
            i++;
         }
         return out;
      }

      // items filled into lines up to WIDTH
      private static function wrap(items:Array, indent:String) : String
      {
         var lines:Array = [];
         var cur:String = "";
         var i:int = 0;
         var piece:String = null;
         while(i < items.length)
         {
            piece = items[i] + (i < items.length - 1 ? "," : "");
            if(cur.length > 0 && indent.length + cur.length + 1 + piece.length > WIDTH)
            {
               lines.push(indent + cur);
               cur = "";
            }
            cur = cur.length > 0 ? cur + " " + piece : piece;
            i++;
         }
         if(cur.length > 0)
         {
            lines.push(indent + cur);
         }
         return lines.join("\n");
      }

      // an object of one-line objects with the same keys, as aligned columns:
      //   "MODS_PA4":     { "label": "4{star}PA",  "color": "0xf6cd60" },
      private static function tableRows(v:Object, keys:Array, tpl:*, indent:String) : Array
      {
         var cols:Array = null;
         var cells:Array = [];
         var widths:Array = [];
         var keyW:int = 0;
         var i:int = 0;
         var j:int = 0;
         var row:Object = null;
         var ck:Array = null;
         var out:Array = [];
         var line:String = null;
         var cell:String = null;
         while(i < keys.length)
         {
            row = v[keys[i]];
            ck = keysOf(row,child(tpl,keys[i]));
            if(cols == null)
            {
               cols = ck;
            }
            if(ck.join("\n") != cols.join("\n") || ck.length == 0)
            {
               return null;
            }
            cells[i] = [];
            j = 0;
            while(j < cols.length)
            {
               cell = quote(cols[j]) + ": " + inline(row[cols[j]],child(child(tpl,keys[i]),cols[j])) + (j < cols.length - 1 ? "," : "");
               cells[i].push(cell);
               widths[j] = Math.max(int(widths[j]),cell.length);
               if(row[cols[j]] is Array || isObj(row[cols[j]]))
               {
                  return null;
               }
               j++;
            }
            keyW = Math.max(keyW,quote(keys[i]).length + 1);
            i++;
         }
         i = 0;
         while(i < keys.length)
         {
            line = indent + pad(quote(keys[i]) + ":",keyW) + " { ";
            j = 0;
            while(j < cols.length)
            {
               line += j < cols.length - 1 ? pad(cells[i][j],widths[j]) + " " : cells[i][j];
               j++;
            }
            out.push(line + " }");
            i++;
         }
         return out;
      }

      private static function pad(str:String, w:int) : String
      {
         while(str.length < w)
         {
            str += " ";
         }
         return str;
      }

      // ------------------------------------------------------------------ reader

      private function fail(msg:String) : void
      {
         var line:int = 1;
         var col:int = 1;
         var i:int = 0;
         while(i < this.p && i < this.s.length)
         {
            if(this.s.charCodeAt(i) == 10)
            {
               line++;
               col = 1;
            }
            else
            {
               col++;
            }
            i++;
         }
         throw new Error("line " + line + ", column " + col + ": " + msg);
      }

      private function ws() : void
      {
         var c:int = 0;
         var end:int = 0;
         while(this.p < this.s.length)
         {
            c = this.s.charCodeAt(this.p);
            if(c == 32 || c == 9 || c == 10 || c == 13)
            {
               this.p++;
            }
            else if(c == 47 && this.s.charCodeAt(this.p + 1) == 47)
            {
               if(!this.lenient)
               {
                  this.fail("comments are not allowed (use a \"// name\": \"text\" entry)");
               }
               end = this.s.indexOf("\n",this.p);
               this.p = end < 0 ? this.s.length : end + 1;
            }
            else if(c == 47 && this.s.charCodeAt(this.p + 1) == 42)
            {
               if(!this.lenient)
               {
                  this.fail("comments are not allowed (use a \"// name\": \"text\" entry)");
               }
               end = this.s.indexOf("*/",this.p + 2);
               this.p = end < 0 ? this.s.length : end + 2;
            }
            else
            {
               return;
            }
         }
      }

      private function value() : *
      {
         var c:String = this.s.charAt(this.p);
         if(c == "{")
         {
            return this.object();
         }
         if(c == "[")
         {
            return this.array();
         }
         if(c == "\"")
         {
            return this.string();
         }
         if(this.s.substr(this.p,4) == "true")
         {
            this.p += 4;
            return true;
         }
         if(this.s.substr(this.p,5) == "false")
         {
            this.p += 5;
            return false;
         }
         if(this.s.substr(this.p,4) == "null")
         {
            this.p += 4;
            return null;
         }
         if(c == "-" || (c >= "0" && c <= "9"))
         {
            return this.number();
         }
         if(this.p >= this.s.length)
         {
            this.fail("the file ends too early (missing } or ])");
         }
         this.fail("expected a value, found " + c + (c == "'" ? " (use double quotes)" : ""));
         return null;
      }

      private function object() : Object
      {
         var o:Object = {};
         var keys:Array = [];
         var k:String = null;
         this.p++;
         this.ws();
         if(this.s.charAt(this.p) == "}")
         {
            this.p++;
            ORDER[o] = keys;
            return o;
         }
         while(true)
         {
            if(this.s.charAt(this.p) != "\"")
            {
               this.fail(this.s.charAt(this.p) == "}" ? "comma before } (remove the last comma)" : "expected a \"name\"");
            }
            k = this.string();
            this.ws();
            if(this.s.charAt(this.p) != ":")
            {
               this.fail("expected : after \"" + k + "\"");
            }
            this.p++;
            this.ws();
            if(!o.hasOwnProperty(k))
            {
               keys.push(k);
            }
            o[k] = this.value();
            this.ws();
            if(this.s.charAt(this.p) == ",")
            {
               this.p++;
               this.ws();
               if(this.lenient && this.s.charAt(this.p) == "}")
               {
                  this.p++;
                  break;
               }
               continue;
            }
            if(this.s.charAt(this.p) == "}")
            {
               this.p++;
               break;
            }
            this.fail(this.p >= this.s.length ? "the file ends too early (missing } or ])" : "expected , or } after \"" + k + "\" (missing comma?)");
         }
         ORDER[o] = keys;
         return o;
      }

      private function array() : Array
      {
         var a:Array = [];
         this.p++;
         this.ws();
         if(this.s.charAt(this.p) == "]")
         {
            this.p++;
            return a;
         }
         while(true)
         {
            if(this.s.charAt(this.p) == "]")
            {
               this.fail("comma before ] (remove the last comma)");
            }
            a.push(this.value());
            this.ws();
            if(this.s.charAt(this.p) == ",")
            {
               this.p++;
               this.ws();
               if(this.lenient && this.s.charAt(this.p) == "]")
               {
                  this.p++;
                  break;
               }
               continue;
            }
            if(this.s.charAt(this.p) == "]")
            {
               this.p++;
               break;
            }
            this.fail(this.p >= this.s.length ? "the file ends too early (missing } or ])" : "expected , or ] in a list (missing comma?)");
         }
         return a;
      }

      private function string() : String
      {
         var out:String = "";
         var c:int = 0;
         var e:String = null;
         var start:int = 0;
         this.p++;
         start = this.p;
         while(true)
         {
            if(this.p >= this.s.length)
            {
               this.p = start - 1;
               this.fail("text in quotes is never closed");
            }
            c = this.s.charCodeAt(this.p);
            if(c == 34)
            {
               out += this.s.substring(start,this.p);
               this.p++;
               return out;
            }
            if(c < 32)
            {
               this.fail("line break inside quotes (missing closing \"?)");
            }
            if(c == 92)
            {
               out += this.s.substring(start,this.p);
               e = this.s.charAt(this.p + 1);
               if(e == "n")
               {
                  out += "\n";
               }
               else if(e == "t")
               {
                  out += "\t";
               }
               else if(e == "r")
               {
                  out += "\r";
               }
               else if(e == "b")
               {
                  out += "\b";
               }
               else if(e == "f")
               {
                  out += "\f";
               }
               else if(e == "u")
               {
                  if(!/^[0-9a-fA-F]{4}$/.test(this.s.substr(this.p + 2,4)))
                  {
                     this.fail("bad \\u escape");
                  }
                  out += String.fromCharCode(parseInt(this.s.substr(this.p + 2,4),16));
                  this.p += 4;
               }
               else if(e == "\"" || e == "\\" || e == "/")
               {
                  out += e;
               }
               else
               {
                  this.fail("a backslash must be doubled (\\\\)");
               }
               this.p += 2;
               start = this.p;
               continue;
            }
            this.p++;
         }
         return out;
      }

      private function number() : Number
      {
         var start:int = this.p;
         var c:String = null;
         var n:Number = NaN;
         while(this.p < this.s.length)
         {
            c = this.s.charAt(this.p);
            if((c >= "0" && c <= "9") || c == "-" || c == "+" || c == "." || c == "e" || c == "E")
            {
               this.p++;
            }
            else
            {
               break;
            }
         }
         n = Number(this.s.substring(start,this.p));
         if(isNaN(n))
         {
            this.p = start;
            this.fail("bad number");
         }
         return n;
      }
   }
}
