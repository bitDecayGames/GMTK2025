package ui;

import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;

/**
 * A reusable HUD message system for displaying temporary text on screen.
 * Messages stay fixed on screen regardless of camera movement.
 * 
 * Basic usage (auto-positioned at center-top):
 * ```haxe
 * HudMessage.show("Let's GOOOOOOO");
 * ```
 * 
 * With custom duration:
 * ```haxe
 * HudMessage.show("Bonus Round!", 3.0);
 * ```
 * 
 * With custom position and font size:
 * ```haxe
 * HudMessage.show("Game Over", 2.0, 200, 40);
 * ```
 * 
 * Multiple messages can be shown simultaneously:
 * ```haxe
 * HudMessage.show("GOAL!");
 * HudMessage.show("Combo x3", 1.5, null, 24);
 * ```
 * 
 * For more control, create instance directly:
 * ```haxe
 * var message = new HudMessage("Custom Message", 3.0, 150, 36);
 * add(message);
 * ```
 */
class HudMessage extends FlxText {
	var timer:FlxTimer;
	var fadeTween:FlxTween;

	public function new(text:String, ?duration:Float = 2.0, ?y:Null<Float> = null, ?fontSize:Int = 48) {
		// Auto-calculate center-top position if not specified
		var yPos = y != null ? y : 1; // Minimal padding from top of screen

		super(0, yPos, 0, text, fontSize);

		this.font = "assets/data/font/dot_digital-7.ttf";
		this.color = 0xFFFFFF; // White color
		this.alignment = CENTER;
		this.scrollFactor.set(0, 0); // Stay fixed on screen

		// Center horizontally after font is loaded
		this.x = (FlxG.width - this.width) / 2;

		// Start fade-out 0.5 seconds before removal
		var fadeStartTime = Math.max(0, duration - 0.5);

		timer = new FlxTimer();
		timer.start(fadeStartTime, function(t:FlxTimer) {
			// Fade out over 0.5 seconds
			fadeTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween) {
					FlxG.state.remove(this);
					this.destroy();
				}
			});
		});
	}

	override public function destroy() {
		if (timer != null) {
			timer.destroy();
			timer = null;
		}
		if (fadeTween != null) {
			fadeTween.destroy();
			fadeTween = null;
		}
		super.destroy();
	}

	/**
	 * Static helper to easily show messages from anywhere in the code
	 */
	public static function show(text:String, ?duration:Float = 2.0, ?y:Null<Float> = null, ?fontSize:Int):HudMessage {
		var message = new HudMessage(text, duration, y, fontSize);
		FlxG.state.add(message);
		trace('HudMessage: ${text}');
		return message;
	}
}
