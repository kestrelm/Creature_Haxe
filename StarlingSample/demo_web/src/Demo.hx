package;
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.system.Capabilities;
#if 0
import flash.system.System;
import flash.utils.setTimeout;
#end
import haxe.Timer;
import openfl.Assets;
import openfl.display3D.Context3DRenderMode;
import openfl.errors.Error;
import openfl.geom.Rectangle;
import starling.display.Stage;
import starling.text.BitmapFont;
import starling.text.TextField;
import starling.textures.Texture;
import starling.textures.TextureAtlas;
import starling.utils.Max;
import starling.utils.RectangleUtil;

import starling.core.Starling;
import starling.events.Event;
import starling.utils.AssetManager;

// This is a demonstration of how to load and play a Creature character in Starling using the Creature Starling Renderer

#if 0
[SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
#end
class Demo extends Sprite
{
    private var _starling:Starling;

    public function new()
    {
        super();
        if (stage != null) start();
        else addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Dynamic):Void
    {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        start();
    }

    private function start():Void
    {		
		// Setup Starling
        _starling = new Starling(Game, stage, new Rectangle(0, 0, 800, 600));
        _starling.simulateMultitouch = true;
        _starling.skipUnchangedFrames = true;
        _starling.enableErrorChecking = Capabilities.isDebugger;
        _starling.addEventListener(Event.ROOT_CREATED, function():Void
        {
            loadAssets(startGame);
        });
        
        this.stage.addEventListener(Event.RESIZE, onResize, false, Max.INT_MAX_VALUE, true);

        _starling.start();
    }

	// Load the texture map and binary asset file of the Creature character
	// The actual character creation is done in Game.hx
    private function loadAssets(onComplete:AssetManager->Void):Void
    {
        var assets:AssetManager = new AssetManager();

        assets.verbose = Capabilities.isDebugger;
        var atlasTexture:Texture = Texture.fromBitmapData(Assets.getBitmapData("assets/raptorTest_character_img.png"), false);
        assets.addTexture("texture", atlasTexture);
        
		var loadData = Assets.getBytes("assets/raptorTest_character_data.creature_pack");
		assets.addByteArray("data", loadData);

		startGame(assets);
    }

    private function startGame(assets:AssetManager):Void
    {
        var game:Game = cast(_starling.root, Game);
        game.start(assets);
    }
    
    private function onResize(e:openfl.events.Event):Void
    {

    }
}