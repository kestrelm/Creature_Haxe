package;
import flash.system.System;
import flash.ui.Keyboard;
#if 0
import flash.utils.getDefinitionByName;
#end

import starling.core.Starling;
import starling.display.Button;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.KeyboardEvent;
import starling.utils.AssetManager;
import CreaturePackModule;
import CreatureStarlingRenderer;

import haxe.Timer;

@:keep class Game extends Sprite
{
        
    private static var sAssets:AssetManager;
    var creature_render : CreatureStarlingRenderer;
	
    public function new()
    {
        super();
        // nothing to do here -- Startup will call "start" immediately.
    }
    
    public function start(assets:AssetManager):Void
    {
        sAssets = assets;
		
		var curTexture = sAssets.getTexture("texture");
		var curData = sAssets.getByteArray("data");
		var creatureData = new CreaturePackLoader(curData);
		
		var texWidth = 512;
		var texHeight = 512;
		
		// Load the Creature Starling Renderer
		creature_render = new CreatureStarlingRenderer(creatureData, curTexture, 15, 15);
		
		addChild(creature_render);
		
		// Now set the position and playback speed
		creature_render.x = 380;
		creature_render.y = 250;
		creature_render.speed = 100;
		
		// Set animation clip to cplay
		creature_render.creatureRender.setActiveAnimation("default");
		
		// Do animation updates via timer, you can use your own update methods 
		// for your own game
		var timer = new Timer(16);
		timer.run = function()
		{
			creature_render.update(1.0 / 60.0);
		}
    }
    
    
    public static var assets(get, never):AssetManager;
    @:noCompletion private static function get_assets():AssetManager { return sAssets; }
}