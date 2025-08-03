package entities.interact;

import flixel.util.FlxTimer;
import flixel.FlxObject;

class LightShow extends FlxObject {
	public var showType:LightShowEnum = SEQUENTIAL;
	public var stepSpeed:Float = 0.2;
	public var numOfCycles:Int = 5;
	public var IID:String;
	public var nodes:Array<Light> = new Array<Light>();

	private var started:Bool;

	public function new() {
		super();
	}

	public function start(v:Bool) {
		trace('START LIGHT SHOW: ${showType}');
		if (!started) {
			started = true;
			switch (showType) {
				case SEQUENTIAL:
					sequential();
				case ALTERNATE:
					alternate();
				case BLINK:
					blink();
			}
		}
	}

	function sequential() {
		var totalCycles = numOfCycles * nodes.length;
		FlxTimer.loop(stepSpeed, (loopNum) -> {
			var index = loopNum % nodes.length;
			for (i in 0...nodes.length) {
				var light = nodes[i];
				if (i == index) {
					light.lightOn();
				} else {
					light.lightOff();
				}
			}
			if (loopNum == totalCycles) {
				resetLights();
			}
		}, totalCycles);
	}

	function alternate() {
		var on:Bool = false;
		FlxTimer.loop(stepSpeed, (loopNum) -> {
			for (i in 0...nodes.length) {
				var light = nodes[i];
				if (on) {
					if (i % 2 == 0) {
						light.lightOff();
					} else {
						light.lightOn();
					}
				} else {
					if (i % 2 == 0) {
						light.lightOn();
					} else {
						light.lightOff();
					}
				}
			}
			on = !on;
			if (loopNum == numOfCycles) {
				resetLights();
			}
		}, numOfCycles);
	}

	function blink() {
		var on:Bool = false;
		FlxTimer.loop(stepSpeed, (loopNum) -> {
			for (light in nodes) {
				if (on) {
					light.lightOff();
				} else {
					light.lightOn();
				}
			}
			on = !on;
			if (loopNum == numOfCycles) {
				resetLights();
			}
		}, numOfCycles);
	}

	function resetLights() {
		started = false;
		for (light in nodes) {
			if (light.isOn()) {
				light.lightOn();
			} else {
				light.lightOff();
			}
		}
	}
}
