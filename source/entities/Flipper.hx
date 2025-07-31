package entities;

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

class Flipper extends FlxNapeSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/flipper.json");

	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	var ctrlGroup:ControlGroup;

	var speed:Float = 450;
	var restingAngle:Float;
	var flipAngle:Float;

	var flipDirection:FlipDir;

	var jointMin:Float;
	var jointMax:Float;
	var angleJoint:AngleJoint;

	private var dir:Float = 0;

	public function new(group:ControlGroup, X:Float, Y:Float, width:Float, strength:Float, bigRad:Float, smallRad:Float, restingAngle:Float, flipAngle:Float) {
		super();
		Aseprite.loadAllAnimations(this, AssetPaths.flipper__json);
		animation.play(anims.flipper_1_aseprite);
		origin.set(12, 24);
		this.ctrlGroup = group;
		this.width = width;
		this.height = bigRad;
		this.restingAngle = restingAngle;
		this.flipAngle = flipAngle;
		speed *= strength;

		if (flipAngle - restingAngle < 0) {
			flipDirection = CCW;
			dir = -1 * speed;
		} else {
			flipDirection = CW;
			dir = 1 * speed;
		}
		var w = width;

		var body = new Body(BodyType.DYNAMIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Circle(bigRad, Vec2.weak(0, 0), Material.rubber()));
		body.shapes.add(new Circle(smallRad, Vec2.weak(w - bigRad - smallRad, 0), Material.rubber()));
		body.shapes.add(new Polygon([
			Vec2.weak(0, -bigRad),
			Vec2.weak(w - bigRad - smallRad, -smallRad),
			Vec2.weak(w - bigRad - smallRad, smallRad),
			Vec2.weak(0, bigRad)
		], Material.rubber()));

		body.setShapeFilters(new InteractionFilter(CGroups.CONTROL_SURFACE, CGroups.BALL));

		var pivot = new PivotJoint(body, FlxNapeSpace.space.world, Vec2.get(), body.localPointToWorld(Vec2.get()));
		pivot.active = true;
		pivot.stiff = true;
		pivot.space = FlxNapeSpace.space;

		jointMin = Math.min(restingAngle, flipAngle) * degToRad;
		jointMax = Math.max(restingAngle, flipAngle) * degToRad;
		angleJoint = new AngleJoint(FlxNapeSpace.space.world, body, jointMin, jointMax);
		angleJoint.active = true;
		angleJoint.stiff = true;
		angleJoint.space = FlxNapeSpace.space;

		body.mass = 100;
		body.rotation = restingAngle * degToRad;
		addPremadeBody(body);
	}

	override public function update(delta:Float) {
		super.update(delta);
		var activated = switch ctrlGroup {
			case LEFT:
				FlxG.keys.pressed.Z;
			case RIGHT:
				FlxG.keys.pressed.M;
		};
		if (activated) {
			flip(delta);
		} else {
			rest(delta);
		}
	}

	override function setBody(body:Body) {
		super.setBody(body);
		body.userData.data = this;
	}

	// Some jank to help us stop moving the flipper once it's at its limit
	var lockout = 0;

	public function flip(delta:Float) {
		if (lockout == 1) {
			return;
		} else {
			lockout = 0;
		}

		if (flipDirection == CCW && body.rotation <= jointMin) {
			body.angularVel = 0;
			angleJoint.jointMax = jointMin;
			lockout = 1;
			return;
		} else if (flipDirection == CW && body.rotation >= jointMax) {
			body.angularVel = 0;
			angleJoint.jointMin = jointMax;
			lockout = 1;
			return;
		} else {
			angleJoint.jointMax = jointMax;
			angleJoint.jointMin = jointMin;
		}

		body.applyAngularImpulse(dir * (body.mass / 3));
		// body.applyImpulse();
		// body.angularVel = dir * degToRad;
	}

	public function rest(delta:Float) {
		if (lockout == -1) {
			return;
		} else {
			lockout = 0;
		}

		if (flipDirection == CCW && body.rotation >= jointMax) {
			body.angularVel = 0;
			angleJoint.jointMin = jointMax;
			lockout = -1;
			return;
		} else if (flipDirection == CW && body.rotation <= jointMin) {
			body.angularVel = 0;
			angleJoint.jointMax = jointMin;
			lockout = -1;
			return;
		} else {
			angleJoint.jointMax = jointMax;
			angleJoint.jointMin = jointMin;
		}

		body.applyAngularImpulse(-dir * (body.mass / 3));
		// body.angularVel = -dir * degToRad;
	}
}

enum ControlGroup {
	LEFT;
	RIGHT;
}

enum FlipDir {
	CW;
	CCW;
}
