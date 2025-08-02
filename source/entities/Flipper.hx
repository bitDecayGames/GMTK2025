package entities;

import nape.callbacks.PreFlag;
import nape.callbacks.PreCallback;
import constants.CbTypes;
import nape.callbacks.InteractionType;
import nape.callbacks.CbEvent;
import nape.callbacks.PreListener;
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
import nape.phys.Body;
import nape.phys.BodyType;

class Flipper extends SelfAssigningFlxNapeSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/flipper.json");

	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	private static var loggedMessages = new Map<String, Bool>();

	var ctrlGroup:ControlGroup;

	var restAngle:Float;
	var flipAngle:Float;

	var flipDirection:FlipDir;

	var jointMin:Float;
	var jointMax:Float;
	var angleJoint:AngleJoint;
	var pivotJoint:PivotJoint;

	var leverArmScale = 2.0;
	var activateJoint:DistanceJoint;
	var restingJoint:DistanceJoint;

	var flipperStrength:Float = 10;

	var flipperMaterial = new Material(-0.2, .01, .01, 1, 0);

	private var dir:Float = 0;

	// public function new(group:ControlGroup, X:Float, Y:Float, width:Float, strength:Float, bigRad:Float, smallRad:Float, restAng:Float, flipAng:Float,
	public function new(group:ControlGroup, X:Float, Y:Float, width:Float, bigRad:Float, smallRad:Float, restAng:Float, flipAng:Float, fmass:Float) {
		super();
		Aseprite.loadAllAnimations(this, AssetPaths.flipper__json);
		animation.play(anims.flipper_1_aseprite);
		origin.set(12, 24);
		this.ctrlGroup = group;
		this.width = width;
		this.height = bigRad;
		flipperStrength *= 10000;

		if (flipAng - restAng < 0) {
			flipDirection = CCW;
			flipAngle = Math.min(flipAng, restAng);
			restAngle = Math.max(flipAng, restAng);
		} else {
			flipDirection = CW;
			flipAngle = Math.max(flipAng, restAng);
			restAngle = Math.min(flipAng, restAng);
		}
		flipAngle *= degToRad;
		restAngle *= degToRad;
		var w = width;

		var body = new Body(BodyType.DYNAMIC);
		body.position.set(Vec2.get(X, Y));
		body.shapes.add(new Circle(bigRad, Vec2.weak(0, 0), flipperMaterial));
		body.shapes.add(new Circle(smallRad, Vec2.weak(w - bigRad - smallRad, 0), flipperMaterial));
		body.shapes.add(new Polygon([
			Vec2.weak(0, -bigRad),
			Vec2.weak(w - bigRad - smallRad, -smallRad),
			Vec2.weak(w - bigRad - smallRad, smallRad),
			Vec2.weak(0, bigRad)
		], flipperMaterial));
		body.mass = fmass;
		body.isBullet = true;

		body.setShapeFilters(new InteractionFilter(CGroups.CONTROL_SURFACE, CGroups.BALL));

		pivotJoint = new PivotJoint(body, FlxNapeSpace.space.world, Vec2.get(), body.localPointToWorld(Vec2.get()));
		pivotJoint.active = true; // Keep pivot to anchor flipper
		pivotJoint.stiff = true;
		pivotJoint.space = FlxNapeSpace.space;

		jointMin = Math.min(restAngle, flipAngle);
		jointMax = Math.max(restAngle, flipAngle);
		angleJoint = new AngleJoint(FlxNapeSpace.space.world, body, jointMin, jointMax);
		angleJoint.active = true; // Re-enable angle joint
		angleJoint.stiff = true;
		angleJoint.space = FlxNapeSpace.space;

		var forceLocalPos = Vec2.get(w - bigRad - smallRad, 0).muleq(leverArmScale);
		var activeJointWorldPos = body.localPointToWorld(forceLocalPos.copy().rotate(flipAngle));
		activateJoint = new DistanceJoint(body, FlxNapeSpace.space.world, forceLocalPos, activeJointWorldPos, 0, 0);
		activateJoint.active = false; // Start inactive
		activateJoint.stiff = false;
		activateJoint.space = FlxNapeSpace.space;
		activateJoint.damping = 0;
		activateJoint.maxForce = flipperStrength * fmass;

		// Calculate resting joint position AFTER body rotation is set correctly
		var restingJointWorldPos = body.localPointToWorld(forceLocalPos.copy().rotate(restAngle));
		restingJoint = new DistanceJoint(body, FlxNapeSpace.space.world, forceLocalPos, restingJointWorldPos, 0, 0);
		restingJoint.active = false; // Will re-enable after rotation fix
		restingJoint.stiff = false;
		restingJoint.space = FlxNapeSpace.space;
		restingJoint.damping = 0;
		restingJoint.maxForce = flipperStrength * fmass;

		addPremadeBody(body);

		// Set rotation after body is added to physics space
		body.rotation = restAngle;

		trace('Flipper initialized - rotation: ${body.rotation}, restAngle: ${restAngle}, min: ${jointMin}, max: ${jointMax}');

		body.cbTypes.add(CbTypes.CB_CONTROL_SURFACE);

		// CbEvent.BEGIN, InteractionType.COLLISION, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE,
		var listener = new PreListener(InteractionType.COLLISION, CbTypes.CB_BALL, CbTypes.CB_CONTROL_SURFACE, testPre, 0, false);
		FlxNapeSpace.space.listeners.add(listener);
		trace('Flipper collision listener added for body type: ${body.type}');

		// Force lockout to 0 to fix CW flipper initialization issue
		lockout = 0;

		// Ensure flipper starts at correct rotation within joint range
		body.rotation = restAngle;
		if (flipDirection == CW) {
			trace('LOG INFO: Constructor set rotation to: ${body.rotation}, restAngle: ${restAngle}');
		}

		// Only recalculate resting joint for CW flippers (CCW flippers work fine with original calculation)
		if (flipDirection == CW) {
			var forceLocalPos2 = Vec2.get(width - height - height / 2, 0).muleq(leverArmScale);
			var correctedRestingPos = body.localPointToWorld(forceLocalPos2.copy().rotate(restAngle));
			restingJoint.anchor2 = correctedRestingPos;
		}
		restingJoint.active = true; // Enable for all flippers
	}

	function testPre(cb:PreCallback):PreFlag {
		if (cb.int2.castBody != body) {
			return null;
		}
		// Add small tolerance for floating point precision issues
		var tolerance = 0.001;
		if (body.rotation > (jointMax + tolerance) || body.rotation < (jointMin - tolerance)) {
			trace('Flipper collision blocked - rotation: ${body.rotation}, min: ${jointMin}, max: ${jointMax}');
			return PreFlag.IGNORE_ONCE;
		} else {
			trace('Flipper collision accepted - rotation: ${body.rotation}, min: ${jointMin}, max: ${jointMax}');
			return PreFlag.ACCEPT_ONCE;
		}
	}

	override public function update(delta:Float) {
		logInfo('LOG INFO: update start');
		if (FlxG.keys.justPressed.Z || FlxG.keys.justPressed.M) {
			if (flipDirection == CW) {
				trace('LOG INFO: Flipper key pressed!');
			}
		}
		var activated = switch ctrlGroup {
			case LEFT:
				FlxG.keys.pressed.Z;
			case RIGHT:
				FlxG.keys.pressed.M;
			default:
				FlxG.keys.pressed.SPACE;
		};
		if (activated) {
			flip(delta);
		} else {
			rest(delta);
		}
		super.update(delta);
	}

	override function setBody(body:Body) {
		super.setBody(body);
		body.userData.data = this;
	}

	// Some jank to help us stop moving the flipper once it's at its limit
	var lockout = 0;

	function logInfo(msg:String) {
		if (loggedMessages.exists(msg))
			return; // Only log each message once
		if (flipDirection != CW)
			return; // Only log for clockwise flippers
		loggedMessages.set(msg, true);

		trace('LOG INFO: ${msg} - lockout: ${lockout}, rotation: ${body.rotation}, jointMin: ${jointMin}, jointMax: ${jointMax}');
	}

	public function flip(delta:Float) {
		logInfo('before button press');

		trace('flip() called - lockout: ${lockout}, rotation: ${body.rotation}');
		if (lockout == 1) {
			return;
		} else {
			lockout = 0;
		}

		if (flipDirection == CCW && body.rotation <= jointMin) {
			body.rotation = jointMin;
			makeStatic();
			lockout = 1;
			return;
		} else if (flipDirection == CW && body.rotation >= jointMax) {
			body.rotation = jointMax;
			makeStatic();
			lockout = 1;
			return;
		} else {
			makeDynamic();
			angleJoint.jointMax = jointMax;
			angleJoint.jointMin = jointMin;
		}

		activateJoint.active = true;
		restingJoint.active = false;

		logInfo('after button press');
	}

	public function rest(delta:Float) {
		logInfo('rest start');
		if (flipDirection == CW) {
			trace('CW rest() called - lockout: ${lockout}, rotation: ${body.rotation}');
		}
		if (lockout == -1) {
			logInfo('rest early return lockout -1');
			return;
		} else {
			lockout = 0;
		}

		if (flipDirection == CCW && body.rotation >= jointMax) {
			logInfo('rest CCW at jointMax making static');
			body.rotation = jointMax;
			makeStatic();
			lockout = -1;
			return;
		} else if (flipDirection == CW && body.rotation <= jointMin) {
			logInfo('rest CW at jointMin making static');
			body.rotation = jointMin;
			makeStatic();
			lockout = -1;
			return;
		} else {
			logInfo('rest normal operation making dynamic');
			makeDynamic();
			angleJoint.jointMax = jointMax;
			angleJoint.jointMin = jointMin;
		}

		activateJoint.active = false;
		restingJoint.active = true;
	}

	function makeStatic() {
		trace('Making flipper static');
		pivotJoint.active = false;
		angleJoint.active = false;
		activateJoint.active = false;
		restingJoint.active = false;
		body.type = BodyType.STATIC;
		body.setShapeMaterials(flipperMaterial);
	}

	function makeDynamic() {
		trace('Making flipper dynamic');
		pivotJoint.active = true;
		angleJoint.active = true;
		body.type = BodyType.DYNAMIC;
		body.setShapeMaterials(flipperMaterial);
	}
}

enum ControlGroup {
	LEFT;
	RIGHT;
}

enum FlipDir {
	CW;
	CCW;
}
