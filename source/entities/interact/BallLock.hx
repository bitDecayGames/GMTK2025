package entities.interact;

import entities.SnakeNut.SnakeNutSystem;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
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
import entities.Player;
import ui.HudMessage;

class BallLock extends Interactable {
	public var destIID:String = null;
	public var exit:FlxPoint = FlxPoint.get();

	public var killIIDs:Array<String> = [];
	public var aliveIIDs:Array<String> = [];

	public var killOnActivate:Array<FlxObject> = [];
	public var aliveOnActivate:Array<FlxObject> = [];

	public static var onTunnelExit:Tunnel->Void = null;

	public var snakeNutSystem:SnakeNutSystem;

	public function new(X:Float, Y:Float, exitIID:String) {
		super(X, Y);
		destIID = exitIID;
		loadGraphic(AssetPaths.Icons48x48__png, true, 48, 48);
		animation.add('a', [0]);
		animation.play('a');
		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));
		var s = new Circle(1);
		s.sensorEnabled = true;
		body.shapes.add(s);
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(0, 0, CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
	}

	public function prekill() {
		for (a in aliveOnActivate) {
			a.kill();
		}
	}

	public function teleportTo(player:Player, exit:FlxPoint) {
		FmodPlugin.playSFX(FmodSFX.TunnelEnter);

		for (k in killOnActivate) {
			k.kill();
		}

		for (a in aliveOnActivate) {
			a.revive();
		}

		player.body.velocity.muleq(0);
		FlxTween.tween(player.body, {
			"position.x": body.position.x,
			"position.y": body.position.y,
			"velocity.x": 0,
			"velocity.y": 0
		}, .3, {
			ease: FlxEase.cubeInOut,
			type: ONESHOT,
			onStart: (t:FlxTween) -> {
				TODO.sfx('ball lock entered');
			},
			onComplete: (t:FlxTween) -> {
				player.disappear();
				FlxTween.tween(player.body, {
					"position.x": exit.x,
					"position.y": exit.y
				}, 1.0, {
					ease: FlxEase.cubeInOut,
					type: ONESHOT,
					onComplete: (t:FlxTween) -> {
						if (snakeNutSystem != null) {
							snakeNutSystem.trigger(() -> {
								TODO.sfx('ball lock exited');
								player.reappear();
							});
						} else {
							TODO.sfx('ball lock exited');
							player.reappear();
						}
						// onTunnelExit(targetTunnel);
					}
				});
			}
		});
	}

	override public function handleInteraction(data:InteractionCallback) {
		if (exit == null) {
			return;
		}

		super.handleInteraction(data);

		for (o in killOnActivate) {
			o.kill();
		}
		var player:Player = data.int1.userData.data;
		teleportTo(player, exit);
	}
}
