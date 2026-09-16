extends CharacterBody2D 

# --- EXPORT VARIABLES ---
@export var interact_type: String = "restaurant" 
@export var wait_time: float = 1.0

# --- NODE REFERENCES ---
@onready var sprite = $Sprite2D
@onready var dialog_bubble = $DialogBubble
@onready var quest_label = $DialogBubble/Panel/QuestLabel
@onready var timer = $Timer
@onready var interaction_area = $Area2D # Area2D child node for trigger detection

var has_triggered: bool = false 
var player_ref: Node2D = null 

func _ready():
	timer.wait_time = wait_time
	timer.one_shot = true
	
	# Connect signals to child Area2D
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	timer.timeout.connect(_on_timer_timeout)
	dialog_bubble.visible = false

# --- PLAYER ENTERED AREA ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body 
		has_triggered = false
		timer.start() 

# --- PLAYER EXITED AREA ---
func _on_body_exited(body):
	if body == player_ref:
		timer.stop() 
		player_ref = null
		has_triggered = false
		dialog_bubble.visible = false 

# --- TIMER TIMEOUT ---
func _on_timer_timeout():
	if player_ref != null:
		has_triggered = true
		update_dialog_from_manager() 
		show_dialogue()

# --- RETRIEVE RESTAURANT QUEST FROM CACHE ---
func update_dialog_from_manager():
	if Globals.cache.has("quests"):
		var all_quests = Globals.cache["quests"]
		var found_quest_text = ""
		
		for q in all_quests:
			if q.get("category") == "restaurant" and q.get("type") == "daily":
				found_quest_text = q.get("description", "")
				break
		
		if found_quest_text != "":
			quest_label.text = found_quest_text
		else:
			quest_label.text = "We're out of specials. Try again later!"
	else:
		quest_label.text = "Menu is loading..."

func show_dialogue():
	dialog_bubble.visible = true

func _process(_delta):
	if player_ref != null and not has_triggered:
		flip_towards_player()

func flip_towards_player():
	if player_ref.global_position.x < global_position.x:
		sprite.flip_h = false 
	else:
		sprite.flip_h = true
