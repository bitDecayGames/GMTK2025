package entities;

import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.util.FlxTimer;
import todo.TODO;
import flixel.group.FlxGroup.FlxTypedGroup;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import flixel.FlxSprite;

class SnakeNut extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/snakeNut.json");
	public static var animsRed = AsepriteMacros.tagNames("assets/aseprite/characters/snakeNut_red.json");

	public var isRed:Bool;
	public var isFilled:Bool;
	public var endZonePostion:FlxPoint;

	public function new(X:Float, Y:Float, isRed:Bool, endZoneX:Float, endZoneY:Float) {
		super(X, Y);
		this.isRed = isRed;
		if (isRed) {
			Aseprite.loadAllAnimations(this, AssetPaths.snakeNut_red__json);
			animation.play(animsRed.Off);
		} else {
			Aseprite.loadAllAnimations(this, AssetPaths.snakeNut__json);
			animation.play(anims.Off);
		}
		endZonePostion = FlxPoint.get(endZoneX, endZoneY);
		offset.set(width / 2, -height / 7);
	}

	public function fillUp(onComplete:String->Void) {
		if (isFilled) {
			return;
		}
		isFilled = true;
		if (onComplete != null) {
			animation.onLoop.addOnce(onComplete);
		}
		animation.onLoop.addOnce((name) -> {
			trace('finished animation: ${name}');
			if (isRed) {
				animation.play(animsRed.Bubble);
			} else {
				animation.play(anims.Bubble);
			}
		});
		if (isRed) {
			TODO.sfx("Start to fill up the RED nut");
			animation.play(animsRed.FillUp);
		} else {
			TODO.sfx("Start to fill up one of the GREEN nuts");
			animation.play(anims.FillUp);
		}
	}
}

class SnakeNutSystem extends FlxTypedGroup<SnakeNut> {
	public var player:Player;

	public function trigger(onComplete:() -> Void) {
		var nut:SnakeNut = null;
		// find the first non-red, non-filled snake nut
		for (sn in this) {
			if (!sn.isRed && !sn.isFilled) {
				nut = sn;
				break;
			}
		}

		if (nut != null) {
			nut.fillUp((name) -> {
				for (sn in this) {
					if (!sn.isRed && !sn.isFilled) {
						// if we are here, then there are still more nuts to be filled so we can stop
						onComplete();
						return;
					}
				}
				TODO.sfx("Filled up the last green nut");
				FlxTimer.wait(2.0, () -> {
					// if we get here, that means it was the last nut to fill, gotta fill the red nut
					trigger(onComplete);
				});
			});
		} else {
			// find the first red nut
			for (sn in this) {
				if (sn.isRed) {
					nut = sn;
					break;
				}
			}
			// can't fill a nut past its breaking point
			if (nut.isFilled)
				return;

			nut.fillUp((name) -> {
				TODO.sfx("Finished filling up the RED nut");
				FlxTimer.wait(2.0, () -> {
					var ez = new EndZone(nut.endZonePostion.x, nut.endZonePostion.y);
					FlxG.state.add(ez);
					ez.start(player);
					onComplete();
				});
			});
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		#if debug
		// because 8 is the ballsack of the keyboard
		if (FlxG.keys.justPressed.EIGHT) {
			trigger(() -> {
				// doing nothing is fine here, it is debug after all
			});
		}
		#end
	}
}
