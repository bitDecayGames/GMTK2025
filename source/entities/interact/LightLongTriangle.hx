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
 * These stay on until they have been reset, good for hooking up to CollectionTriggers to get them to do something
 */
class LightLongTriangle extends Interactable {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/tallTriangleLight.json");

	public function new(X:Float, Y:Float, rotation:Float = 0.0) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.tallTriangleLight__json);
		animation.play(anims.tallTriangleLight_0_aseprite);
		var body = new Body(BodyType.STATIC);
		body.rotation = rotation;
		body.position.set(Vec2.get(X, Y));
		var shape = new Circle(width / 2);
		shape.sensorEnabled = true;
		body.shapes.add(shape);
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);
		body.setShapeMaterials(new Material(-100));
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
		isBackground = true;
	}

	override function onOnOffChanged(value:Bool) {
		if (value) {
			animation.play(anims.tallTriangleLight_1_aseprite);
		} else {
			animation.play(anims.tallTriangleLight_0_aseprite);
		}
		super.onOnOffChanged(value);
	}
}
