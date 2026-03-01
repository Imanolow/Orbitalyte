extends Node
## Global physics configuration constants.

class_name PhysicsConfig

const GAP: float = 13.0					# Distance from planet surface to ship center
const SAFE: float = 8.0					# Max landing speed
const TMAX: int = 55					# Trail max length
const LAUNCH_BASE: float = 0.8			# Min launch velocity
const LAUNCH_MAX: float = 10.0			# Max launch velocity range (was 6.5, increased to allow crashing)
const MAX_SPEED: float = 18.0			# Max ship velocity
const GRAVITY_LIMIT: float = 2500.0		# Max gravity value
