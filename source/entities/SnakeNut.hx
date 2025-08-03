package entities;

import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import flixel.FlxSprite;

class SnakeNut extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/snakeNut.json");
	public static var animsRed = AsepriteMacros.tagNames("assets/aseprite/characters/snakeNut_red.json");

	public function new(X:Float, Y:Float, isRed:Bool) {
		super(X, Y);
		if (isRed) {
			Aseprite.loadAllAnimations(this, AssetPaths.snakeNut_red__json);
			animation.play(animsRed.Off);
		} else {
			Aseprite.loadAllAnimations(this, AssetPaths.snakeNut__json);
			animation.play(anims.Off);
		}
	}

	override public function update(delta:Float) {
		super.update(delta);
	}
}
