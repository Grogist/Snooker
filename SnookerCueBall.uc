class SnookerCueBall extends SnookerBall;

var bool IsInHand;

event Tick(float DeltaTime)
{
	// If the Cue Ball is in hand, prevent it from moving.
	if(IsInHand)
		BallMesh.SetRBLinearVelocity(Vect(0,0,0));

	super.Tick(DeltaTime);
}

// Doesn't get called.
simulated event RigidBodyCollision
( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	Super.RigidBodyCollision(HitComponent, OtherComponent, RigidCollisionData, ContactIndex);
};

// Doesn't get called.
event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local SnookerGame TheGame;
	local SnookerBall TouchedBall;
	
	super.Touch(Other,OtherComp,HitLocation,HitNormal);
	
	TheGame = SnookerGame(WorldInfo.Game);
	TouchedBall = SnookerBall(Other);
	
	if(TheGame == None || TouchedBall == None || SnookerCueBall(Other) != None)
		return;
		
	`log("SnookerCueBall Touch");
	TheGame.CueBallTouch(TouchedBall);
};

defaultproperties
{
	BallValue = 0
	Type = WhiteBall
	IsInHand = true;
	
	Begin Object Name=StaticMeshComponent0
		Materials(0)=Material'TurretContent.BallWhite'
	End Object
	
	NormalMaterial=Material'TurretContent.BallWhite'
	GlowMaterial=Material'TurretContent.BallWhite'
}