package entities;

import flixel.util.FlxTimer;
import echo.Physics;
import nape.callbacks.InteractionCallback;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
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
import addons.BDFlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import entities.interact.Slingshot;

class Player extends SelfAssigningFlxNapeSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/ball.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/ball.json");

	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	// public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/ball.json", "Layer 1");
	var speed:Float = 150;
	var playerNum = 0;

	public var emitter:FlxEmitter;
	public var disappearer:FlxEmitter;
	public var sparks:FlxEmitter;

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

		body.setShapeFilters(new InteractionFilter(CGroups.BALL, CGroups.ALL, CGroups.BALL, CGroups.ALL));
		body.cbTypes.add(CbTypes.CB_BALL);

		var trailLength = 200;
		var lifespan = .2;
		var startScale = 0.7;
		var endScale = 0.0;
		var startAlpha = 1;
		var endAlpha = 1;
		emitter = new FlxEmitter(X, Y, trailLength);
		emitter.loadParticles(AssetPaths.ball_trail__png, trailLength, 0, false, false);
		emitter.launchMode = SQUARE;
		emitter.velocity.set(0, 0, 0, 0, 0, 0, 0, 0);
		emitter.lifespan.set(lifespan, lifespan);
		emitter.scale.set(startScale, startScale, startScale, startScale, startScale / 2, endScale, startScale / 2, endScale);
		emitter.alpha.set(startAlpha, startAlpha, endAlpha, endAlpha);
		emitter.start(false, 0);

		disappearer = new FlxEmitter(X, Y, 20);
		disappearer.loadParticles(AssetPaths.spark__png, 20, 0, false, false);
		disappearer.launchMode = CIRCLE;
		disappearer.launchAngle.set(0, 360);
		disappearer.alpha.set(.8, 1, 0, 0);
		disappearer.angularVelocity.set(-800, 800, 0, 0);
		disappearer.lifespan.set(0.8, 1);

		sparks = new FlxEmitter(X, Y, 20);
		sparks.loadParticles(AssetPaths.spark__png, 20, 0, false, false);
		sparks.launchMode = CIRCLE;
		sparks.speed.set(400, 500);
		sparks.launchAngle.set(0, 360);
		sparks.alpha.set(.8, 1, 0, 0);
		sparks.angularVelocity.set(-800, 800, 0, 0);
		sparks.lifespan.set(.1, .2);
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
	}

	override function draw() {
		this.angle = 0;
		super.draw();
	}

	public function disappear() {
		visible = false;
		emitter.visible = false;
		disappearer.visible = true;
		disappearer.setPosition(body.position.x, body.position.y);
		disappearer.start(true);
		FlxTimer.wait(0.1, () -> {
			physicsEnabled = false;
		});
	}

	public function reappear() {
		visible = true;
		emitter.visible = true;
		disappearer.visible = false;
		physicsEnabled = true;
	}

	public function spark() {
		sparks.setPosition(body.position.x, body.position.y);
		sparks.start(true);
	}

	public function handleInteraction(data:InteractionCallback) {
		var arb = data.arbiters.at(0).collisionArbiter;
		var impactNormal = Vec2.get(arb.normal.x, arb.normal.y);
		if (arb.shape2.body == body) {
			impactNormal.muleq(-1);
		}
		var impactImpulse = arb.normalImpulse(data.int1.castBody);

		// Only spark for strong impacts
		if (impactImpulse.length < 1)
			return;

		// Get the other body and shape in the collision
		var otherBody = (arb.body1 == body) ? arb.body2 : arb.body1;
		var hitShape = (arb.body1 == body) ? arb.shape2 : arb.shape1;

		// If hitting slingshot, only spark on front face hits
		if (otherBody.userData.data is Slingshot && hitShape.userData.data != true)
			return;

		spark();
	}
}
