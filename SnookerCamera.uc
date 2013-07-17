class SnookerCamera extends Camera;

/* The possible camera angles. */
enum CameraSetting
{
	TopView,
	CueView,
	FreeView,
	NoView,
};

var SnookerCameraProperties CameraProperties;

/* The current camera angle. */
var CameraSetting TheCameraSetting;

/* The Locations and Rotations of each camera angle */
var Vector  TopViewLocation;
var Vector	CueViewLocation;
var Rotator CueViewRotation;
var Vector  FreeViewLocation;
var Rotator FreeViewRotation;

simulated event PostBeginPlay()
{
	local LocalPlayer LocalPlayer;
	local vector aVector;

	Super.PostBeginPlay();
	
	// The vector FreeViewRotation initally looks down.
	aVector.X = -110;
	aVector.Y = -110;
	aVector.Z = 50;
	
	TopViewLocation = CameraProperties.TopViewPosition;
	FreeViewLocation = Location;
	FreeViewLocation.Z += 600;
	FreeViewRotation = Rotator(aVector-FreeViewLocation);
	CueViewLocation = Location;
	CueViewRotation = Rotation;
	
	if(PCOwner != None)
	{
		LocalPlayer = LocalPlayer(PCOwner.Player);		
		if(LocalPlayer != None && LocalPlayer.ViewPortClient != None)
		{
			//LocalPlayer.ViewportClient.SetMouse(PCOwner.MyHud.SizeX/2, PCOwner.MyHud.SizeY/2);
			// Doesn't seem to work. Sets the Player's initial Mouse position.
			LocalPlayer.ViewportClient.SetMouse(500, 500);
		}
	}
}

simulated function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	local CameraActor   CamActor;

	// Don't update outgoing viewtarget during an interpolation 
	if( PendingViewTarget.Target != None && OutVT == ViewTarget && BlendParams.bLockOutgoing )
	{
	return;
	}

	// Viewing through a camera actor.
	CamActor = CameraActor(OutVT.Target);
	if( CamActor != None )
	{
		CamActor.GetCameraView(DeltaTime, OutVT.POV);

		// Grab aspect ratio from the CameraActor.
		bConstrainAspectRatio   = bConstrainAspectRatio || CamActor.bConstrainAspectRatio;
		OutVT.AspectRatio      = CamActor.AspectRatio;

		// See if the CameraActor wants to override the PostProcess settings used.
		CamOverridePostProcessAlpha = CamActor.CamOverridePostProcessAlpha;
		CamPostProcessSettings = CamActor.CamOverridePostProcess;
	}
	else
	{
		// Sets the ViewTarget to be the specified camera angle.
		if(TheCameraSetting == TopView)
		{
			OutVT.POV.Location = CameraProperties.TopViewPosition;
			OutVT.POV.Rotation = CameraProperties.TopViewRotation;
		}
		else if(TheCameraSetting == CueView)
		{
			OutVT.POV.Location = CueViewLocation;
			OutVT.POV.Rotation = CueViewRotation;
		}
		else if(TheCameraSetting == FreeView)
		{
			OutVT.POV.Location = FreeViewLocation;
			OutVT.POV.Rotation = FreeViewRotation;
		}
		else
			Super.UpdateViewTarget(OutVT, DeltaTime);
	}
}

defaultproperties
{
	TheCameraSetting = FreeView
	CameraProperties=SnookerCameraProperties'TurretContent.SnookerCameraProperites'
}