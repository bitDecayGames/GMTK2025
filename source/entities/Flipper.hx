package entities;

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

class Flipper extends FlxNapeSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/flipper.json");

	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	var ctrlGroup:ControlGroup;

	var restAngle:Float;
	var flipAngle:Float;

	var flipDirection:FlipDir;

	var jointMin:Float;
	var jointMax:Float;
	var angleJoint:AngleJoint;

	var activateJoint:DistanceJoint;
	var restingJoint:DistanceJoint;

	private var dir:Float = 0;

	public function new(group:ControlGroup, X:Float, Y:Float, width:Float, strength:Float, bigRad:Float, smallRad:Float, restAng:Float, flipAng:Float,
			fmass:Float) {
		super();
		Aseprite.loadAllAnimations(this, AssetPaths.flipper__json);
		animation.play(anims.flipper_1_aseprite);
		origin.set(12, 24);
		this.ctrlGroup = group;
		this.width = width;
		this.height = bigRad;
		strength *= 10000;

		if (flipAng - restAng < 0) {
			flipDirection = CCW;
			flipAngle = Math.min(flipAng, restAng);
			restAngle = Math.max(flipAng, restAng);
		} else {
			flipDirection = CW;
			flipAngle = Math.max(flipAng, restAng);
			restAngle = Math.min(flipAng, restAng);
		}
		flipAngle *= degToRad;
		restAngle *= degToRad;
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
		body.mass = fmass;
		body.isBullet = true;

		body.setShapeFilters(new InteractionFilter(CGroups.CONTROL_SURFACE, CGroups.BALL));

		var pivot = new PivotJoint(body, FlxNapeSpace.space.world, Vec2.get(), body.localPointToWorld(Vec2.get()));
		pivot.active = true;
		pivot.stiff = true;
		pivot.space = FlxNapeSpace.space;

		jointMin = Math.min(restAngle, flipAngle);
		jointMax = Math.max(restAngle, flipAngle);
		angleJoint = new AngleJoint(FlxNapeSpace.space.world, body, jointMin, jointMax);
		angleJoint.active = true;
		angleJoint.stiff = true;
		angleJoint.space = FlxNapeSpace.space;

		var forceLocalPos = Vec2.get(w - bigRad - smallRad, 0);
		var activeJointWorldPos = body.localPointToWorld(forceLocalPos.copy().rotate(flipAngle));
		activateJoint = new DistanceJoint(body, FlxNapeSpace.space.world, forceLocalPos, activeJointWorldPos, 0, 0);
		activateJoint.active = true;
		activateJoint.stiff = false;
		activateJoint.space = FlxNapeSpace.space;
		activateJoint.damping = 0;
		activateJoint.maxForce = strength * fmass;

		var restingJointWorldPos = body.localPointToWorld(forceLocalPos.copy().rotate(restAngle));
		restingJoint = new DistanceJoint(body, FlxNapeSpace.space.world, forceLocalPos, restingJointWorldPos, 0, 0);
		restingJoint.active = true;
		restingJoint.stiff = false;
		restingJoint.space = FlxNapeSpace.space;
		restingJoint.damping = 0;
		restingJoint.maxForce = strength * fmass;

		body.rotation = restAngle;
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

	public function flip(delta:Float) {
		activateJoint.active = true;
		restingJoint.active = false;
	}

	public function rest(delta:Float) {
		activateJoint.active = false;
		restingJoint.active = true;
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
