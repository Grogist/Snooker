/* The Pawn is not used for anything in the Snooker Game. It just exists
   so that it doesn't get in the way. Also, it shouldn't collide with anything. */
class SnookerDefaultPawn extends Pawn;

var(LightEnvironment) DynamicLightEnvironmentComponent LightEnvironment;

// Don't take falling Damage.
function TakeFallingDamage();

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();
	
	SetCollision(false, false, false);
	SetCollisionType(COLLIDE_NoCollision);
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetCollision(false, false, false);
	SetCollisionType(COLLIDE_NoCollision);
}

defaultproperties
{
	WalkingPct=+0.4
	CrouchedPct=+0.4
	BaseEyeHeight=40.0
	EyeHeight=40.0
	GroundSpeed=440.0
	AirSpeed=440.0
	WaterSpeed=220.0
	AccelRate=1048.0
	JumpZ=0.0
	CrouchHeight=29.0
	CrouchRadius=21.0
	WalkableFloorZ=0.78
   
	bCanClimbLadders=true
   
	bCanFly=true
	bCanWalk=true
	bSimulateGravity=false

	Components.Remove(Sprite)

	Begin Object Name=CollisionCylinder
		CollisionRadius=+0034.000000
		CollisionHeight=+0046.000000
		CollideActors=false
		BlockActors=false
		BlockRigidBody=false
	End Object
   
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Remove(CollisionCylinder)
	Components.Add(CollisionCylinder)

   
	bCollideActors=false
	bCollideWorld=true
	bBlockActors=false
}