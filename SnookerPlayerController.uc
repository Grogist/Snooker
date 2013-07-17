class SnookerPlayerController extends PlayerController;

var SnookerCueBall		CueBall;
var SnookerInHandPointer InHandPointer;
/* Reference to the Coloured OnBall. Specifically used to set and revert
 * the Material on the OnBall. */
var SnookerBall			GlowBall; // OnBall;
var SnookerCue			Cue;
var float				ShotPower;
var bool				IsRMBPressed;
var bool				IsActivePlayer;
var bool				IsReady;
var int					RequestsRestart;

var bool				IsSelectingOnBall;
var bool				HasSelectedOnBall;
var bool				IsCueBallInHand;

var SnookerHUDGFxMovie	HUDGFxMovie;

/* Store properties of Shot Power. */
var SnookerPlayerControllerProperties SnookerPlayerProperties;

/* Default state for Player Controller is Player Walking. This is overwritten to both stop the Pawn
   from moving, and to control the Camera position. */
state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;
	
	// Not Needed.
	event NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		if ( NewVolume.bWaterVolume && Pawn.bCollideWorld )
		{
			GotoState(Pawn.WaterMovementState);
		}
	}

	// Not Needed.
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		if( Pawn == None )
		{
			return;
		}

		if (Role == ROLE_Authority)
		{
			// Update ViewPitch for remote clients
			Pawn.SetRemoteViewPitch( Rotation.Pitch );
		}

		Pawn.Acceleration = NewAccel;

		CheckJumpOrDuck();
	}

	/* Overwritten PlayerMove(). Is called upon user input from class'PlayerInput'.
	 * Depending on the Camera's view setting / view angle, move the Camera location.
	 *
	 * @param DeltaTime: The time elapsed since the last call to PlayerMove().
	 */
	simulated function PlayerMove( float DeltaTime )
	{
		local vector			X,Y,Z;
		local float				RotateBy;

		local SnookerCamera		SnookerCamera;
		local Rotator			DeltaRot, newRotation, ViewRotation;
		local SnookerCameraProperties CameraProperties;
		
		SnookerCamera = SnookerCamera(PlayerCamera);
		if(SnookerCamera == None)
			return;
		CameraProperties = SnookerCamera.CameraProperties;
		
		if( Pawn == None )
		{
			GotoState('Dead');
		}
		// Rotates the Cue is conditions are correct.
		else if(ISRMBPressed == true)
		{
			RotateBy = PlayerInput.aTurn * PlayerInput.LookRightScale * DeltaTime * 0.001f;
			RotateCue(RotateBy);
		}
		// Rotates the Camera in FreeView.
		else if(SnookerCamera.TheCameraSetting == FreeView)
		{
			GetAxes(SnookerCamera.FreeViewRotation,X,Y,Z);

			ViewRotation = SnookerCamera.FreeViewRotation;

			DeltaRot.Yaw	= PlayerInput.aTurn * PlayerInput.LookRightScale;
			DeltaRot.Pitch	= -PlayerInput.aLookUp * PlayerInput.LookUpScale;

			ViewRotation += DeltaRot * 0.25f * DeltaTime;

			ViewRotation.Pitch = Fclamp(ViewRotation.Pitch, -90 * degtounrrot, 90 * degtounrrot);

			NewRotation = ViewRotation;
			NewRotation.Roll = SnookerCamera.FreeViewRotation.Roll;

			SnookerCamera.FreeViewLocation += PlayerInput.aForward*X*DeltaTime*0.25f + PlayerInput.aStrafe*Y*DeltaTime*0.25f;

			SnookerCamera.FreeViewRotation = NewRotation;
		}
		// Rotates the Camera in CueView.
		else if(CameraProperties != None && SnookerCamera.TheCameraSetting == CueView)
		{
			GetAxes(SnookerCamera.CueViewRotation,X,Y,Z);
			
			CameraProperties = SnookerCamera.CameraProperties;
			
			CameraProperties.CueViewDistance -= PlayerInput.aForward*0.25f*DeltaTime;
			CameraProperties.CueViewDistance = FClamp(CameraProperties.CueViewDistance, CameraProperties.CueViewMinDistance, CameraProperties.CueViewMaxDistance);
			HUDGFxMovie.UpdateCVDistanceSlider(CameraProperties.CueViewDistance);
			
			CameraProperties.CueViewRotation -= PlayerInput.aStrafe*0.075f*DeltaTime;
			CameraProperties.CueViewRotation = CameraProperties.CueViewRotation%360;
			if(CameraProperties.CueViewRotation<0)
				CameraProperties.CueViewRotation = 359 - CameraProperties.CueViewRotation;
			HUDGFxMovie.UpdateCVAngleSlider(CameraProperties.CueViewRotation);
			
			SnookerCamera.CueViewLocation.X = CueBall.Location.X + CameraProperties.CueViewDistance * Cos(CameraProperties.CueViewRotation*Pi/180);
			SnookerCamera.CueViewLocation.Y = CueBall.Location.Y + CameraProperties.CueViewDistance * Sin(CameraProperties.CueViewRotation*Pi/180);
			SnookerCamera.CueViewLocation.Z = CameraProperties.CueViewZOffset;

			SnookerCamera.CueViewRotation = Rotator(CueBall.Location-SnookerCamera.CueViewLocation);
		}
	}

	// Not Needed.
	event BeginState(Name PreviousStateName)
	{
		DoubleClickDir = DCLICK_None;
		bPressedJump = false;
		GroundPitch = 0;
		if ( Pawn != None )
		{
			Pawn.ShouldCrouch(false);
			if (Pawn.Physics != PHYS_Falling && Pawn.Physics != PHYS_RigidBody) // FIXME HACK!!!
				Pawn.SetPhysics(Pawn.WalkingPhysics);
		}
	}

	// Not Needed.
	event EndState(Name NextStateName)
	{
		GroundPitch = 0;
		if ( Pawn != None )
		{
			Pawn.SetRemoteViewPitch( 0 );
			if ( bDuck == 0 )
			{
				Pawn.ShouldCrouch(false);
			}
		}
	}

