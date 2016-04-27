// This is the core Creature Haxe Runtime

import haxe.Resource;
import haxe.ds.HashMap;
import haxe.io.Bytes;
import haxe.io.Float64Array;
import org.msgpack.Decoder;
import org.msgpack.MsgPack;

#if flash
import flash.Vector;
#else
import openfl.Vector;
#end

class CreatureTimeSample
{
	public var beginTime : Int;
	public var endTime : Int;
	public var dataIdx : Int;
	
	public function new(beginTimeIn : Int, endTimeIn : Int, dataIdxIn : Int)
	{
		beginTime = beginTimeIn;
		endTime = endTimeIn;
		dataIdx = dataIdxIn;
	}
	
	public function getAnimPointsOffset() : Int
	{
		if (dataIdx < 0)
		{
			return -1; // invalid
		}
		
		return dataIdx + 1;
	}
	
	public function getAnimUvsOffset() : Int
	{
		if (dataIdx < 0)
		{
			return -1; // invalid
		}
		
		return dataIdx + 2;
	}
	
	public function getAnimColorsOffset() : Int
	{
		if (dataIdx < 0)
		{
			return -1; // invalid
		}
		
		return dataIdx + 3;
	}
}

class CreaturePackAnimClip
{
	public var startTime: Int;
	public var endTime : Int;
	public var timeSamplesMap : Map<Int, CreatureTimeSample>;
	public var dataIdx : Int;
	var firstSet : Bool;
	
	public function new(dataIdxIn : Int)
	{
		dataIdx = dataIdxIn;
		startTime = 0;
		endTime = 0;
		firstSet = false;
		timeSamplesMap = new  Map<Int, CreatureTimeSample>();
	}
	
	public function sampleTime(timeIn: Float) : { firstSampleIdx: Int, secondSampleIdx: Int, sampleFraction : Float }
	{
		var lookupTime = Math.round(timeIn);
		var lowTime : Float = timeSamplesMap[lookupTime].beginTime;
		var highTime : Float = timeSamplesMap[lookupTime].endTime;
		
		if ( (highTime - lowTime) <= 0.0001)
		{
			return { firstSampleIdx : Std.int(lowTime), secondSampleIdx : Std.int(highTime), sampleFraction: 0};
		}
	
		var curFraction : Float = (timeIn - lowTime) / ( highTime - lowTime );
		
		return { firstSampleIdx : Std.int(lowTime), secondSampleIdx : Std.int(highTime), sampleFraction: curFraction};
	}
	
	public function correctTime(timeIn: Float, withLoop : Bool) : Float
	{
		if(withLoop == false) {
			if (timeIn < startTime)
			{
				return startTime;
			}
			else if (timeIn > endTime)
			{
				return endTime;
			}
		}
		else {
			if (timeIn < startTime)
			{
				return endTime;
			}
			else if (timeIn > endTime)
			{
				return startTime;
			}
		}
		
		return timeIn;
	}
	
	public function addTimeSample(timeIn : Int, dataIdxIn : Int)
	{
		var newTimeSample : CreatureTimeSample = new CreatureTimeSample(timeIn, timeIn, dataIdxIn);
		timeSamplesMap.set(timeIn, newTimeSample);
		
		if (firstSet == false)
		{
			firstSet = true;
			startTime = timeIn;
			endTime = timeIn;
		}
		else {
			if (startTime > timeIn)
			{
				startTime = timeIn;
			}
			
			if (endTime < timeIn)
			{
				endTime = timeIn;
			}
		}
	}
	
	function sortArrayNum(a : Int, b: Int) : Int
	{
		if (a > b)
		{
			return 1;
		}
		else if (a < b)
		{
			return -1;
		}
		
		return 0;
	}
	
