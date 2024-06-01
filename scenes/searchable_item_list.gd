extends VBoxContainer

var _item_dict: Dictionary
var _selected_item_key = null
signal item_selected(selected_item_key)  # Sends the "key" of the item that has been activated
signal item_activated(activated_item_key)  # Sends the "key" of the item that has been activated


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    %SearchLineEdit.text_changed.connect(self._on_search_line_edit_text_changed)
    %ItemList.item_activated.connect(self._on_item_list_item_activated)
    %ItemList.item_selected.connect(self._on_item_list_item_selected)


func get_selected_item_key() -> Variant:
    return self._selected_item_key


func change_item_dict(item_dict: Dictionary) -> void:
    self._item_dict = item_dict
    self._update_item_list(item_dict, self._get_search_string())


func search_bar_grab_focus() -> void:
    %SearchLineEdit.grab_focus()


func _get_search_string() -> String:
    return %SearchLineEdit.text


func is_anything_selected() -> bool:
    return true if self._selected_item_key else false


func _filter_item_dictionary(search_string: String, item_dict: Dictionary) -> Dictionary:
    "Filter 'item_dict' based on 'search_string'. If neither the key or the value of an 'item_dict' item contains 'search_string', then it gets filtered out."
    # If the search string is empty, return the whole item_dict
    if search_string.is_empty():
        return item_dict

    var filtered_dict := {}
    search_string = search_string.to_lower()

    for key in item_dict:
        var value = item_dict[key]
        if search_string in str(key).to_lower() or search_string in str(value).to_lower():
            filtered_dict[key] = value

    return filtered_dict


func _update_item_list(item_dict: Dictionary, search_string: String) -> void:
    %ItemList.clear()

    var filtered_dict := self._filter_item_dictionary(search_string, item_dict)
    for key in filtered_dict:
        var value = filtered_dict[key]
        var item_index1 = %ItemList.add_item(str(key))
        var item_index2 = %ItemList.add_item(str(value))

        # Set the key as metadata for both elements
        %ItemList.set_item_metadata(item_index1, key)
        %ItemList.set_item_metadata(item_index2, key)


func _on_item_list_item_activated(index: int) -> void:
    item_activated.emit(%ItemList.get_item_metadata(index))


func _on_item_list_item_selected(index: int) -> void:
    var selected_item_key = %ItemList.get_item_metadata(index)
    self._selected_item_key = selected_item_key
    item_selected.emit(selected_item_key)


func _on_search_line_edit_text_changed(new_text: String) -> void:
    self._update_item_list(self._item_dict, new_text)

    if not new_text.is_empty() and %ItemList.item_count > 0:
        %ItemList.select(1)
        %ItemList.item_selected.emit(1)  # Need to manually emit signal because select() does not emit it
