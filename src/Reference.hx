package;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;



import haxe.Resource;
import haxe.io.Bytes;
import org.msgpack.MsgPack;

import format.agal.Tools;

/**
 * ...
 * @author Me
 */

 @:file("raptorTest_character_data.creature_pack")
class MyData extends flash.utils.ByteArray
{
    
}

/*
class Main 
{
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

	static function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		// Entry point
		
		//var readData = Resource.getBytes("raptorTest_character_data.creature_pack");
		//var testDecode = MsgPack.decode(readData.getData().readBytes(readData.length));
		
		var readData = new MyData();
		var testData = toBytes(readData);
		var testDecode = MsgPack.decode(testData);
		
		
		trace("Hello World!");
        //var m = MsgPack.encode(i);
        //var o = MsgPack.decode(m);

        //trace(i);
        //trace(m.toHex());
        //trace(o);
		
		// Testing
		// creates a TextField         
         var tf = new flash.text.TextField();
         tf.text = "Hello World !";
         // add it to the display list
         flash.Lib.current.addChild(tf);
	}
	
}
*/

typedef K = flash.ui.Keyboard;

class Shader extends hxsl.Shader {

	static var SRC = {
		var input : {
			pos : Float3,
		};
		var color : Float3;
		function vertex( mpos : M44, mproj : M44 ) {
			out = input.pos.xyzw * mpos * mproj;
			color = input.pos;
		}
		function fragment() {
			out = color.xyzw;
		}
	};

}

class Const {

	public static inline var EPSILON = 1e-10;

	// round to 4 significant digits, eliminates <1e-10
	public static function f( v : Float ) {
		var neg;
		if( v < 0 ) {
			neg = -1.0;
			v = -v;
		} else
			neg = 1.0;
		var digits = Std.int(4 - Math.log(v) / Math.log(10));
		if( digits < 1 )
			digits = 1;
		else if( digits >= 10 )
			return 0.;
		var exp = Math.pow(10,digits);
		return Math.floor(v * exp + .49999) * neg / exp;
	}

}

class Polygon {

	public var points : Array<Vector>;
	public var normals : Array<Vector>;
	public var tcoords : Array<UV>;
	public var idx : Array<UInt>;
	
	public var ibuf : flash.display3D.IndexBuffer3D;
	public var vbuf : flash.display3D.VertexBuffer3D;
	
	public function new( points, ?idx ) {
		this.points = points;
		if( idx == null ) {
			idx = new Array<UInt>();
			for( i in 0...points.length )
				idx[i] = i;
		}
		this.idx = idx;
	}
	
	public function dispose() {
		if( ibuf != null ) { ibuf.dispose(); ibuf = null; }
		if( vbuf != null ) { vbuf.dispose(); vbuf = null; }
	}
	
	public function alloc( c : flash.display3D.Context3D ) {
		dispose();
		ibuf = c.createIndexBuffer(idx.length);
		ibuf.uploadFromVector(flash.Vector.ofArray(idx), 0, idx.length);
		var size = 3;
		if( normals != null )
			size += 3;
		if( tcoords != null )
			size += 2;
		vbuf = c.createVertexBuffer(points.length, size);
		var buf = new flash.Vector<Float>();
		var i = 0;
		for( k in 0...points.length ) {
			var p = points[k];
			buf[i++] = p.x;
			buf[i++] = p.y;
			buf[i++] = p.z;
			if( normals != null ) {
				var n = normals[k];
				buf[i++] = n.x;
				buf[i++] = n.y;
				buf[i++] = n.z;
			}
			if( tcoords != null ) {
				var t = tcoords[k];
				buf[i++] = t.u;
				buf[i++] = t.v;
			}
		}
		vbuf.uploadFromVector(buf, 0, points.length);
	}
	