	public function finalTimeSamples()
	{
		var oldTime : Int = startTime;
		var sorted_keys = new Array<Int>();
		
		for (curTime in timeSamplesMap.keys())
		{
			sorted_keys.push(curTime);
		}
		
		sorted_keys.sort(sortArrayNum);
		
		for (curTime in sorted_keys)
		{
			if (curTime != oldTime)
			{
				for (fillTime in (oldTime + 1) ... curTime)
				{
					var newTimeSample : CreatureTimeSample = new CreatureTimeSample(oldTime, curTime, -1);
					timeSamplesMap.set(fillTime, newTimeSample);
				}
				
				oldTime = curTime;
			}
		}		
	}
}

// This is the class the loads in Creature Pack Data from disk
class CreaturePackLoader {
	public var indices : Vector<UInt>;
	public var uvs : Vector<Float>;
	public var points : Vector<Float>;
	public var animClipMap : Map<String, CreaturePackAnimClip>;
	
	public var fileData : Array<Dynamic>;
	var headerList : Array<String>;
	var animPairsOffsetList : Array<Int>;
	
	
#if flash	
	public function new(byteArray:flash.utils.ByteArray)
	{
		getDecoder(byteArray);
	}
	
	function toBytes(byteArray:flash.utils.ByteArray):Bytes 
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
#else
	public function new(byteArray: openfl.utils.ByteArray)
	{
		getDecoder(byteArray);
	}
	
	function toBytes(byteArray: openfl.utils.ByteArray):Bytes 
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
#end
	
	function getDecoder(byteArray:flash.utils.ByteArray): Array<Dynamic>
	{
		var convertData = toBytes(byteArray);
		return getBaseDecoder(convertData);
	}
	
	function getBaseDecoder(convertData : Bytes): Array<Dynamic>
	{
		fileData = MsgPack.decode(convertData);
		
		headerList = fileData[getBaseOffset()];
		animPairsOffsetList = fileData[getAnimPairsListOffset()];
		
		// init basic points and topology structure
		indices = new Vector<UInt>(getNumIndices());
		points = new Vector<Float>(getNumPoints());
		uvs = new Vector<Float>(getNumUvs());
		
		updateIndices(getBaseIndicesOffset());
		updatePoints(getBasePointsOffset());
		updateUVs(getBaseUvsOffset());
		
		// init Animation Clip Map
		animClipMap = new Map<String, CreaturePackAnimClip>();
		
		for (i in 0...getAnimationNum())
		{
			var curOffsetPair = getAnimationOffsets(i);
			
			var animName = fileData[curOffsetPair.a];
			var k = curOffsetPair.a ;
			k++;
			var newClip = new CreaturePackAnimClip(k);
				
			while(k < curOffsetPair.b)
			{
				var cur_time = fileData[k];
				newClip.addTimeSample(cur_time, k);
					
				k += 4;
			}
				
			newClip.finalTimeSamples();
			animClipMap.set(animName, newClip);
		}
		
		return fileData;

	}
	
	public function updateIndices(idx:Int)
	{
		var cur_data : Array<Int> = fileData[idx];
		for (i in 0...cur_data.length)
		{
			indices[i] = cur_data[i];
		}
	}

	public function updatePoints(idx:Int)
	{
		var cur_data : Array<Float> = fileData[idx];
		for (i in 0...cur_data.length)
		{
			points[i] =  cur_data[i];
		}
	}

	public function updateUVs(idx:Int)
	{
		var cur_data : Array<Float> = fileData[idx];
		for (i in 0...cur_data.length)
		{
			uvs[i] =  cur_data[i];
		}
	}

	public function getAnimationNum() : Int
	{
		var sum = 0;
		for ( i in 0...headerList.length)
		{
			if (headerList[i] == "animation")
			{
				sum++;
			}
		}
		
		return sum;
	}
	
	public function getAnimationOffsets(idx:Int) : {a : Int, b : Int}
	{
		return {a : animPairsOffsetList[idx * 2], b: animPairsOffsetList[idx * 2 + 1]};
	}
		
	public function getBaseOffset() : Int
	{
		return 0;
	}

	public function getAnimPairsListOffset() : Int
	{
		return 1;
	}
	
	public function getBaseIndicesOffset() : Int
	{
		return getAnimPairsListOffset() + 1;
	}
	
