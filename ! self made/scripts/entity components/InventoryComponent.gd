extends Node
class_name InventoryComponent

signal inventory_changed(item: ItemData, new_amount: int)
signal active_slot_changed(slot_index: int)

@export var max_slots: int = 5

# Key = ItemData resource, Value = integer (amount)
var contents: Dictionary = {}
# -1 = no item selected
var active_slot_index: int = -1



# Adds Item to Inventory
# Returns the amount of items that were picked up (int)
# So 0 means no items to subtract ferom the item
# and 5 means the player picked up 5 of itemtype,
# meaning the item needs to subtract 5. 
# If depleted, the item deletes itself
func add_item(item: ItemData, amount: int = 1) -> int:
	# Reject item if new Item AND Inventory full
	if not contents.has(item) and contents.size() >= max_slots:
		return 0
		
	# get current amount (returns 0 if empty)
	var current_amount = contents.get(item, 0)
	
	# get how much space is left in slot
	var space_left = item.max_stack_size - current_amount
	
	# get how much we can pick up of the item
	var amount_to_add = mini(amount, space_left)
	
	# If no space left, 0
	if amount_to_add <= 0:
		return 0
	
	# Add the amounmt to the currently owned amount
	contents[item] = current_amount + amount_to_add
	
	inventory_changed.emit(item, contents[item])
	return amount_to_add

# Removes Item to Inventory
func remove_item(item: ItemData, amount: int = 1) -> void:
	if not contents.has(item):
		return
		
	contents[item] -= amount
	
	if contents[item] <= 0:
		contents.erase(item)
		inventory_changed.emit(item, 0)
	else:
		inventory_changed.emit(item, contents[item])

# Check for crafting or doors that require key (Not implemented, just placeholder for now)
func has_item(item: ItemData, amount: int = 1) -> bool:
	return contents.has(item) and contents[item] >= amount

# Switches/select/deselect slots
func toggle_slot(index: int) -> void:
	if active_slot_index == index:
		active_slot_index = -1 # Deselect
	else:
		active_slot_index = index # Select new slot        
	active_slot_changed.emit(active_slot_index)

# returns ItemData currently held
func get_active_item() -> ItemData:
	if active_slot_index == -1:
		return null
	
	var items = contents.keys()
	if active_slot_index < items.size():
		return items[active_slot_index]
	
	return null
