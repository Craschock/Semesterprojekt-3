extends MarginContainer
class_name InventoryUI

## Player Inventory data
var inventory_component: InventoryComponent

@onready var slot_container: HBoxContainer = $HBoxContainer
var slots: Array[InventorySlot] = []

func _ready() -> void:
	for child in slot_container.get_children():
		if child is InventorySlot:
			slots.append(child)
	
	await get_tree().process_frame
	
	if PlayerManager.player:
		inventory_component = PlayerManager.player.inventory_component
	
	if inventory_component:
		inventory_component.max_slots = slots.size()
		
		_initialize_ui()
		
		# Listen for changes
		inventory_component.inventory_changed.connect(_on_inventory_changed)
		inventory_component.active_slot_changed.connect(_on_active_slot_changed)

func _initialize_ui() -> void:
	for slot in slots:
		slot.clear_slot()
		slot.set_selected(false)
		
	_update_all_slots()

func _on_inventory_changed(_item: ItemData, _amount: int) -> void:
	_update_all_slots()

func _on_active_slot_changed(active_index: int) -> void:
	# Loop all slots to highlight selected one
	for i in range(slots.size()):
		slots[i].set_selected(i == active_index)

func _update_all_slots() -> void:
	# Clear everything
	for slot in slots:
		slot.clear_slot()
		
	# Insert based on current inventory
	var items = inventory_component.contents.keys()
	
	for i in range(items.size()):
		if i < slots.size():
			var item = items[i]
			var amount = inventory_component.contents[item]
			slots[i].update_slot(item, amount)
			
			if inventory_component.active_slot_index == i:
				slots[i].set_selected(true)
