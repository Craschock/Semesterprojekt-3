extends Node
class_name InventoryComponent

# Emitted future UI
signal inventory_changed(item: ItemData, new_amount: int)

# The actual backpack. 
# Key = ItemData resource, Value = integer (amount)
var contents: Dictionary = {}

# Functions

# Adds Item to Inventory
func add_item(item: ItemData, amount: int = 1) -> void:
	if contents.has(item):
		contents[item] += amount
	else:
		contents[item] = amount
		
	# Cap at max stack size
	if contents[item] > item.max_stack_size:
		contents[item] = item.max_stack_size
		
	inventory_changed.emit(item, contents[item])

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
	
	
