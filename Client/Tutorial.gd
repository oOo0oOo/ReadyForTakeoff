extends Node2D

var cur_page = 0

func _ready():
	cur_page = 0
	update_screen()


func update_screen():
	for i in range(0, 4):
		if cur_page == i:
			get_node('Page' + str(i)).show()
		else:
			get_node('Page' + str(i)).hide()
			
	if cur_page == 3:
		$NextButton.hide()
		$BackButton.hide()
		get_parent().finish_tutorial()
	
	else:
		$BackButton.show()
		$NextButton.show()
	
	if cur_page == 0:
		$BackButton.hide()


func _on_NextButton_button_up():
	cur_page += 1
	update_screen()


func _on_BackButton_button_up():
	cur_page -= 1
	update_screen()
