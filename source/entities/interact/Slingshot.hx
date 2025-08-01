package entities.interact;

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
import flixel.addons.nape.FlxNapeSpace;
import nape.constraint.AngleJoint;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.shape.Circle;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;
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

			bounceShape = new Polygon([Vec2.get(-18 + 9, -36), Vec2.get(18, 37 - 9), Vec2.get(-9, 9)]);
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

			bounceShape = new Polygon([Vec2.get(18 - 9, -36), Vec2.get(-18, 37 - 9), Vec2.get(9, 9)]);
			bounceShape.userData.data = true;
			body.shapes.add(bounceShape);
		}
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);

		body.setShapeMaterials(new Material(-100));

		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
	}

	override public function handleInteraction(data:InteractionCallback) {
		var arb = data.arbiters.at(0).collisionArbiter;

		if (arb.body1 == body && !arb.shape1.userData.data) {
			TODO.sfx('slingshot non-bounce side hit');
			return;
		} else if (arb.body2 == body && !arb.shape2.userData.data) {
			TODO.sfx('slingshot non-bounce side hit');
			return;
		}

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
			TODO.sfx('slingshot face hit');
		}
	}
}
