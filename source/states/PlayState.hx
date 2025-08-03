package states;

import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
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
import entities.interact.Tunnel;
import events.gen.Event;
import events.EventBus;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import addons.BDFlxNapeSpace;
import ui.HudMessage;

using states.FlxStateExt;

class PlayState extends FlxTransitionableState {
	var timeScale:Float = 1;
	var cameraZones:Array<FlxRect> = [];
	var activeCamBounds:FlxRect = null;
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
	var lastTunnelExit:Tunnel = null;
	var originalTimeScaleBeforePausing:Float;

	var transitions = new FlxTypedGroup<CameraTransition>();
	var level:Level;

	var ldtk = new LdtkProject();

	override public function create() {
		super.create();

		// FlxG.camera.pixelPerfectRender = true;

		Achievements.onAchieve.add(handleAchieve);
		EventBus.subscribe(ClickCount, (c) -> {
			QLog.notice('I got me an event about ${c.count} clicks having happened.');
		});

		CbTypes.initTypes();
		BDFlxNapeSpace.init();
		BDFlxNapeSpace.velocityIterations = 100;
		BDFlxNapeSpace.positionIterations = 100;

		#if napeDebug
		BDFlxNapeSpace.drawDebug = true;
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

		#if title
		loadLevel("Title", "");
		#elseif logan
		loadLevel("Logan", "");
		#else
		loadLevel("BaseWorld", "Level_4");
		#end
	}

	function loadLevel(worldName:String, levelName:String) {
		unload();

		level = new Level(worldName, levelName);
		// BDFlxNapeSpace.space.gravity.setxy(level.rawLevels[0].f_GravityX, level.rawLevels[0].f_GravityY);
		BDFlxNapeSpace.space.gravity.setxy(gravity.x, gravity.y);

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
			cameraZones.push(zone);
		}

		for (flipper in level.flippers) {
			flipperGroup.add(flipper);
		}

		for (popper in level.poppers) {
			foregroundGroup.add(popper.emitter);
			foregroundGroup.add(popper);
		}

		for (popperSmall in level.poppersSmall) {
			foregroundGroup.add(popperSmall.emitter);
			foregroundGroup.add(popperSmall);
		}

		for (slingshot in level.slingshots) {
			flipperGroup.add(slingshot.emitter);
			flipperGroup.add(slingshot);
		}

		for (interactable in level.interactables) {
			if (interactable.isBackground) {
				midGroundGroup.add(interactable);
			} else {
				foregroundGroup.add(interactable);
			}
		}

		for (kicker in level.kickers) {
			midGroundGroup.add(kicker);
		}

		for (summer in level.summers) {
			midGroundGroup.add(summer);
		}

		for (tunnel in level.tunnels) {
			midGroundGroup.add(tunnel);
		}

		for (focus in level.focusZones) {
			focusZones.add(focus);
		}

