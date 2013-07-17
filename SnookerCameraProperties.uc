/* Used as an Archetype detailing the Camera's properties. */

class SnookerCameraProperties extends Object
	ClassGroup(Snooker)
	HideCategories(Object);

/**** TOP VIEW ****/
// Where the Camera is looking.
var(SnookerCamera) Rotator TopViewRotation;
// Where the Camera is located.
var(SnookerCamera) Vector  TopViewPosition;
/**** CUE VIEW ****/
// How far the Camera is from the Cue Ball.
var(SnookerCamera) Float   CueViewDistance;
// (In Polar Coordinates) What is the Rotation of the Camera relative to the Cue Ball.
var(SnookerCamera) Float   CueViewRotation;
// How far about the Cue Ball the Camera is.
var(SnookerCamera) Float   CueViewZOffset;
// Minimum distance from the Cue Ball.
var(SnookerCamera) Float   CueViewMinDistance;
// Maximum distance from the Cue Ball.
var(SnookerCamera) Float   CueViewMaxDistance;

defaultproperties
{
	CueViewZOffset = 800.f
	CueViewDistance = 500.f
	CueViewRotation = 180.f
	CueViewMinDistance = 100.f
	CueViewMaxDistance = 1500.0f
}