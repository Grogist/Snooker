class SnookerCue extends Actor
	ClassGroup(Snooker)
	placeable
	HideCategories(Movement, AI, Camera, Debug, Attachment, Physics, Advanced, Object);

var() StaticMeshComponent CueMesh;

var SnookerCueProperties CueProperties;

/* Is the shot animation occuring? */
var bool bFireAnimation;
/* Stores the last know location of the Cue Ball */
var Vector OldCueBallLocation;
var float DistanceToCueBall;
var float ShotAnimationTimeRemaining;
/* How fast the Cue moves during the shot animation */
var float ShotCueSpeed;

/* (In Polar Coordinates) The Cue's current angle relative to the Cue Ball */
var float RotationAngle;

simulated event PostBeginPlay()
{
	`Log(Self$" Spawned");
	
	super.PostBeginPlay();
	
	DistanceToCueBall=CueProperties.DefaultDistance;

	ShotCueSpeed=(CueProperties.DefaultDistance-CueProperties.MinDistance)/CueProperties.ShotAnimationTime;
}

// Rename to ChangeRotation()
/* Updates the Cue's RotationAngle and moves it accordingly.
 *
 * @param DeltaRotationAngle: the change in rotation angle.
 */
function UpdateRotation(float DeltaRotationAngle)
{
	RotationAngle += DeltaRotationAngle;
	RotationAngle = RotationAngle%360;
	UpdateLocation(OldCueBallLocation);
}

// Rename to Update()?
/* Updates the Location of the Cue.
 *
 * @param CueBallLocation: The location of the Cue Ball.
 */
function UpdateLocation(Vector CueBallLocation)
{
	local Vector DeltaPosition;
	local Rotator DeltaRotation;
	
	// Updates OldCueBallLocation with the new location.
	OldCueBallLocation = CueBallLocation;
	
	// Converts 2D polar defined by DistanceToCueBall and RotationAngle into 2D cartesian.
	DeltaPosition.X = CueBallLocation.X + Cos((RotationAngle*Pi/180)) * DistanceToCueBall;
	DeltaPosition.Y = CueBallLocation.Y + Sin((RotationAngle*Pi/180)) * DistanceToCueBall;
	DeltaPosition.Z = CueBallLocation.Z;
	
	SetLocation(DeltaPosition);
	// Gives the Cue a slight upward tilt.
	DeltaRotation.Pitch = -85 * DegToUnrRot;
	DeltaRotation.Yaw = Rotator(Location-CueBallLocation).Yaw;
	SetRotation(DeltaRotation);
}

/* Called once per frame? */
event Tick(float DeltaTime)
{
	// If the Cue's fire animation is active advance it.
	if(bFireAnimation)
	{
		DistanceToCueBall -= ShotCueSpeed*DeltaTime;
		
		UpdateLocation(OldCueBallLocation);
		
		// If the distance to the Cue Ball is small enough, the animation has finished.
		if(DistanceToCueBall <= CueProperties.MinDistance)
			EndShotAnimation();
		else
			UpdateLocation(OldCueBallLocation);
	}
}

/* Causes the shot animation to begin. */
function StartShotAnimation()
{
	bFireAnimation = true;
}

/* Is called once the shot animation has ended. */
function EndShotAnimation()
{
	local SnookerGame TheGame;

	bFireAnimation = false;
	
	// Causes the Cue to become hidden in one second.
	SetTimer(1.0f, false, 'SetHiddenCall');
	
	TheGame = SnookerGame(WorldInfo.Game);
	if(TheGame != none)
		// Alerts TheGame that a shot has been taken.
		TheGame.ShotTaken();
}

/* Is called from EndShotAnimation(). */
function SetHiddenCall()
{
	SetHidden(true);
	DistanceToCueBall = CueProperties.DefaultDistance;
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=CueLightEnvironment
		bEnabled=true
		bIsCharacterLightEnvironment=true
		bUseBooleanEnvironmentShadowing=false
	End Object;
	Components.Add(CueLightEnvironment)

	// The Cue doesn't collide or block with anything.
	Begin Object Class=StaticMeshComponent Name=CueStaticMeshComponent
		Scale3D=(X=0.1,Y=0.1,Z=0.5)
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
		LightEnvironment=CueLightEnvironment;
		BlockRigidBody=false;
		CollideActors=false;
		BlockZeroExtent=true;
		//bHasPhysicsAssetInstance=true
		bAllowAmbientOcclusion=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		StaticMesh=StaticMesh'TurretContent.Cue'
	End Object
	CueMesh=CueStaticMeshComponent
	Components.Add(CueStaticMeshComponent)
	
	bCollideActors=false
	
	RotationAngle=180.0f
	
	// Exists on the Client and Server.
	bAlwaysRelevant=true
	bSkipActorPropertyReplication=false
	bUpdateSimulatedPosition=true
	bReplicateMovement=true
	bForceNetUpdate=true
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=+00002.000000
	
	CueProperties=SnookerCueProperties'TurretContent.SnookerCueProperties'
}