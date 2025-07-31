package entities.interact;

import nape.callbacks.InteractionCallback;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import nape.dynamics.InteractionFilter;
import constants.CGroups;
import nape.geom.Vec2;
import nape.shape.Circle;
import flixel.addons.nape.FlxNapeSprite;
import nape.phys.Body;
import nape.phys.BodyType;

class Interactable extends SelfAssigningFlxNapeSprite {
	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	public function handleInteraction(data:InteractionCallback) {
		// Override to provide functionality
	}
}
