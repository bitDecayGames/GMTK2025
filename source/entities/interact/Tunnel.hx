package entities.interact;

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

class Tunnel extends Interactable {
	// public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/tunnel.json");
	public var exitIID:String = "";
	public var exit:Tunnel = null;

	public static var onTunnelExit:Tunnel->Void = null;

	public function new(X:Float, Y:Float) {
		super(X, Y);
		loadGraphic(AssetPaths.Icons48x64__png, true, 48, 64);
		animation.add('enter', [0]);
		animation.add('exit', [1]);
		animation.play('enter');
		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Polygon(Polygon.rect(-24, -24, 48, 48)));
		// body.isBullet = true;(
		body.shapes.at(0).sensorEnabled = true;

		body.setShapeFilters(new InteractionFilter(0, 0, CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);

		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
	}

	public function setExit() {
		animation.play('exit');
	}

	public static function teleportTo(player:Player, targetTunnel:Tunnel, isRespawn:Bool = false) {
		FmodPlugin.playSFX(FmodSFX.TunnelEnter);

		player.body.velocity.muleq(0);
		player.disappear();
		FlxTween.tween(player.body, {
			"position.x": targetTunnel.body.position.x,
			"position.y": targetTunnel.body.position.y,
			"velocity.x": 0,
			"velocity.y": 0
		}, 1.0, {
			ease: FlxEase.cubeInOut,
			type: ONESHOT,
			onComplete: (t:FlxTween) -> {
				FmodPlugin.playSFX(FmodSFX.TunnelExit);
				player.reappear();
				if (!isRespawn && onTunnelExit != null) {
					onTunnelExit(targetTunnel);
				} else if (isRespawn) {
					HudMessage.show("You can do it!");
				}
			}
		});
	}

	override public function handleInteraction(data:InteractionCallback) {
		if (exit == null) {
			return;
		}

		super.handleInteraction(data);
		var player:Player = data.int1.userData.data;
		teleportTo(player, exit);
	}
}