Begin:
}

/* Alerts the Client which Player is the active Player.
 *
 * @param set: True if this Player is the Active Player.
 *
 * @param ActivePlayer: Index of the Active Player.
 */
reliable client function SetActive(bool set, int ActivePlayer)
{
	IsActivePlayer = set;

	// Is the Active Player
	if(IsActivePlayer == true)
	{
		//Update Cue Position and Rotation.
		Cue.UpdateLocation(CueBall.Location);
		
		SnookerHUD(myHUD).SetShowTrajectoryLine(true);
	}
	else
	{
		SnookerHUD(myHUD).SetShowTrajectoryLine(false);
	}
	
	// Indicate on the HUD who is the Active Player.
	HUDGFxMovie.SetTurnIndicators(ActivePlayer);
}

/* Rotates the Cue by an amount RotateBy. */
simulated function RotateCue(float RotateBy)
{
	if(Cue == None || Cue.bHidden == true || IsActivePlayer == false)
		return;
	
	// Syncronizes Client and Server.
	if (Role < Role_Authority)
		ServerRotateCue(RotateBy,self);

	// Causes the ShotAngleSlider to be updated.
	HUDGFxMovie.UpdateShotAngleSlider(RotateBy);
	
	Cue.UpdateRotation(RotateBy);
}

/* Rotates the Cue on the Server. */
reliable server function ServerRotateCue(float RotateBy, SnookerPlayerController CallingPlayer)
{
	local SnookerGame TheGame;
	local SnookerCue ActiveCue;
	
	TheGame = SnookerGame(WorldInfo.Game);
	
	ActiveCue = TheGame.PlayerCues[TheGame.Turn];
	
	// Make sure the Calling Player is Active.
	if(CallingPlayer.IsActivePlayer == false)
		return;
	
	if(ActiveCue != None && TheGame.CueBall != None)
	{
		ActiveCue.UpdateRotation(RotateBy);
	}
}

/* Once two Players have logged in to the Server the Server call this function on each Client.
 * Activates each Players ready Buttton. */
reliable client function ActivateIsReadyButton()
{
	if(HUDGFxMovie.ReadyBtn != none)
	{
		HUDGFxMovie.ReadyBtn.SetBool("disabled", false);
	}
}

/* Is called when the changes their Ready status. Also alerts the Server of the change.
 *
 * @param set: True if the Player is Ready.
 */
reliable client function SetReady(bool set) //simulated function?
{
	IsReady = set;
	ServerSetReady(set);
}

/* Called when a player changes their Ready status. Checks if the Game is
 * ready to start.
 *
 * @param set: True if the Player is Ready.
 */
reliable server function ServerSetReady(bool set)
{
	local SnookerGame TheGame;
	
	IsReady = set;
	
	TheGame = SnookerGame(WorldInfo.Game);
	
	if(TheGame != none)
	{
			TheGame.CheckStartGame();
	}
}

