package entities;

import flixel.FlxSprite;
import input.SimpleController;

using echo.FlxEcho;

class Flipper extends FlxSprite {
	var speed:Float = 150;
	var restingAngle:Float = 150;
	var flipAngle:Float = 150;
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

		var xOffset = 0.0;
		var yOffset = -height * .25;

		this.body = this.add_body({
			x: x,
			y: y,
			kinematic: false,
			rotation: restingAngle,
			shape: {
				type: RECT,
				width: 100,
				height: 100 / 2,
				offset_x: xOffset,
				offset_y: yOffset,
			}
		});
		body.on_move = (x, y) -> this.setPosition(x, y);
		body.on_rotate = (rot) -> angle = rot;
	}

	override public function update(delta:Float) {
		super.update(delta);
		// if (SimpleController.just_pressed(triggerButton, 1)) {
		flip(delta);
		// }
	}

	public function flip(delta:Float) {
		if (dir < 0) {
			if (body.rotation + dir < flipAngle) {
				body.rotation = flipAngle;
			} else {
				body.rotation += dir;
			}
		} else {
			if (body.rotation + dir > flipAngle) {
				body.rotation = flipAngle;
			} else {
				body.rotation += dir;
			}
		}
	}
}
