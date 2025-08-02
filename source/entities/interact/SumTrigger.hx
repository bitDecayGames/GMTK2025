package entities.interact;

import flixel.util.FlxTimer;
import entities.interact.Interactable.Triggerable;
import flixel.FlxObject;
import flixel.util.FlxSignal;

class SumTrigger extends FlxObject implements Triggerable {
	public var requiredSum:Int = 10;
	public var shouldResetNodesOnComplete:Bool = false;
	public var shouldDisableNodesOnComplete:Bool = false;

	public var IID:String;

	public var nodes:List<Interactable> = new List<Interactable>();

	private var on:Bool;

	public var disabled:Bool;
	public var onOffSignal:FlxTypedSignal<Bool->Void> = new FlxTypedSignal<Bool->Void>();
	public var followListensTo:Bool;

	public function new() {
		super();
	}

	private function check() {
		if (!on) {
			var sum = 0;
			for (node in nodes) {
				sum += node.numberOfTimesInteractedWith;
			}
			if (sum >= requiredSum) {
				setOn(true);
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		check();
	}

	public function setOn(value:Bool) {
		if (disabled)
			return;
		if (on != value) {
			onOnOffChanged(value);
		}
		on = value;
		if (on) {
			disabled = true;
			FlxTimer.wait(1, () -> {
				if (shouldResetNodesOnComplete) {
					for (node in nodes) {
						node.resetOnOff();
					}
				}
				if (shouldDisableNodesOnComplete) {
					for (node in nodes) {
						node.disabled = true;
					}
				}
			});
		}
	}

	public function isOn():Bool {
		return on;
	}

	public function resetOnOff() {
		on = false;
		disabled = false;
	}

	function onOnOffChanged(value:Bool) {
		onOffSignal.dispatch(on);
	}
}
