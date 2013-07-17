/* SnookerSpotTrigger is used to determine if it is safe to spot a Ball at a particular location. */

class SnookerSpotTrigger extends Trigger;

var vector InitialLocation;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	InitialLocation = Location;
}

defaultproperties
{
	Begin Object NAME=CollisionCylinder
		CollideActors=true
		// Size of the Snooker Balls.
		CollisionRadius=+004.000000
		CollisionHeight=+004.000000
		bAlwaysRenderIfSelected=true
	End Object
	
	bNoEncroachCheck=false
	
	bTearOff=true
	
	bStatic=false
	bNoDelete=false
}