#Creature Haxe Plugin

This repository contains the **Creature Haxe Plugin** for the **Creature Animation Tool** ( http://creature.kestrelmoon.com/ )


##Live Demo
A live web demonstration of a **running UtahRaptor** using the plugin in **Flash** and **HaxeFlixel** is [here](http://www.kestrelmoon.com/creature/WebDemo/demo_flash.html). The demo shows a dinosaur animated with deforming meshes exported from **Creature**.



**UtahRaptor Artwork**: Emily Willoughby (http://emilywilloughby.com) 

**Ice Demon Artwork**: Katarzyna Zalecka [http://kasia88.deviantart.com]

![Alt text](https://github.com/kestrelm/Creature_Haxe/blob/master/logo1.png)

##Using the Haxe Plugin
The Haxe plugin core code lives in the folder **CreatureHaxe** In it, yoi will find the file **CreaturePackModule.hx** which contains the core classes you will need to playback Creature Animations in Haxe.

###Animation File Format + Playback
The Haxe Plugin uses the more compact **creature_pack** format. This file format has most of the functionality of the original **Creature JSON/FlatData** formats except for **Bone Information**. Meshe playback, deform, blend etc. in this format but if you need to attach objects to your character, the preferred method is to do it **by vertex**.

Because **creature_pack** has no bones, the deformation evaulation is much faster since all the deformations have already been baked out into the file. In addition to that, the **Creature Animation Tool** allows you to specify a number of options to reduce the export file size of this format dramatically. Key to reducing the file size is the **Gap Step** parameter during export. Increasing this value will decrease the file size but reduce the animation quality. Try values between **2 and 6**.

###Core Classes/Methods

In order to load data, you create the **CreaturePackLoader** object with an input **ByteArray**.

		var readData = new MyData();
		creatureData = new CreaturePackLoader(readData);

Animation Playback functions are accomplished with the **CreatureHaxeBaseRenderer** class. This class drives the animation and provides functions for you to play, blend, start/stop the animation(s).
Depending on the renderer (Stage3D, HaxeFlixel etc.), you will typically grab access to this **CreatureHaxeBaseRenderer** ( or an inherited version of it ) to play your animations

**Methods:**

- **setActiveAnimation(nameIn : String)** - Sets the active animation name

- **function blendToAnimation(nameIn : String, blendDelta : Float)** - Smoothly blends to a target animation with a blend delta between 0 to 1

- **function getRunTime()** : Float - Returns the current time of the animation

- **function stepTime(deltaTime : Float)** - Steps the animation forwards by a time delta

- **function syncRenderData()** - Call this before a render to update the render data. **NOTE:** This function is only needed if you are using lower level renderes like the Stage3D renderer.

###Flash Target with Stage3D
If you want to target pure Flash, there is a **CreatureStage3DRenderer** available that does just that.

####Loading Data

Take a look at the sample code below:

	 @:file("raptorTest_character_data.creature_pack")
	class MyData extends flash.utils.ByteArray
	{   
	}

	@:bitmap("raptorTest_character_img.png")
	class MyBitmap extends BitmapData
	{
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
		
		creatureTexture.uploadFromBitmapData(curBitmap);
		
		// creature renderer
		creatureDraw = new CreatureStage3DRenderer(creatureData, creatureTexture, ctx);
		creatureDraw.setActiveAnimation("default");
	}

####Rendering
Rendering is done with the following code:

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

Please take a look at the folder **FlashDev** for the full sample source.

###HaxeFlixel Target
There is a **CreatureHaxeFlixelRenderer** that works in the **HaxeFlixel** ( http://haxeflixel.com/ ) framework. Note that in order for this renderer to run, your target must support the **drawTriangles** rendering method.

To setup and play the animation, take a look at the sample code below:

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

You can adjust the playback speed by changing the **speed** variable on the **CreatureHaxeFlixelRenderer** object. You have access to the **CreatureHaxeBaseRenderer** object from the **CreatureHaxeFlixelRenderer** via the **creatureRender** variable. This allows you to blend, switch, stop etc. animations.