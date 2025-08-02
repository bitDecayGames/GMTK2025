package entities.interact;

import todo.TODO;
import nape.callbacks.InteractionCallback;
import constants.CbTypes;
import nape.phys.Material;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import nape.dynamics.InteractionFilter;
import constants.CGroups;
import nape.geom.Vec2;
import nape.shape.Circle;
import nape.phys.Body;
import nape.phys.BodyType;

class Post extends Interactable {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/post.json");

	public function new(X:Float, Y:Float, sensitivity:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.post__json);
		animation.play(anims.post_aseprite);
		var body = new Body(BodyType.STATIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Circle(width / 2, Vec2.weak(0, 0)));
		body.isBullet = true;
		body.setShapeFilters(new InteractionFilter(CGroups.INTERACTABLE, CGroups.BALL));
		addPremadeBody(body);
		body.setShapeMaterials(new Material(-100));
		body.cbTypes.add(CbTypes.CB_INTERACTABLE);
	}

	override public function handleInteraction(data:InteractionCallback) {
		TODO.sfx("hit post");
	}
}
