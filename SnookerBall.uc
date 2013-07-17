class SnookerBall extends KActorSpawnable
	placeable
	ClassGroup(Snooker);

// Different Types/Colours of Balls in Snooker
enum BallType
{
	RedBall,
	YellowBall,
	GreenBall,
	BrownBall,
	BlueBall,
	PinkBall,
	BlackBall,
	WhiteBall // CueBall is already used term.
};

/* Stores reference to BallMesh. This is useful when working with KActors as
   Physics are applied to the Static Mesh (Rigid Body) not the actor. */
var StaticMeshComponent BallMesh;

/* Default Material applied to the Ball. */
var Material NormalMaterial;
/* When a player selects the On Ball GlowMaterial is applied to it.
   This shows the players when Ball is now On */
var Material GlowMaterial;

/* Used to determine if a Ball moves. OldPosition implies position
   in the previous Tick. */
var Vector OldPosition;

var bool IsOnTable;

/* Number of points a Ball is worth */
var(SnookerBall) int BallValue;
var(SnookerBall) BallType Type;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	OldPosition = InitialLocation;
};

// This is fucking terrible.
/* For some reason KActors do not reliably give Touch, or other collisions events.
   Even when Spawning a Trigger (because it's round), and each Tick setting it's
   position equal to the Ball's, the Trigger also doesn't give reliable collision
   events with Balls or other Triggers. So the best/only way I can think of checking
   for Ball Collisions is to simply see if a Ball moves. A collision is the only reason
   a non-Cue Ball will move. */
event Tick(float DeltaTime)
{
	local SnookerGame TheGame;

	/* Allowing Angular Velocity causes Ball to jitter when in motion.
	   Not allowing it causes the Balls to move much more smoothly.
	   Also, increasing NetUpdateFrequency has little to no effect on
	   the jitter */
	BallMesh.SetRBAngularVelocity(Vect(0,0,0));
	
	super.Tick(DeltaTime);

	// Only preform this horrible for of collision checking on the Server.
	if (Role == Role_Authority)
	{
		// Ball has moved.
		if(OldPosition != BallMesh.GetPosition())
		{
			TheGame = SnookerGame(WorldInfo.Game);
			if(TheGame!=None)
			{
				// Alert the Snooker Game.
				TheGame.CueBallTouch(self);
			}
		}
		// Keep track of "new" position.
		OldPosition = BallMesh.GetPosition();
	}
};

function int GetBallValue()
{
	return BallValue;
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'TurretContent.Sphere'
		CollideActors=true
		BlockActors=true
		Scale3D=(X=0.025,Y=0.025,Z=0.025)
		bNotifyRigidBodyCollision=true
		PhysMaterialOverride=PhysicalMaterial'TurretContent.Ball_PhysicalMaterial'
		Materials(0)=Material'TurretContent.BallRed'
	End Object
	BallMesh=StaticMeshComponent0
	CollisionComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)

	bWakeOnLevelStart=true
	bNoEncroachCheck=false
	bCollideActors=true
	bBlockActors=true

	// Exists on both client and server.
	bAlwaysRelevant=true
	bSkipActorPropertyReplication=false
	bReplicateRigidBodyLocation=true
	bUpdateSimulatedPosition=true
	bReplicateMovement=true
	bForceNetUpdate=true
	// Has little to no effect on Ball jitter.
	//NetPriority=8
	//NetUpdateFrequency=200
	RemoteRole=ROLE_SimulatedProxy
	
	BallValue=1
	
	IsOnTable=true

	NormalMaterial=Material'TurretContent.BallRed'
	GlowMaterial=Material'TurretContent.BallRed'
}