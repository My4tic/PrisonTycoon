## TutorialPanel - Panel komunikatów tutoriala
## Wyświetla instrukcje dla gracza podczas kampanii
class_name TutorialPanel
extends PanelContainer

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton

var _current_message_id: String = ""


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_connect_signals()
	visible = false


func _connect_signals() -> void:
	Signals.tutorial_message_shown.connect(_on_tutorial_message)

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_tutorial_message(message_id: String) -> void:
	_current_message_id = message_id

	# Pobierz aktualny krok tutoriala
	if CampaignManager.current_chapter and CampaignManager.tutorial_active:
		var step_index := CampaignManager.current_tutorial_step
		var steps: Array = CampaignManager.current_chapter.tutorial_steps

		if step_index < steps.size():
			var step: Dictionary = steps[step_index]
			var message: String = step.get("message", "")

			if message_label:
				message_label.text = message

			visible = true

			# Zapauzuj grę podczas tutoriala
			GameManager.pause_game()


func _on_continue_pressed() -> void:
	visible = false

	# Odpauzuj grę
	GameManager.unpause_game()

	# Przejdź do następnego kroku
	CampaignManager.advance_tutorial()


# =============================================================================
# API PUBLICZNE
# =============================================================================
func show_message(message: String) -> void:
	if message_label:
		message_label.text = message
	visible = true


func hide_panel() -> void:
	visible = false
