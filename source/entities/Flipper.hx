package entities;

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

	var speed:Float = 450;
	var restingAngle:Float;
	var flipAngle:Float;

	private var dir:Float = 0;

	public function new(X:Float, Y:Float, width:Float, bigRad:Float, smallRad:Float, restingAngle:Float, flipAngle:Float) {
		super();
		Aseprite.loadAllAnimations(this, AssetPaths.flipper__json);
		animation.play(anims.flipper_1_aseprite);
		origin.set(12, 24);
		this.width = width;
		this.height = bigRad;
		this.restingAngle = restingAngle;
		this.flipAngle = flipAngle;

		if (flipAngle - restingAngle < 0) {
			dir = -1 * speed;
		} else {
			dir = 1 * speed;
		}
		var w = width;

		var body = new Body(BodyType.DYNAMIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Circle(bigRad, Vec2.weak(0, 0)));
		body.shapes.add(new Circle(smallRad, Vec2.weak(w - bigRad - smallRad, 0)));
		body.shapes.add(new Polygon([
			Vec2.weak(0, -bigRad),
			Vec2.weak(w - bigRad - smallRad, -smallRad),
			Vec2.weak(w - bigRad - smallRad, smallRad),
			Vec2.weak(0, bigRad)
		]));

		body.setShapeFilters(new InteractionFilter(CGroups.CONTROL_SURFACE, CGroups.BALL));

		var pivot = new PivotJoint(body, FlxNapeSpace.space.world, Vec2.get(), body.localPointToWorld(Vec2.get()));
		pivot.active = true;
		pivot.stiff = true;
		pivot.space = FlxNapeSpace.space;

		var angleJoint = new AngleJoint(FlxNapeSpace.space.world, body, Math.min(restingAngle, flipAngle) * degToRad,
			Math.max(restingAngle, flipAngle) * degToRad);
		angleJoint.active = true;
		angleJoint.space = FlxNapeSpace.space;

		body.mass = 1;
		body.rotation = restingAngle * degToRad;
		addPremadeBody(body);
	}

	override public function update(delta:Float) {
		super.update(delta);
		if (FlxG.keys.pressed.SPACE) {
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
		body.angularVel = dir * degToRad;
	}

	public function rest(delta:Float) {
		body.angularVel = -dir * degToRad;
	}
}