	public function unindex() {
		if( points.length != idx.length ) {
			var p = [], id : Array<UInt> = [];
			for( i in idx ) {
				id.push(p.length);
				p.push(points[i]);
			}
			points = p;
			idx = id;
		}
	}

	public function translate( dx, dy, dz ) {
		for( p in points ) {
			p.x += dx;
			p.y += dy;
			p.z += dz;
		}
	}
	
	public function addTCoords() {
		throw "Not implemented for this polygon";
	}

	public function addNormals() {
		// make per-point normal
		normals = new Array();
		for( i in 0...points.length )
			normals[i] = new Vector();
		var pos = 0;
		for( i in 0...triCount() ) {
			var i0 = idx[pos++], i1 = idx[pos++], i2 = idx[pos++];
			var p0 = points[i0];
			var p1 = points[i1];
			var p2 = points[i2];
			// this is the per-face normal
			var n = p1.sub(p0).cross(p2.sub(p0));
			// add it to each point
			normals[i0].x += n.x; normals[i0].y += n.y; normals[i0].z += n.z;
			normals[i1].x += n.x; normals[i1].y += n.y; normals[i1].z += n.z;
			normals[i2].x += n.x; normals[i2].y += n.y; normals[i2].z += n.z;
		}
		// normalize all normals
		for( n in normals )
			n.normalize();
	}
	
	public function triCount() {
		return Std.int(idx.length / 3);
	}

}

class Cube extends Polygon {

	public function new( x = 1, y = 1, z = 1 )
	{
		var p = [
			new Vector(0, 0, 0),
			new Vector(x, 0, 0),
			new Vector(0, y, 0),
			new Vector(0, 0, z),
			new Vector(x, y, 0),
			new Vector(x, 0, z),
			new Vector(0, y, z),
			new Vector(x, y, z),
		];
		var idx : Array<UInt> = [
			0, 1, 5,
			0, 5, 3,
			1, 4, 7,
			1, 7, 5,
			3, 5, 7,
			3, 7, 6,
			0, 6, 2,
			0, 3, 6,
			2, 7, 4,
			2, 6, 7,
			0, 4, 1,
			0, 2, 4,
		];
		super(p, idx);
	}
	
	override function addTCoords() {
		unindex();
		
		var z = new UV(0, 0);
		var x = new UV(1, 0);
		var y = new UV(0, 1);
		var o = new UV(1, 1);
		
		tcoords = [
			z, x, o,
			z, o, y,
			x, z, y,
			x, y, o,
			z, x, o,
			z, o, y,
			z, o, x,
			z, y, o,
			x, y, z,
			x, o, y,
			z, o, x,
			z, y, o,
		];
	}
	
}

class Camera {
	
	public var zoom : Float;
	public var ratio : Float;
	public var fov : Float;
	public var zNear : Float;
	public var zFar : Float;
	
	public var mproj : Matrix;
	public var mcam : Matrix;
	public var m : Matrix;
	
	public var pos : Vector;
	public var up : Vector;
	public var target : Vector;

	public function new( fov = 60., zoom = 1., ratio = 1.333333, zNear = 0.02, zFar = 40. ) {
		this.fov = fov;
		this.zoom = zoom;
		this.ratio = ratio;
		this.zNear = zNear;
		this.zFar = zFar;
		pos = new Vector(2, 3, 4);
		up = new Vector(0, 0, -1);
		target = new Vector(0, 0, 0);
		m = new Matrix();
		mcam = new Matrix();
		update();
	}

	public function update() {
		var az = pos.sub(target);
		az.normalize();
		var ax = up.cross(az);
		ax.normalize();
		if( ax.length() == 0 ) {
			ax.x = az.y;
			ax.y = az.z;
			ax.z = az.x;
		}
		var ay = az.cross(ax);
		mcam._11 = ax.x;
		mcam._12 = ay.x;
		mcam._13 = az.x;
		mcam._14 = 0;
		mcam._21 = ax.y;
		mcam._22 = ay.y;
		mcam._23 = az.y;
		mcam._24 = 0;
		mcam._31 = ax.z;
		mcam._32 = ay.z;
		mcam._33 = az.z;
		mcam._34 = 0;
		mcam._41 = -ax.dot(pos);
		mcam._42 = -ay.dot(pos);
		mcam._43 = -az.dot(pos);
		mcam._44 = 1;
		mproj = makeFrustumMatrix();
		m.multiply4x4(mcam, mproj);
	}
	
