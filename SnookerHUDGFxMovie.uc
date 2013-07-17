/* The GFxMovie that represents the in Game HUD. */
class SnookerHUDGFxMovie extends GFxMoviePlayer;

var array<ASValue> args;

var WorldInfo ThisWorld;
/* Reference to the Owner as a SnookerPlayerController */
var SnookerPlayerController SPC;

/* Array of previous chat messages. */
var array<string> chatMessages;
/* Is the Player Chatting? */
var bool bChatting;

/* The name of each Player */
var string PlayerNames[2];

/* References to the chat window. . */
var GFxClikWidget MyChatInput, MyChatSendButton, MyChatLog;

/* References to the various Bttons, Sliders, Labels, etc. that make up
   and can change in the HUD */
var GFxClikWidget ShotPowerSldr, ShotAngleSldr, ShootBtn;
// FreeViewRadioBtn, CueBallViewRadioBtn, TopViewRadioBtn, ShowTrajectoryLineCheckBox.
var GFxClikWidget FVRadioBtn, CBVRadioBtn, TVRadioBtn, STrLCheckBox;
var GFxClikWidget BallDistSldr, BallRotSldr;
var GFxClikWidget ReadyBtn, RestartBtn, QuitBtn;
var GFxClikWidget playerOneScoreLbl, playerTwoScoreLbl;
var GFxClikWidget playerOneTurnInd, playerTwoTurnInd;
var GFxClikWidget SelectOnBallLbl, BallInHandLbl;
var GFxClikWidget PlayNextShotBtn, OpponentShootAgainBtn;
var GFxClikWidget NoRestartBtn, YesRestartBtn;
var GFxClikWidget WinnerNameLbl;

var GFxObject RootMC, MouseContainer, MouseCursor;

/* Used to calculate how much the Slider value has changed between
   OnShotAngleSliderChange calls. The Cue rotates by small changes. */
var float OldShotAngleSliderValue;

function Init(optional LocalPlayer player)
{
	super.Init(player);
	ThisWorld = GetPC().WorldInfo;
	
	/* Start the Movie and Advance to frame 0. */
	Start();
	Advance(0);
	
	SPC = SnookerPlayerController(GetPC());
	// Tell the Player Controller about the Hud Movie.
	SPC.registerHUD(self);
	
	RootMC = GetVariableObject("_root");
	
	AddFocusIgnoreKey('LeftControl');
	AddFocusIgnoreKey('Enter');
	AddFocusIgnoreKey('Escape');

	/* Show the Cursor initially. */
	ToggleCursor(true, 0, 0);
}

/* Updates the Mouse position. */
function UpdateMousePosition(float x, float y)
{
	local SnookerMouseInterfacePlayerInput MouseInputPlayerInput;
	local SnookerHUD HUD;
	
	MouseInputPlayerInput = SnookerMouseInterfacePlayerInput(GetPC().PlayerInput);

	if(MouseInputPlayerInput != none)
	{
		MouseInputPlayerInput.SetMousePosition(x,y);
	}
	
	/* If the Cue Ball is in hand, tell the HUD class to prepare to
	   do a Ball in hand check. This check can only be done between
	   frames when a Canvas exists. */
	if(SPC.IsCueBallInHand)
	{
		HUD = SnookerHUD(SPC.myHUD);
		if(HUD!=None)
		{
			HUD.bPendingBallInHandCheck = true;
		}
	}
		
}

/* Toggles mouse cursor.
 *
 * @param showCursor: Whether of not to show the Cursor.
 
 * @param mx,my: X,Y position to set the cursor at.
 */
function ToggleCursor(bool showCursor, float mx, float my)
{
	if(showCursor)
	{
		MouseContainer = RootMC.AttachMovie("MouseContainer", "MouseCursor");
		MouseCursor = MouseContainer.GetObject("my_cursor");
		MouseCursor.SetPosition(mx, my);
		MouseContainer.SetBool("topmostlevel", true);
		
		// GFxMovie becomes the focus of Player Input.
		self.bCaptureInput = true;
		self.bIgnoreMouseInput = false;
		
		SetMovieCanReceiveInput(true);
		SetMovieCanReceiveFocus(true);
	}
	else
	{
		MouseContainer.Invoke("removeMovieClip", args);
		MouseContainer = none;
		// Cursor disabled means player should not be chatting.
		bChatting = false;
		
		// GFxMovie loses focus of Player Input.
		self.bCaptureInput = false;
		self.bIgnoreMouseInput = true;
		
		SetMovieCanReceiveInput(false);
		SetMovieCanReceiveFocus(false);
	}
}

