extends CharacterBody3D

####### PLAYER CONTROLLER SETTINGS #######
const SPEED = 6.5
const SENSITIVITY = .008
####### PLAYER CONTROLLER SETTINGS #######

####### CAMERA BOB SETTINGS #######
const BOB_FREQ = 2.0
const BOB_AMP = .08
var t_bob = .0
var _was_on_floor_last_frame = false
var _snapped_to_stairs_last_frame = false
@onready var head = $Head
@onready var camera = $Head/Camera3D
####### CAMERA BOB SETTINGS #######

####### HP SETTINGS #######
var health = 100
var health_max = 100
var health_min = 0
@onready var hpBarRight = $Head/Camera3D/health_bar/health_right
@onready var hpBarLeft = $Head/Camera3D/health_bar/health_left
@onready var hpBarAmount = $Head/Camera3D/health_bar/health_prec
####### HP SETTINGS #######

@onready var pistolSprite = $Head/Camera3D/PISTOLET
@onready var pricelSprite = $Head/Camera3D/PRICEL
@onready var ammoSprite = $Head/Camera3D/AMMO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hpBarAmount.text = "[center]%s[/center]" % str(health_max)
	hpBarRight.value = health_max
	hpBarLeft.value = health_max
	
func _process(delta: float) -> void:
	## health bars update ##
	hpBarRight.value = health
	hpBarLeft.value = health
	hpBarAmount.text = "[center]%s[/center]" % str(health)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	if event.is_action_pressed("escape"):
		get_tree().quit()
		

func _snap_down_to_stairs_check():
	var did_snap = false
	if not is_on_floor() and velocity.y <= 0 and (_was_on_floor_last_frame or _snapped_to_stairs_last_frame) and $StairsBelowRayCast3D.is_colliding():
		var body_test_result = PhysicsTestMotionResult3D.new()
		var params = PhysicsTestMotionParameters3D.new()
		var max_step_down = -0.5
		params.from = self.global_transform
		params.motion = Vector3(0,max_step_down,0)
		if PhysicsServer3D.body_test_motion(self.get_rid(), params, body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true

	_was_on_floor_last_frame = is_on_floor()
	_snapped_to_stairs_last_frame = did_snap
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = .0
		velocity.z = .0
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	move_and_slide()
	_snap_down_to_stairs_check()
	
	if Input.is_action_just_pressed("damage"):
		_healthManagment(-10)
		
func _healthManagment(amount):
	if (health + amount != health_min):
		health += amount
	else:
		health = 0
		_deathPlayer()

func _deathPlayer():
	pistolSprite.visible = not pistolSprite.visible
	pricelSprite.visible = not pricelSprite.visible
	ammoSprite.visible = not ammoSprite.visible
	## Здесь добавить спрайт смерти визибл ##
