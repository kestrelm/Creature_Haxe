/******************************************************************************
 * Creature Runtimes License
 * 
 * Copyright (c) 2015, Kestrel Moon Studios
 * All rights reserved.
 * 
 * Preamble: This Agreement governs the relationship between Licensee and Kestrel Moon Studios(Hereinafter: Licensor).
 * This Agreement sets the terms, rights, restrictions and obligations on using [Creature Runtimes] (hereinafter: The Software) created and owned by Licensor,
 * as detailed herein:
 * License Grant: Licensor hereby grants Licensee a Sublicensable, Non-assignable & non-transferable, Commercial, Royalty free,
 * Including the rights to create but not distribute derivative works, Non-exclusive license, all with accordance with the terms set forth and
 * other legal restrictions set forth in 3rd party software used while running Software.
 * Limited: Licensee may use Software for the purpose of:
 * Running Software on Licensee’s Website[s] and Server[s];
 * Allowing 3rd Parties to run Software on Licensee’s Website[s] and Server[s];
 * Publishing Software’s output to Licensee and 3rd Parties;
 * Distribute verbatim copies of Software’s output (including compiled binaries);
 * Modify Software to suit Licensee’s needs and specifications.
 * Binary Restricted: Licensee may sublicense Software as a part of a larger work containing more than Software,
 * distributed solely in Object or Binary form under a personal, non-sublicensable, limited license. Such redistribution shall be limited to unlimited codebases.
 * Non Assignable & Non-Transferable: Licensee may not assign or transfer his rights and duties under this license.
 * Commercial, Royalty Free: Licensee may use Software for any purpose, including paid-services, without any royalties
 * Including the Right to Create Derivative Works: Licensee may create derivative works based on Software, 
 * including amending Software’s source code, modifying it, integrating it into a larger work or removing portions of Software, 
 * as long as no distribution of the derivative works is made
 * 
 * THE RUNTIMES IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE RUNTIMES OR THE USE OR OTHER DEALINGS IN THE
 * RUNTIMES.
 *****************************************************************************/

import flash.display.InterpolationMethod;
import flash.display3D.textures.RectangleTexture;
import flash.geom.Matrix3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Program3D;
import flash.geom.Rectangle;
import flash.display3D.textures.Texture;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Mesh;
import starling.events.Event;
import starling.textures.Texture;
import starling.rendering.IndexData;
import starling.rendering.VertexData;
import starling.styles.MeshStyle;

import CreaturePackModule;

// Stage3D Renderer for the Creature character
class CreatureStarlingRenderer extends Mesh {

	public var creatureRender : CreatureHaxeBaseRenderer;
	public var creatureData : CreaturePackLoader;
	public var speed : Float;

	private var _bounds:Rectangle;
	
	public function new(dataIn:CreaturePackLoader, textureIn:Texture, 
					width:Float, height:Float)
	{		
		_bounds = new Rectangle(0, 0, width, height);
		creatureData = dataIn;
		creatureRender = new CreatureHaxeBaseRenderer(creatureData);
		
		speed = 60.0;
		
		var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, Std.int(creatureData.points.length / 2));
        var indexData:IndexData = new IndexData(creatureData.indices.length);

        super(vertexData, indexData);
		
		this.texture = textureIn; //starling.textures.Texture.fromTextureBase(textureIn, texWidth, texHeight);
		this.color = 0xffffff;
		
		setupVertices();
	}
	
	private function setupVertices():Void
    {
        var indexData:IndexData = this.indexData;
		
		indexData.useQuadLayout = false;
		indexData.numIndices = 0;
		
		var i = 0;
		while(i < creatureData.indices.length)
		{
			indexData.addTriangle(creatureData.indices[i], creatureData.indices[i + 1], creatureData.indices[i + 2]);
			i += 3;
		}
		
		update(0);
	}
	
	// Call this before a render to update the render data
	public function update(elapsed:Float):Void
	{
		var posAttr:String = "position";
        var texAttr:String = "texCoords";
        var texture:Texture = style.texture;
        var vertexData:VertexData = this.vertexData;
		
		creatureRender.stepTime(elapsed * speed);
		creatureRender.syncRenderData();
		
		for (i in 0 ... Std.int(creatureData.points.length / 2))
		{
			vertexData.setPoint(i, 
				posAttr, 
				creatureRender.render_points[i * 2] * _bounds.width, 
				-creatureRender.render_points[i * 2 + 1] * _bounds.height);
			
			texture.setTexCoords(vertexData, i, texAttr, creatureRender.render_uvs[i * 2], creatureRender.render_uvs[i * 2 + 1]);
		}
		
		setRequiresRedraw();
	}
}