package entities.interact;

import flixel.effects.particles.FlxEmitter;
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
import flixel.addons.nape.FlxNapeSpace;
import nape.constraint.AngleJoint;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.shape.Circle;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;

class Popper extends Interactable {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/jetBumper.json");

	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	var bumpStrength:Float = 10;

	// Required velocity to trigger the popper
	var sensitivity:Float = 10;

	public var emitter:FlxEmitter;

	public function new(X:Float, Y:Float, strength:Float, sensitivity:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.jetBumper__json);
		animation.play(anims.jetBumper_0_aseprite);
		// origin.set(12, 24);
		bumpStrength = strength;
		this.sensitivity = sensitivity;

		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Circle(19, Vec2.weak(0, 0)));
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
		emitter.loadParticles(AssetPaths.bumper_trail__png, 1, 0, false, false);
		emitter.launchMode = SQUARE;
		emitter.velocity.set(0, 0, 0, 0, 0, 0, 0, 0);
		emitter.lifespan.set(lifespan, lifespan);
		emitter.scale.set(startScale, startScale, startScale, startScale, endScale, endScale, endScale, endScale);
		emitter.alpha.set(startAlpha, startAlpha, endAlpha, endAlpha);
	}

	override public function handleInteraction(data:InteractionCallback) {
		emitter.start(true);

		var arb = data.arbiters.at(0).collisionArbiter;
		var impactNormal = arb.normal;
		if (arb.shape2.body == body) {
			impactNormal.muleq(-1);
		}

		var impactImpulse = arb.normalImpulse(data.int1.castBody);
		// trace(impactImpulse);
		// trace(impactImpulse.length);

		// trace(impactNormal);
		// trace(data.int1.castBody.velocity);
		// trace(data.int1.castBody.velocity.length);
		// trace(data.int1.castBody.velocity.dot(impactNormal));
		// trace(impactNormal.dot(data.int1.castBody.velocity));
		if (impactImpulse.length >= sensitivity) {
			// if (data.int1.castBody.velocity.dot(impactNormal) >= sensitivity) {
			// if (data.int1.castBody.velocity.length >= sensitivity) {
			data.int1.castBody.applyImpulse(impactNormal.mul(bumpStrength));
			TODO.sfx('popper hit');
		}
	}
}
