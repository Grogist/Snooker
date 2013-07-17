/* Used in an Archetype detailing Cue's properties. */
class SnookerCueProperties extends Object
	ClassGroup(Snooker)
	HideCategories(Object);

// Default Distance to the Cue Ball.
var(SnookerCue) float	DefaultDistance;
// Minimum Distance to the Cue Ball.
var(SnookerCue) float	MinDistance;
/* When Player shoots the Cue Ball, the Cue plays a short
   "animation" before the forces are applied to the Cue Ball. */
var(SnookerCue) float	ShotAnimationTime; // In Seconds.

defaultproperties
{
	DefaultDistance=30.f
	MinDistance=4.0f
	ShotAnimationTime=0.1f
}