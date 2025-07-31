package entities;

import nape.geom.Vec2;
import flixel.FlxSprite;
import input.InputCalculator;
import input.SimpleController;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import flixel.addons.nape.FlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;

class Player extends FlxNapeSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/ball.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/ball.json");

	// public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/ball.json", "Layer 1");
	var speed:Float = 150;
	var playerNum = 0;

	public function new(X:Float, Y:Float) {
		super(X, Y);
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.ball__json);
		animation.play(anims.all_frames);
		// animation.onFrameChange.add((anim, frame, index) -> {
		// 	if (eventData.exists(index)) {
		// 		trace('frame $index has data ${eventData.get(index)}');
		// 	}
		// });

		var body = new Body(BodyType.DYNAMIC);
		body.mass = 1;
		body.shapes.add(new Circle(16));
		addPremadeBody(body);
	}

	override function setBody(body:Body) {
		super.setBody(body);
		body.userData.data = this;
	}

	override public function update(delta:Float) {
		super.update(delta);

		var inputDir = InputCalculator.getInputCardinal(playerNum);
		if (inputDir != NONE) {
			body.velocity.set(new Vec2(inputDir.asVector().x * speed, inputDir.asVector().y * speed));
		}

		if (SimpleController.just_pressed(Button.A, playerNum)) {
			color = color ^ 0xFFFFFF;
		}
	}
}
