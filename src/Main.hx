package;

import flash.display.BitmapData;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.RectangleTexture;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.display3D.textures.Texture;
import flash.display.Bitmap;
import flash.Vector;


import haxe.Resource;
import haxe.io.Bytes;
import org.msgpack.MsgPack;
import CreaturePackModule;
import glm.Mat4;
import glm.Projection;

import format.agal.Tools;

 @:file("raptorTest_character_data.creature_pack")
class MyData extends flash.utils.ByteArray
{   
}

@:bitmap("raptorTest_character_img.png")
class MyBitmap extends BitmapData
{
}

/*
 @:file("iceDemonExport_character_data.creature_pack")
class MyData2 extends flash.utils.ByteArray
{   
}

@:bitmap("iceDemonExport_character_img.png")
class MyBitmap2 extends BitmapData
{
}
*/

class Main 
{
	var s3d : flash.display.Stage3D;
	var ctx : flash.display3D.Context3D;
	var creatureData : CreaturePackLoader;
	var creatureDraw : CreatureStage3DRenderer;
	var creatureTexture : RectangleTexture;
	
	static public function toBytes(byteArray:flash.utils.ByteArray):Bytes 
	{
		byteArray.position = 0; 
		var bytes:Bytes = Bytes.alloc(byteArray.length); 
		while (byteArray.bytesAvailable > 0) { 
			var position = byteArray.position;
			bytes.set(position, 
			byteArray.readByte());
		}
		
		return bytes;
	}
	
	function onReady( _ ) {
		var stage = Lib.current.stage;
		ctx = s3d.context3D;
		ctx.enableErrorChecking = true;
		ctx.configureBackBuffer( stage.stageWidth, stage.stageHeight, 0, true );
		ctx.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		
		// Load Creature Data
		var readData = new MyData();
		creatureData = new CreaturePackLoader(readData);

		// Create texture
		var curBitmap : MyBitmap = new MyBitmap(2048, 871);
		creatureTexture = ctx.createRectangleTexture(2048, 871, Context3DTextureFormat.BGRA, false);
		
		//var curBitmap : MyBitmap2 = new MyBitmap2(1600, 1600);
		//creatureTexture = ctx.createRectangleTexture(1600, 1600, Context3DTextureFormat.BGRA, false);
		
		creatureTexture.uploadFromBitmapData(curBitmap);
		
		// creature renderer
		creatureDraw = new CreatureStage3DRenderer(creatureData, creatureTexture, ctx);
		creatureDraw.setActiveAnimation("default");
		//creatureDraw.blendToAnimation("default1", 0.01);
	}
	
	function update(_) {
		if (ctx == null) return;
		
		// Camera and screen buffer
		ctx.clear(0, 0, 0, 1);
		ctx.setDepthTest( true, flash.display3D.Context3DCompareMode.LESS_EQUAL );
		ctx.setCulling(flash.display3D.Context3DTriangleFace.NONE);
		
		var stage = Lib.current.stage;
		var ratio = stage.stageHeight / stage.stageWidth;
		
		var curCamera = new Matrix3D();
		var camMat:Mat4 = Projection.ortho( -1, 1, -1 * ratio, 1 * ratio, -1, 1);
		var readCamArray:Array<Float> = camMat.toArrayColMajor();
		var rawCamArray : Vector<Float> = new Vector<Float>(16);
		for (i in 0...16)
		{
			rawCamArray[i] = readCamArray[i];
		}
		
		// Creature Animation
		creatureDraw.transformMat.identity();
		creatureDraw.transformMat.appendScale(0.035, 0.035, 0.035);
		
		curCamera.copyRawDataFrom(rawCamArray);
		
		creatureDraw.stepTime(2);
		creatureDraw.syncRenderData();
		creatureDraw.render(curCamera);
		
		// Show results onto screen
		ctx.present();
	}
	
	function new() {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		s3d = stage.stage3Ds[0];
		s3d.addEventListener( flash.events.Event.CONTEXT3D_CREATE, onReady );
		flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, update);
		s3d.requestContext3D();
	}

	static function main() 
	{
		var inst = new Main();
	}
	
}