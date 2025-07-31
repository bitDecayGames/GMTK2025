package states;

import echo.Body;
import echo.math.Vector2;
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

using echo.FlxEcho;
using states.FlxStateExt;

class PlayState extends FlxTransitionableState {
	var player:Player;
	var playerGroup = new FlxGroup();
	var worldTiles = new FlxGroup();
	var midGroundGroup = new FlxGroup();
	var flipperGroup = new FlxGroup();
	var activeCameraTransition:CameraTransition = null;

	var gravity = FlxPoint.get(0, 16 * 9);

	var transitions = new FlxTypedGroup<CameraTransition>();

	var ldtk = new LdtkProject();

	override public function create() {
		super.create();

		// FlxG.camera.pixelPerfectRender = true;

		Achievements.onAchieve.add(handleAchieve);
		EventBus.subscribe(ClickCount, (c) -> {
			QLog.notice('I got me an event about ${c.count} clicks having happened.');
		});

		FlxEcho.init({
			width: FlxG.width,
			height: FlxG.height,
			gravity_x: gravity.x,
			gravity_y: gravity.y,
			// iterations: 16,
		});

		FlxEcho.add_group_bodies(worldTiles);
		FlxEcho.add_group_bodies(playerGroup);

		// QLog.error('Example error');

		// Build out our render order
		add(midGroundGroup);
		add(worldTiles);
		add(playerGroup);
		add(flipperGroup);
		add(transitions);

		loadLevel("BaseWorld", "Level_0");

		var f = new Flipper(200, 410);
		f.add_to_group(flipperGroup);

		FlxEcho.draw_debug = true;
		// FlxEcho.debug_drawer.draw_quadtree = true;
	}

	// override function draw() {
	// 	super.draw();
	// 	FlxEcho.instance.draw();
	// }

	function loadLevel(world:String, level:String) {
		unload();

		var level = new Level(world, level);
		FmodPlugin.playSong(level.rawLevels[0].f_Music);
		var minBounds = FlxPoint.get(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
		var maxBounds = FlxPoint.get(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
		for (tl in level.terrainLayers) {
			minBounds.x = Math.min(minBounds.x, tl.x);
			minBounds.y = Math.min(minBounds.y, tl.y);
			maxBounds.x = Math.max(maxBounds.x, tl.x + tl.width);
			maxBounds.y = Math.max(maxBounds.y, tl.y + tl.height);
			midGroundGroup.add(tl);

			makeEchoTiles(tl);
		}

		player = new Player(level.spawnPoint.x, level.spawnPoint.y);
		camera.follow(player);
		player.add_to_group(playerGroup);

		for (t in level.camTransitions) {
			transitions.add(t);
		}

		for (_ => zone in level.camZones) {
			if (zone.containsPoint(level.spawnPoint)) {
				setCameraBounds(zone);
			}
		}

		FlxEcho.instance.world.set(minBounds.x, minBounds.y, maxBounds.x - minBounds.x, maxBounds.y - minBounds.y);

		FlxEcho.listen(worldTiles, playerGroup, {
			separate: true,
			enter: (a, b, o) -> {
				trace('something happened');
				// Collide.ignoreCollisionsOfBColor(a, b);
			},
			exit: (a, b) -> {
				// Collide.restoreCollisions(a, b);
			}
		});
		FlxEcho.listen(flipperGroup, playerGroup, {
			separate: true,
			enter: (a, b, o) -> {
				// Collide.ignoreCollisionsOfBColor(a, b);
			},
			exit: (a, b) -> {
				// Collide.restoreCollisions(a, b);
			}
		});

		EventBus.fire(new PlayerSpawn(player.x, player.y));
	}

	function makeEchoTiles(l:BDTilemap) {
		for (x in 0...l.widthInTiles) {
			for (y in 0...l.heightInTiles) {
				var data = l.getMetaDataAt(x, y);
				if (data != null) {
					trace(data);
					var body = buildTile(data, l.tileWidth);
					if (body != null) {
						body.set_position(l.x + x * l.tileWidth, l.y + y * l.tileHeight);
					}
				}
			}
		}
	}

	function buildTile(data:TileCollisionData, tSize:Int):Body {
		switch (data.type) {
			case "polygon":
				// TODO: put these all on a 'world' body or something
				var b = new FlxObject();
				var vertices:Array<Vector2> = [];
				for (p in data.points) {
					vertices.push(new Vector2(p[0] * tSize, p[1] * tSize));
					// vertices.push(new Vector2(p[0] * tSize, p[1] * tSize));
				}
				var body = FlxEcho.add_body(b, {
					kinematic: true,
					shape: {
						type: POLYGON,
						vertices: vertices
					}
				});
				b.add_to_group(worldTiles);
				return body;
			default:
				return null;
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

		for (o in midGroundGroup) {
			o.destroy();
		}
		midGroundGroup.clear();

		for (o in worldTiles) {
			o.destroy();
		}
		worldTiles.clear();

		FlxEcho.clear();
	}

	function handleAchieve(def:AchievementDef) {
		add(def.toToast(true));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.mouse.justPressed) {
			EventBus.fire(new Click(FlxG.mouse.x, FlxG.mouse.y));
		}

		FlxG.collide(midGroundGroup, player);
		handleCameraBounds();

		// TODO.sfx('scarySound');
	}

	function handleCameraBounds() {
		if (activeCameraTransition == null) {
			FlxG.overlap(player, transitions, (p, t) -> {
				activeCameraTransition = cast t;
			});
		} else if (!FlxG.overlap(player, activeCameraTransition)) {
			var bounds = activeCameraTransition.getRotatedBounds();
			for (dir => camZone in activeCameraTransition.camGuides) {
				switch (dir) {
					case N:
						if (player.y < bounds.top) {
							setCameraBounds(camZone);
						}
					case S:
						if (player.y > bounds.bottom) {
							setCameraBounds(camZone);
						}
					case E:
						if (player.x > bounds.right) {
							setCameraBounds(camZone);
						}
					case W:
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
