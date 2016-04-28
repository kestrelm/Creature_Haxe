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
import flash.display3D.textures.Texture;
import CreaturePackModule;
import hxsl.Shader;

// A Basic Shader to render the Creature
class CreatureShader extends hxsl.Shader {
	static var SRC = {
		var input : {
			pos : Float3,
			uv : Float2,
			color : Float4,
		};
		
		var tuv : Float2;
		var tcolor : Float4;
		
		function vertex( mpos : M44, mproj : M44 ) {
			out = input.pos.xyzw * mpos * mproj;
			tuv = input.uv;
			tcolor = input.color;
		}
		function fragment( tex : Texture ) {
			out = tex.get(tuv) * tcolor;
		}
	};
}

// Stage3D Renderer for the Creature character
class CreatureStage3DRenderer extends CreatureHaxeBaseRenderer {
	var texture:RectangleTexture;
	var mVertexBuffer:VertexBuffer3D;
	var mColorBuffer:VertexBuffer3D;
    var mUVBuffer:VertexBuffer3D;
    var mIndexBuffer:IndexBuffer3D;

	var ctx:Context3D;
	var shader : CreatureShader;
	public var transformMat : Matrix3D;
	
	public function new(dataIn:CreaturePackLoader, textureIn:RectangleTexture, ctxIn:Context3D)
	{
		super(dataIn);
		
		ctx = ctxIn;
		texture = textureIn;
		
		transformMat = new Matrix3D();
		transformMat.identity();
		
		createBuffers();
		shader = new CreatureShader();
	}
	
	
	function createBuffers()
	{
		mVertexBuffer = ctx.createVertexBuffer(Std.int(data.points.length / 2), 2);
		mUVBuffer = ctx.createVertexBuffer(Std.int(data.uvs.length / 2), 2);
		mColorBuffer = ctx.createVertexBuffer(Std.int(data.uvs.length / 2), 4);
		mIndexBuffer = ctx.createIndexBuffer(data.indices.length);		
	}
	
	// Call this before a render to update the render data
	public override function syncRenderData()
	{
		super.syncRenderData();
		
		// Indices, Points UVs, and Color
		mIndexBuffer.uploadFromVector(data.indices, 0, data.indices.length);
		mVertexBuffer.uploadFromVector(render_points, 0, Std.int(render_points.length / 2));
		mUVBuffer.uploadFromVector(render_uvs, 0, Std.int(render_uvs.length / 2));
		mColorBuffer.uploadFromVector(render_colors, 0, Std.int(render_points.length / 2));
	}
	
	// Renders the creature given an input model view transfor matrix
	public function render(mvpMatrix:Matrix3D)
	{		
		shader.mpos = transformMat;
		shader.mproj = mvpMatrix;
		shader.tex = texture;
		
        
		shader.bindSimple(ctx, mVertexBuffer);
		ctx.setVertexBufferAt(0, mVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); 
        ctx.setVertexBufferAt(1, mUVBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
        ctx.setVertexBufferAt(2, mColorBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
		
		ctx.drawTriangles(mIndexBuffer);
	}
}