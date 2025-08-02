package entities.interact;

import flixel.util.FlxTimer;
import entities.interact.Interactable.Triggerable;
import flixel.FlxObject;
import flixel.util.FlxSignal;

class CollectionTrigger extends FlxObject implements Triggerable {
	public var onlyOneNodeRequired:Bool = false;
	public var shouldResetNodesOnComplete:Bool = false;
	public var shouldDisableNodesOnComplete:Bool = false;

	public var IID:String;

	private var nodes:List<Triggerable> = new List<Triggerable>();

	private var on:Bool;

	public var disabled:Bool;
	public var onOffSignal:FlxTypedSignal<Bool->Void> = new FlxTypedSignal<Bool->Void>();
	public var followListensTo:Bool;
	public var numberOfTimesTriggered:Int = 0;

	public function new() {
		super();
	}

	private function check(v:Bool) {
		if (v) {
			// if only one is required, we are good already
			if (!onlyOneNodeRequired) {
				// if all of them are required, we must check the rest
				for (node in nodes) {
					if (!node.isOn()) {
						return;
					}
				}
			}
			// all nodes are positive, dispatch signal
			setOn(true);
		}
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
			trace('Num: ${numberOfTimesTriggered}');
			onOffSignal.dispatch(on);
			FlxTimer.wait(1, () -> {
				if (shouldResetNodesOnComplete) {
					for (node in nodes) {
						node.resetOnOff();
					}
					resetOnOff();
				}
				if (shouldDisableNodesOnComplete) {
					for (node in nodes) {
						node.disabled = true;
					}
					disabled = true;
				}
			});
		}
	}

	public function isOn():Bool {
		return on;
	}

	public function resetOnOff() {
		setOn(false);
	}

	public function add(node:Triggerable) {
		nodes.push(node);
		node.onOffSignal.add(check);
	}

	public function remove(node:Triggerable) {
		nodes.remove(node);
		node.onOffSignal.remove(check);
	}

	function onOnOffChanged(value:Bool) {}
}
