class SnookerGame extends GameInfo;

/* Score[0] = Player 1's score, Score[1] = Player 2's score. */
var int Score[2];
/* Turn determines which Player's turn it is. Has values
   0, or 1. Could be a BOOL */
var int Turn;
/* Current Maximum value is 2. Designed to allow games with more
   than 2 players. However this is not implemented. */
var int NumberOfPlayers;
var const int MaxNumberofPlayers;
/* Reference to the PlayerControllers. */
var array<SnookerPlayerController> Players;
/* Reference to the Cues of each player.
   PlayerCues[0] = The Cue of Player[0]. */
var array<SnookerCue> PlayerCues;

/* In order to "reset" Balls at their initial locations, new Balls
   must be spawned their. */
var array<Vector> RedBallLocations;
var Vector 	BlackBallLocation, BlueBallLocation, PinkBallLocation,
			YellowBallLocation, BrownBallLocation, GreenBallLocation;

/* Records the Location of each Ball. Used in checking ball movement.
   Checking using the Ball's velocity is unreliable */
var vector OldBallLocations[22];

/* Did the player not make a foul and pocket the On Ball? */
var bool PlayerContinues;
var BallType OnBallType;
/* Has a Ball been hit by the Cue Ball? */
var bool IsFirstTouch;
/* Is a Player setting the Location of the Cue Ball? */
var bool IsCueInHand;
/* Is a Player in Shooting the Cue Ball? */
var bool IsCueBallShot;
/* Has a Foul occured this turn? */
var bool FoulOccured;

/* Stores the Shot Power of the Player making the Shot.
   PendingShotPower is checked by the Server to ensure
   it is with in the proper bounds. */
var float PendingShotPower;

/* The default point amount of a penalty. */
var int DefaultPenalty;
/* Specifically used for determining if a ball is potted. */
var int NumberOfRedBallsLeft;
var int NumberofColourBallsLeft;

var vector HalfCircleCentre;
var float HalfCircleRadius;
/* A vector denoting the direction "up" the table. Specifically
   from where the Black Ball starts to where the Brown Ball starts */
var vector UpTableDirection;

var SnookerCueBall CueBall;
var SnookerInHandPointer InHandPointer;

/* Determines if it is safe to spot a Ball at a specified Location */
var SnookerSpotTrigger 	SpotBallTrigger;
/* Records what happens to potted Balls between turns. */
var array<SnookerBall>	BallsToBeSpotted;
var array<SnookerBall>  BallsToBeRemoved;

var class<BroadcastHandler> BroadcastHandlerClass;
var BroadcastHandler BroadcastHandler;	// handles message (text and localized) broadcasts

event InitGame( string Options, out string ErrorMessage)
{
	Super.InitGame(Options, ErrorMessage);
	
	BroadcastHandler = spawn(BroadcastHandlerClass);
	
	// Increases Max Physics Substeps to ensure Balls don't get stuck in other objects.
	WorldInfo.MaxPhysicsSubsteps = 10;
}

/* Used by Server to sent chat messages between Players.
 *
 * @param Sender: The message's Sender.
 *
 * @param Msg: The message's text.
 *
 * @param Type: The message's type.
 *
 */
