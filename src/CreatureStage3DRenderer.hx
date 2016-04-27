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