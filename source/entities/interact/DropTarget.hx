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
import flixel.addons.nape.FlxNapeSpace;
import nape.constraint.AngleJoint;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.shape.Circle;
import nape.phys.Body;
import nape.phys.BodyType;

/**
 * These can be set to reset after a certain amount of time, or hooked up to some other triggerable
 */
class DropTarget extends Interactable {
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
	}

	override public function handleInteraction(data:InteractionCallback) {
		TODO.sfx('drop target hit');
		setOn(true);
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
		FlxTimer.wait(0.2, () -> {
			body.setShapeFilters(new InteractionFilter(0, 0));
		});
	}

	function enableInteractions() {
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
	}
}
