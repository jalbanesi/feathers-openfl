package feathers.examples.youtube.screens;
import feathers.controls.Label;
import feathers.controls.List;
import feathers.controls.PanelScreen;
import feathers.controls.ScreenNavigatorItem;
import feathers.controls.renderers.DefaultListItemRenderer;
import feathers.controls.renderers.IListItemRenderer;
import feathers.data.ListCollection;
import feathers.events.FeathersEventType;
import feathers.examples.youtube.models.VideoFeed;
import feathers.layout.AnchorLayout;
import feathers.layout.AnchorLayoutData;
import feathers.skins.StandardIcons;

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;

import starling.events.Event;
import starling.textures.Texture;
//[Event(name="listVideos",type="starling.events.Event")]

class MainMenuScreen extends PanelScreen
{
	inline public static var LIST_VIDEOS:String = "listVideos";

	inline private static var CATEGORIES_URL:String = "http://gdata.youtube.com/schemas/2007/categories.cat";
	inline private static var FEED_URL_BEFORE:String = "http://gdata.youtube.com/feeds/api/standardfeeds/US/most_popular_";
	inline private static var FEED_URL_AFTER:String = "?v=2";

	public function MainMenuScreen()
	{
		this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStageHandler);
	}

	private var _list:List;

	private var _loader:URLLoader;
	private var _message:Label;

	public var savedVerticalScrollPosition:Float = 0;
	public var savedSelectedIndex:Int = -1;
	public var savedDataProvider:ListCollection;

	override private function initialize():Void
	{
		super.initialize();

		this.layout = new AnchorLayout();

		this._list = new List();
		this._list.layoutData = new AnchorLayoutData(0, 0, 0, 0);
		this._list.itemRendererFactory = function():IListItemRenderer
		{
			var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();

			//enable the quick hit area to optimize hit tests when an item
			//is only selectable and doesn't have interactive children.
			renderer.isQuickHitAreaEnabled = true;

			renderer.labelField = "name";
			renderer.accessorySourceFunction = accessorySourceFunction;
			return renderer;
		}
		//when navigating to video results, we save this information to
		//restore the list when later navigating back to this screen.
		if(this.savedDataProvider)
		{
			this._list.dataProvider = this.savedDataProvider;
			this._list.selectedIndex = this.savedSelectedIndex;
			this._list.verticalScrollPosition = this.savedVerticalScrollPosition;
		}
		this.addChild(this._list);

		this._message = new Label();
		this._message.text = "Loading...";
		this._message.layoutData = new AnchorLayoutData(NaN, NaN, NaN, NaN, 0, 0);
		//hide the loading message if we're using restored results
		this._message.visible = this.savedDataProvider == null;
		this.addChild(this._message);

		this.headerProperties.title = "YouTube Feeds";

		this.owner.addEventListener(FeathersEventType.TRANSITION_COMPLETE, owner_transitionCompleteHandler);
	}

	override private function draw():Void
	{
		var dataInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_DATA);

		//only load the list of videos if don't have restored results
		if(!this.savedDataProvider && dataInvalid)
		{
			this._list.dataProvider = null;
			this._message.visible = true;
			if(this._loader)
			{
				this.cleanUpLoader();
			}
			this._loader = new URLLoader();
			this._loader.addEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
			this._loader.addEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
			this._loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_errorHandler);
			this._loader.load(new URLRequest(CATEGORIES_URL));
		}

		//never forget to call super.draw()!
		super.draw();
	}

	private function cleanUpLoader():Void
	{
		if(!this._loader)
		{
			return;
		}
		this._loader.removeEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
		this._loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
		this._loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_errorHandler);
		this._loader = null;
	}

	private function parseFeed(feed:XML):Void
	{
		this._message.visible = false;

		var atom:Namespace = feed.namespace("atom");
		var yt:Namespace = feed.namespace("yt");
		var deprecatedElement:QName = new QName(yt, "deprecated");
		var browsableElement:QName = new QName(yt, "browsable");

		var items:Array<VideoFeed> = new Array();
		var categories:XMLList = feed.atom::category;
		var categoryCount:Int = categories.length();
		for(i in 0 ... categoryCount)
		{
			var category:XML = categories[i];
			var item:VideoFeed = new VideoFeed();
			if(category.elements(deprecatedElement).length() > 0)
			{
				continue;
			}
			var browsable:XMLList = category.elements(browsableElement);
			if(browsable.length() < 0)
			{
				continue;
			}
			var regions:String = browsable[0].@regions.toString();
			if(regions.toString().indexOf("US") < 0)
			{
				continue;
			}
			item.name = category.@label[0].toString();
			var term:String = category.@term[0].toString();
			item.url = FEED_URL_BEFORE + encodeURI(term) + FEED_URL_AFTER;
			items.push(item);
		}
		var collection:ListCollection = new ListCollection(items);
		this._list.dataProvider = collection;

		//show the scroll bars so that the user knows they can scroll
		this._list.revealScrollBars();
	}

	private function accessorySourceFunction(item:Dynamic):Texture
	{
		return StandardIcons.listDrillDownAccessoryTexture;
	}

	private function list_changeHandler(event:starling.events.Event):Void
	{
		var screenItem:ScreenNavigatorItem = this._owner.getScreen(this.screenID);
		if(!screenItem.properties)
		{
			screenItem.properties = {};
		}
		//we're going to save the position of the list so that when the user
		//navigates back to this screen, they won't need to scroll back to
		//the same position manually
		screenItem.properties.savedVerticalScrollPosition = this._list.verticalScrollPosition;
		//we'll also save the selected index to temporarily highlight
		//the previously selected item when transitioning back
		screenItem.properties.savedSelectedIndex = this._list.selectedIndex;
		//and we'll save the data provider so that we don't need to reload
		//data when we return to this screen. we can restore it.
		screenItem.properties.savedDataProvider = this._list.dataProvider;

		this.dispatchEventWith(LIST_VIDEOS, false, VideoFeed(this._list.selectedItem));
	}

	private function owner_transitionCompleteHandler(event:starling.events.Event):Void
	{
		this.owner.removeEventListener(FeathersEventType.TRANSITION_COMPLETE, owner_transitionCompleteHandler);

		this._list.selectedIndex = -1;
		this._list.addEventListener(starling.events.Event.CHANGE, list_changeHandler);

		this._list.revealScrollBars();
	}

	private function removedFromStageHandler(event:starling.events.Event):Void
	{
		this.cleanUpLoader();
	}

	private function loader_completeHandler(event:flash.events.Event):Void
	{
		try
		{
			var loaderData:* = this._loader.data;
			this.parseFeed(new XML(loaderData));
		}
		catch(error:Error)
		{
			this._message.text = "Unable to load data. Please try again later.";
			this._message.visible = true;
			this.invalidate(INVALIDATION_FLAG_STYLES);
			trace(error.toString());
		}
		this.cleanUpLoader();
	}

	private function loader_errorHandler(event:ErrorEvent):Void
	{
		this.cleanUpLoader();
		this._message.text = "Unable to load data. Please try again later.";
		this._message.visible = true;
		this.invalidate(INVALIDATION_FLAG_STYLES);
		trace(event.toString());
	}
}
