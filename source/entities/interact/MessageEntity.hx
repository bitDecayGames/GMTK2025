package entities.interact;

import ui.HudMessage;
import flixel.util.FlxSignal.FlxTypedSignal;
import entities.interact.Interactable.Triggerable;
import flixel.util.FlxTimer;
import flixel.FlxObject;

class MessageEntity extends FlxObject implements Triggerable {
	public var IID:String;

	public var secondsUntilHidden:Float = 5;
	public var content:String = "";

	private var on:Bool;

	public var disabled:Bool;
	public var followListensTo:Bool;
	public var onOffSignal:FlxTypedSignal<Bool->Void>;

	public function new() {
		super();
	}

	public function isOn():Bool {
		return on;
	}

	public function setOn(value:Bool):Void {
		if (disabled)
			return;
		if (value != on) {
			onOnOffChanged(value);
		}
		on = value;
		if (on) {
			disabled = true;
			// this automatically hides it after the number of seconds
			HudMessage.show(content, secondsUntilHidden);
			FlxTimer.wait(secondsUntilHidden, () -> {
				on = false;
			});
		}
	}

	private function onOnOffChanged(value:Bool):Void {
		onOffSignal.dispatch(value);
	}

	public function resetOnOff():Void {
		on = false;
		disabled = false;
	}
}
