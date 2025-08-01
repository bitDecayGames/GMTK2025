package entities.interact;

import flixel.util.FlxSignal;
import nape.callbacks.InteractionCallback;

class Interactable extends SelfAssigningFlxNapeSprite implements Triggerable {
	private static var degToRad = Math.PI / 180.0;
	private static var radToDeg = 180.0 / Math.PI;

	public var IID:String;

	private var on:Bool;

	public var disabled:Bool;
	public var onOffSignal:FlxTypedSignal<Bool->Void> = new FlxTypedSignal<Bool->Void>();

	public function setOn(value:Bool) {
		if (disabled)
			return;
		var different = on != value;
		on = value;
		if (different) {
			onOffSignal.dispatch(on);
		}
	}

	public function isOn():Bool {
		return on;
	}

	public function resetOnOff() {
		setOn(false);
	}

	public function handleInteraction(data:InteractionCallback) {
		// Override to provide functionality
	}
}

interface Triggerable {
	private var on:Bool;
	public var disabled:Bool;
	public var onOffSignal:FlxTypedSignal<Bool->Void>;
	public function isOn():Bool;
	public function setOn(value:Bool):Void;
	public function resetOnOff():Void;
}
