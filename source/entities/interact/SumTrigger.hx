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
	public var otherNodes:List<Triggerable> = new List<Triggerable>();

	private var on:Bool;

	public var disabled:Bool;
	public var onOffSignal:FlxTypedSignal<Bool->Void> = new FlxTypedSignal<Bool->Void>();
	public var followListensTo:Bool;
	public var numberOfTimesTriggered:Int = 0;

	public function new() {
		super();
	}

	private function check() {
		if (!on) {
			var sum = 0;
			for (node in nodes) {
				sum += node.numberOfTimesInteractedWith;
			}
			for (node in otherNodes) {
				sum += node.numberOfTimesTriggered;
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
			numberOfTimesTriggered += 1;
			disabled = true;
			FlxTimer.wait(1, () -> {
				if (shouldResetNodesOnComplete) {
					for (node in nodes) {
						node.resetOnOff();
					}
					for (node in otherNodes) {
						node.resetOnOff();
					}
				}
				if (shouldDisableNodesOnComplete) {
					for (node in nodes) {
						node.disabled = true;
					}
					for (node in otherNodes) {
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
		onOffSignal.dispatch(value);
	}
}