function TickHUD(float DeltaTime)
{
	return;
}

/* Is called when the Chat Input field is pressed. */
function OnChat(GFxClikWidget.EventData ev)
{
	// The Player is now chatting.
	bChatting = true;
}

/* Called when the chat send Button is clicked. */
function OnChatSend(GFxClikWidget.EventData ev)
{
	ChatHandler();
}

/* Attempts to send the text in the chat input field to the server. */
function ChatHandler()
{
	local string Msg;
	
	// Get the chat message.
	Msg = MyChatInput.GetString("text");
	
	if(Msg != "")
	{
		SPC.SendTextToServer(SPC, Msg);
	}
	
	MyChatInput.SetString("text", "");
	//The Player is no longer chatting.
	bChatting = false;
}

/* When the Player recieves a chat message it is displayed in the Chat Log
 * Updates the Chat Log.
 *
 * @param message: The chat message.
 */
function UpdateChatLog(string message)
{
	local string displayMsg;
	local int i;
	
	// Add the message to the list of chat messages.
	chatMessages.AddItem(message);
	
	displayMsg = "";
	
	// Concatenates each chat message into displayMsg, seperated by line breaks.
	for(i = 0; i < chatMessages.length; i++)
	{
		displayMsg @= chatMessages[i];
		displayMsg @= "\n";
	}
	
	// The concatenated messages are given to the chat log to display.
	MyChatLog.SetString("text", displayMsg);
	MyChatLog.SetFloat("position", MyChatLog.GetFloat("maxscroll"));
}

/* Sets and stores the names of each player.
 *
 * @param names: Each Player's name.
 */
function SetNames(string names[2])
{
	`log("Set Names:"@names[0]@names[1]);
	PlayerNames[0] = names[0];
	PlayerNames[1] = names[1];
	playerOneScoreLbl.SetString("text", PlayerNames[0]$":"@0);
	playerTwoScoreLbl.SetString("text", PlayerNames[1]$":"@0);
	// Show both Player name labels.
	playerOneScoreLbl.SetBool("visible", true);
	playerTwoScoreLbl.SetBool("visible", true);
}

/* Displays the scores of each Player.
 *
 * @param scores: Each Player's score.
 */
function SetScores(int scores[2])
{
	`log("SetScores:"@scores[0]@scores[1]);
	playerOneScoreLbl.SetString("text", PlayerNames[0]$":"@scores[0]);
	playerTwoScoreLbl.SetString("text", PlayerNames[1]$":"@scores[1]);
}

/* Beside each Player's name is an indicator for whose turn it is.
 * This function determines which indicator to show.
 *
 * @param ActivePlayer: Used to indicate whose turn it is.
 */
function SetTurnIndicators(int ActivePlayer)
{
	switch(ActivePlayer)
	{
		case 0:	// Neither
			playerOneTurnInd.SetBool("visible", false);
			playerTwoTurnInd.SetBool("visible", false);
			break;
		case 1: // Player 1
			playerOneTurnInd.SetBool("visible", true);
			playerTwoTurnInd.SetBool("visible", false); // Not Needed?
			break;
		case 2: // Player 2
			playerOneTurnInd.SetBool("visible", false); // Not Needed?
			playerTwoTurnInd.SetBool("visible", true);
			break;
		default:
			break;
	}
}

function SetOnBallLabelVisible(bool set)
{
	SelectOnBallLbl.SetBool("visible", set);
}

function SetBallInHandLabelVisible(bool set)
{
	BallInHandLbl.SetBool("visible", set);
}

