package levels.ldtk;

import entities.CameraTransition;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import levels.ldtk.Ldtk.LdtkProject;

using levels.ldtk.LdtkUtils;

/**
 * The middle layer between LDTK project and game code. This class
 * should do all of the major parsing of project data into flixel
 * types and basic game objects.
**/
class Level {
	public static var project = new LdtkProject();

	/**
	 * World id that this level was loaded from
	**/
	public var worldID:String;

	/**
	 * The raw level from the project. Available to get any needed
	 * one-off values out of the level for special use-cases
	**/
	public var raw:Ldtk.Ldtk_Level;

	// This is the painted image for the level itself
	public var terrainRender:FlxSprite;

	public var terrainLayer:BDTilemap;
	public var spawnPoint:FlxPoint = FlxPoint.get();

	public var camZones:Map<String, FlxRect>;
	public var camTransitions:Array<CameraTransition>;

	public function new(worldNameOrIID:String, nameOrIID:String) {
		this.worldID = worldNameOrIID;
		var world = project.getWorld(worldNameOrIID);
		raw = world.getLevel(nameOrIID);
		terrainLayer = new BDTilemap();
		terrainLayer.loadLdtk(raw.l_Terrain);

		if (raw.l_Objects.all_Spawn.length == 0) {
			// TODO: probably don't want to throw here as spawns are not the same in this game
			throw('no spawn found in level ${nameOrIID}');
		}
		var sp = raw.l_Objects.all_Spawn[0];
		spawnPoint.set(sp.pixelX, sp.pixelY);

		// raw.identifier

		parseCameraZones(raw.l_Objects.all_CameraZone);
		parseCameraTransitions(raw.l_Objects.all_CameraTransition);
	}

	function parseCameraZones(zoneDefs:Array<Ldtk.Entity_CameraZone>) {
		camZones = new Map<String, FlxRect>();
		for (z in zoneDefs) {
			camZones.set(z.iid, FlxRect.get(z.pixelX, z.pixelY, z.width, z.height));
		}
	}

	function parseCameraTransitions(areaDefs:Array<Ldtk.Entity_CameraTransition>) {
		camTransitions = new Array<CameraTransition>();
		for (def in areaDefs) {
			var transArea = FlxRect.get(def.pixelX, def.pixelY, def.width, def.height);
			var camTrigger = new CameraTransition(transArea);
			for (i in 0...def.f_Directions.length) {
				camTrigger.addGuideTrigger(def.f_Directions[i].toCardinal(), camZones.get(def.f_Zones[i].entityIid));
			}
			camTransitions.push(camTrigger);
		}
	}
}
