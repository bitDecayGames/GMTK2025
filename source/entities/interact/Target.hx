package entities.interact;

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
import flixel.addons.nape.FlxNapeSpace;
import nape.constraint.AngleJoint;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.shape.Circle;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;
import flixel.util.FlxSignal;

class Target extends Interactable {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/jetBumper.json");

	public function new(X:Float, Y:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.jetBumper__json);
		animation.play(anims.jetBumper_0_aseprite);
		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Circle(19, Vec2.weak(0, 0)));
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);
		body.setShapeMaterials(new Material(-100));
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
	}

	override public function handleInteraction(data:InteractionCallback) {
		TODO.sfx('target hit');
	}
}
