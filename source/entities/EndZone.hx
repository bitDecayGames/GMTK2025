package entities;

import haxefmod.flixel.FmodFlxUtilities;
import todo.TODO;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import flixel.FlxSprite;
import states.CreditsState;

class EndZone extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/endZone.json");

	private var checking = false;
	private var player:Player;

	public function new(X:Float, Y:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.endZone__json);
		animation.play(anims.Waiting);
		offset.set(width / 2, 0);
		alpha = 0;
	}

	public function start(player:Player) {
		this.player = player;
		TODO.sfx("End Zone is starting to appear");
		FlxTween.tween(this, {alpha: 1}, 2.0, {
			onComplete: (t) -> {
				TODO.sfx("End Zone has appeared");
				checking = true;
			}
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (checking) {
			check();
		}
	}

	function check() {
		if (player == null) {
			trace("MW: I need to be called with the player object");
		}
		if (getPosition().dist(player.body.position.x, player.body.position.y) < width) {
			trigger();
		}
	}

	function trigger() {
		checking = false;
		TODO.sfx("Ball has entered the end zone");
		player.disappear();
		animation.onLoop.addOnce((name) -> {
			FmodFlxUtilities.TransitionToState(new CreditsState());
		});
		animation.play(anims.Eat);
	}
}
