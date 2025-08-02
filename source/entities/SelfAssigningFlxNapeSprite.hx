package entities;

import addons.BDFlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import nape.phys.Body;
import addons.BDFlxNapeSprite;

class SelfAssigningFlxNapeSprite extends BDFlxNapeSprite {
	override function setBody(body:Body):Void {
		super.setBody(body);
		body.userData.data = this;
	}
}
