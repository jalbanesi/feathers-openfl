package feathers.examples.displayObjects.screens;
import feathers.controls.Button;
import feathers.controls.PanelScreen;
import feathers.display.Scale9Image;
import feathers.examples.displayObjects.themes.DisplayObjectExplorerTheme;
import feathers.skins.IStyleProvider;
import feathers.textures.Scale9Textures;
import openfl.Assets;

import openfl.geom.Rectangle;

import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.textures.Texture;

public class Scale9ImageScreen extends PanelScreen
{
	//[Embed(source="/../assets/images/scale9.png")]
	//inline private static var SCALE_9_TEXTURE:Class<Dynamic>;
	inline private static var SCALE_9_TEXTURE_FILE_NAME = "assets/images/scale9.png";

	public static var globalStyleProvider:IStyleProvider;

	public function new()
	{
		super();
	}

	private var _image:Scale9Image;
	private var _rightButton:Button;
	private var _bottomButton:Button;

	private var _minDisplayObjectWidth:Float;
	private var _minDisplayObjectHeight:Float;
	private var _maxDisplayObjectWidth:Float;
	private var _maxDisplayObjectHeight:Float;
	private var _startX:Float;
	private var _startY:Float;
	private var _startWidth:Float;
	private var _startHeight:Float;
	private var _rightTouchPointID:Int = -1;
	private var _bottomTouchPointID:Int = -1;

	private var _texture:Texture;

	override private function get_defaultStyleProvider():IStyleProvider
	{
		return Scale9ImageScreen.globalStyleProvider;
	}

	override public function dispose():Void
	{
		if(this._texture != null)
		{
			this._texture.dispose();
			this._texture = null;
		}
		super.dispose();
	}

	override private function initialize():Void
	{
		super.initialize();
		
		this.title = "Scale 9 Image";

		this._texture = Texture.fromBitmapData(Assets.getBitmapData(SCALE_9_TEXTURE_FILE_NAME), false);
		var textures:Scale9Textures = new Scale9Textures(this._texture, new Rectangle(20, 20, 20, 20));
		this._image = new Scale9Image(textures);
		this._minDisplayObjectWidth = 40;
		this._minDisplayObjectHeight = 40;
		this.addChild(this._image);

		this._rightButton = new Button();
		this._rightButton.styleNameList.add(DisplayObjectExplorerTheme.THEME_NAME_RIGHT_GRIP);
		this._rightButton.addEventListener(TouchEvent.TOUCH, rightButton_touchHandler);
		this.addChild(this._rightButton);

		this._bottomButton = new Button();
		this._bottomButton.styleNameList.add(DisplayObjectExplorerTheme.THEME_NAME_BOTTOM_GRIP);
		this._bottomButton.addEventListener(TouchEvent.TOUCH, bottomButton_touchHandler);
		this.addChild(this._bottomButton);
	}

	override protected function layoutChildren():void
	{
		super.layoutChildren();

		this._rightButton.validate();
		this._bottomButton.validate();

		this._maxDisplayObjectWidth = this.actualWidth - this._paddingLeft - this._rightButton.width - this._image.x;
		this._maxDisplayObjectHeight = this.actualHeight - this.header.height - this._paddingTop - this._bottomButton.height - this._image.y;

		this._image.width = Math.max(this._minDisplayObjectWidth, Math.min(this._maxDisplayObjectWidth, this._image.width));
		this._image.height = Math.max(this._minDisplayObjectHeight, Math.min(this._maxDisplayObjectHeight, this._image.height));

		this.layoutButtons();
	}

	private function layoutButtons():Void
	{
		this._rightButton.x = this._image.x + this._image.width;
		this._rightButton.y = this._image.y + (this._image.height - this._rightButton.height) / 2;

		this._bottomButton.x = this._image.x + (this._image.width - this._bottomButton.width) / 2;
		this._bottomButton.y = this._image.y + this._image.height;
	}

	private function rightButton_touchHandler(event:TouchEvent):Void
	{
		var touch:Touch = event.getTouch(this._rightButton);
		if(touch == null || (this._rightTouchPointID >= 0 && touch.id != this._rightTouchPointID))
		{
			return;
		}

		if(touch.phase == TouchPhase.BEGAN)
		{
			this._rightTouchPointID = touch.id;
			this._startX = touch.globalX;
			this._startWidth = this._image.width;
		}
		else if(touch.phase == TouchPhase.MOVED)
		{
			this._image.width = Math.min(this._maxDisplayObjectWidth, Math.max(this._minDisplayObjectWidth, this._startWidth + touch.globalX - this._startX));
			this.layoutButtons();
		}
		else if(touch.phase == TouchPhase.ENDED)
		{
			this._rightTouchPointID = -1;
		}
	}

	private function bottomButton_touchHandler(event:TouchEvent):Void
	{
		var touch:Touch = event.getTouch(this._bottomButton);
		if(touch == null || (this._bottomTouchPointID >= 0 && touch.id != this._bottomTouchPointID))
		{
			return;
		}

		if(touch.phase == TouchPhase.BEGAN)
		{
			this._bottomTouchPointID = touch.id;
			this._startY = touch.globalY;
			this._startHeight = this._image.height;
		}
		else if(touch.phase == TouchPhase.MOVED)
		{
			this._image.height = Math.min(this._maxDisplayObjectHeight, Math.max(this._minDisplayObjectHeight, this._startHeight + touch.globalY - this._startY));
			this.layoutButtons();
		}
		else if(touch.phase == TouchPhase.ENDED)
		{
			this._bottomTouchPointID = -1;
		}
	}
}
