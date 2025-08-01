package entities;

import constants.CbTypes;
import flixel.util.FlxColor;
import flixel.effects.particles.FlxParticle;
import flixel.effects.particles.FlxEmitter;
import nape.phys.Material;
import constants.CGroups;
import nape.dynamics.InteractionFilter;
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

class Player extends SelfAssigningFlxNapeSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/ball.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/ball.json");

	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	// public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/ball.json", "Layer 1");
	var speed:Float = 150;
	var playerNum = 0;

	public var emitter:FlxEmitter;

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
		body.isBullet = true;

		body.shapes.add(new Circle(16, Material.steel()));
		addPremadeBody(body);

		body.setShapeFilters(new InteractionFilter(CGroups.BALL, CGroups.ALL));
		body.cbTypes.add(CbTypes.CB_BALL);

		var trailLength = 15;
		var lifespan = .2;
		var endScale = 0.6;
		var startAlpha = 0.8;
		emitter = new FlxEmitter(X, Y, trailLength);
		emitter.loadParticles(AssetPaths.ball_trail__png, trailLength, 0, false, false);
		emitter.launchMode = SQUARE;
		emitter.velocity.set(0, 0, 0, 0, 0, 0, 0, 0);
		emitter.lifespan.set(lifespan, lifespan);
		emitter.scale.set(1, 1, 1, 1, endScale, endScale, endScale, endScale);
		emitter.alpha.set(startAlpha, startAlpha, 0, 0);
		emitter.start(false, lifespan / trailLength);
	}

	override function setBody(body:Body) {
		super.setBody(body);
		body.userData.data = this;
	}

	override public function update(delta:Float) {
		super.update(delta);
		emitter.setPosition(body.position.x, body.position.y);
		var rot = body.velocity.angle * radToDeg;
		emitter.angle.set(rot, rot, rot, rot);

		var inputDir = InputCalculator.getInputCardinal(playerNum);
		if (inputDir != NONE) {
			body.velocity.set(new Vec2(inputDir.asVector().x * speed, inputDir.asVector().y * speed));
		}

		if (SimpleController.just_pressed(Button.A, playerNum)) {
			color = color ^ 0xFFFFFF;
		}
	}

	override function draw() {
		this.angle = 0;
		super.draw();
	}
}
