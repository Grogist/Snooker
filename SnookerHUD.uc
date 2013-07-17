class SnookerHUD extends UDKHUD;

/* The GFxMovie that contains the HUD. */
var SnookerHUDGFxMovie HUDMovie;

var class<SnookerHUDGFxMovie>	HUDMovieClass;

var GFxObject	HUDMovieSize;

var SnookerMouseInterfacePlayerInput MouseInterfacePlayerInput;
/* The position of the Mouse Cursor. */
var float MouseX, MouseY;

/* Show the Cue Ball trajectory line. */
var bool bShowTrajectoryLine;
/* Show the Mouse Cursor */
var bool bShowCursor;

/* Is there a pending request to find a ball through deprojection? */
var bool bPendingFindBall;
/* Does the Ball In Hand Pointer need to be repositioned? */
var bool bPendingBallInHandCheck;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	
	CreateHUDMovie();

	HUDMovieSize = HUDMovie.GetVariableObject("Stage.originalRect");
	
	MouseInterfacePlayerInput = SnookerMouseInterfacePlayerInput(PlayerOwner.PlayerInput);
}

/* Creates to HUD GfxMovie. */
function CreateHUDMovie()
{
	HUDMovie = new HUDMovieClass;
	
	HUDMovie.SetTimingMode(TM_Real);
	HUDMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HUDMovie.LocalPlayerOwnerIndex]);
	
	HUDMovie.SetViewScaleMode(SM_NoScale);
	HUDMovie.SetAlignment(Align_TopLeft);
}

function PreCalcValues()
{	
	Super.PreCalcValues();
}

/* Toggles whether the Mouse Cursor is visible. (Left-Ctrl) */
exec function ShowCursor()
{
	bShowCursor = !bShowCursor;
	
	HUDMovie.ToggleCursor(bShowCursor, MouseX, MouseY);
}

/* Attempts to send the a chat message. (Enter) */
exec function SendMessage()
{
	HUDMovie.ChatHandler();
}

event PostRender()
{
	Super.PostRender();

	if(bShowTrajectoryLine)
		RenderTrajectoryLine();
	
	// Renders Player Stats. Not Needed in Final Release.
	//RenderStats();
	
	// Aligns MouseX and MouseY to the PlayerInput's MousePoisition.
	MouseX = MouseInterfacePlayerInput.MousePosition.X;
	MouseY = MouseInterfacePlayerInput.MousePosition.Y;
	
	// Tick the GFxMovie.
	if(HUDMovie != none)
	{
		HUDMovie.TickHUD(0);
	}
	
	/* If Player is selecting the On Ball, attempt to find the Ball the Player
	   is selecting. */
	if(bPendingFindBall)
		FindBall();
		
	// Find position to place the Ball in hand Pointer.
	if(bPendingBallInHandCheck)
		BallInHandCheck();
}

function SetShowTrajectoryLine(bool set)
{
	bShowTrajectoryLine = set;
}

/* Creates a line from the Cue Ball to the first Actor in the direction the Cue is facing. */
function RenderTrajectoryLine()
{
	local SnookerPlayerController SPCOwner;
	local Color LineColor;
	local Vector LineDirection;
	local Actor HitActor;
	local Vector HitLocation, HitNormal;

	// The trajectory line is white.
	LineColor = MakeColor( 255, 255, 255, 255 );
	
	SPCOwner = SnookerPlayerController(PlayerOwner);
	// If the Player Controller, Cue Ball, and Cue exist.
	if(SPCOwner != None && SPCOwner.CueBall != None && SPCOwner.Cue != None)
	{
		// Vector in direction the Cue is facing.
		LineDirection = SPCOwner.CueBall.Location - SPCOwner.Cue.Location;
		LineDirection.Z = 0;

		// Find the nearest Actor to the CueBall that isn't the CueBall or the Cue.
		Foreach WorldInfo.TraceActors(class'Actor', HitActor, HitLocation, HitNormal, LineDirection * 6384.f, SPCOwner.CueBall.Location, , ,TRACEFLAG_Bullet)
		{
			if(HitActor != SPCOwner.CueBall && HitActor != SPCOwner.Cue)
			{
				// Draw the Trajectory Line.
				Draw3DLine(	SPCOwner.CueBall.Location, HitLocation, LineColor );
				// GET OUT OF HERE!
				break;
			}
		}
	}
}

