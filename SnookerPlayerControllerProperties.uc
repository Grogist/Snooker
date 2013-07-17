/* Used as an Archetype to detail properties of the Player Controller. */

class SnookerPlayerControllerProperties extends Object
	ClassGroup(Snooker)
	HideCategories(Object);

var(SnookerPlayer) float MinShotPower;	
var(SnookerPlayer) float MaxShotPower;
// The increment shot power changes by.
var(SnookerPlayer) float ShotPowerIncrement;

defaultproperties
{
	MinShotPower=0
	MaxShotPower=100
	ShotPowerIncrement=10
}