		handleCameraBounds(true);
		BDFlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, CbTypes.CB_BALL, CbTypes.CB_TERRAIN,
			ballTerrainHandler));
		BDFlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, CbTypes.CB_BALL, CbTypes.CB_CONTROL_SURFACE,
			ballTerrainHandler));
		BDFlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE,
			ballInteractableCallback));
		BDFlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE,
			sensorStartCb));
		BDFlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE,
			sensorOngoingCb));
		BDFlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.SENSOR, CbTypes.CB_BALL, CbTypes.CB_INTERACTABLE, sensorEndCb));

		EventBus.fire(new PlayerSpawn(player.x, player.y));

		// Set up tunnel exit tracking
		Tunnel.onTunnelExit = (exitTunnel) -> {
			lastTunnelExit = exitTunnel;
			HudMessage.show("You can do it!");
		};

		// Show welcome message
		HudMessage.show("Let's GOOOOOOO");
	}

	function getClosestTunnelToSpawn():Tunnel {
		var closest:Tunnel = null;
		var closestDist:Float = Math.POSITIVE_INFINITY;

		for (tunnel in level.tunnels) {
			var dist = Math.sqrt(Math.pow(tunnel.x - level.spawnPoint.x, 2) + Math.pow(tunnel.y - level.spawnPoint.y, 2));
			if (dist < closestDist) {
				closest = tunnel;
				closestDist = dist;
			}
		}

		return closest;
	}

	function respawnToTunnel() {
		var targetTunnel = lastTunnelExit != null ? lastTunnelExit : getClosestTunnelToSpawn();

		if (targetTunnel == null) {
			// Fallback to full reset if no tunnels
			FlxG.resetState();
			return;
		}

		// Use tunnel's teleportation with respawn flag
		Tunnel.teleportTo(player, targetTunnel, true);
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
		worldBody.cbTypes.add(CbTypes.CB_TERRAIN);
		worldBody.space = BDFlxNapeSpace.space;
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

		cameraZones = [];

		BDFlxNapeSpace.space.clear();
	}

	function ballTerrainHandler(data:InteractionCallback) {
		var impulse = 0.0;
		for (a in data.arbiters) {
			impulse += a.totalImpulse(data.int1.castBody).length;
		}

		QLog.notice('touch @ $impulse');

		var hitSound = FmodPlugin.playSFXWithRef(FmodSFX.BallTerrain2);
		FmodManager.SetEventParameterOnSound(hitSound, "volume", impulse);
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

	function sensorEndCb(data:InteractionCallback) {
		var player:Player = cast data.int1.castBody.userData.data;
		var inter:Interactable = cast data.int2.castBody.userData.data;

		inter.handleInteractionEnd(data);
	}

	function handleAchieve(def:AchievementDef) {
		add(def.toToast(true));
	}

	override public function update(elapsed:Float) {
		if (FlxG.keys.justPressed.P || FlxG.keys.justPressed.ESCAPE) {
			togglePause();
		}

		if (FlxG.keys.justPressed.R) {
			respawnToTunnel();
			return;
		}

		if (isPaused) {
			return;
		}

		/* Cheese to make the flipper sound exactly once all the time*/
		if (FlxG.keys.anyJustPressed([FlxKey.Z, FlxKey.X, FlxKey.M])) {
			FmodPlugin.playSFX(FmodSFX.FlipperStart2);
		}

		BDFlxNapeSpace.timeScale = timeScale;
		super.update(elapsed);

		if (FlxG.mouse.justPressed) {
			EventBus.fire(new Click(FlxG.mouse.x, FlxG.mouse.y));
		}

		handleCameraBounds();
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

	function handleCameraBounds(instant:Bool = false) {
		if (activeCamBounds != null && !activeCamBounds.containsPoint(player.getMidpoint(tmp))) {
			transitionCamera(null, instant);
		}

		if (activeCamBounds == null) {
			for (zone in cameraZones) {
				if (zone.containsPoint(player.getMidpoint(tmp))) {
					transitionCamera(zone, instant);
				}
			}
		}
	}

	public function setCameraBounds(bounds:FlxRect) {
		activeCamBounds = bounds;
		if (bounds == null) {
			camera.setScrollBounds(null, null, null, null);
		} else {
			camera.setScrollBoundsRect(bounds.x, bounds.y, bounds.width, bounds.height);
		}
	}

	function transitionCamera(area:FlxRect, instant:Bool = false) {
		activeCamBounds = area;
		if (instant) {
			setCameraBounds(area);
			return;
		}

		FmodManager.SetEventParameterOnSong("highpass", 1);
		FlxTween.tween(this, {"timeScale": 0.01}, 0.3, {
			ease: FlxEase.cubeOut,
			onComplete: (t) -> {
				if (area != null) {
					var destPoint = findCameraDest(camera, area);
					camera.follow(null);
					FlxTween.tween(camera, {
						"scroll.x": destPoint.x,
						"scroll.y": destPoint.y
					}, 1, {
						ease: FlxEase.cubeOut,
						onComplete: (t) -> {
							setCameraBounds(area);
							camera.follow(player, LOCKON, 0.1);
						}
					});
					destPoint.put();
				} else {
					setCameraBounds(null);
				}
				FlxTimer.wait(1, () -> {
					FmodManager.SetEventParameterOnSong("highpass", 0);
					FlxTween.tween(this, {"timeScale": 1}, 0.3, {
						ease: FlxEase.cubeOut,
					});
				});
			}
		});
	}

	function findCameraDest(camera:FlxCamera, zone:FlxRect):FlxPoint {
		var current = camera.scroll.copyTo(FlxPoint.get());
		// keep point within bounds
		// current.x = FlxMath.bound(current.x, zone.left - camera.viewMarginLeft, zone.right - camera.viewMarginRight);
		// current.y = FlxMath.bound(current.y, zone.top- camera.viewMarginTop, zone.bottom - camera.viewMarginBottom);
		current.x = FlxMath.bound(current.x, zone.left - camera.viewMarginLeft, zone.right - camera.viewMarginRight);
		current.y = FlxMath.bound(current.y, zone.top - camera.viewMarginTop, zone.bottom - camera.viewMarginBottom);
		return current;
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