/* Shows the Player's Shot Power, and Shot Angle. */
function RenderStats()
{
	local SnookerPlayerController SPCOwner;

	SPCOwner = SnookerPlayerController(PlayerOwner);
	
	if(SPCOwner != None)
	{
		// Write ShotPower to screen.
		Canvas.SetPos(20,20);
		Canvas.DrawText("Power:"$string(SPCOwner.ShotPower));
	}
	Canvas.SetPos(20,40);
	Canvas.DrawText("Angle:"$string(HUDMovie.ShotAngleSldr.GetFloat("value")));
	Canvas.SetPos(20,60);
	Canvas.DrawText("OldAngle:"$string(HUDMovie.OldShotAngleSliderValue));
}

function GetBall()
{
	bPendingFindBall = true;
}

/* When a Player is selecting the on Ball FindBall() is called to attempt to find a 
   SnookerBall at the world coordinates of the Mouse Cursor (Deproject). */
function FindBall()
{
	local Vector2D MousePosition;
	local Vector MouseWorldOrigin, MouseWorldDirection, HitLocation, HitNormal;
	local Actor HitActor;
	local SnookerBall Ball;
	local SnookerPlayerController SnookerOwner;
	
	SnookerOwner = SnookerPlayerController(PlayerOwner);
	
	MousePosition.X = MouseX;
	MousePosition.Y = MouseY;
	
	// Deproject can only occur if the Canvas exists.
	if(Canvas == None || SnookerOwner == None)
		return;
	
	Canvas.DeProject(MousePosition, MouseWorldOrigin, MouseWorldDirection);
	
	// Find the first Snooker Ball in the direction of MouseWorldDirection. 
	ForEach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, MouseWorldOrigin + MouseWorldDirection * 65536.f, MouseWorldOrigin,,,TRACEFLAG_Bullet)
	{
		Ball = SnookerBall(HitActor);
		// Only SetOnBall is the Player is actually Selecting it.
		if(Ball != None && SnookerOwner.IsSelectingOnBall)
		{
			`log("Found A Ball"@Ball.Type);
			SnookerOwner.SetOnBall(Ball);
			// The Player has selected an OnBall, but can still select another one.
			SnookerOwner.HasSelectedOnBall = true;
			break;
		}
	}
	
	bPendingFindBall=false;
}

/* Finds the position on the table the Mouse Cursor is pointing at. */
function BallInHandCheck()
{
	local Vector2D MousePosition;
	local Vector MouseWorldOrigin, MouseWorldDirection, CueBallPosition;
	local SnookerPlayerController SPCOwner;
	local float DirectionMultiple;
	
	MousePosition.X = MouseX;
	MousePosition.Y = MouseY;
	
	SPCOwner = SnookerPlayerController(Owner);
	
	if(Canvas == None || SPCOwner == None || SPCOwner.CueBall == None)
		return;
		
	Canvas.DeProject(MousePosition, MouseWorldOrigin, MouseWorldDirection);
	
	// Needed for Z-direction.
	CueBallPosition = SPCOwner.CueBall.InitialLocation;
	
	// Isn't MouseWorldDirection already a unit vector?
	MouseWorldDirection = Normal(MouseWorldDirection);
	
	// DirectionMultiple*MouseWorldDirection = MouseWorldOrigin - HitLocation. HitLocation is unknown.
	// DirectionMultiple constant for X,Y, and Z. (HitLocation.Z) is known.
	// Rearrange formula to solve.
	DirectionMultiple = (MouseWorldOrigin.Z - CueBallPosition.Z) / MouseWorldDirection.Z;
	CueBallPosition.X = MouseWorldOrigin.X - DirectionMultiple * MouseWorldDirection.X;
	CueBallPosition.Y = MouseWorldOrigin.Y - DirectionMultiple * MouseWorldDirection.Y;
	
	// Tell the Player to set the BallInHandPointer location to CueBallPosition. 
	SPCOwner.SetInHandPointerPosition(CueBallPosition);
	
	// BallInHandCheck completed.
	bPendingBallInHandCheck=false;
}

defaultproperties
{
	bShowTrajectoryLine = true
	bShowCursor = true
	HUDMovieClass = class'SnookerHUDGFxMovie'
}