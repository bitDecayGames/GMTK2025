package levels.ldtk;

import entities.Flipper;
import flixel.FlxSprite;
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
	public var rawLevels:Array<Ldtk.Ldtk_Level> = [];

	// This is the painted image for the level itself
	public var terrainRender:Array<FlxSprite> = [];

	public var terrainLayers:Array<BDTilemap> = [];
	public var spawnPoint:FlxPoint = FlxPoint.get();

	public var camZones:Map<String, FlxRect>;
	public var camTransitions:Array<CameraTransition>;

	public var flippers:Array<Flipper> = [];

	public function new(worldNameOrIID:String, nameOrIID:String) {
		this.worldID = worldNameOrIID;
		var world:Ldtk.Ldtk_World = null;
		for (w in project.worlds) {
			if (w.identifier == worldNameOrIID || w.iid == worldNameOrIID) {
				world = w;
			}
		}
		if (world == null) {
			// TODO: how to handle?
			throw('no world with name/IID: $worldNameOrIID');
		}

		// We are loading each world as a full "level" in terms of gameplay.
		// So we load every level in the world file and stitch them all together
		for (raw in world.levels) {
			rawLevels.push(raw);
			var terrainLayer = new BDTilemap();
			terrainLayer.loadLdtk(raw.l_Terrain);
			terrainLayer.setPosition(raw.worldX, raw.worldY);
			terrainLayers.push(terrainLayer);

			if (raw.l_Objects.all_Spawn.length > 0) {
				var sp = raw.l_Objects.all_Spawn[0];
				spawnPoint.set(sp.worldPixelX, sp.worldPixelY);
			}

			parseCameraZones(raw.l_Objects.all_CameraZone);
			parseCameraTransitions(raw.l_Objects.all_CameraTransition);
			parseFlippers(raw.l_Objects.all_FlipperLeft, raw.l_Objects.all_FlipperRight);
		}
	}

	function parseCameraZones(zoneDefs:Array<Ldtk.Entity_CameraZone>) {
		camZones = new Map<String, FlxRect>();
		for (z in zoneDefs) {
			camZones.set(z.iid, FlxRect.get(z.worldPixelX, z.worldPixelY, z.width, z.height));
		}
	}

	function parseCameraTransitions(areaDefs:Array<Ldtk.Entity_CameraTransition>) {
		camTransitions = new Array<CameraTransition>();
		for (def in areaDefs) {
			var transArea = FlxRect.get(def.worldPixelX, def.worldPixelY, def.width, def.height);
			var camTrigger = new CameraTransition(transArea);
			for (i in 0...def.f_Directions.length) {
				camTrigger.addGuideTrigger(def.f_Directions[i].toCardinal(), camZones.get(def.f_Zones[i].entityIid));
			}
			camTransitions.push(camTrigger);
		}
	}

	function parseFlippers(leftDefs:Array<Ldtk.Entity_FlipperLeft>, rightDefs:Array<Ldtk.Entity_FlipperRight>) {
		for (ld in leftDefs) {
			flippers.push(new Flipper(LEFT, ld.worldPixelX, ld.worldPixelY, 80, ld.f_ForceFactor, 13, 8, 30, -50));
		}
		for (rd in rightDefs) {
			flippers.push(new Flipper(RIGHT, rd.worldPixelX, rd.worldPixelY, 80, rd.f_ForceFactor, 13, 8, 150, 230));
		}
	}
}
