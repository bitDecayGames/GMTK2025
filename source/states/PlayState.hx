package states;

import flixel.FlxCamera.FlxCameraFollowStyle;
import entities.interact.Interactable;
import nape.callbacks.InteractionCallback;
import constants.CbTypes;
import nape.callbacks.InteractionType;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionListener;
import nape.phys.Material;
import constants.CGroups;
import nape.dynamics.InteractionFilter;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.phys.Body;
import nape.geom.Vec2;
import flixel.FlxObject;
import levels.ldtk.LdtkTilemap.LdtkTile;
import levels.ldtk.BDTilemap;
import flixel.math.FlxPoint;
import todo.TODO;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.CameraTransition;
import levels.ldtk.Level;
import levels.ldtk.Ldtk.LdtkProject;
import achievements.Achievements;
import entities.Player;
import entities.Flipper;
import events.gen.Event;
import events.EventBus;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.nape.FlxNapeSpace;

using states.FlxStateExt;

class PlayState extends FlxTransitionableState {
	var focusZones = new FlxTypedGroup<FlxObject>();

	var ballMass:Float = 1;
	var gravity = FlxPoint.get(0, 1000);

	var player:Player;
	var playerGroup = new FlxGroup();
	var worldTiles = new FlxGroup();
	var bgGroup = new FlxGroup();
	var midGroundGroup = new FlxGroup();
	var foregroundGroup = new FlxGroup();
	var flipperGroup = new FlxGroup();
	var activeCameraTransition:CameraTransition = null;

	var isPaused:Bool = false;
	var originalTimeScaleBeforePausing:Float;

	var transitions = new FlxTypedGroup<CameraTransition>();

	var ldtk = new LdtkProject();

	override public function create() {
		super.create();

		// FlxG.camera.pixelPerfectRender = true;

		Achievements.onAchieve.add(handleAchieve);
		EventBus.subscribe(ClickCount, (c) -> {
			QLog.notice('I got me an event about ${c.count} clicks having happened.');
		});

		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.velocityIterations = 100;
		FlxNapeSpace.positionIterations = 100;

		#if napeDebug
		FlxNapeSpace.drawDebug = true;
		#end

		// QLog.error('Example error');

		// Build out our render order
		add(bgGroup);
		add(midGroundGroup);
		add(worldTiles);
		add(playerGroup);
		add(flipperGroup);
		add(foregroundGroup);
		add(transitions);

		add(focusZones);

		#if logan
		loadLevel("Logan", "Level_7");
		#else
		loadLevel("BaseWorld", "Level_4");
		#end
	}

