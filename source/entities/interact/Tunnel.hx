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

class Tunnel extends Interactable {
	// public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/tunnel.json");
	public var exit:Tunnel = null;

	public function new(X:Float, Y:Float) {
		super(X, Y);
		makeGraphic(64, 64, FlxColor.RED);

		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Polygon(Polygon.rect(-24, -24, 48, 48)));
		// body.isBullet = true;(
		body.shapes.at(0).sensorEnabled = true;

		body.setShapeFilters(new InteractionFilter(0, 0, CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);

		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
	}

	override public function handleInteraction(data:InteractionCallback) {
		if (exit == null) {
			return;
		}

		FmodPlugin.playSFX(FmodSFX.TunnelEnter);

		data.int1.castBody.velocity.muleq(0);
		var d = data.int1.userData.data;
		d.disappear();
		FlxTween.tween(data.int1.castBody, {
			"position.x": exit.body.position.x,
			"position.y": exit.body.position.y,
			"velocity.x": 0,
			"velocity.y": 0
		}, 1.0, {
			ease: FlxEase.cubeInOut,
			type: ONESHOT,
			onComplete: (t:FlxTween) -> {
				FmodPlugin.playSFX(FmodSFX.TunnelExit);
				d.reappear();
			}
		});
	}
}