event BroadCast(Actor Sender, coerce string Msg, optional name Type)
{
	local SnookerPlayerController PC;
	local PlayerReplicationInfo PRI;
	
	// If the Sender is a Pawn. (It should never be.)
	if( Pawn(Sender) != None)
	{
		PRI = Pawn(Sender).PlayerReplicationInfo;
		`log("Pawn(Sender)");
	}
	// If the Sender is a Controller. (It should always be.)
	else if( Controller(Sender) != None)
	{
		PRI = Controller(Sender).PlayerReplicationInfo;
		`log("Controller(Sender)");
	}
	
	BroadCastHandler.BroadCast(Sender, Msg, Type);
	
	if(WorldInfo != None && PRI!= None)
	{
		// Sent the Message to all Players.
		foreach WorldInfo.AllControllers(class'SnookerPlayerController', PC)
		{
	    `Log(Self$":: Sending "$PC$" a broadcast message from "$PRI.PlayerName$" which is '"$Msg$"'.");
	    PC.ReceiveBroadcast(PRI.PlayerName, Msg);
		}
	}
}

/*event PreLogin(string Options, string Address, out string ErrorMessage)
{
	// Enforce Player Limit.
	super.PreLogin(Options, Address, ErrorMessage);
	
	if(NumberofPlayers>=MaxNumberofPlayers)
	{
		// Disconnect Player;
	}
	NumberofPlayers++;
}*/


/*event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local PlayerController PC;
	PC = super.Login(Portal, Options, UniqueID, ErrorMessage);
    return PC;
}*/

/* Occurs after Login(...). Checks if enough Players have joined the Game to start it.
 *
 * @param NewPlayer: Reference to the PlayerController that has just joined.
 *
 */
event PostLogin(PlayerController NewPlayer)
{
	local SnookerPlayerController SnookerPlayer;

	super.PostLogin(NewPlayer);
	
	SnookerPlayer = SnookerPlayerController(NewPlayer);
	
	// Ensure that the PlayerController is a SnookerPlayer
	if(SnookerPlayer != None)
	{
		Players.AddItem(SnookerPlayer);
		// If the requisite number of Players has joined. Allow the Game to progress.
		if(Players.Length == NumberofPlayers)
		{
			/* Tells each Player that the Game can start. Asks that both players
			   confirm that they are ready. */
			Players[0].ActivateIsReadyButton();
			Players[1].ActivateIsReadyButton();
		}
		// Alerts all players that a new player has joined.
		BroadCast(SnookerPlayer, SnookerPlayer.PlayerReplicationInfo.GetHumanReadableName()@"Has Joined");
	}
}

/* Sets reference necessary for the game. */
event PostBeginPlay()
{
	local Vector SpawnLocation;
	local SnookerBall Ball;
	local SnookerCueBall TempCueBall;
	local SnookerBall BBall; // Brown Ball
	local SnookerBall YBall; // Yellow Ball
	local SnookerBall PBall; // Pink Ball
	
	local int i;
	
	// Not Needed?
	i=0;

	Super.PostBeginPlay();
	
	
	
	// Not Needed?
	CueBall = None;
		
	// Find the CueBall.
	foreach AllActors(class'SnookerCueBall', TempCueBall)
	{
		CueBall = TempCueBall;
	}
	
	// If no CueBall is found, Spawn one.
	if(CueBall == None)
	{
		// Magic Numbers. THIS IS BAD. // TestMap5.udk
		SpawnLocation.X = -164; 	   // -656
		SpawnLocation.Y = 20;		   // 80
		foreach AllActors(class'SnookerBall', Ball)
		{
			SpawnLocation.Z = Ball.Location.Z;
			break;
		}
		CueBall = Spawn(class'SnookerCueBall', , , SpawnLocation);
	}
	
	InHandPointer = Spawn(class'SnookerInHandPointer', , , CueBall.Location);

	// Spawn a Cue for each Player, and hide them.
	PlayerCues.AddItem(Spawn(class'SnookerCue', , , CueBall.Location));
	PlayerCues.AddItem(Spawn(class'SnookerCue', , , CueBall.Location));
	PlayerCues[0].SetHidden(true);
	PlayerCues[1].SetHidden(true);
	
	Players[0].HideGameOverDialog();
	Players[1].HideGameOverDialog();
	
	SpawnLocation.X = 0;
	SpawnLocation.Y = 0;
	SpawnLocation.Z = -500;
	// Spawn a SpotTrigger.
	SpotBallTrigger = Spawn(class'SnookerSpotTrigger', , , SpawnLocation);
	// MAGIC NUMBERS. Set the Cylinder radius to be the diameter of the Ball's
	SpotBallTrigger.CylinderComponent.SetCylinderSize(4.0f, 4.0f);
	
	// Associates OldBallLocations each Ball.
	foreach AllActors(class'SnookerBall', Ball)
	{
		OldBallLocations[i] = Ball.Location;
		
		if(Ball.Type == RedBall)
			RedBallLocations.AddItem(Ball.Location);

		// Used in calculations of the Half Circle.
		if(Ball.Type == BrownBall)
		{
			BBall = Ball;
			BrownBallLocation = Ball.Location;
		}
		else if(Ball.Type == YellowBall)
		{
			YBall = Ball;
			YellowBallLocation = Ball.Location;
		}
		else if(Ball.Type == PinkBall)
		{
			PBall = Ball;
			PinkBallLocation = Ball.Location;
		}
		else if(Ball.Type == BlackBall)
		{
			BlackBallLocation = Ball.Location;
		}
		else if(Ball.Type == BlueBall)
		{
			BlueBallLocation = Ball.Location;
		}
		else if(Ball.Type == GreenBall)
		{
			GreenBallLocation = Ball.Location;
		}
		
		i++;
		// WHY?
		if(i>=22)
		{
			`log("PostBeginPlay Out of Range");
			break;
		}
	}
	
	// Calculates the dimensions of the Half Circle.
	HalfCircleCentre = BBall.Location;
	HalfCircleRadius = VSize(BBall.location - YBall.location);
	UpTableDirection = Normal(PBall.location-BBall.location);
}