/* Called from the GFXMovie ActionScript whenever the left mouse Button is pressed. */
function MouseDown()
{
	local SnookerHUD HUD;
	
	HUD = SnookerHUD(SPC.myHUD);
	// If the Player is selecting the On Ball tell the HUD to attempt to find it.
	if(HUD != None && SPC.IsSelectingOnBall)
		HUD.GetBall();

	// If the Player has the Cue Ball in hand, set the Cue Ball's locations.
	if(SPC.IsCueBallInHand)
	{
		SPC.CueBallInHandIsSet();
	}
}

/* Called when ShotPowerSlider changes value in the GFxMovie. */
function OnShotPowerSliderChange(GFxClikWidget.EventData ev)
{
	local float SliderValue;
	SliderValue = ShotPowerSldr.GetFloat("value");
	
	// The Player's shot power equals the new value.
	SPC.ShotPower = SliderValue;
}

/* Updates the ShotPowerSlider whenever the Player changes it through non-Hud means.
 *
 * @param ShotPower: The new shot power.
 */
function UpdateShotPowerSlider(float ShotPower)
{
	ShotPowerSldr.SetFloat("value", ShotPower);
	// Needed to update blue and red components of the slider.
	ActionScriptVoid("ASUpdateShotPowerSlider");
}

/* Called when ShotAngleSlider changes value in the GFxMovie. */
function OnShotAngleSliderChange(GFxClikWidget.EventData ev)
{
	local float SliderValue;
	SliderValue = ShotAngleSldr.GetFloat("value");

	// Rotates the Cue by the difference in values between Slider changes.
	SPC.RotateCue(OldShotAngleSliderValue - SliderValue);
	
	OldShotAngleSliderValue = SliderValue;
}

/* Updates the ShotPowerSlider whenever the Player changes it through non-Hud means.
 *
 * @param value: The new Cue shot angle.
 */
function UpdateShotAngleSlider(float value)
{
	local float SliderValue;

	SliderValue = ShotAngleSldr.GetFloat("value");
	
	SliderValue = (SliderValue+value)%360;
	if(SliderValue<0)
		SliderValue = ShotAngleSldr.GetFloat("maximum")-SliderValue;
	
	ShotAngleSldr.SetFloat("value", SliderValue);
	// Needed to update blue and red components of the slider.
	ActionScriptVoid("ASUpdateShotAngleSlider");
}

/* Called when ShootButton is clicked. */
function OnShootButton(GFxClikWidget.EventData ev)
{
	SPC.StartFire(0);
}

/* Called when FreeViewRadioButton is clicked. */
function OnFVRadioButton(GFxClikWidget.EventData ev)
{
	SPC.ChangeCameraView(FreeView);
}

/* Called when CueBallViewRadioButton is clicked. */
function OnCBVRadioButton(GFxClikWidget.EventData ev)
{
	SPC.ChangeCameraView(CueView);
}

/* Called when TopViewRadioButton is clicked. */
function OnTVRadioButton(GFxClikWidget.EventData ev)
{
	SPC.ChangeCameraView(TopView);
}

/* Called when CueBallViewDistanceSlider changes value in the GFxMovie. */
function OnCVDistanceSliderChange(GFxClikWidget.EventData ev)
{
	SnookerCamera(SPC.PlayerCamera).CameraProperties.CueViewDistance = BallDistSldr.GetFloat("value");
}

/* Updates the CueBallViewDistanceSlider whenever the Player changes it through non-Hud means.
 *
 * @param value: The new view distance.
 */
function UpdateCVDistanceSlider(float value)
{
	BallDistSldr.SetFloat("value", value);
	// Needed to update blue and red components of the slider.
	ActionScriptVoid("ASUpdateDistanceSlider");
}

/* Called when CueBallViewAngleSlider changes value in the GFxMovie. */
function OnCVAngleSliderChange(GFxClikWidget.EventData ev)
{
	SnookerCamera(SPC.PlayerCamera).CameraProperties.CueViewRotation = BallRotSldr.GetFloat("value");
}

/* Updates the CueBallViewAngleSlider whenever the Player changes it through non-Hud means.
 *
 * @param value: The new view angle.
 */
