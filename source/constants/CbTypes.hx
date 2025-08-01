package constants;

import nape.callbacks.CbType;

// Callback types
class CbTypes {
	public static var CB_TERRAIN:CbType;
	public static var CB_INTERACTABLE:CbType;
	public static var CB_CONTROL_SURFACE:CbType;
	public static var CB_BALL:CbType;
	public static var CB_SENSOR:CbType;

	public static function initTypes() {
		CB_TERRAIN = new CbType();
		CB_INTERACTABLE = new CbType();
		CB_CONTROL_SURFACE = new CbType();
		CB_BALL = new CbType();
		CB_SENSOR = new CbType();
	}
}
