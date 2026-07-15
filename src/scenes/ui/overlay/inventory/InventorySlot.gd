extends PanelContainer
class_name InventorySlot

@onready var icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel

var current_item: ItemData = null

func update_slot(item: ItemData, amount: int) -> void:
	current_item = item
	
	if item.size() > 0:
		icon.texture = item.icon[0]
	
	# Only show the number if amount > 1
	if amount > 1:
		amount_label.text = str(amount)
		amount_label.show()
	else:
		amount_label.hide()

func clear_slot() -> void:
	current_item = null
	icon.texture = null
	amount_label.hide()

func set_selected(is_selected: bool) -> void:
	$Highlight.visible = is_selected
	
	if current_item == null:
		return
	
	if is_selected:
		# select
		if current_item.icon.size() > 1:
			icon.texture = current_item.icon[1]
	else:
		#deselect
		if current_item.icon.size() > 0:
			icon.texture = current_item.icon[0]
			
