extends Control

var steamapps_root := '/home/adam/.steam/root/steamapps/'
var steamapps_external := '/mnt/data/games/SteamLibrary/steamapps/'
var steam_apps: Dictionary = {}

var _library_folders_regex := RegEx.create_from_string('(?<="path"\\t\\t")[^"]+')


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    for library_folder in _get_steam_library_folders():
        self.steam_apps.merge(_get_steam_apps_from_library_folder(library_folder))

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
    %AppNameLineEdit.focus_entered.connect(_on_app_name_line_edit_focus_entered)
    %AppIdLineEdit.focus_entered.connect(_on_app_id_line_edit_focus_entered)


func _get_steam_library_folders() -> Array[String]:
    var os_name := OS.get_name()
    var steam_library_folders_config_path := ''

    if os_name == 'Windows':
        steam_library_folders_config_path = 'C:\\Program Files (x86)\\Steam\\steamapps\\libraryfolders.vdf'
    elif os_name == 'Linux':
        steam_library_folders_config_path = OS.get_environment("HOME") + '/.steam/root/steamapps/libraryfolders.vdf'

    var library_folders_config_file := FileAccess.open(steam_library_folders_config_path, FileAccess.READ)
    var library_folders_config_content := library_folders_config_file.get_as_text()

    var steam_library_folders: Array[String] = []
    for folder in _library_folders_regex.search_all(library_folders_config_content):
        print(folder.get_string())
        steam_library_folders.push_back(folder.get_string())

    return steam_library_folders


func _get_steam_apps_from_library_folder(library_folder_path: String) -> Dictionary:
    var steam_apps: Dictionary = {}

    var dir = DirAccess.open(library_folder_path + '/steamapps')
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

    if OS.get_name() == 'Linux':
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


func _on_app_name_line_edit_focus_entered() -> void:
    if not %SteamAppsItemList.is_anything_selected():
        return

    var list_item_index: int = %SteamAppsItemList.get_selected_items()[0]
    var steam_app := _get_steam_app_by_item_list_index(list_item_index)

    DisplayServer.clipboard_set(steam_app.name)
    ToastParty.show({
        "text": "Text copied to clipboard!",           # Text (emojis can be used)
        "bgcolor": Color(0, 0, 0, 0.7),     # Background Color
        "color": Color(1, 1, 1, 1),         # Text Color
        "gravity": "bottom",                   # top or bottom
        "direction": "center",               # left or center or right
    })


func _on_app_id_line_edit_focus_entered() -> void:
    if not %SteamAppsItemList.is_anything_selected():
        return

    var list_item_index: int = %SteamAppsItemList.get_selected_items()[0]
    var steam_app := _get_steam_app_by_item_list_index(list_item_index)

    DisplayServer.clipboard_set(String.num(steam_app.id))
    ToastParty.show({
        "text": "Text copied to clipboard!",           # Text (emojis can be used)
        "bgcolor": Color(0, 0, 0, 0.7),     # Background Color
        "color": Color(1, 1, 1, 1),         # Text Color
        "gravity": "bottom",                   # top or bottom
        "direction": "center",               # left or center or right
    })