	public function getBasePointsOffset() : Int
	{
		return getAnimPairsListOffset() + 2;
	}

	public function getBaseUvsOffset() : Int
	{
		return getAnimPairsListOffset() + 3;
	}
	
	public function getNumIndices() : Int
	{
		return fileData[getBaseIndicesOffset()].length;
	}
	
	public function getNumPoints() : Int
	{
		return fileData[getBasePointsOffset()].length;
	}

	public function getNumUvs() : Int
	{
		return fileData[getBaseUvsOffset()].length;
	}
	
}

// Base Renderer class that target renderers inherit from
class CreatureHaxeBaseRenderer {
	public var render_uvs : Vector<Float>;
	public var render_points : Vector<Float>;
	public var render_colors : Vector<Float>;
	public var runTimeMap : Map<String, Float>;
	public var isPlaying : Bool;
	public var isLooping : Bool;
	
	var data:CreaturePackLoader;
	var activeAnimationName : String;
	var prevAnimationName : String;
	var animBlendFactor : Float;
	var animBlendDelta : Float;
	
	public function new(dataIn:CreaturePackLoader)
	{
		data = dataIn;
		createRuntimeMap();
		isPlaying = true;
		isLooping = true;
		animBlendFactor = 0;
		animBlendDelta = 0;
				
		// create data buffers
		render_points = new Vector<Float>(data.points.length);
		render_uvs = new Vector<Float>(data.uvs.length);
		render_colors = new Vector<Float>(Std.int(data.points.length / 2 * 4));
		
		for (i in 0 ... render_colors.length)
		{
			render_colors[i] = 1.0;
		}
		
		for (i in 0 ... render_uvs.length)
		{
			render_uvs[i] = data.uvs[i];
		}
	}
	
	function createRuntimeMap()
	{
		runTimeMap = new Map<String, Float>();
		var firstSet = false;
		for (animName in data.animClipMap.keys())
		{
			if (firstSet == false)
			{
				firstSet = true;
				activeAnimationName = animName;
				prevAnimationName = animName;
			}
			
			var animClip = data.animClipMap.get(animName);
			runTimeMap.set(animName, animClip.startTime);
		}
		
	}
	
	// Sets an active animation without blending
	public function setActiveAnimation(nameIn : String)
	{
		if (runTimeMap.exists(nameIn))
		{
			activeAnimationName = nameIn;
			prevAnimationName = nameIn;
			runTimeMap.set(activeAnimationName, data.animClipMap[activeAnimationName].startTime);
		}
	}
	
	// Smoothly blends to a target animation
	public function blendToAnimation(nameIn : String, blendDelta : Float)
	{
		prevAnimationName = activeAnimationName;
		activeAnimationName = nameIn;
		animBlendFactor = 0;
		animBlendDelta = blendDelta;
	}

		public function setRunTime(timeIn : Float)
	{	
		runTimeMap[activeAnimationName] = data.animClipMap[activeAnimationName].correctTime(timeIn, isLooping);
	}
	
	public function getRunTime() : Float
	{
		return runTimeMap[activeAnimationName];
	}
	
	// Steps the animation by a delta time
	public function stepTime(deltaTime : Float)
	{
		setRunTime(getRunTime() + deltaTime);
		
		// update blending
		animBlendFactor += animBlendDelta;
		if (animBlendFactor > 1)
		{
			animBlendFactor = 1;
		}
	}
	
	function interpScalar(val1 : Float, val2 : Float, fraction : Float) : Float
	{
		return ((1.0 - fraction) * val1) + (fraction * val2);
	}
	
