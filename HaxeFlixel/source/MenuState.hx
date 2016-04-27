package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;

import openfl.Lib;
import openfl.Assets;
import haxe.Resource;
import haxe.io.Bytes;
import org.msgpack.MsgPack;
import CreaturePackModule;
import CreatureHaxeFlixelRenderer; 
 
 
class MenuState extends FlxState
{
	var creatureData : CreaturePackLoader;

	override public function create():Void
	{
		super.create();
		
		var load_data = Assets.getBytes(AssetPaths.raptorData__creature_pack);
		var load_img = Assets.getBitmapData(AssetPaths.raptorImg__png);
		creatureData = new CreaturePackLoader(load_data);
		
		var flixelCreatureRenderer = new CreatureHaxeFlixelRenderer(creatureData, 350, 350);
		flixelCreatureRenderer.loadGraphic(AssetPaths.raptorImg__png);
		flixelCreatureRenderer.creatureRender.setActiveAnimation("default");
		
		flixelCreatureRenderer.setSize(16, 16);
		
		add(flixelCreatureRenderer);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
