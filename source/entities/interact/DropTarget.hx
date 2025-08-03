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
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;

/**
 * These can be set to reset after a certain amount of time, or hooked up to some other triggerable
 */
class DropTarget extends Interactable {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/dropTarget.json");

	public function new(X:Float, Y:Float, rotation:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.dropTarget__json);
		animation.play(anims.dropTarget_0_aseprite);
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
		FmodPlugin.playSFX(FmodSFX.Dropper3);
		setOn(true);
		super.handleInteraction(data);
	}

	override function onOnOffChanged(value:Bool) {
		if (value) {
			disableInteractions();
			animation.play(anims.dropTarget_1_aseprite);
		} else {
			enableInteractions();
			animation.play(anims.dropTarget_0_aseprite);
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
