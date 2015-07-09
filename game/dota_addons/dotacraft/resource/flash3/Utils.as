package  
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getDefinitionByName;
	
	/**
	 * ...
	 * @author ractis
	 */
	public class Utils 
	{
		
		// http://yrrep.me/dota/flash-components.php
		public static function replaceWithValveComponent( disp:DisplayObjectContainer, type:String, keepDimensions:Boolean = false ):MovieClip
		{
			var parent:DisplayObjectContainer = disp.parent;
			var oldX:Number = disp.x;
			var oldY:Number = disp.y;
			var oldWidth:Number = disp.width;
			var oldHeight:Number = disp.height;
			
			var newObjectClass:Class;
			try
			{
				newObjectClass = getDefinitionByName( type ) as Class;
			}
			catch ( error : ReferenceError )
			{
				trace( "[replaceWithValveComponent] " + type + " is not found" );
				return null;
			}
			
			var newObject:MovieClip = new newObjectClass();
			newObject.x = oldX;
			newObject.y = oldY;
			if ( keepDimensions )
			{
				newObject.width = oldWidth;
				newObject.height = oldHeight;
			}
			
			parent.removeChild( disp );
			parent.addChild( newObject );
			
			return newObject;
		}
		
		public static function CreateLabel( text:String, fontType:String, funcDefaultTextFormat:Function = null ):TextField
		{
			var tf:TextField = new TextField();
			tf.selectable = false;
			
			var format:TextFormat = new TextFormat();
			format.font = fontType;
			format.color = 0xDDDDDD;
			if ( funcDefaultTextFormat != null )
			{
				funcDefaultTextFormat( format );
			}
			tf.defaultTextFormat = format;
			
			tf.text = text;
		//	tf.autoSize = TextFieldAutoSize.LEFT;
			tf.autoSize = TextFieldAutoSize.NONE;
			
			return tf;
		}
		
		public static function ItemNameToTexture( itemName:String ):DisplayObject
		{
			var textureName:String = itemName.replace( "item_", "images\\items\\" ) + ".png";
			
			var texture:Loader = new Loader();
			texture.load( new URLRequest( textureName ) );
			return texture;
		}
		
		static public function Log( ...rest ):void 
		{
			trace( "[DotaHS] " + rest );
		}
		
		static public function LogError( e:Error ):void 
		{
			Log( e.message );
			Log( "\n" + e.getStackTrace() );
		}
		
	}

}