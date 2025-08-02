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
 * A gate can only be turned on and off by something else triggering it
 */
class Gate extends Interactable {
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
		enableInteractions();
		addPremadeBody(body);
		body.setShapeMaterials(new Material(-100));
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
		isBackground = true;
		followListensTo = true;
	}

	override public function handleInteraction(data:InteractionCallback) {
		TODO.sfx('gate hit');
	}

	override function onOnOffChanged(value:Bool) {
		if (value) {
			disableInteractions();
			animation.play(anims.narrowTarget_1_aseprite);
		} else {
			enableInteractions();
			animation.play(anims.narrowTarget_0_aseprite);
		}
		super.onOnOffChanged(value);
	}

	function disableInteractions() {
		body.setShapeFilters(new InteractionFilter(0, 0));
	}

	function enableInteractions() {
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
	}
}
