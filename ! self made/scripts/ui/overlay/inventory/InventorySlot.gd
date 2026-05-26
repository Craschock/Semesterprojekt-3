extends PanelContainer
class_name InventorySlot

@onready var icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel

func update_slot(item: ItemData, amount: int) -> void:
	icon.texture = item.icon
	
	# Only show the number if amount > 1
	if amount > 1:
		amount_label.text = str(amount)
		amount_label.show()
	else:
		amount_label.hide()

func clear_slot() -> void:
	icon.texture = null
	amount_label.hide()

func set_selected(is_selected: bool) -> void:
	$Highlight.visible = is_selected