/* Is called when a Ball touches the Cue Ball. It currently works by
 * whenever a ball moves CueBallTouch is called. This is not the original
 * design of this function, however it seems to be the only reliable way
 * of determining a touch.
 *
 * Is used to determine when ball, if any, the Cue Ball first touches.
 *
 * @param TouchBall: The Ball the Cue Ball touched.
 *
 */
function CueBallTouch(SnookerBall TouchedBall)
{
	// If the conditions of the touch are correct.
	if(TouchedBall == None || TouchedBall == CueBall || !IsCueBallShot)
		return;

	if(IsFirstTouch == true && OnBallType != TouchedBall.Type)
	{
		// FOUL OCCURED! Cue Ball First Hit Ball Not On.
		`log("Cue Ball First Hit Ball Not On. OnBallType:"@OnBallType);
		// Awards the other player with points.
		AddToScore(Max(DefaultPenalty, TouchedBall.BallValue), (Turn+1)%NumberOfPlayers);
		FoulOccured = true;
	}
	
	IsFirstTouch = false;
}

/* Called by a SnookerPocket object when a ball is potted.
 *
 * @param Ball: The Ball that has been potted.
 *
 */
function BallPotted(SnookerBall Ball)
{
	// Assumes that the Player does not continue.
	PlayerContinues = false;
	
	if(Ball.Type == OnBallType)
	{
		`log("Potted OnBall");
		// Player only continues if Ball potted is the OnBall.
		PlayerContinues = true;
		// Awards Player with points.
		AddToScore(Ball.BallValue, Turn);
	}
	else
	{
		// FOUL OCCURED! Ball Not On Potted.
		`log("Ball Not On Potted");
		// Awards other Player with points.
		AddToScore(Max(DefaultPenalty, Ball.BallValue), (Turn+1)%NumberofPlayers);
		FoulOccured = true;
	}
	
	if(Ball.Type == RedBall)
	{
		NumberOfRedBallsLeft--;
		// Always remove Red Balls from play.
		BallsToBeRemoved.AddItem(Ball);
	}
	// If the CueBall is potted, it always become In Hand.
	else if(Ball.Type == WhiteBall)
	{
		IsCueInHand = true;
		CueBall.IsInHand=true;
	}
	// Ball is a coloured ball.
	else if(NumberOfRedBallsLeft > 0)
	{
		// If more Red Balls remain spot the Ball.
		AddBallToBeSpotted(Ball);
	}
	else if(NumberOfRedBallsLeft == 0)
	{
		// Remove the Ball it is the On Ball.
		if(Ball.Type == OnBallType)
		{
			NumberOfColourBallsLeft--;
			BallsToBeRemoved.AddItem(Ball);
		}
		// Else Spot it.
		else
			AddBallToBeSpotted(Ball);
	}
}

/* Adds Balls To Be Spotted */
function AddBallToBeSpotted(SnookerBall Ball)
{
	BallsToBeSpotted.AddItem(Ball);
}

/* Called when a Ball falls off of the table.
 *
 * @param Ball: The Ball that is off the table.
 */
function BallOffTable(SnookerBall Ball)
{
	if(Ball.IsOnTable)
	{
		// Awards other Player with points.
		AddToScore(Max(DefaultPenalty, Ball.BallValue), (Turn+1)%NumberofPlayers);
		FoulOccured = true;
	
		if(Ball.Type == RedBall)
		{
			NumberOfRedBallsLeft--;
			// Always remove Red Balls from play.
			BallsToBeRemoved.AddItem(Ball);
		}
		// If the CueBall is potted, it always become In Hand.
		else if(Ball.Type == WhiteBall)
		{
			IsCueInHand = true;
			CueBall.IsInHand=true;
		}
		// Ball is a coloured ball.
		else if(NumberOfRedBallsLeft > 0)
		{
			// If more Red Balls remain spot the Ball.
			AddBallToBeSpotted(Ball);
		}
		else if(NumberOfRedBallsLeft == 0)
		{
			// Remove the Ball it is the On Ball.
			if(Ball.Type == OnBallType)
			{
				NumberOfColourBallsLeft--;
				BallsToBeRemoved.AddItem(Ball);
			}
			// Else Spot it.
			else
				AddBallToBeSpotted(Ball);
		}
	}

	Ball.IsOnTable = false;
}

/* Preforms a set of checks to determine where to Spot a Ball.
 *
 * @param Ball: The Ball to be Spotted.
 *
 */
function SpotBall(SnookerBall Ball)
{
	SpotBallTrigger.SetLocation(Ball.InitialLocation);
	// Ball's Initial Location is empty. Place Ball at its initial location.
	if(SpotBallTrigger.Touching.Length == 0)
	{
		Ball.BallMesh.SetRBPosition(Ball.InitialLocation);
		Ball.BallMesh.SetRBLinearVelocity(Vect(0,0,0));
		Ball.BallMesh.SetRBAngularVelocity(Vect(0,0,0));
	}
	// Ball's Initial Location is occupied. Attempt to place the ball at a lower
	// valued Ball's initial location.
	else if(!SpotByValuedBalls(Ball, Ball.BallValue-1))
	{
		// Couldn't spot the Ball at a lower valued Ball's initial location.
		// Spot the Ball by the neared open position to its own initial location.
		SpotByNearestOpenPosition(Ball);
	}
	// Remove the SpotBallTrigger from the table.
	SpotBallTrigger.SetLocation(SpotBallTrigger.InitialLocation);
}

// This is horribly inefficient. Better solution is to simply keep track of each coloured ball
// and not use recursion. Fancy but bad. Too many Return statments.
/* Attempts to Spot a Ball by placing it at a lower valued Ball's initial position.
 *
 * @param Ball: The Ball to be spotted.
 *
 * @param Value: the lower valued Ball's value.
 *
 * @return: True is successfully spotted. False if not spotted.
 */
function bool SpotByValuedBalls(SnookerBall Ball, int Value)
{
	local SnookerBall LowerValueBallCheck;

	/* Cannot spot Yellow Ball, or Cue Ball this way.
	   If Value <= 1 then the Ball could not have been spotted this way. */
	if(Ball.Type == YellowBall || Ball.Type == WhiteBall || Value <= 1)
		return false;
		
	// Find Ball with lower Value.
	Foreach AllActors(class'SnookerBall', LowerValueBallCheck)
	{
		// Found
		if(Value == LowerValueBallCheck.BallValue)
		{
			// Check if initial location is occupied.
			SpotBallTrigger.SetLocation(LowerValueBallCheck.InitialLocation);
			// If location is not occupied.
			if(SpotBallTrigger.Touching.Length == 0)
			{
				// Spot the Ball.
				`log("SpotByValuedBalls True");
				Ball.BallMesh.SetRBPosition(LowerValueBallCheck.InitialLocation);
				Ball.BallMesh.SetRBLinearVelocity(Vect(0,0,0));
				Ball.BallMesh.SetRBAngularVelocity(Vect(0,0,0));
				// The Ball has been successfully spotted.
				return true;
			}
			// Location is occupied so check with a more lower valued ball.
			else
			{
				Value--;
				// Seach recursively.
				return SpotByValuedBalls(Ball, Value-1);
			}
		}
	}
	
	// If all else fails, the ball was not spotted.
	return false;
}

