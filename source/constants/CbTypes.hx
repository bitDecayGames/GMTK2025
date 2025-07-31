package constants;

import nape.callbacks.CbType;

// Callback types
class CbTypes {
	public static var CB_TERRAIN:CbType;
	public static var CB_BALL:CbType;

	public static function initTypes() {
		CB_TERRAIN = new CbType();
		CB_BALL = new CbType();
	}
}
