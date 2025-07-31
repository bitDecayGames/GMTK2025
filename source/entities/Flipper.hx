package entities;

import flixel.math.FlxMath;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.shape.Circle;
import echo.math.Vector2;
import flixel.FlxG;
import flixel.FlxSprite;
import input.SimpleController;
import flixel.addons.nape.FlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;

class Flipper extends FlxNapeSprite {
	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	var speed:Float = 450;
	var restingAngle:Float = 30;
	var flipAngle:Float = -30;

	private var dir:Float = 0;

	public function new(X:Float, Y:Float, width:Float, height:Float, restingAngle:Float, flipAngle:Float) {
		super(X, Y);
		this.restingAngle = restingAngle;
		this.flipAngle = flipAngle;

		if (flipAngle - restingAngle < 0) {
			dir = -1 * speed;
		} else {
			dir = 1 * speed;
		}
		var w = width;
		var h = height;
		var body = new Body(BodyType.KINEMATIC);
		body.shapes.add(new Circle(h * .5, Vec2.weak(0, 0)));
		body.shapes.add(new Circle(h * .4, Vec2.weak(w, 0)));
		body.shapes.add(new Polygon([
			Vec2.weak(0, -h * .5),
			Vec2.weak(w, -h * .4),
			Vec2.weak(w, h * .4),
			Vec2.weak(0, h * .5)
		]));
		body.mass = 0.0001;
		body.rotation = restingAngle * degToRad;
		addPremadeBody(body);
	}

	override public function update(delta:Float) {
		super.update(delta);
		if (FlxG.keys.pressed.SPACE) {
			body.angularVel = dir * degToRad;
		} else {
			body.angularVel = -dir * degToRad;
		}
		var deg = body.rotation * radToDeg;
		if (dir < 0) {
			if (deg > restingAngle) {
				body.rotation = restingAngle * degToRad;
				body.angularVel = 0;
			} else if (deg < flipAngle) {
				body.rotation = flipAngle * degToRad;
				body.angularVel = 0;
			}
		} else {
			if (deg < restingAngle) {
				body.rotation = restingAngle * degToRad;
				body.angularVel = 0;
			} else if (deg > flipAngle) {
				body.rotation = flipAngle * degToRad;
				body.angularVel = 0;
			}
		}
	}

	override function setBody(body:Body) {
		super.setBody(body);
		body.userData.data = this;
	}

	public function flip(delta:Float) {
		var deg = body.rotation * radToDeg;
		var d = delta * dir;
		if (d < 0) {
			if (deg + d < flipAngle) {
				deg = flipAngle;
			} else {
				deg += d;
			}
		} else {
			if (deg + d > flipAngle) {
				deg = flipAngle;
			} else {
				deg += d;
			}
		}
		body.rotation = deg * degToRad;
	}

	public function rest(delta:Float) {
		var deg = body.rotation * radToDeg;
		var d = delta * dir;
		if (-d < 0) {
			if (deg - d < restingAngle) {
				deg = restingAngle;
			} else {
				deg -= d;
			}
		} else {
			if (deg - d > restingAngle) {
				deg = restingAngle;
			} else {
				deg -= d;
			}
		}
		body.rotation = deg * degToRad;
	}
}
