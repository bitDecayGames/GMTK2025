package entities.interact;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.effects.particles.FlxEmitter;
import todo.TODO;
import nape.callbacks.InteractionCallback;
import constants.CbTypes;
import nape.constraint.DistanceJoint;
import input.SimpleController;
import nape.phys.Material;
import nape.constraint.WeldJoint;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import nape.dynamics.InteractionFilter;
import constants.CGroups;
import nape.constraint.PivotJoint;
import addons.BDFlxNapeSpace;
import nape.constraint.AngleJoint;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.shape.Circle;
import flixel.FlxG;
import addons.BDFlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;
import flixel.util.FlxSignal;

/**
 * These will only stay on for a quarter of a second, they should be hooked up to Lights instead of
 * directly to a CollectionTrigger
 */
class Kicker extends Interactable {
	// public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/kicker.json");
	var shootDir = Vec2.get(1, 0);
	var kickPower:Float = 0;

	public function new(X:Float, Y:Float, rotation:Float, power:Float) {
		super(X, Y);
		loadGraphic(AssetPaths.Icons48x48__png, true, 48, 48);
		animation.add('a', [0]);
		animation.play('a');
		var body = new Body(BodyType.STATIC);
		body.rotation = rotation;
		body.position.set(Vec2.get(X, Y));
		var s = new Circle(1);
		s.sensorEnabled = true;
		body.shapes.add(s);
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(0, 0, CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);

		shootDir.rotate(rotation);
		kickPower = power;
	}

	var occupied = false;

	override public function handleInteraction(data:InteractionCallback) {
		if (occupied) {
			return;
		}

		occupied = true;
		var player:Player = data.int1.userData.data;
		player.body.velocity.muleq(0);
		player.body.allowMovement = false;
		FlxTween.tween(data.int1.castBody, {
			"position.x": body.position.x,
			"position.y": body.position.y,
			"velocity.x": 0,
			"velocity.y": 0
		}, .3, {
			ease: FlxEase.cubeInOut,
			type: ONESHOT,
			onStart: (t:FlxTween) -> {
				FmodPlugin.playSFX(FmodSFX.KickerEnter);
			},
			onComplete: (t:FlxTween) -> {
				FlxTimer.wait(1.0, () -> {
					FmodPlugin.playSFX(FmodSFX.KickerLaunch);
					player.body.allowMovement = true;
					player.body.velocity.set(shootDir.mul(kickPower, true));
					player.spark();
				});
				FlxTimer.wait(1.3, () -> {
					occupied = false;
				});
			}
		});
	}

	override function resetOnOff() {
		// super.resetOnOff();
		// animation.play(anims.wideTarget_0_aseprite);
	}
}
