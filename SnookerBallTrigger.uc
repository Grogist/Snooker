// Each Ball has its own associated SnookerBallTrigger. SnookerBallTrigger is used to detect collisions
//  between the CueBall and other SnookerBalls. Touch events don't seem to occur when KActors touch
//  other KActors. Touch events are unreliable when KActors touch Triggers. Thus Trigger need to touch
//  other Triggers to do these detections accurately.
//  This method of collision detection is painfully poor, be seemingly necessary.
//  THIS METHOD DOESN'T WORK! WAAAHH!

class SnookerBallTrigger extends Trigger;

var SnookerBall BallOwner;

function RegisterBallOwner(SnookerBall ball)
{
	BallOwner = ball;
}

event Tick(float DeltaTime)
{
	/*if(TheBall != none)
		SetLocation(TheBall.Location);*/
	
	super.Tick(DeltaTime);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local SnookerGame TheGame;
	local SnookerBallTrigger TouchedTrigger;
	local SnookerBall TouchedBall;
	
	super.Touch(Other,OtherComp,HitLocation,HitNormal);
	
	if(SnookerCueBall(BallOwner) == None)
		return;
	
	//`log("Touch Owner is SnookerCueBall");
	
	TheGame = SnookerGame(WorldInfo.Game);
	TouchedTrigger = SnookerBallTrigger(Other);
	TouchedBall = SnookerBall(Other);
	
	if(TheGame == None)
		return;
		
	if(TouchedTrigger != None)//`log("SnookerBallTrigger Touch");
		TheGame.CueBallTouch(TouchedTrigger.BallOwner);
	else if(TouchedBall != None)
		TheGame.CueBallTouch(TouchedBall);
}

event UnTouch( Actor Other )
{
	local SnookerGame TheGame;
	local SnookerBallTrigger TouchedTrigger;
	local SnookerBall TouchedBall;
	
	super.UnTouch(Other);
	
	if(SnookerCueBall(BallOwner) == None)
		return;
	
	//`log("Touch Owner is SnookerCueBall");
	
	TheGame = SnookerGame(WorldInfo.Game);
	TouchedTrigger = SnookerBallTrigger(Other);
	TouchedBall = SnookerBall(Other);
	
	if(TheGame == None)
		return;
		
	if(TouchedTrigger != None)//`log("SnookerBallTrigger Touch");
		TheGame.CueBallTouch(TouchedTrigger.BallOwner);
	else if(TouchedBall != None)
		TheGame.CueBallTouch(TouchedBall);
}

defaultproperties
{
	Begin Object NAME=CollisionCylinder
		CollideActors=true
		CollisionRadius=+0016.000000
		CollisionHeight=+0032.000000
		bAlwaysRenderIfSelected=true
	End Object
	
	bNoEncroachCheck=false
	
	bAlwaysRelevant=true
	bSkipActorPropertyReplication=false
	bReplicateRigidBodyLocation=true
	bUpdateSimulatedPosition=true
	bReplicateMovement=true
	bForceNetUpdate=true
	//NetPriority=8
	//NetUpdateFrequency=200
	RemoteRole=ROLE_SimulatedProxy
	
	//bTearOff=true
	bHidden=false
	bStatic=false
	bNoDelete=false
}