/* When the Game starts each Player needs to know which Actor is the Cue Ball, InHandPointer, and their Cue.
 *
 * @param aBall: Reference to the Cue Ball.
 *
 * @param aPointer: Reference to the In Hand Pointer.
 *
 * @param aCue: Reference to a Player's personal Cue.
 */
reliable client function SetCueBallAndCue(SnookerCueBall aBall, SnookerInHandPointer aPointer, SnookerCue aCue)
{
	`log("SetCueBallAndCue");
	if(aBall == None)
	{
		`log("aBall == None!");
	}
	else
	{
		CueBall = aBall;
		// The CueBallView is now available as the Player know's which Actor to look at.
		SnookerHUD(myHUD).HUDMovie.CBVRadioBtn.SetBool("disabled", false);
	}
	
	if(aBall == None)
	{
		`log("aBall == None!");
	}
	else
	{
		InHandPointer = aPointer;
	}
	
	if(aCue == None)
	{
		`log("aCue == None!");
	}
	else
	{
		Cue = aCue;
	}
}

reliable client function ShowFoulDialog()
{
	HUDGFxMovie.ShowFoulDialog();
}

reliable client function HideFoulDialog()
{
	HUDGFxMovie.HideFoulDialog();
}

/* When a foul occurs a other Player has the option to play the next shot.
 * This function tells the server of that decision. */
reliable server function ServerOnPlayNextShotButton()
{
	local SnookerGame TheGame;
	
	TheGame = SnookerGame(WorldInfo.Game);
	
	if(TheGame != None)
	{
		TheGame.FoulResponsePlayNextShot();
	}
}

/* When a foul occurs a other Player has the option force the offending Player to play again.
 * This function tells the server of that decision. */
reliable server function ServerOnOpponentShootAgainButton()
{
	local SnookerGame TheGame;
	
	TheGame = SnookerGame(WorldInfo.Game);
	
	if(TheGame != None)
	{
		TheGame.FoulResponseOpponentShootAgain();
	}
}

/* Alerts the Server that a Player has attempted to take a shot.
 *
 * @param Power: The power of the shot.
 */
reliable server function ShotTaken(float Power)
{
	local SnookerGame TheGame;
	
	TheGame = SnookerGame(WorldInfo.Game);
	if(TheGame!=None)
		TheGame.PendingShotTaken(Power);
}

