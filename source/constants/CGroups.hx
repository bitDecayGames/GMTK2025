package constants;

// CGroups are collision group flags
class CGroups {
	public static inline var TERRAIN:Int = 0x1 << 0;

	public static inline var BALL:Int = 0x1 << 1;
	public static inline var CONTROL_SURFACE:Int = 0x1 << 2;
	public static inline var INTERACTABLE:Int = 0x1 << 3;
	public static inline var SENSOR:Int = 0x1 << 4;

	public static inline var OTHER_SENSOR:Int = 0x1 << 31;

	public static inline var ALL:Int = ~(0);
}
