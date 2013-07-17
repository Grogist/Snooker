/* A Trigger Volume located in each Pocket. When it is Touched by a Ball the Pocket alerts the Game. */

class SnookerOffTableVolume extends TriggerVolume
	placeable
	ClassGroup(Snooker);

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local SnookerBall TouchedBall;
	local SnookerGame TheGame;
	
	TouchedBall = SnookerBall(Other);
	TheGame = SnookerGame(WorldInfo.Game);

	// If the touched object is a SnookerBall, and the Game is SnookerGame.
	if(TouchedBall != None && TheGame != None)
	{
		`log("Ball in Trigger");
		// Alerts TheGame that a Ball has been potted.
		TheGame.BallOffTable(TouchedBall);
	}
}

defaultproperties
{
}