/* Called when the Server tells the Players each other's name. */
reliable client function SetNames(string names[2])
{
	`log("Set Names:"@names[0]@names[1]);
	HUDGFxMovie.SetNames(names);
}

/* Called when the Server tells each Players the score. */
reliable client function SetScores(int scores[2])
{
	HUDGFxMovie.SetScores(scores);
}

/* Called when the Server tells a Player that they are now Selecting
 * (or not Selecting) the On Ball.
 *
 * @param IsSelecting: True if the Player is selecting the On Ball.
 */
reliable client function SelectOnBall(bool IsSelecting)
{
	IsSelectingOnBall=IsSelecting;
	if(IsSelecting)
		HasSelectedOnBall=false;
		
	HUDGFxMovie.SetOnBallLabelVisible(IsSelecting);
}

/* Called when the Server tells a Player that the Cue Ball is in hand.
 *
 * @param IsInHand: True if the Ball is in hand.
 */
reliable client function CueBallInHand(bool IsInHand)
{
	IsCueBallInHand = IsInHand;
	if(IsInHand)
	{
		CueBall.IsInHand=true;
		HUDGFxMovie.SetBallInHandLabelVisible(true);
	}
}

/* Called when a Player has the Cue Ball in hand and changes the position of the InHandPointer */
simulated function SetInHandPointerPosition(Vector position)
{
	ServerSetInHandPointerPosition(position);
}

/* Called when a Player has the Cue Ball in hand and changes the position of the InHandPointer */
reliable server function ServerSetInHandPointerPosition(Vector position)
{
	local SnookerGame TheGame;
	
	if(Role == Role_Authority)
	{
		TheGame = SnookerGame(WorldInfo.Game);
		
		if(TheGame != None)
		{
			//Check if position is in the Half Circle.
			if(NoZDot(TheGame.UpTableDirection, TheGame.HalfCircleCentre - position) >= 0
				&& VSize(position - TheGame.HalfCircleCentre) <= TheGame.HalfCircleRadius)
			{
				TheGame.InHandPointer.SetLocation(position);
			}
		}
	}
}

/* Attempt to place Cue Ball at InHandPointer's location.
 * If successful Cue Ball is no longer In Hand, and alerts the Player. */
simulated function CueBallInHandIsSet()
{	
	ServerCueBallInHandSet();
}

reliable server function ServerCueBallInHandSet()
{
	local SnookerGame TheGame;
	local Vector SetLocation;
	
	TheGame = SnookerGame(WorldInfo.Game);

	if(TheGame != None)
	{
	
		TheGame.SpotBallTrigger.SetLocation(TheGame.InHandPointer.Location);
		if(TheGame.SpotBallTrigger.Touching.Length == 0
			|| (TheGame.SpotBallTrigger.Touching.Length == 1 && TheGame.SpotBallTrigger.Touching[0] == TheGame.CueBall))
		{
			TheGame.IsCueInHand = false;
			
			TheGame.CueBall.IsInHand=false;
			SetLocation = TheGame.InHandPointer.Location;
			SetLocation.Z = TheGame.CueBall.InitialLocation.Z;
			TheGame.CueBall.BallMesh.SetRBPosition(SetLocation);
			TheGame.PlayerCues[TheGame.Turn].UpdateLocation(SetLocation);
			
			TheGame.InHandPointer.SetHidden(true);
			
			// Synchronizes the active Player.
			TheGame.Players[TheGame.Turn].FinishBallInHand();
		}
	}
}

/* Synchronizes the Client with the Server. Tells the Client the Cue Ball has successfully
 * been moved. The Cue Ball is no longer in hand. */
reliable client function FinishBallInHand()
{
	local vector SetLocation;

	IsCueBallInHand = false;
		
	CueBall.IsInHand=false;
		
	SetLocation = InHandPointer.Location;
	SetLocation.Z = CueBall.InitialLocation.Z;
		
	CueBall.BallMesh.SetRBPosition(SetLocation);
		
	Cue.UpdateLocation(SetLocation);
	
	HUDGFxMovie.SetBallInHandLabelVisible(false);
}

/* Called when the Player has selected an On Ball.
 *
 * @param Ball: The selected On Ball.
 */
reliable server function SetOnBall(SnookerBall Ball)
{
	local SnookerGame TheGame;
	
	TheGame = SnookerGame(WorldInfo.Game);
	
	if(TheGame != None)
	{
		TheGame.SetOnBall(Ball);
	}
}

/* Sets the material of the On Ball.
 *
 * @param Set: The Ball is being to to Glow.
 *
 * @param Ball: The Ball whose Material is being Set.
 */
reliable client function SetGlowBall(bool Set, optional SnookerBall Ball)
{
	if(GlowBall != None)
		GlowBall.BallMesh.SetMaterial(0, GlowBall.NormalMaterial);

	if(Set && Ball != None)
	{
		GlowBall = Ball;
		GlowBall.BallMesh.SetMaterial(0, GlowBall.GlowMaterial);
	}
}

/* The Player wants to restart the Game. */
simulated function RequestRestart()
{
	ServerRequestsRestart();
}

/* Causes each Player to show their Restart Dialog.  If both Players decide
 * to restart the Game then the Game is restarted. */
reliable server function ServerRequestsRestart()
{
	local SnookerGame TheGame;
	local SnookerPlayerController PC;
	
	TheGame = SnookerGame(WorldInfo.Game);
	
	if(TheGame != None)
	{
		TheGame.Broadcast(self, "Requests Game Restart", 'say');
		foreach WorldInfo.AllControllers(class'SnookerPlayerController', PC)
		{
			PC.ShowRestartDialog();
		}
	}
}

reliable client function ShowRestartDialog()
{
	HUDGFxMovie.ShowRestartDialog();
}

/* Sets the Player's response to the restart request.
 *
 * @param set: True is the Player wants to reset the Game.
 */
reliable client function SetRestart(int set)
{
	RequestsRestart = set;
	ServerSetRestart(set);
}

reliable server function ServerSetRestart(int set)
{
	local SnookerGame TheGame;
	
	RequestsRestart = set;
	
	TheGame = SnookerGame(WorldInfo.Game);
	
	if(TheGame != none)
	{
			TheGame.CheckRestartGame();
	}
}

/* Restart Request sequence has completed. Neither Player is requesting a restart now. */
reliable client function ResetRestartRequest()
{
	RequestsRestart = 0;
	HUDGFxMovie.HideGameOverDialog();
}

reliable client function ShowGameOverDialog(string WinnerName)
{
	HUDGFxMovie.ShowGameOverDialog(WinnerName);
}

reliable client function HideGameOverDialog()
{
	HUDGFxMovie.HideGameOverDialog();
}

/* Is called whenever the Player attempts to shoot. */
exec function StartFire(optional byte FireModeNum)
{
	`log("Client IsActivePlayer"@IsActivePlayer);
	
	Super.StartFire(FireModeNum);
	
	if(IsActivePlayer && Cue != none && FireModeNum == 0)
	{
		if((!IsSelectingOnBall || ( IsSelectingOnBall && HasSelectedOnBall)) && !IsCueBallInHand )
		{
			ShotTaken(ShotPower);
			HUDGFxMovie.SetOnBallLabelVisible(false);
		}
	}
}

