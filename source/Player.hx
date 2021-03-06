package ;

import org.flixel.FlxEmitter;
import org.flixel.FlxG;
import org.flixel.FlxGroup;
import org.flixel.FlxObject;
import org.flixel.FlxSprite;
import org.flixel.util.FlxAngle;
import org.flixel.util.FlxPoint;
#if (flash)
import org.flixel.plugin.photonstorm.api.FlxKongregate;
#end

/**
 * ...
 * @author Adam Harte (adam@adamharte.com)
 */
class Player extends FlxSprite
{
	private static var MAX_HEALTH:Int = 10;
	private static var _jumpPower:Int = 150; //200 //TODO: Find a good jump power value.
	
	public var playerMidPoint:FlxPoint;
	
	private var _bullets:FlxGroup;
	private var _gibs:FlxEmitter;
	private var _restart:Float;
	private var _spawnPoint:FlxPoint;
	private var _reloadTimer:Float;
	private var _reloadMax:Float;
	
	
	public function new(startX:Float, startY:Float, bullets:FlxGroup, gibs:FlxEmitter) 
	{
		super(startX, startY);
		
		playerMidPoint = new FlxPoint();
		_spawnPoint = new FlxPoint(startX, startY);
		_bullets = bullets;
		_gibs = gibs;
		_restart = 0;
		_reloadTimer = 0;
		_reloadMax = 0.2;
		
		loadGraphic('assets/player.png', true, true, 8, 8);
		width = 6;
		height = 7;
		offset.x = 1;
		offset.y = 1;
		
		var runSpeed:Int = 80;
		drag.x = runSpeed * 8;
		acceleration.y = 420;
		maxVelocity.x = runSpeed;
		maxVelocity.y = _jumpPower;
		
		// 2Setup animations.
		addAnimation('idle', [0]);
		addAnimation('run', [1, 2, 3, 4], 12);
		addAnimation('jump', [4, 3, 5], 12, false);
		
		health = MAX_HEALTH;
	}
	
	override public function destroy():Void
	{
		super.destroy();
		
		_bullets = null;
		_gibs = null;
		playerMidPoint = null;
	}
	
	override public function update():Void
	{
		if (!alive) 
		{
			_restart += FlxG.elapsed;
			if (_restart > 2) 
			{
				respawn();
			}
			return;
		}
		
		getMidpoint(playerMidPoint);
		
		//var tx:Int = Math.round(x / PlayState.TILE_WIDTH);
		//var ty:Int = Math.round(y / PlayState.TILE_HEIGHT);
		//trace(tx, ty);
		
		// Movement
		acceleration.x = 0;
		if(FlxG.keys.A)
		{
			facing = FlxObject.LEFT;
			acceleration.x -= drag.x;
		}
		else if(FlxG.keys.D)
		{
			facing = FlxObject.RIGHT;
			acceleration.x += drag.x;
		}
		
		// Jumping
		if (velocity.y == 0 && (FlxG.keys.justPressed('W') || FlxG.keys.justPressed('SPACE'))) 
		{
			velocity.y = -_jumpPower;
			FlxG.play('Jump', 0.5);
			play('jump');
		}
		
		// Animation
		if (velocity.y != 0)
		{
			// Don't change animation if our Y vel is zero.
		}
		else if(velocity.x == 0)
		{
			play('idle');
		}
		else 
		{
			play('run');
		}
		
		// Shoot
		_reloadTimer += FlxG.elapsed;
		var shotReady:Bool = false;
		if (_reloadTimer >= _reloadMax) 
		{
			_reloadTimer = 0;
			shotReady = true;
		}
		if (FlxG.mouse.justPressed() || (shotReady && FlxG.mouse.pressed())) 
		{
			shoot(null, FlxAngle.angleBetweenMouse(this));
		}
		else if (FlxG.keys.justPressed('LEFT') || (shotReady && FlxG.keys.LEFT)) 
		{
			shoot(FlxObject.LEFT);
		}
		else if (FlxG.keys.justPressed('RIGHT') || (shotReady && FlxG.keys.RIGHT)) 
		{
			shoot(FlxObject.RIGHT);
		}
		else if (FlxG.keys.justPressed('UP') || (shotReady && FlxG.keys.UP)) 
		{
			shoot(FlxObject.UP);
		}
		else if (FlxG.keys.justPressed('DOWN') || (shotReady && FlxG.keys.DOWN)) 
		{
			shoot(FlxObject.DOWN);
		}
		
		super.update();
	}
	
	override public function hurt(damage:Float):Void
	{
		flicker(0.2);
		//FlxG.camera.shake(0.002, 0.2);
		
		super.hurt(damage);
	}
	
	override public function kill():Void
	{
		if(!alive)
		{
			return;
		}
		
		super.kill();
		
		#if (flash)
		if (FlxKongregate.hasLoaded) 
		{
			FlxKongregate.submitStats('Deaths', 1);
		}
		#end
		
		flicker(0);
		FlxG.play('Explosion', 0.6);
		exists = true;
		visible = false;
		velocity.make();
		acceleration.x = 0;
		
		_gibs.at(this);
		_gibs.start(true, 5, 0, 35);
		
		FlxG.camera.shake(0.05, 0.4);
		//FlxG.camera.flash(0xffd8eba2, 0.35);
	}
	
	
	
	private function respawn() 
	{
		reset(_spawnPoint.x, _spawnPoint.y);
		acceleration.x = 0;
		velocity.make();
		_restart = 0;
		exists = true;
		visible = true;
		health = MAX_HEALTH;
		_reloadTimer = 0;
		flicker(1);
	}
	
	private function shoot(?direction:Int, ?angle:Float) 
	{
		trace('shoot');
		_reloadTimer = 0;
		
		// Make the shoot sound.
		if (FlxG.timeScale < 0.7) 
		{
			FlxG.play('ShootSlow', 0.5);
		}
		else 
		{
			FlxG.play('Shoot', 0.5);
		}
		
		// Fire the bullet.
		var bullet:Bullet = cast(_bullets.recycle(Bullet), Bullet);
		if (direction == null) 
		{
			bullet.shootPrecise(playerMidPoint, angle);
		}
		else 
		{
			bullet.shoot(playerMidPoint, direction);
		}
	}
	
}