/* Find the nearest acceptable position from the Ball's initial location to spot.
 * Searches locations up the table until an available one is found.
 *
 * @param Ball: The Ball to the spotted.
 *
 */
function SpotByNearestOpenPosition(SnookerBall Ball)
{
	local float IncrementDistance;
	local float TotalIncrementedDistance;
	local vector IncrementedLocation;
	local bool HasBeenSpotted;
	
	HasBeenSpotted = false;
	
	IncrementDistance = 0.25;
	
	while(!HasBeenSpotted)
	{
		TotalIncrementedDistance += IncrementDistance;
		
		IncrementedLocation = Ball.InitialLocation;
		IncrementedLocation += UpTableDirection*TotalIncrementedDistance;
		
		SpotBallTrigger.SetLocation(IncrementedLocation);
		// If IncrementedLocation is empty.
		if(SpotBallTrigger.Touching.Length == 0)
		{
			// Spot the Ball.
			`log("SpotByNearestOpenPosition");
			Ball.BallMesh.SetRBPosition(IncrementedLocation);
			Ball.BallMesh.SetRBLinearVelocity(Vect(0,0,0));
			Ball.BallMesh.SetRBAngularVelocity(Vect(0,0,0));
			// The Ball has been spotted.
			HasBeenSpotted = true;
		}
	}
}

/* Adds points to a Player's score.
 *
 * @param value: The number of points to be added.
 *
 * @param Player: The Player the points are added to.
 *
 */
function AddToScore(int value, int Player)
{
	`log("AddToScore:"@value);
	Score[Player] += value;
	
	// Inform the client Players that the score has changed.
	Players[0].SetScores(Score);
	Players[1].SetScores(Score);
}

/* Set the type of Ball that is on.
 *
 * @param Ball: The Ball from which type is derived.
 *
 */
function SetOnBall(SnookerBall Ball)
{
	local SnookerPlayerController PC;
	
	OnBallType = Ball.Type;
	
	if(OnBallType != RedBall)
	{
		// Alerts each Player of the change in OnBall.
		foreach WorldInfo.AllControllers(class'SnookerPlayerController', PC)
		{
			// Causes the Player to set Ball's material to be the Glow Material.
			PC.SetGlowBall(true, Ball);
		}
	}
}

/* Is called when a Player tells the Server it wants to shoot.
 * 
 * @param Power: The power of the shot.
 * 
 */
function PendingShotTaken(float Power)
{
	// Not needed. This check should never be true.
	if(Players[Turn].IsActivePlayer == false)
		return;

	PendingShotPower = Power;
	
	// Neither Player is now Active. Alerts both Players.
	Players[0].SetActive(false, 0);
	Players[1].SetActive(false, 0);
	Players[Turn].IsActivePlayer=false;
	
	// Start the Cue shot animation.
	PlayerCues[Turn].StartShotAnimation();
}

/* After the Cue's shot animation finishes, SnookerCue calls ShotTaken().
 * Adds and impulse to the CueBall causing the shot to occur. */
function ShotTaken()
{
	local Rotator ShotDirection;

	// The ShotDirection is the direction (Yaw) the Cue is facing.
	ShotDirection.Pitch = 0;
	ShotDirection.Yaw = PlayerCues[Turn].Rotation.Yaw;
	ShotDirection.Roll = 0;
	
	// EEWWW!
	// Clamps PendingShotPower to min and max presets found in the 'TurretContent.SnookerPlayerControllerProperties' Archetype.
	PendingShotPower = FClamp(PendingShotPower,SnookerPlayerControllerProperties'TurretContent.SnookerPlayerControllerProperties'.MinShotPower,SnookerPlayerControllerProperties'TurretContent.SnookerPlayerControllerProperties'.MaxShotPower);
	
	CueBall.BallMesh.AddImpulse( -Vector(ShotDirection) * PendingShotPower, Vector(ShotDirection)*CueBall.Location );
	
	// Turn is Active again.
	// Why here?
	IsCueBallShot=true;

	// Starts to check the movement of each Ball. Only when each ball is no longer
	// moving does the next turn being.
	SetTimer(1.12, false, 'CheckBallMovement');
}

/* Checks is both Players are ready and prepares both Players (Clients) for the game. */
function CheckStartGame()
{
	local string PlayerNames[2];
	
	// If not enough players are present.
	if(Players.Length < 2)
		return;
	
	// If a player is not ready.
	if(Players[0].IsReady == false || Players[1].IsReady == false)
		return;

	// Updates the position of each Cue to be near the Cue Ball.
	PlayerCues[0].UpdateLocation(CueBall.Location);
	PlayerCues[1].UpdateLocation(CueBall.Location);
	
	// Player[0] starts. Reveal its Cue.
	PlayerCues[0].SetHidden(false);
	
	// Tells both Players which object is the CueBal, InHandPointer,
	// and their respective Cues.
	Players[0].SetCueBallAndCue(CueBall, InHandPointer, PlayerCues[0]);
	Players[1].SetCueBallAndCue(CueBall, InHandPointer, PlayerCues[1]);
	
	PlayerNames[0] = Players[0].PlayerReplicationInfo.GetHumanReadableName();
	PlayerNames[1] = Players[1].PlayerReplicationInfo.GetHumanReadableName();
	`log("ServerSetNames:"@PlayerNames[0]@PlayerNames[1]);
	// Tells each Players of each others names.
	Players[0].SetNames(PlayerNames);
	Players[1].SetNames(PlayerNames);
	
	// Tells both Players about who is the active Player.
	Players[0].IsActivePlayer = true;
	Players[0].SetActive(true, 1);
	Players[1].IsActivePlayer = false;
	Players[1].SetActive(false, 1);
	// Tells Player[0] that the CueBall is in hand.
	Players[0].CueBallInHand(IsCueInHand);
	if(IsCueInHand)
		InHandPointer.SetHidden(!IsCueInHand);
}

/* Checks if the Players want to restart the Game */
function CheckRestartGame()
{
	// A Player has not yet responded to Restart Dialog.
	if(Players[0].RequestsRestart == 0 || Players[1].RequestsRestart == 0)
	{
		return;
	}
	
	// A Player does not want to Restart.
	if(Players[0].RequestsRestart < 0 || Players[1].RequestsRestart < 0)
	{
		Players[0].RequestsRestart = 0;
		Players[1].RequestsRestart = 0;
		Players[0].ResetRestartRequest();
		Players[1].ResetRestartRequest();
	}
	
	// Both Players have requested a Restart.
	if(Players[0].RequestsRestart > 0 && Players[1].RequestsRestart > 0)
	{
		RestartGame();
	}
	
	// Both Players have responded to Restart Dialog.
	if(Players[0].RequestsRestart != 0 && Players[1].RequestsRestart != 0)
	{
		Players[0].RequestsRestart = 0;
		Players[1].RequestsRestart = 0;
		Players[0].ResetRestartRequest();
		Players[1].ResetRestartRequest();
	}
}

/* Causes the Game to reset to it's initial state */
function RestartGame()
{
	local SnookerBall Ball;
	
	NumberOfRedBallsLeft = 15;
	NumberofColourBallsLeft = 6;
	
	Turn = 0;
	
	BallsToBeSpotted.length = 0;
	BallsToBeRemoved.length = 0;
	
	// Place each Ball back to its initial location.
	foreach AllActors(class'SnookerBall', Ball)
	{
		Ball.BallMesh.SetRBLinearVelocity(Vect(0,0,0));
		Ball.BallMesh.SetRBAngularVelocity(Vect(0,0,0));
		Ball.BallMesh.SetRBPosition(Ball.InitialLocation);
	}
	
	// Resets the scores.
	Score[0]=0;
	Score[1]=0;
	Players[0].SetScores(Score);
	Players[1].SetScores(Score);
	Players[0].HideFoulDialog();
	Players[1].HideFoulDialog();
	// Updates the Cues.
	PlayerCues[0].UpdateLocation(CueBall.Location);
	PlayerCues[1].UpdateLocation(CueBall.Location);
	InHandPointer.SetHidden(false);
	
	// Allows the Player to pass through CheckChangeTurn() to set variable to initial state.
	PlayerContinues = true;
	OnBallType = BlackBall;
	IsFirstTouch = false;
	IsCueInHand = true;
	IsCueBallShot = false;
	FoulOccured = false;
	
	CheckChangeTurn();
}

/* This should check a Ball's velocity. This is unreliable however.
 * A motionless ball can still have a non-zero velocity.
 *
 * Checks if Balls are moving by checking if a balls old location is close to
 * it's new location. */
function CheckBallMovement()
{
	local SnookerBall Ball;
	local bool CheckAgain;
	local int i;
	local vector Difference;
	
	CheckAgain=false;
	i=0;
	
	// Check each Snooker Ball for movement.
	foreach AllActors(class'SnookerBall', Ball)
	{
		if(Ball.IsOnTable)
		{
			// If a Snooker Ball is moving enough check for Ball movement again.
			Difference = OldBallLocations[i]-Ball.Location;
			Difference.Z = 0;
			if(VSize(Difference) >= 5.0)
				CheckAgain=true;
			// Store the Ball's current location.
			OldBallLocations[i] = Ball.Location;
		}
		i++;
		if(i>=22)
			break;
	}
	
	if(CheckAgain == true)
	{
		SetTimer(1.12, false, 'CheckBallMovement');
		return;
	}
	
	// From this point on code only executes if no balls are moving.
	
	// Check to see if players change turn.
	CheckChangeTurn();
}

/* In the event of a foul, the non-fouling Player plays the next shot */
function FoulResponsePlayNextShot()
{
	// Exit function if no foul has occured.
	if(!FoulOccured)
		return;
	
	// Allows game to progress in CheckChangeTurn().
	FoulOccured = false;
	IsFirstTouch = false;
	// Causes responding player to play.
	PlayerContinues = false;
	CheckChangeTurn();
}

/* In the event of a foul, the fouling Player plays the next shot */
function FoulResponseOpponentShootAgain()
{
	// Exit function if no foul has occured.
	if(!FoulOccured)
		return;
	
	// Allows game to progress in CheckChangeTurn().
	FoulOccured = false;
	IsFirstTouch = false;
	OnBallType = WhiteBall;
	// Causes the fouling Player to continue.
	PlayerContinues = true;
	CheckChangeTurn();
}

/* Check the current state of the game to determine how the next turn is to be played. */
function CheckChangeTurn()
{
	local SnookerBall Ball;
	local SnookerPlayerController PC;
	local vector position;
	
	// Spotted each Ball needed to be spotted.
	foreach BallsToBeSpotted(Ball)
	{
		SpotBall(Ball);
	}
	BallsToBeSpotted.Length = 0;
	
	// Removes each Ball needed to be removed.
	foreach BallsToBeRemoved(Ball)
	{
		Ball.IsOnTable = false;
		Ball.BallMesh.SetRBPosition(Vect(5000.f,5000.f,0));
		//Ball.Destroy();
	}
	BallsToBeRemoved.Length = 0;

	// If at the end of a turn the Cue Ball has not touched any other
	// Ball, a foul occurs.
	if(IsFirstTouch)
	{
		// FOUL OCCURED! Cueball Misses all Objects Balls.
		`log("Cueball Misses all Objects Balls.");
		AddToScore(DefaultPenalty, (Turn+1)%NumberofPlayers);
		FoulOccured = true;
	}

	// If a foul occured during the turn. Give the other Player a choice to play
	// or force the fouling player to play.
	if(FoulOccured)
	{
		Players[(Turn+1)%NumberofPlayers].ShowFoulDialog();
		return;
	}
	
	// If there are no more coloured Balls left the Game is over.
	if(NumberOfColourBallsLeft <= 0)
	{
		GameOver();
		return;
	}
	
	// If the Player does not continue.
	if(!PlayerContinues)
	{
		// The other Player plays the next turn.
		Turn = (Turn+1)%NumberofPlayers;
		OnBallType = RedBall;
	}
	// If the Player does continue.
	else
	{
		// If the OnBall Type was Red allow the Player to select the OnBall.
		if(OnBallType == RedBall && NumberOfRedBallsLeft > 0)
		{
			//Player Must Select OnBallType (!Red).
			`log("SelectBALL");
			Players[Turn].SelectOnBall(true);
		}
		// If the OnBall Type was not Red, the OnBall Type is now Red.
		else if(OnBallType != RedBall && NumberOfRedBallsLeft > 0)
		{
			OnBallType = RedBall;
			Players[Turn].SelectOnBall(false);
		}
		// If no Red Ball are left, the OnBall Type becomes the Ball with the
		// lowest value remaining.
		else if(NumberOfRedBallsLeft <= 0)
		{
			Switch(NumberOfColourBallsLeft)
			{
				case 6:
					OnBallType = YellowBall;
					break;
				case 5:
					OnBallType = GreenBall;
					break;
				case 4:
					OnBallType = BrownBall;
					break;
				case 3:
					OnBallType = BlueBall;
					break;
				case 2:
					OnBallType = PinkBall;
					break;
				case 1:
					OnBallType = BlackBall;
					break;
				case 0:
					break;
				default:
					break;
			}
			Players[Turn].SelectOnBall(false);
		}
	}
	
	// Assume the Player does not continue.
	PlayerContinues = false;
	
	// Stop balls from bouncing between turns.
	foreach AllActors(class'SnookerBall', Ball)
	{
		position.X = Ball.BallMesh.GetPosition().X;
		position.Y = Ball.BallMesh.GetPosition().Y;
		position.Z = Ball.InitialLocation.Z;
		Ball.OldPosition = position;
		Ball.BallMesh.SetRBPosition(position);
		Ball.BallMesh.SetRBLinearVelocity(Vect(0,0,0));
		Ball.BallMesh.SetRBAngularVelocity(Vect(0,0,0));
	}
	
	// Sets all Ball back to their default material.
	// Get better way of doing this.
	foreach WorldInfo.AllControllers(class'SnookerPlayerController', PC)
	{
		PC.SetGlowBall(false);
	}
	// Alerts all Players of the new OnBall's Type.
	Broadcast(PC, "OnBallType:"@OnBallType, 'Say');

	IsFirstTouch = true;
	IsCueBallShot = false;
	// Sets active Players
	Players[Turn].SetActive(true, Turn+1);
	Players[(Turn+1)%NumberofPlayers].SetActive(false, Turn+1);
	Players[Turn].IsActivePlayer = true;
	
	if(!CueBall.IsOnTable)
	{
		CueBall.BallMesh.SetRBLinearVelocity(Vect(0,0,0));
		CueBall.BallMesh.SetRBPosition(CueBall.InitialLocation);
		CueBall.IsOnTable = true;
	}
	PlayerCues[Turn].UpdateLocation(CueBall.Location);
	PlayerCues[Turn].SetHidden(false);

	// If the Cue Ball is in hand, tell the active Player.
	Players[Turn].CueBallInHand(IsCueInHand);
	// Show the InHandPointer if the Cue Ball is in hand.
	InHandPointer.SetHidden(!IsCueInHand);

	`log("Turn#"@Turn);
}

/* Called once all Coloured Balls have been removed from the table*/
function GameOver()
{
	// The name of the winner.
	local string Winner;
	
	// Find the winner and store its name.
	if(Score[0] > Score[1])
		Winner = Players[0].PlayerReplicationInfo.GetHumanReadableName();
	else
		Winner = Players[0].PlayerReplicationInfo.GetHumanReadableName();

	// Request a game start.
	Players[0].RequestRestart();
	
	// Show the game over dialog.
	Players[0].ShowGameOverDialog(Winner);
	Players[1].ShowGameOverDialog(Winner);
}

defaultproperties
{
	HUDType=class'SnookerHUD'
	DefaultPawnClass=class'SnookerDefaultPawn'
	PlayerControllerClass=class'SnookerPlayerController'
	
	bDelayedStart=false

	Turn = 0
	NumberofPlayers = 2
	MaxNumberofPlayers = 2
	MaxPlayersAllowed=2
	PlayerContinues = false
	IsFirstTouch = true
	IsCueInHand = true
	IsCueBallShot = false
	FoulOccured = false
	
	DefaultPenalty = 4
	NumberOfRedBallsLeft = 15
	NumberofColourBallsLeft = 6
	
	OnBallType = RedBall
}

// Implement Penalties for:
//	- a snooker with free ball
//	- a push stroke