package entities.interact;

class Light extends Interactable {
	private var lightOnPath:String;
	private var lightOffPath:String;

	public function lightOn() {
		animation.play(lightOnPath);
	}

	public function lightOff() {
		animation.play(lightOffPath);
	}

	override function onOnOffChanged(value:Bool) {
		if (value) {
			lightOn();
		} else {
			lightOff();
		}
		super.onOnOffChanged(value);
	}
}
