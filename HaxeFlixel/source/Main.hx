package;

import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.Assets;
import haxe.Resource;
import haxe.io.Bytes;
import org.msgpack.MsgPack;
import CreaturePackModule;

class Main extends Sprite
{		
	public function new()
	{
		super();

		addChild(new FlxGame(800, 600, MenuState));
	}
}