function UpdateCVAngleSlider(float value)
{
	BallRotSldr.SetFloat("value", value);
	// Needed to update blue and red components of the slider.
	ActionScriptVoid("ASUpdateAngleSlider");
}

/* Called when ReadyButton is clicked. */
function OnReadyButton(GFxClikWidget.EventData ev)
{
	// Disable the ReadyButton.
	ReadyBtn.SetBool("disabled", true);
	
	SPC.SetReady(true);
}

/* Called when ShowTrajectoryLineCheckBox is clicked. */
function OnTrLBoxClick(GFxClikWidget.EventData ev)
{
	local SnookerHUD HUD;
	
	HUD = SnookerHUD(SPC.myHUD);
	
	if(HUD != none)
	{
		HUD.bShowTrajectoryLine = !HUD.bShowTrajectoryLine;
		STrLCheckBox.SetBool("selected", HUD.bShowTrajectoryLine);
	}
}

/* Called when RestartButton is clicked. */
function OnRestartButton(GFxClikWidget.EventData ev)
{
	SPC.RequestRestart();
}

function ShowRestartDialog()
{
	ActionScriptVoid("ASRestartDialogShow");
}

function HideRestartDialog()
{
	ActionScriptVoid("ASRestartDialogHide");
}

/* Called when QuitButton is clicked. */
function OnQuitButton(GFxClikWidget.EventData ev)
{
	ConsoleCommand("Exit");
}

function ShowFoulDialog()
{
	ActionScriptVoid("ASFoulDialogShow");
}

function HideFoulDialog()
{
	ActionScriptVoid("ASFoulDialogHide");
}

/* Called when PlayNextShotButton in the FoulDialog is clicked. */
function OnPlayNextShotButton(GFxClikWidget.EventData ev)
{
	// Alerts the Server of the Player's action.
	SPC.ServerOnPlayNextShotButton();
	HideFoulDialog();
}

/* Called when OpponentShootAgainButton in the FoulDialog is clicked. */
function OnOpponentShootAgainButton(GFxClikWidget.EventData ev)
{
	// Alerts the Server of the Player's action.
	SPC.ServerOnOpponentShootAgainButton();
	HideFoulDialog();
}

/* Called when NoRestartButton in the RestartDialog is clicked. */
function OnNoRestartButton(GFxClikWidget.EventData ev)
{
	SPC.SetRestart(-1);
	HideRestartDialog();
}

/* Called when YesRestartButton in the RestartDialog is clicked. */
function OnYesRestartButton(GFxClikWidget.EventData ev)
{
	SPC.SetRestart(1);
	HideRestartDialog();
}

function ShowGameOverDialog(string WinnerName)
{
	ActionScriptVoid("ASGameOverDialogShow");
	WinnerNameLbl.SetString("text", WinnerName@"Wins.");
}

function HideGameOverDialog()
{
	ActionScriptVoid("ASGameOverDialogHide");
	WinnerNameLbl.SetString("text", "");
}

/* List of each ClikWidget being used.
var GFxClikWidget MyChatInput, MyChatSendButton, MyChatLog;
var GFxClikWidget ShotPowerSldr, ShotAngleSldr, ShootBtn;
var GFxClikWidget FVRadioBtn, CBVRadioBtn, TVRadioBtn, STrLCheckBox;
var GFxClikWidget BallDistSldr, BallRotSldr;
var GFxClikWidget ReadyBtn, RestartBtn, QuitBtn;
var GFxClikWidget PlayerOneScoreLbl, PlayerTwoScoreLbl;
var GFxClikWidget playerOneTurnInd, playerTwoTurnInd; // Not a Clik Widget.
var GFxClikWidget SelectOnBallLbl, BallInHandLbl;
var GFxClikWidget PlayNextShotBtn, OpponentShootAgainBtn;
var GFxClikWidget NoRestartBtn, YesRestartBtn;
var GFxClikWidget WinnerNameLbl;
*/

/* Is called whenever a Widget is initialized and requests an InitCallback.
 *
 * @param WidgetName: The name of the Widget.
 *
 * @param WidgetPath: The ActionScript path of the Widget.
 *
 * @param Widget: The GFxObject representing the Widget.
 */
