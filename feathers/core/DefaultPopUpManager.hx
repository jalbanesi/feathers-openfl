/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core;
import feathers.events.FeathersEventType;

import flash.utils.Dictionary;

import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Quad;
import starling.display.Stage;
import starling.events.Event;
import starling.events.ResizeEvent;

/**
 * The default <code>IPopUpManager</code> implementation.
 *
 * @see PopUpManager
 */
class DefaultPopUpManager implements IPopUpManager
{
	/**
	 * @copy PopUpManager#defaultOverlayFactory()
	 */
	public static function defaultOverlayFactory():DisplayObject
	{
		var quad:Quad = new Quad(100, 100, 0x000000);
		quad.alpha = 0;
		return quad;
	}

	/**
	 * Constructor.
	 */
	public function DefaultPopUpManager(root:DisplayObjectContainer = null)
	{
		this.root = root;
	}

	/**
	 * @private
	 */
	private var _popUps:Array<DisplayObject> = new Array();

	/**
	 * @private
	 */
	private var _popUpToOverlay:Dictionary = new Dictionary(true);

	/**
	 * @private
	 */
	private var _popUpToFocusManager:Dictionary = new Dictionary(true);

	/**
	 * @private
	 */
	private var _centeredPopUps:Array<DisplayObject> = new Array();

	/**
	 * @private
	 */
	private var _overlayFactory:Dynamic = defaultOverlayFactory;

	/**
	 * @copy PopUpManager#overlayFactory
	 */
	public function get_overlayFactory():Dynamic
	{
		return this._overlayFactory;
	}

	/**
	 * @private
	 */
	public function set_overlayFactory(value:Dynamic):Void
	{
		this._overlayFactory = value;
	}

	/**
	 * @private
	 */
	private var _ignoreRemoval:Bool = false;

	/**
	 * @private
	 */
	private var _root:DisplayObjectContainer;

	/**
	 * @copy PopUpManager#root
	 */
	public function get_root():DisplayObjectContainer
	{
		return this._root;
	}

	/**
	 * @private
	 */
	public function set_root(value:DisplayObjectContainer):Void
	{
		if(this._root == value)
		{
			return;
		}
		var popUpCount:Int = this._popUps.length;
		var oldIgnoreRemoval:Bool = this._ignoreRemoval; //just in case
		this._ignoreRemoval = true;
		for(i in 0 ... popUpCount)
		{
			var popUp:DisplayObject = this._popUps[i];
			var overlay:DisplayObject = DisplayObject(_popUpToOverlay[popUp]);
			popUp.removeFromParent(false);
			if(overlay)
			{
				overlay.removeFromParent(false);
			}
		}
		this._ignoreRemoval = oldIgnoreRemoval;
		this._root = value;
		for(i = 0; i < popUpCount; i++)
		{
			popUp = this._popUps[i];
			overlay = DisplayObject(_popUpToOverlay[popUp]);
			if(overlay)
			{
				this._root.addChild(overlay);
			}
			this._root.addChild(popUp);
		}
	}

	/**
	 * @copy PopUpManager#addPopUp()
	 */
	public function addPopUp(popUp:DisplayObject, isModal:Bool = true, isCentered:Bool = true, customOverlayFactory:Dynamic = null):DisplayObject
	{
		if(isModal)
		{
			if(customOverlayFactory == null)
			{
				customOverlayFactory = this._overlayFactory;
			}
			if(customOverlayFactory == null)
			{
				customOverlayFactory = defaultOverlayFactory;
			}
			var overlay:DisplayObject = customOverlayFactory();
			overlay.width = this._root.stage.stageWidth;
			overlay.height = this._root.stage.stageHeight;
			this._root.addChild(overlay);
			this._popUpToOverlay[popUp] = overlay;
		}

		this._popUps.push(popUp);
		this._root.addChild(popUp);
		popUp.addEventListener(Event.REMOVED_FROM_STAGE, popUp_removedFromStageHandler);

		if(this._popUps.length == 1)
		{
			this._root.stage.addEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
		}

		if(isModal && FocusManager.isEnabledForStage(this._root.stage) && popUp is DisplayObjectContainer)
		{
			this._popUpToFocusManager[popUp] = FocusManager.pushFocusManager(DisplayObjectContainer(popUp));
		}

		if(isCentered)
		{
			if(Std.is(popUp, IFeathersControl))
			{
				popUp.addEventListener(FeathersEventType.RESIZE, popUp_resizeHandler);
			}
			this._centeredPopUps.push(popUp);
			this.centerPopUp(popUp);
		}

		return popUp;
	}

