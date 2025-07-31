package entities;

import echo.math.Vector2;
import flixel.FlxG;
import flixel.FlxSprite;
import input.SimpleController;

using echo.FlxEcho;

class Flipper extends FlxSprite {
	var speed:Float = 650;
	var restingAngle:Float = 30;
	var flipAngle:Float = -30;
	var power:Float = 150;
	var triggerButton:Button;

	var body:echo.Body;

	private var dir:Float = 0;

	public function new(X:Float, Y:Float) {
		super(X, Y);

		if (flipAngle - restingAngle < 0) {
			dir = -1 * speed;
		} else {
			dir = 1 * speed;
		}
		var w = 30;
		var h = 50;
		this.body = this.add_body({
			x: x,
			y: y,
			kinematic: true,
			mass: 100,
			rotation: restingAngle,
			shapes: [
				{
					type: CIRCLE,
					radius: h * .5,
					offset_x: 0,
					offset_y: 0,
				},
				{
					type: CIRCLE,
					radius: h * .4,
					offset_x: w,
					offset_y: 0,
				},
				// {
				// 	type: POLYGON,
				// 	vertices: [new Vector2(0, -h*.5), new Vector2(w, -h*.4), new Vector2(w, h*.4), new Vector2(0, h*.5)]
				// }
			],
		});
		body.on_move = (x, y) -> this.setPosition(x, y);
		body.on_rotate = (rot) -> angle = rot;
	}

	override public function update(delta:Float) {
		super.update(delta);
		if (FlxG.keys.pressed.SPACE) {
			body.rotational_velocity = -100;
			// flip(delta);
		} else {
			body.rotational_velocity = 100;
			// rest(delta);
		}
	}

	public function flip(delta:Float) {
		var d = delta * dir;
		if (d < 0) {
			if (body.rotation + d < flipAngle) {
				body.rotation = flipAngle;
			} else {
				body.rotation += d;
			}
		} else {
			if (body.rotation + d > flipAngle) {
				body.rotation = flipAngle;
			} else {
				body.rotation += d;
			}
		}
	}

	public function rest(delta:Float) {
		var d = delta * dir;
		if (-d < 0) {
			if (body.rotation - d < restingAngle) {
				body.rotation = restingAngle;
			} else {
				body.rotation -= d;
			}
		} else {
			if (body.rotation - d > restingAngle) {
				body.rotation = restingAngle;
			} else {
				body.rotation -= d;
			}
		}
	}
}
