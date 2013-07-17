/* When the Cue Ball is in hand the SnookerInHandPointer tells the Players
   where the Cue Ball will be placed */

class SnookerInHandPointer extends Actor;

var StaticMeshComponent PointerMesh;

// The number of degrees per second the Pointer spins.
var float RotRate;

event Tick(float DeltaTime)
{
	local Rotator rotateBy;
	
	super.Tick(DeltaTime);
	
	// Rotate the Pointer.
	if(!bHidden)
	rotateBy.Yaw = RotRate*DeltaTime*DegToUnrRot;
	SetRotation(Rotation+rotateBy);
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=TRUE
   	End Object
   	Components.Add(MyLightEnvironment)

	Begin Object Class=StaticMeshComponent Name=MeshComponent
		StaticMesh=StaticMesh'TurretContent.Arrow'
		CollideActors=false
		BlockActors=false
		LightEnvironment=MyLightEnvironment
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
	End Object
	PointerMesh=MeshComponent
	Components.Add(MeshComponent)

	RotRate=110.f;
	
	bCollideActors=false
	bBlockActors=false
	bHidden=true
	
	bAlwaysRelevant=true
	bSkipActorPropertyReplication=false
	bReplicateRigidBodyLocation=true
	bUpdateSimulatedPosition=true
	bReplicateMovement=true
	bForceNetUpdate=true
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=+00002.000000
}