package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import input.SimpleController;

using echo.FlxEcho;

class Flipper extends FlxSprite {
	var speed:Float = 650;
	var restingAngle:Float = -30;
	var flipAngle:Float = 30;
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
		this.body = this.add_body({
			x: x,
			y: y,
			kinematic: true,
			rotation: restingAngle,
			shape: {
				type: RECT,
				width: 100,
				height: 100 / 2,
				offset_x: -100,
				offset_y: 0,
			}
		});
		body.on_move = (x, y) -> this.setPosition(x, y);
		body.on_rotate = (rot) -> angle = rot;
	}

	override public function update(delta:Float) {
		super.update(delta);
		if (FlxG.keys.pressed.SPACE) {
			flip(delta);
		} else {
			rest(delta);
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
