class SnookerMouseInterfacePlayerInput extends PlayerInput;

var PrivateWrite IntPoint MousePosition;
var SnookerHUD HUD;
var float HUDX, HUDY;

/* Gets and sets the height and width of the HUD movie. */
function GetHUDSize()
{
	HUD = SnookerHUD(myHUD);
	HUDX = HUD.HUDMovieSize.GetFloat("width");
	HUDY = HUD.HUDMovieSize.GetFloat("height");
}

/* return: the position of the mouse. */
function Vector2D GetMousePosition()
{
	local Vector2D Position;
	
	Position.X = MousePosition.X;
	Position.Y = MousePosition.Y;
	
	return Position;
}

/* Sets the Mouse Position */
function SetMousePosition(int X, int Y)
{
	GetHUDSize();
	
	if(myHUD != None)
	{
		MousePosition.X = Clamp(X, 0, HUDX);
		MousePosition.Y = Clamp(Y, 0, HUDY);
	}
}

defaultproperties
{
}