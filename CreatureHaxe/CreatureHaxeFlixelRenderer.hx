import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import openfl.Lib;
import openfl.Assets;
import haxe.Resource;
import haxe.io.Bytes;
import org.msgpack.MsgPack;
import CreaturePackModule;

class CreatureHaxeFlixelRenderer extends FlxStrip
 {
	 var creatureData : CreaturePackLoader;
	 public var creatureRender : CreatureHaxeBaseRenderer;
	 public var speed : Float;
	 
	 public function new(creatureDataIn : CreaturePackLoader, ?X:Float=0, ?Y:Float=0, ?SimpleGraphic:FlxGraphicAsset)
     {
		 super(X, Y);
		 
		 creatureData = creatureDataIn;
		 creatureRender = new CreatureHaxeBaseRenderer(creatureData);
		 speed = 60.0;
		 
		 // Initialize the data
		 for (i in 0 ... creatureData.indices.length)
		 {
			 indices.push(creatureData.indices[i]);
		 }
		 
		 for (i in 0 ... creatureData.points.length)
		 {
			 vertices.push(creatureData.points[i]);
		 }
		 
		 for (i in 0 ... creatureData.uvs.length)
		 {
			 uvtData.push(creatureData.uvs[i]);
		 }		 
	 }
	 
	 override public function update(elapsed:Float):Void
	{
		creatureRender.stepTime(elapsed * speed);
		creatureRender.syncRenderData();
		
		for (i in 0 ... Std.int(creatureData.points.length / 2))
		{
			vertices[i * 2] = creatureRender.render_points[i * 2] * width;
			vertices[i * 2 + 1] = -creatureRender.render_points[i * 2 + 1] * height;
			
			uvtData[i * 2] = creatureRender.render_uvs[i * 2];
			uvtData[i * 2 + 1] = creatureRender.render_uvs[i * 2 + 1];
		}
		
		super.update(elapsed);
	}
 }
 