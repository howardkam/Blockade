extends CharacterBody2D

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var move_speed: float = 500.0
@export var fire_rate: float = 0.07

const WORLD_LIMIT_MIN = -3000.0
const WORLD_LIMIT_MAX = 3000.0

var can_shoot: bool = true
var shoot_timer: float = 0.0
var score: int = 0

@onready var score_label: Label = $UI/ScoreLabel

func _ready():
	update_score_ui()

func add_score(amount: int = 10):
	score += amount
	update_score_ui()

func update_score_ui():
	if score_label:
		score_label.text = str(score)

func _physics_process(delta):
	# 1. Handle Diagonal Movement
	var move_dir = Vector2.ZERO
	move_dir.x = Input.get_axis("left", "right")
	move_dir.y = Input.get_axis("up", "down")
	
	velocity = move_dir.normalized() * move_speed
	move_and_slide()

	# Clamp player position within world limits
	global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)
	global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	# 2. Handle Rapid & Diagonal Shooting
	var shoot_dir = Vector2.ZERO
	shoot_dir.x = Input.get_axis("shootleft", "shootright")
	shoot_dir.y = Input.get_axis("shootup", "shootdown")

	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			can_shoot = true

	if shoot_dir != Vector2.ZERO and can_shoot:
		fire_bullet(shoot_dir.normalized())
		can_shoot = false
		shoot_timer = fire_rate

func fire_bullet(dir: Vector2):
	var bullet = bullet_scene.instantiate()
	
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.rotation = dir.angle()
	
	get_tree().current_scene.add_child(bullet)