	/**
	 * @copy PopUpManager#removePopUp()
	 */
	public function removePopUp(popUp:DisplayObject, dispose:Bool = false):DisplayObject
	{
		var index:Int = this._popUps.indexOf(popUp);
		if(index < 0)
		{
			throw new ArgumentError("Display object is not a pop-up.");
		}
		popUp.removeFromParent(dispose);
		return popUp;
	}

	/**
	 * @copy PopUpManager#isPopUp()
	 */
	public function isPopUp(popUp:DisplayObject):Bool
	{
		return this._popUps.indexOf(popUp) >= 0;
	}

	/**
	 * @copy PopUpManager#isTopLevelPopUp()
	 */
	public function isTopLevelPopUp(popUp:DisplayObject):Bool
	{
		var lastIndex:Int = this._popUps.length - 1;
		for(var i:Int = lastIndex; i >= 0; i--)
		{
			var otherPopUp:DisplayObject = this._popUps[i];
			if(otherPopUp == popUp)
			{
				//we haven't encountered an overlay yet, so it is top-level
				return true;
			}
			var overlay:DisplayObject = this._popUpToOverlay[otherPopUp] as DisplayObject;
			if(overlay)
			{
				//this is the first overlay, and we haven't found the pop-up
				//yet, so it is not top-level
				return false;
			}
		}
		//pop-up was not found at all, so obviously, not top-level
		return false;
	}

	/**
	 * @copy PopUpManager#centerPopUp()
	 */
	public function centerPopUp(popUp:DisplayObject):Void
	{
		var stage:Stage = this._root.stage;
		if(Std.is(popUp, IValidating))
		{
			IValidating(popUp).validate();
		}
		popUp.x = Math.round((stage.stageWidth - popUp.width) / 2);
		popUp.y = Math.round((stage.stageHeight - popUp.height) / 2);
	}

	/**
	 * @private
	 */
	private function popUp_resizeHandler(event:Event):Void
	{
		var popUp:DisplayObject = DisplayObject(event.currentTarget);
		var index:Int = this._centeredPopUps.indexOf(popUp);
		if(index < 0)
		{
			return;
		}
		this.centerPopUp(popUp);
	}

	/**
	 * @private
	 */
	private function popUp_removedFromStageHandler(event:Event):Void
	{
		if(this._ignoreRemoval)
		{
			return;
		}
		var popUp:DisplayObject = DisplayObject(event.currentTarget);
		popUp.removeEventListener(Event.REMOVED_FROM_STAGE, popUp_removedFromStageHandler);
		var index:Int = this._popUps.indexOf(popUp);
		this._popUps.splice(index, 1);
		var overlay:DisplayObject = DisplayObject(this._popUpToOverlay[popUp]);
		if(overlay)
		{
			overlay.removeFromParent(true);
			delete _popUpToOverlay[popUp];
		}
		var focusManager:IFocusManager = this._popUpToFocusManager[popUp] as IFocusManager;
		if(focusManager)
		{
			delete this._popUpToFocusManager[popUp];
			FocusManager.removeFocusManager(focusManager);
		}
		index = this._centeredPopUps.indexOf(popUp);
		if(index >= 0)
		{
			if(Std.is(popUp, IFeathersControl))
			{
				popUp.removeEventListener(FeathersEventType.RESIZE, popUp_resizeHandler);
			}
			this._centeredPopUps.splice(index, 1);
		}

		if(_popUps.length == 0)
		{
			this._root.stage.removeEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
		}
	}

	/**
	 * @private
	 */
	private function stage_resizeHandler(event:ResizeEvent):Void
	{
		var stage:Stage = this._root.stage;
		var popUpCount:Int = this._popUps.length;
		for(i in 0 ... popUpCount)
		{
			var popUp:DisplayObject = this._popUps[i];
			var overlay:DisplayObject = DisplayObject(this._popUpToOverlay[popUp]);
			if(overlay)
			{
				overlay.width = stage.stageWidth;
				overlay.height = stage.stageHeight;
			}
		}
		popUpCount = this._centeredPopUps.length;
		for(i = 0; i < popUpCount; i++)
		{
			popUp = this._centeredPopUps[i];
			centerPopUp(popUp);
		}
	}
}
