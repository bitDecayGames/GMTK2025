package entities.interact;

import flixel.util.FlxTimer;
import nape.callbacks.InteractionCallback;
import constants.CbTypes;
import nape.phys.Material;
import nape.dynamics.InteractionFilter;
import constants.CGroups;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;

/**
 * These are on when the ball is intersecting the body, and off when the ball is not. They are invisible.
 */
class Sensor extends Interactable {
	public function new(X:Float, Y:Float, W:Float, H:Float) {
		super(X, Y);
		visible = false;
		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));
		var shape = new Polygon(Polygon.rect(-W / 2, -H / 2, W, H));
		shape.sensorEnabled = true;
		body.shapes.add(shape);
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(CGroups.SENSOR, CGroups.BALL));
		addPremadeBody(body);
		body.setShapeMaterials(new Material(-100));
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
		isBackground = true;
		followListensTo = true;
	}

	override public function handleInteraction(data:InteractionCallback) {
		setOn(true);
	}

	override function handleInteractionEnd(data:InteractionCallback) {
		FlxTimer.wait(0.5, () -> {
			setOn(false);
		});
	}
}