	function loadLevel(worldName:String, levelName:String) {
		unload();

		var level = new Level(worldName, levelName);
		// FlxNapeSpace.space.gravity.setxy(level.rawLevels[0].f_GravityX, level.rawLevels[0].f_GravityY);
		FlxNapeSpace.space.gravity.setxy(gravity.x, gravity.y);

		// FmodPlugin.playSong(level.rawLevels[0].f_Music);
		FmodPlugin.playSong(FmodSong.Fkip);

		for (bg in level.levelBgs) {
			bgGroup.add(bg);
		}

		for (fg in level.levelFgs) {
			foregroundGroup.add(fg);
		}

		var minBounds = FlxPoint.get(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		var maxBounds = FlxPoint.get(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
		for (tl in level.terrainLayers) {
			minBounds.x = Math.min(minBounds.x, tl.x);
			minBounds.y = Math.min(minBounds.y, tl.y);
			maxBounds.x = Math.max(maxBounds.x, tl.x + tl.width);
			maxBounds.y = Math.max(maxBounds.y, tl.y + tl.height);

			#if (debug || drawTerrain)
			tl.alpha = .5;
			midGroundGroup.add(tl);
			#end

			makeTileBodies(tl);
		}
		FlxG.worldBounds.set(minBounds.x, minBounds.y, maxBounds.x - minBounds.x, maxBounds.y - minBounds.y);

		player = new Player(level.spawnPoint.x, level.spawnPoint.y);
		// player.body.mass = level.rawLevels[0].f_BallMass;
		player.body.mass = ballMass;
		camera.follow(player, LOCKON, 0.1);
		playerGroup.add(player.disappearer);
		playerGroup.add(player.emitter);
		playerGroup.add(player);
		playerGroup.add(player.sparks);

		for (t in level.camTransitions) {
			transitions.add(t);
		}

		for (_ => zone in level.camZones) {
			if (zone.containsPoint(level.spawnPoint)) {
				setCameraBounds(zone);
			}
		}

		for (flipper in level.flippers) {
			flipperGroup.add(flipper);
		}

		for (popper in level.poppers) {
			foregroundGroup.add(popper.emitter);
			foregroundGroup.add(popper);
		}

		for (slingshot in level.slingshots) {
			flipperGroup.add(slingshot.emitter);
			flipperGroup.add(slingshot);
		}

		for (tunnel in level.tunnels) {
			midGroundGroup.add(tunnel);
		}

		for (focus in level.focusZones) {
			focusZones.add(focus);
		}

		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE,
			ballInteractableCallback));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE,
			sensorStartCb));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE,
			sensorOngoingCb));

		EventBus.fire(new PlayerSpawn(player.x, player.y));
	}

	function makeTileBodies(l:BDTilemap) {
		var worldBody = new Body(BodyType.STATIC);

		for (x in 0...l.widthInTiles) {
			for (y in 0...l.heightInTiles) {
				var data = l.getMetaDataAt(x, y);
				if (data != null) {
					// trace(data);
					buildTileShape(worldBody, l.x + x * l.tileWidth, l.y + y * l.tileHeight, data, l.tileWidth);
				}
			}
		}
		worldBody.setShapeFilters(new InteractionFilter(CGroups.TERRAIN, ~CGroups.CONTROL_SURFACE));
		worldBody.space = FlxNapeSpace.space;
	}

	var baseWallMat = new Material(-.7, .1);

	function buildTileShape(worldBody:Body, shapeX:Float, shapeY:Float, data:TileCollisionData, tSize:Int) {
		switch (data.type) {
			case "polygon":
				var b = new FlxObject();
				var vertices:Array<Vec2> = [];
				for (p in data.points) {
					vertices.push(new Vec2(shapeX + p[0] * tSize, shapeY + p[1] * tSize));
				}

				worldBody.shapes.add(new Polygon(vertices, baseWallMat));
			default:
		}
	}

	function unload() {
		for (t in transitions) {
			t.destroy();
		}
		transitions.clear();

		for (o in playerGroup) {
			o.destroy();
		}
		playerGroup.clear();

		for (o in bgGroup) {
			o.destroy();
		}
		bgGroup.clear();

		for (o in midGroundGroup) {
			o.destroy();
		}
		midGroundGroup.clear();

		for (o in flipperGroup) {
			o.destroy();
		}
		flipperGroup.clear();

		for (o in foregroundGroup) {
			o.destroy();
		}
		foregroundGroup.clear();

		for (o in focusZones) {
			o.destroy();
		}
		focusZones.clear();

		for (o in worldTiles) {
			o.destroy();
		}
		worldTiles.clear();

		FlxNapeSpace.space.clear();
	}

	function ballInteractableCallback(data:InteractionCallback) {
		var player:Player = cast data.int1.castBody.userData.data;
		var inter:Interactable = cast data.int2.castBody.userData.data;

		player.handleInteraction(data);
		inter.handleInteraction(data);
	}

	function sensorStartCb(data:InteractionCallback) {
		var player:Player = cast data.int1.castBody.userData.data;
		var inter:Interactable = cast data.int2.castBody.userData.data;

		inter.handleInteraction(data);
	}

	function sensorOngoingCb(data:InteractionCallback) {}

	function handleAchieve(def:AchievementDef) {
		add(def.toToast(true));
	}

	override public function update(elapsed:Float) {
		if (FlxG.keys.justPressed.P || FlxG.keys.justPressed.ESCAPE) {
			togglePause();
		}

		if (isPaused) {
			return;
		}

		super.update(elapsed);

		if (FlxG.mouse.justPressed) {
			EventBus.fire(new Click(FlxG.mouse.x, FlxG.mouse.y));
		}

		handleCameraBounds();

		// TODO.sfx('scarySound');
	}

	function togglePause() {
		isPaused = !isPaused;

		if (isPaused) {
			originalTimeScaleBeforePausing = FlxG.timeScale;
			FlxG.timeScale = 0;
		} else {
			FlxG.timeScale = originalTimeScaleBeforePausing;
		}
	}

	var tmp = FlxPoint.get();

	function handleCameraBounds() {
		var camZoneFound = false;
		for (zone in focusZones) {
			if (FlxG.overlap(zone, player)) {
				camZoneFound = true;
				if (zone.width >= camera.width && zone.height >= camera.height) {
					camera.setScrollBoundsRect(zone.x, zone.y, zone.width, zone.height);
				} else {
					camera.follow(zone);
					camera.deadzone = null;
					camera.followLerp = 0.2;
				}
				break;
			}
		}
		if (!camZoneFound) {
			camera.setScrollBounds(null, null, null, null);
			camera.follow(player);
			camera.followLerp = 0.2;
		}

		if (activeCameraTransition == null) {
			FlxG.overlap(player, transitions, (p, t) -> {
				activeCameraTransition = cast t;
			});
		} else if (!FlxG.overlap(player, activeCameraTransition)) {
			var bounds = activeCameraTransition.getRotatedBounds();
			for (dir => camZone in activeCameraTransition.camGuides) {
				switch (dir) {
					case UP:
						if (player.y < bounds.top) {
							setCameraBounds(camZone);
						}
					case DOWN:
						if (player.y > bounds.bottom) {
							setCameraBounds(camZone);
						}
					case RIGHT:
						if (player.x > bounds.right) {
							setCameraBounds(camZone);
						}
					case LEFT:
						if (player.x < bounds.left) {
							setCameraBounds(camZone);
						}
					default:
						QLog.error('camera transition area has unsupported cardinal direction ${dir}');
				}
			}
		}
	}

	public function setCameraBounds(bounds:FlxRect) {
		camera.setScrollBoundsRect(bounds.x, bounds.y, bounds.width, bounds.height);
	}

	override public function onFocusLost() {
		super.onFocusLost();
		this.handleFocusLost();
	}

	override public function onFocus() {
		super.onFocus();
		this.handleFocus();
	}
}
