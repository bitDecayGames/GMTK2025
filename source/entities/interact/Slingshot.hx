package entities.interact;

import flixel.effects.particles.FlxEmitter;
import nape.shape.Shape;
import todo.TODO;
import nape.callbacks.InteractionCallback;
import constants.CbTypes;
import nape.constraint.DistanceJoint;
import input.SimpleController;
import nape.phys.Material;
import nape.constraint.WeldJoint;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import nape.dynamics.InteractionFilter;
import constants.CGroups;
import nape.constraint.PivotJoint;
import addons.BDFlxNapeSpace;
import nape.constraint.AngleJoint;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.shape.Circle;
import flixel.FlxG;
import addons.BDFlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;
import types.Direction;

class Slingshot extends Interactable {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/slingshot.json");

	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	var bumpStrength:Float = 10;

	// Required velocity to trigger the popper
	var sensitivity:Float = 10;

	var bounceShape:Shape;

	public var emitter:FlxEmitter;

	public function new(X:Float, Y:Float, strength:Float, facing:Direction, sensitivity:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.slingshot__json);
		animation.play(anims.slingshot_0_aseprite);
		// origin.set(12, 24);
		bumpStrength = strength;
		this.sensitivity = sensitivity;

		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));

		if (facing == RIGHT) {
			body.shapes.add(new Circle(9, Vec2.weak(-18, -36))); // top circle
			body.shapes.add(new Circle(9, Vec2.weak(-18, 18))); // back circle
			body.shapes.add(new Circle(9, Vec2.weak(18, 37))); // bottom circle
			body.shapes.add(new Polygon([
				Vec2.get(-18 - 9, -36),
				Vec2.get(-18 - 9, 18),
				Vec2.get(-18, 18 + 9),
				Vec2.get(17, 37 + 9)
			]));

			bounceShape = new Polygon([Vec2.get(-18 + 9, -36), Vec2.get(23, 37 - 9), Vec2.get(-9, 9)]);
			bounceShape.userData.data = true;
			body.shapes.add(bounceShape);
		} else {
			flipX = true;
			body.shapes.add(new Circle(9, Vec2.weak(18, -36)));
			body.shapes.add(new Circle(9, Vec2.weak(18, 18)));
			body.shapes.add(new Circle(9, Vec2.weak(-18, 37)));
			body.shapes.add(new Polygon([
				Vec2.get(18 + 9, -36),
				Vec2.get(18 + 9, 18),
				Vec2.get(18, 18 + 9),
				Vec2.get(-17, 37 + 9)
			]));

			bounceShape = new Polygon([Vec2.get(18 - 9, -36), Vec2.get(-23, 37 - 9), Vec2.get(9, 9)]);
			bounceShape.userData.data = true;
			body.shapes.add(bounceShape);
		}
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);

		body.setShapeMaterials(new Material(-100));

		body.cbTypes.add(CbTypes.CB_INTERACTABLE);

		var lifespan = 0.3;
		var startScale = 1;
		var endScale = 2.5;
		var startAlpha = 1;
		var endAlpha = 0;
		emitter = new FlxEmitter(X, Y, 1);
		emitter.loadParticles(AssetPaths.slingshot_trail__png, 1, 0, false, false);
		emitter.launchMode = SQUARE;
		emitter.velocity.set(0, 0, 0, 0, 0, 0, 0, 0);
		emitter.lifespan.set(lifespan, lifespan);
		emitter.scale.set(startScale, startScale, startScale, startScale, endScale, endScale, endScale, endScale);
		emitter.alpha.set(startAlpha, startAlpha, endAlpha, endAlpha);
		if (facing != RIGHT) {
			for (p in emitter) {
				p.flipX = true;
			}
		}
	}

	function playHitSound(data:InteractionCallback) {
		var impulse = 0.0;
		for (a in data.arbiters) {
			impulse += a.totalImpulse(data.int1.castBody).length;
		}

		var hitSound = FmodPlugin.playSFXWithRef(FmodSFX.BallTerrain2);
		FmodManager.SetEventParameterOnSound(hitSound, "volume", impulse);
	}

	override public function handleInteraction(data:InteractionCallback) {
		var arb = data.arbiters.at(0).collisionArbiter;

		if (arb.body1 == body && !arb.shape1.userData.data) {
			playHitSound(data);
			return;
		} else if (arb.body2 == body && !arb.shape2.userData.data) {
			playHitSound(data);
			return;
		}

		var impactNormal = arb.normal;
		if (arb.shape2.body == body) {
			impactNormal.muleq(-1);
		}
		emitter.start(true);

		var impactImpulse = arb.normalImpulse(data.int1.castBody);
		// trace(impactImpulse);
		// trace(impactImpulse.length);

		// trace(impactNormal);
		// trace(data.int1.castBody.velocity);
		// trace(data.int1.castBody.velocity.length);
		// trace(data.int1.castBody.velocity.dot(impactNormal));
		// trace(impactNormal.dot(data.int1.castBody.velocity));
		if (impactImpulse.length >= sensitivity) {
			super.handleInteraction(data);
			// if (data.int1.castBody.velocity.dot(impactNormal) >= sensitivity) {
			// if (data.int1.castBody.velocity.length >= sensitivity) {
			data.int1.castBody.applyImpulse(impactNormal.mul(bumpStrength));
			FmodPlugin.playSFX(FmodSFX.Slingshot);

			animation.play(anims.slingshot_1_aseprite, true);
			animation.finishCallback = function(name:String) {
				animation.play(anims.slingshot_0_aseprite);
			}
		}
	}
}