exec function StopFire(optional byte FireModeNum)
{
	Super.StopFire(FireModeNum);
}

/* Called when the right mouse button is pressed. */
exec function StartAltFire(optional byte FireModeNum)
{
	Super.StartAltFire(FireModeNum);
	IsRMBPressed = true;
}

/* Called when the right mouse button is released. */
exec function StopAltFire(optional byte FireModeNum)
{
	Super.StopAltFire(FireModeNum);
	IsRMBPressed = false;
}

/* Adjusts the Player's ShotPower. */
exec function MiddleMouseScrollDown()
{
	ShotPower -= SnookerPlayerProperties.ShotPowerIncrement;
	
	ShotPower = FClamp(ShotPower, SnookerPlayerProperties.MinShotPower, SnookerPlayerProperties.MaxShotPower);
	
	// Updates the HUD.
	HUDGFxMovie.UpdateShotPowerSlider(ShotPower);
}

/* Adjusts the Player's ShotPower. */
exec function MiddleMouseScrollUp()
{
	ShotPower += SnookerPlayerProperties.ShotPowerIncrement;
	
	ShotPower = FClamp(ShotPower, SnookerPlayerProperties.MinShotPower, SnookerPlayerProperties.MaxShotPower);
	
	// Updates the HUD.
	HUDGFxMovie.UpdateShotPowerSlider(ShotPower);
}

/* Changes the desired Camera View. */
exec function MiddleMousePressed()
{
	ChangeCameraView();
}

/* Changes the desired Camera View. */
exec function SwitchWeapon(int number)
{
	Switch(number)
	{
		case 1:
			ChangeCameraView(FreeView);
			break;
		case 2:
			if(CueBall != None)
				ChangeCameraView(CueView);
			break;
		case 3:
			ChangeCameraView(TopView);
			break;
	}
}

/* Changes the Camera View by setting the Camera to a specific view, or cycling through
 * the different Camera View.
 * 
 * @param Set: The desired Camera View. If = NoView, cycle between the views. */
function ChangeCameraView(optional CameraSetting Set=NoView)
{
	local SnookerCamera SnookerCamera;
	
	SnookerCamera = SnookerCamera(PlayerCamera);
	if(SnookerCamera != None)
	{
		if(Set != NoView)
		{
			SnookerCamera.TheCameraSetting = Set;
		}
		else
		{
			Switch(SnookerCamera.TheCameraSetting)
			{
				case FreeView:
					if(CueBall!=None)
						SnookerCamera.TheCameraSetting = CueView;
					else
						SnookerCamera.TheCameraSetting = TopView;
					break;
				case CueView:
					SnookerCamera.TheCameraSetting = TopView;
					break;
				case TopView:
					SnookerCamera.TheCameraSetting = FreeView;
					break;
			}
		}
	}
}

exec function ShowMenu()
{
	ConsoleCommand("Exit");
}

function registerHUD(SnookerHUDGFxMovie HUD)
{
	HUDGFxMovie = HUD;
}

exec function SendTextToServer(SnookerPlayerController PC, String TextToSend)
{
	`Log(Self$":: Client wants to send '"$TextToSend$"' to the server.");
	ServerReceiveText(PC, TextToSend);
}

reliable server function ServerReceiveText(SnookerPlayerController PC, String RecievedText)
{
	WorldInfo.Game.Broadcast(PC, RecievedText, 'Say');
}

reliable client function ReceiveBroadcast(String PlayerName, String ReceivedText)
{
    `Log(Self$":: The Server sent me '"$ReceivedText$"' from "$PlayerName$".");
    HUDGFxMovie.UpdateChatLog(PlayerName @ ": " @ ReceivedText);
}

defaultproperties
{
	CameraClass=class'SnookerCamera'
	
	IsRMBPressed=false
	IsSelectingOnBall=false
	HasSelectedOnBall=false
	IsCueBallInHand=false

	ShotPower=0.0
	
	SnookerPlayerProperties=SnookerPlayerControllerProperties'TurretContent.SnookerPlayerControllerProperties'
	InputClass=class'SnookerMouseInterfacePlayerInput'
	
	IsActivePlayer=false
	IsReady = false
	RequestsRestart = 0
}