	public function moveAxis( dx : Float, dy : Float ) {
		var p = new Vector(dx, dy, 0);
		p.project3x3(mcam);
		pos.x += p.x;
		pos.y += p.y;
		pos.z += p.z;
	}
				
	function makeFrustumMatrix() {
		var scale = zoom / Math.tan(fov * Math.PI / 360.0);
		var m = new Matrix();
		m.zero();
		m._11 = scale;
		m._22 = -scale * ratio;
		m._33 = zFar / (zNear - zFar);
		m._34 = -1;
		m._43 = (zNear * zFar) / (zNear - zFar);
		return m;
	}
		
}

class Matrix {

	public var _11 : Float;
	public var _12 : Float;
	public var _13 : Float;
	public var _14 : Float;
	public var _21 : Float;
	public var _22 : Float;
	public var _23 : Float;
	public var _24 : Float;
	public var _31 : Float;
	public var _32 : Float;
	public var _33 : Float;
	public var _34 : Float;
	public var _41 : Float;
	public var _42 : Float;
	public var _43 : Float;
	public var _44 : Float;

	public function new() {
	}

	public function zero() {
		_11 = 0.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = 0.0; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 0.0; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 0.0;
	}

	public function identity() {
		_11 = 1.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = 1.0; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 1.0; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initRotateX( a : Float ) {
		var cos = Math.cos(a);
		var sin = Math.sin(a);
		_11 = 1.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = cos; _23 = sin; _24 = 0.0;
		_31 = 0.0; _32 = -sin; _33 = cos; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initRotateY( a : Float ) {
		var cos = Math.cos(a);
		var sin = Math.sin(a);
		_11 = cos; _12 = 0.0; _13 = -sin; _14 = 0.0;
		_21 = 0.0; _22 = 1.0; _23 = 0.0; _24 = 0.0;
		_31 = sin; _32 = 0.0; _33 = cos; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initRotateZ( a : Float ) {
		var cos = Math.cos(a);
		var sin = Math.sin(a);
		_11 = cos; _12 = sin; _13 = 0.0; _14 = 0.0;
		_21 = -sin; _22 = cos; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 1.0; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initTranslate( x : Float, y : Float, z : Float ) {
		_11 = 1.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = 1.0; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 1.0; _34 = 0.0;
		_41 = x; _42 = y; _43 = z; _44 = 1.0;
	}

	public inline function translate( x : Float, y : Float, z : Float ) {
		_41 += x;
		_42 += y;
		_43 += z;
	}

	public function initScale( x : Float, y : Float, z : Float ) {
		_11 = x; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = y; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = z; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	// 3x4 multiply by default
	public function multiply( a : Matrix, b : Matrix ) {
		var a11 = a._11; var a12 = a._12; var a13 = a._13;
		var a21 = a._21; var a22 = a._22; var a23 = a._23;
		var a31 = a._31; var a32 = a._32; var a33 = a._33;
		var a41 = a._41; var a42 = a._42; var a43 = a._43;
		var b11 = b._11; var b12 = b._12; var b13 = b._13;
		var b21 = b._21; var b22 = b._22; var b23 = b._23;
		var b31 = b._31; var b32 = b._32; var b33 = b._33;
		var b41 = b._41; var b42 = b._42; var b43 = b._43;

		_11 = a11 * b11 + a12 * b21 + a13 * b31;
		_12 = a11 * b12 + a12 * b22 + a13 * b32;
		_13 = a11 * b13 + a12 * b23 + a13 * b33;
		_14 = 0;

		_21 = a21 * b11 + a22 * b21 + a23 * b31;
		_22 = a21 * b12 + a22 * b22 + a23 * b32;
		_23 = a21 * b13 + a22 * b23 + a23 * b33;
		_24 = 0;

		_31 = a31 * b11 + a32 * b21 + a33 * b31;
		_32 = a31 * b12 + a32 * b22 + a33 * b32;
		_33 = a31 * b13 + a32 * b23 + a33 * b33;
		_34 = 0;

		_41 = a41 * b11 + a42 * b21 + a43 * b31 + b41;
		_42 = a41 * b12 + a42 * b22 + a43 * b32 + b42;
		_43 = a41 * b13 + a42 * b23 + a43 * b33 + b43;
		_44 = 1;
	}

	public function multiply4x4( a : Matrix, b : Matrix ) {
		var a11 = a._11; var a12 = a._12; var a13 = a._13; var a14 = a._14;
		var a21 = a._21; var a22 = a._22; var a23 = a._23; var a24 = a._24;
		var a31 = a._31; var a32 = a._32; var a33 = a._33; var a34 = a._34;
		var a41 = a._41; var a42 = a._42; var a43 = a._43; var a44 = a._44;
		var b11 = b._11; var b12 = b._12; var b13 = b._13; var b14 = b._14;
		var b21 = b._21; var b22 = b._22; var b23 = b._23; var b24 = b._24;
		var b31 = b._31; var b32 = b._32; var b33 = b._33; var b34 = b._34;
		var b41 = b._41; var b42 = b._42; var b43 = b._43; var b44 = b._44;

		_11 = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
		_12 = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
		_13 = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
		_14 = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

		_21 = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
		_22 = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
		_23 = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
		_24 = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

		_31 = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
		_32 = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
		_33 = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
		_34 = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

		_41 = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
		_42 = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
		_43 = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
		_44 = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
	}

	public inline function multiply3x4_4x4( a : Matrix, b : Matrix ) {
		var a11 = a._11; var a12 = a._12; var a13 = a._13;
		var a21 = a._21; var a22 = a._22; var a23 = a._23;
		var a31 = a._31; var a32 = a._32; var a33 = a._33;
		var a41 = a._41; var a42 = a._42; var a43 = a._43;
		var b11 = b._11; var b12 = b._12; var b13 = b._13; var b14 = b._14;
		var b21 = b._21; var b22 = b._22; var b23 = b._23; var b24 = b._24;
		var b31 = b._31; var b32 = b._32; var b33 = b._33; var b34 = b._34;
		var b41 = b._41; var b42 = b._42; var b43 = b._43; var b44 = b._44;

		_11 = a11 * b11 + a12 * b21 + a13 * b31;
		_12 = a11 * b12 + a12 * b22 + a13 * b32;
		_13 = a11 * b13 + a12 * b23 + a13 * b33;
		_14 = a11 * b14 + a12 * b24 + a13 * b34;

		_21 = a21 * b11 + a22 * b21 + a23 * b31;
		_22 = a21 * b12 + a22 * b22 + a23 * b32;
		_23 = a21 * b13 + a22 * b23 + a23 * b33;
		_24 = a21 * b14 + a22 * b24 + a23 * b34;

		_31 = a31 * b11 + a32 * b21 + a33 * b31;
		_32 = a31 * b12 + a32 * b22 + a33 * b32;
		_33 = a31 * b13 + a32 * b23 + a33 * b33;
		_34 = a31 * b14 + a32 * b24 + a33 * b34;

		_41 = a41 * b11 + a42 * b21 + a43 * b31 + b41;
		_42 = a41 * b12 + a42 * b22 + a43 * b32 + b42;
		_43 = a41 * b13 + a42 * b23 + a43 * b33 + b43;
		_44 = a41 * b14 + a42 * b24 + a43 * b34 + b44;
	}

	public function inverse3x4( m : Matrix ) {
		var m11 = m._11; var m12 = m._12; var m13 = m._13;
		var m21 = m._21; var m22 = m._22; var m23 = m._23;
		var m31 = m._31; var m32 = m._32; var m33 = m._33;
		_11 = m22*m33 - m23*m32;
		_12 = m13*m32 - m12*m33;
		_13 = m12*m23 - m13*m22;
		_14 = 0;
		_21 = m23*m31 - m21*m33;
		_22 = m11*m33 - m13*m31;
		_23 = m13*m21 - m11*m23;
		_24 = 0;
		_31 = m21*m32 - m22*m31;
		_32 = m12*m31 - m11*m32;
		_33 = m11*m22 - m12*m21;
		_34 = 0;
		_41 = -m._41;
		_42 = -m._42;
		_43 = -m._43;
		_44 = 1;
		var det = m11 * _11 + m12 * _21 + m13 * _31;
		if( det < Const.EPSILON ) {
			zero();
			return;
		}
		var invDet = 1.0 / det;
		_11 *= invDet; _12 *= invDet; _13 *= invDet;
		_21 *= invDet; _22 *= invDet; _23 *= invDet;
		_31 *= invDet; _32 *= invDet; _33 *= invDet;
	}

	public inline function project( v : Vector, out : Vector ) {
		var px = _11 * v.x + _21 * v.y + _31 * v.z + _41;
		var py = _12 * v.x + _22 * v.y + _32 * v.z + _42;
		var pz = _13 * v.x + _23 * v.y + _33 * v.z + _43;
		var w = 1.0 / (_14 * v.x + _24 * v.y + _34 * v.z + _44);
		out.x = px * w;
		out.y = py * w;
		out.z = pz;
		return w;
	}

	public inline function transform( v : Vector, out : Vector ) {
		var px = _11 * v.x + _21 * v.y + _31 * v.z + _41;
		var py = _12 * v.x + _22 * v.y + _32 * v.z + _42;
		var pz = _13 * v.x + _23 * v.y + _33 * v.z + _43;
		out.x = px;
		out.y = py;
		out.z = pz;
	}
	
	public function transpose() {
		var tmp;
		tmp = _12; _12 = _21; _21 = tmp;
		tmp = _13; _13 = _31; _31 = tmp;
		tmp = _14; _14 = _41; _41 = tmp;
		tmp = _23; _23 = _32; _32 = tmp;
		tmp = _24; _24 = _42; _42 = tmp;
		tmp = _34; _34 = _43; _43 = tmp;
	}

	public function toString() {
		return "MAT=[\n" +
			"  [ " + Const.f(_11) + ", " + Const.f(_12) + ", " + Const.f(_13) + ", " + Const.f(_14) + " ]\n" +
			"  [ " + Const.f(_21) + ", " + Const.f(_22) + ", " + Const.f(_23) + ", " + Const.f(_24) + " ]\n" +
			"  [ " + Const.f(_31) + ", " + Const.f(_32) + ", " + Const.f(_33) + ", " + Const.f(_34) + " ]\n" +
			"  [ " + Const.f(_41) + ", " + Const.f(_42) + ", " + Const.f(_43) + ", " + Const.f(_44) + " ]\n" +
		"]";
	}
	
	public function toMatrix() {
		return new flash.geom.Matrix3D(flash.Vector.ofArray([
			_11, _12, _13, _14,
			_21, _22, _23, _24,
			_31, _32, _33, _34,
			_41, _42, _43, _44,
		]));
	}

}

class Vector {

	public var x : Float;
	public var y : Float;
	public var z : Float;

	public function new( x = 0., y = 0., z = 0. ) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function sub( v : Vector ) {
		return new Vector(x - v.x, y - v.y, z - v.z);
	}

	public inline function add( v : Vector ) {
		return new Vector(x + v.x, y + v.y, z + v.z);
	}

	public inline function cross( v : Vector ) {
		return new Vector(y * v.z - z * v.y, z * v.x - x * v.z,  x * v.y - y * v.x);
	}

	public inline function dot( v : Vector ) {
		return x * v.x + y * v.y + z * v.z;
	}

	public inline function length() {
		return Math.sqrt(x * x + y * y + z * z);
	}

	public function normalize() {
		var k = length();
		if( k < Const.EPSILON ) k = 0 else k = 1.0 / k;
		x *= k;
		y *= k;
		z *= k;
	}

	public function set(x,y,z) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function scale( f : Float ) {
		x *= f;
		y *= f;
		z *= f;
	}
	
	public inline function project3x3( m : Matrix ) {
		var px = x * m._11 + y * m._12 + z * m._13;
		var py = x * m._21 + y * m._22 + z * m._23;
		var pz = x * m._31 + y * m._32 + z * m._33;
		x = px;
		y = py;
		z = pz;
	}

	public inline function copy() {
		return new Vector(x,y,z);
	}

	public function toString() {
		return "{"+Const.f(x)+","+Const.f(y)+","+Const.f(z)+"}";
	}


}

class UV {
	
	public var u : Float;
	public var v : Float;

	public function new( u = 0., v = 0. ) {
		this.u = u;
		this.v = v;
	}
	
}

class Main {

	var stage : flash.display.Stage;
	var s : flash.display.Stage3D;
	var c : flash.display3D.Context3D;
	var shader : Shader;
	var pol : Polygon;
	var t : Float;
	var keys : Array<Bool>;

	var camera : Camera;

	function new() {
		t = 0;
		keys = [];
		stage = flash.Lib.current.stage;
		s = stage.stage3Ds[0];
		s.addEventListener( flash.events.Event.CONTEXT3D_CREATE, onReady );
		stage.addEventListener( flash.events.KeyboardEvent.KEY_DOWN, onKey.bind(true) );
		stage.addEventListener( flash.events.KeyboardEvent.KEY_UP, onKey.bind(false) );
		flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, update);
		s.requestContext3D();
	}

	function onKey( down, e : flash.events.KeyboardEvent ) {
		keys[e.keyCode] = down;
	}

	function onReady( _ ) {
		c = s.context3D;
		c.enableErrorChecking = true;
		c.configureBackBuffer( stage.stageWidth, stage.stageHeight, 0, true );

		shader = new Shader();
		camera = new Camera();

		pol = new Cube();
		pol.alloc(c);
	}

	function update(_) {
		if( c == null ) return;

		t += 0.01;

		c.clear(0, 0, 0, 1);
		c.setDepthTest( true, flash.display3D.Context3DCompareMode.LESS_EQUAL );
		c.setCulling(flash.display3D.Context3DTriangleFace.BACK);

		if( keys[K.UP] )
			camera.moveAxis(0,-0.1);
		if( keys[K.DOWN] )
			camera.moveAxis(0,0.1);
		if( keys[K.LEFT] )
			camera.moveAxis(-0.1,0);
		if( keys[K.RIGHT] )
			camera.moveAxis(0.1, 0);
		if( keys[109] )
			camera.zoom /= 1.05;
		if( keys[107] )
			camera.zoom *= 1.05;
		camera.update();

		var project = camera.m.toMatrix();

		var mpos = new flash.geom.Matrix3D();
		mpos.appendRotation(t * 10, flash.geom.Vector3D.Z_AXIS);

		shader.mpos = mpos;
		shader.mproj = project;
		shader.bind(c, pol.vbuf);
		c.drawTriangles(pol.ibuf);
		c.present();
	}

	static function main() {
		haxe.Log.setColor(0xFF0000);
		var inst = new Main();
	}

}