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

	var speed:Float = 650;
	var restingAngle:Float = 30;
	var flipAngle:Float = -30;
	var power:Float = 150;
	var triggerButton:Button;

	private var dir:Float = 0;

	public function new(X:Float, Y:Float) {
		super(X, Y);

		if (flipAngle - restingAngle < 0) {
			dir = -1 * speed;
		} else {
			dir = 1 * speed;
		}
		var w = 80;
		var h = 50;
		var body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Circle(h * .5, Vec2.weak(0, 0)));
		body.shapes.add(new Circle(h * .4, Vec2.weak(w, 0)));
		body.shapes.add(new Polygon([
			Vec2.weak(0, -h * .5),
			Vec2.weak(w, -h * .4),
			Vec2.weak(w, h * .4),
			Vec2.weak(0, h * .5)
		]));
		body.rotation = restingAngle * degToRad;
		body.gravMassScale = 0;
		addPremadeBody(body);
		// this.body = this.add_body({
		//	x: x,
		//	y: y,
		//	kinematic: true,
		//	mass: 100,
		//	rotation: restingAngle,
		//	shapes: [
		//		{
		//			type: CIRCLE,
		//			radius: h * .5,
		//			offset_x: 0,
		//			offset_y: 0,
		//		},
		//		{
		//			type: CIRCLE,
		//			radius: h * .4,
		//			offset_x: w,
		//			offset_y: 0,
		//		},
		//		// {
		//		// 	type: POLYGON,
		//		// 	vertices: [Vec2.weak(0, -h*.5), Vec2.weak(w, -h*.4), Vec2.weak(w, h*.4), Vec2.weak(0, h*.5)]
		//		// }
		//	],
		// });
		// body.on_move = (x, y) -> this.setPosition(x, y);
		// body.on_rotate = (rot) -> angle = rot;
	}

	override public function update(delta:Float) {
		super.update(delta);
		if (FlxG.keys.pressed.SPACE) {
			body.applyAngularImpulse(1000);
			// flip(delta);
		} else {
			body.applyAngularImpulse(-1000);
			// rest(delta);
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
		body.rotation = deg;
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
		body.rotation = deg;
	}
}
