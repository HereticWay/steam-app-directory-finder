extends Control

var steamapps_root := '/home/adam/.steam/root/steamapps/'
var steamapps_external := '/mnt/data/games/SteamLibrary/steamapps/'
var steam_apps: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    self.steam_apps.merge(_get_steam_apps_from_library_folder(steamapps_root))
    self.steam_apps.merge(_get_steam_apps_from_library_folder(steamapps_external))

    for steam_app in steam_apps.values():
        #var display_text := '%d: %s' % [steam_app.app_id, steam_app.app_name]
        #%SteamAppsItemList.add_item(display_text)
        %SteamAppsItemList.add_item(str(steam_app.id))
        %SteamAppsItemList.add_item(steam_app.name)

    %SteamAppsItemList.grab_focus()

    %SteamAppsItemList.item_selected.connect(_on_steam_apps_item_list_item_selected)
    %SteamAppsItemList.item_activated.connect(_on_steam_apps_item_list_item_activated)
    %OpenGameDirectoryButton.pressed.connect(_on_open_game_directory_button_pressed)
    %OpenCompatDataButton.pressed.connect(_on_open_compat_data_button_pressed)


func _get_steam_apps_from_library_folder(library_folder_path: String) -> Dictionary:
    var steam_apps: Dictionary = {}

    var dir = DirAccess.open(library_folder_path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir() and file_name.get_extension() == 'acf':
                var file_path := '%s/%s' % [dir.get_current_dir(), file_name]
                var steam_app := SteamApp.new(file_path)
                steam_apps[steam_app.id] = steam_app
            file_name = dir.get_next()
    else:
        print("An error occurred when trying to access the path.")

    return steam_apps


func _get_steam_app_by_item_list_index(index: int) -> SteamApp:
    if index % 2 != 0:
        index -= 1

    var item_text: String = %SteamAppsItemList.get_item_text(index)
    var app_id := int(item_text.split(': ')[0])

    return self.steam_apps[app_id]


func _on_steam_apps_item_list_item_selected(index: int) -> void:
    var steam_app := _get_steam_app_by_item_list_index(index)

    %AppNameLineEdit.text = steam_app.name
    %AppIdLineEdit.text = str(steam_app.id)
    %OpenGameDirectoryButton.disabled = false
    %OpenCompatDataButton.disabled = false


func _on_steam_apps_item_list_item_activated(index: int) -> void:
    var steam_app := _get_steam_app_by_item_list_index(index)

    OS.shell_show_in_file_manager(steam_app.install_dir_path)


func _on_open_game_directory_button_pressed() -> void:
    var list_item_index: int = %SteamAppsItemList.get_selected_items()[0]
    var steam_app := _get_steam_app_by_item_list_index(list_item_index)

    OS.shell_show_in_file_manager(steam_app.install_dir_path)


func _on_open_compat_data_button_pressed() -> void:
    var list_item_index: int = %SteamAppsItemList.get_selected_items()[0]
    var steam_app := _get_steam_app_by_item_list_index(list_item_index)

    OS.shell_show_in_file_manager(steam_app.compatdata_dir_path)
