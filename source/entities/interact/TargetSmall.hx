package entities.interact;

import flixel.util.FlxTimer;
import todo.TODO;
import nape.callbacks.InteractionCallback;
import constants.CbTypes;
import nape.phys.Material;
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
import nape.phys.Body;
import nape.phys.BodyType;

/**
 * These will only stay on for a quarter of a second, they should be hooked up to Lights instead of
 * directly to a CollectionTrigger
 */
class TargetSmall extends Interactable {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/narrowTarget.json");

	public function new(X:Float, Y:Float, rotation:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.narrowTarget__json);
		animation.play(anims.narrowTarget_0_aseprite);
		var body = new Body(BodyType.STATIC);
		body.rotation = rotation;
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Polygon(Polygon.rect(-width / 2, -height / 2, width, height)));
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);
		body.setShapeMaterials(new Material(-100));
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
		secondsToReset = 0.2;
	}

	override public function handleInteraction(data:InteractionCallback) {
		TODO.sfx('small target hit');
		setOn(true);
	}

	override function onOnOffChanged(value:Bool) {
		if (value) {
			animation.play(anims.narrowTarget_1_aseprite);
		} else {
			animation.play(anims.narrowTarget_0_aseprite);
		}
		super.onOnOffChanged(value);
	}
}