event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{    
    switch(WidgetName)
    {
        case ('chatInput'):
            MyChatInput = GFxClikWidget(Widget);
            MyChatInput.AddEventListener('CLIK_press', OnChat);
			`log("chatInput found!");
            break;
		case ('chatSendBtn'):
			MyChatSendButton = GFxClikWidget(Widget);
            MyChatSendButton.AddEventListener('CLIK_press', OnChatSend);
			`log("chatSendBtn found!");
			break;
		case ('chatLog'):
			MyChatLog = GFxClikWidget(Widget);
			`log("chatLog found!");
			break;
		case ('shotPowerSlider'):
			ShotPowerSldr = GFxClikWidget(Widget);
			ShotPowerSldr.AddEventListener('CLIK_change', OnShotPowerSliderChange);
			ShotPowerSldr.SetFloat("minimum", SnookerPlayerControllerProperties'TurretContent.SnookerPlayerControllerProperties'.MinShotPower);
			ShotPowerSldr.SetFloat("maximum", SnookerPlayerControllerProperties'TurretContent.SnookerPlayerControllerProperties'.MaxShotPower);
			ShotPowerSldr.SetFloat("value", SnookerPlayerControllerProperties'TurretContent.SnookerPlayerControllerProperties'.MinShotPower);
			`log("shotPowerSlider found!");
			break;
		case ('shotAngleSlider'):
			ShotAngleSldr = GFxClikWidget(Widget);
			ShotAngleSldr.AddEventListener('CLIK_change', OnShotAngleSliderChange);
			OldShotAngleSliderValue = ShotAngleSldr.GetFloat("value");
			`log("shotAngleSlider found!");
			break;
		case ('shootButton'):
			ShootBtn = GFxClikWidget(Widget);
			ShootBtn.AddEventListener('CLIK_press', OnShootButton);
			`log("shootButton found!");
			break;
		case ('freeViewRadioButton'):
			FVRadioBtn = GFxClikWidget(Widget);
			FVRadioBtn.AddEventListener('CLIK_click', OnFVRadioButton);
			`log("freeViewRadioButton found!");
			break;
		case ('cueBallViewRadioButton'):
			CBVRadioBtn = GFxClikWidget(Widget);
			CBVRadioBtn.AddEventListener('CLIK_click', OnCBVRadioButton);
			CBVRadioBtn.SetBool("disabled", true);
			`log("cueBallViewRadioButton found!");
			break;
		case ('topViewRadioButton'):
			TVRadioBtn = GFxClikWidget(Widget);
			TVRadioBtn.AddEventListener('CLIK_click', OnTVRadioButton);
			`log("topViewRadioButton found!");
			break;
		case ('distanceSlider'):
			BallDistSldr = GFxClikWidget(Widget);
			BallDistSldr.AddEventListener('CLIK_change', OnCVDistanceSliderChange);
			BallDistSldr.SetFloat("minimum", SnookerCameraProperties'TurretContent.SnookerCameraProperites'.CueViewMinDistance);
			BallDistSldr.SetFloat("maximum", SnookerCameraProperties'TurretContent.SnookerCameraProperites'.CueViewMaxDistance);
			BallDistSldr.SetFloat("value", SnookerCameraProperties'TurretContent.SnookerCameraProperites'.CueViewDistance);
			`log("distanceSlider found!");
			break;
		case ('angleSlider'):
			BallRotSldr = GFxClikWidget(Widget);
			BallRotSldr.AddEventListener('CLIK_change', OnCVAngleSliderChange);
			`log("angleSlider found!");
			break;
		case ('showTrajectoryCheckBox'):
			STrLCheckBox = GFxClikWidget(Widget);
			STrLCheckBox.AddEventListener('CLIK_click', OnTrLBoxClick);
			STrLCheckBox.SetBool("selected", true);
			`log("showTrajectoryCheckBox found!");
			break;
		case ('readyButton'):
			ReadyBtn = GFxClikWidget(Widget);
			ReadyBtn.AddEventListener('CLIK_click', OnReadyButton);
			`log("readyButton found!");
			break;
		case ('restartButton'):
			RestartBtn = GFxClikWidget(Widget);
			//RestartBtn.SetBool("visible", false);
			RestartBtn.AddEventListener('CLIK_click', OnRestartButton);
			`log("restartButton found!");
			break;
		case ('quitButton'):
			QuitBtn = GFxClikWidget(Widget);
			QuitBtn.AddEventListener('CLIK_click', OnQuitButton);
			`log("quitButton found!");
			break;
		case ('player1ScoreLabel'):
			PlayerOneScoreLbl = GFxClikWidget(Widget);
			PlayerOneScoreLbl.SetBool("visible", false);
			`log("player1ScoreLabel found!");
			break;
		case ('player2ScoreLabel'):
			PlayerTwoScoreLbl = GFxClikWidget(Widget);
			PlayerTwoScoreLbl.SetBool("visible", false);
			`log("player2ScoreLabel found!");
			break;	
		case ('p1TurnIndicator'):
			playerOneTurnInd = GFxClikWidget(Widget);
			playerOneTurnInd.SetBool("visible", false);
			`log("p1TurnIndicator found!");
			break;
		case ('p2TurnIndicator'):
			playerTwoTurnInd = GFxClikWidget(Widget);
			playerTwoTurnInd.SetBool("visible", false);
			`log("p2TurnIndicator found!");
			break;
		case ('selectOnBallLabel'):
			SelectOnBallLbl = GFxClikWidget(Widget);
			SelectOnBallLbl.SetBool("visible", false);
			`log("selectOnBallLabel found!");
			break;
		case ('ballInHandLabel'):
			BallInHandLbl = GFxClikWidget(Widget);
			BallInHandLbl.SetBool("visible", false);
			`log("ballInHandLabel found!");
			break;
		case ('PlayNextShotButton'):
			PlayNextShotBtn = GFxClikWidget(Widget);
			PlayNextShotBtn.AddEventListener('CLIK_click', OnPlayNextShotButton);
			`log("PlayNextShotButton found!");
			break;
		case ('OpponentShootAgainButton'):
			OpponentShootAgainBtn = GFxClikWidget(Widget);
			OpponentShootAgainBtn.AddEventListener('CLIK_click', OnOpponentShootAgainButton);
			`log("OpponentShootAgainButton found!");
			break;
		case ('noRestartButton'):
			NoRestartBtn = GFxClikWidget(Widget);
			NoRestartBtn.AddEventListener('CLIK_click', OnNoRestartButton);
			break;
		case ('yesRestartButton'):
			YesRestartBtn = GFxClikWidget(Widget);
			YesRestartBtn.AddEventListener('CLIK_click', OnYesRestartButton);
			break;
		case ('winnerNameLabel'):
			WinnerNameLbl = GFxClikWidget(Widget);
			break;
		default:
            break;
    }

    return true;
}

defaultproperties
{
	// Adds a binding for each relevant Widget.
    WidgetBindings.Add((WidgetName="chatInput",WidgetClass=class'GFxClikWidget'))
    WidgetBindings.Add((WidgetName="chatSendBtn",WidgetClass=class'GFxClikWidget'))
    WidgetBindings.Add((WidgetName="chatLog",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="shotPowerSlider",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="shotAngleSlider",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="shootButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="freeViewRadioButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="cueBallViewRadioButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="topViewRadioButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="distanceSlider",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="angleSlider",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="showTrajectoryCheckBox",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="readyButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="restartButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="quitButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="player1ScoreLabel",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="player2ScoreLabel",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="p1TurnIndicator",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="p2TurnIndicator",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="selectOnBallLabel",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="ballInHandLabel",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="PlayNextShotButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="OpponentShootAgainButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="yesRestartButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="noRestartButton",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="winnerNameLabel",WidgetClass=class'GFxClikWidget'))

    bIgnoreMouseInput = true;
    bCaptureInput = false;
	
	// The GFxMovie which acts as the HUD.
	MovieInfo = SwfMovie'TurretContent.SnookerHUD'
}