	// Call this before a render to update the render data
	public function syncRenderData() { 
	{
		// Points blending
		if (activeAnimationName == prevAnimationName)
		{
			var cur_clip : CreaturePackAnimClip =  data.animClipMap[activeAnimationName];
			// no blending
			var cur_clip_info = cur_clip.sampleTime(getRunTime());
			var low_data = cur_clip.timeSamplesMap[cur_clip_info.firstSampleIdx];
			var high_data = cur_clip.timeSamplesMap[cur_clip_info.secondSampleIdx];
			
			var anim_low_points = data.fileData[low_data.getAnimPointsOffset()];
			var anim_high_points = data.fileData[high_data.getAnimPointsOffset()];
			
			for (i in 0 ... render_points.length)
			{
				var low_val : Float = anim_low_points[i];
				var high_val : Float = anim_high_points[i];
				render_points[i] = interpScalar(low_val, high_val, cur_clip_info.sampleFraction);
			}
		}
		else {
			// blending
			
			// Active Clip
			var active_clip : CreaturePackAnimClip =  data.animClipMap[activeAnimationName];
			
			var active_clip_info = active_clip.sampleTime(getRunTime());
			var active_low_data = active_clip.timeSamplesMap[active_clip_info.firstSampleIdx];
			var active_high_data = active_clip.timeSamplesMap[active_clip_info.secondSampleIdx];
			
			var active_anim_low_points = data.fileData[active_low_data.getAnimPointsOffset()];
			var active_anim_high_points = data.fileData[active_high_data.getAnimPointsOffset()];
			
			// Previous Clip
			var prev_clip : CreaturePackAnimClip =  data.animClipMap[prevAnimationName];
			
			var prev_clip_info = prev_clip.sampleTime(getRunTime());
			var prev_low_data = prev_clip.timeSamplesMap[prev_clip_info.firstSampleIdx];
			var prev_high_data = prev_clip.timeSamplesMap[prev_clip_info.secondSampleIdx];
			
			var prev_anim_low_points = data.fileData[prev_low_data.getAnimPointsOffset()];
			var prev_anim_high_points = data.fileData[prev_high_data.getAnimPointsOffset()];

			for (i in 0 ... render_points.length)
			{
				var active_low_val : Float = active_anim_low_points[i];
				var active_high_val : Float = active_anim_high_points[i];
				var active_val : Float =  interpScalar(active_low_val, active_high_val, active_clip_info.sampleFraction);

				var prev_low_val : Float = prev_anim_low_points[i];
				var prev_high_val : Float = prev_anim_high_points[i];
				var prev_val : Float =  interpScalar(prev_low_val, prev_high_val, prev_clip_info.sampleFraction);

				render_points[i] = interpScalar(prev_val, active_val, animBlendFactor);
			}
		}
		
		// Colors
		{
			var cur_clip : CreaturePackAnimClip =  data.animClipMap[activeAnimationName];
			// no blending
			var cur_clip_info = cur_clip.sampleTime(getRunTime());
			var low_data = cur_clip.timeSamplesMap[cur_clip_info.firstSampleIdx];
			var high_data = cur_clip.timeSamplesMap[cur_clip_info.secondSampleIdx];
			
			var anim_low_colors : Array<Float> = data.fileData[low_data.getAnimColorsOffset()];
			var anim_high_colors : Array<Float> = data.fileData[high_data.getAnimColorsOffset()];
			
			if((anim_low_colors.length == render_colors.length)
				&& (anim_high_colors.length == render_colors.length)) {
				for (i in 0 ... render_colors.length)
				{
					var low_val : Float = anim_low_colors[i];
					var high_val : Float = anim_high_colors[i];
					render_colors[i] = interpScalar(low_val, high_val, cur_clip_info.sampleFraction) / 255.0;
				}
			}
		}
	
			// UVs
			{
				var cur_clip : CreaturePackAnimClip =  data.animClipMap[activeAnimationName];
				var cur_clip_info = cur_clip.sampleTime(getRunTime());
				var low_data = cur_clip.timeSamplesMap[cur_clip_info.firstSampleIdx];
				var anim_uvs : Array<Float> = data.fileData[low_data.getAnimUvsOffset()];
				if (anim_uvs.length == render_uvs.length)
				{
					for (i in 0 ... render_uvs.length)
					{
						render_uvs[i] = anim_uvs[i];
					}
				}
			}		
		}
	}
}