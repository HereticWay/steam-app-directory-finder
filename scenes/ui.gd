extends Control


var _steam_apps: Dictionary = {}
var _library_folders_regex := RegEx.create_from_string('(?<="path"\\t\\t")[^"]+')


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    for library_folder in _get_steam_library_folders():
        self._steam_apps.merge(self._get_steam_apps_from_library_folder(library_folder))

    for shortcuts_vdf_path in _get_steam_shortcuts_vdf_paths():
        self._steam_apps.merge(get_steam_apps_from_shortcuts_vdf_file(shortcuts_vdf_path))

    var steam_apps_item_dict := {}
    for steam_app in self._steam_apps.values():
        steam_apps_item_dict[steam_app.id] = steam_app.name

    %SteamAppsItemList.change_item_dict(steam_apps_item_dict)
    %SteamAppsItemList.search_bar_grab_focus()

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
                var acf_file_path := '%s/%s' % [dir.get_current_dir(), file_name]
                var steam_app := SteamAppFactory.from_acf_file(acf_file_path)
                steam_apps[steam_app.id] = steam_app
            file_name = dir.get_next()
    else:
        print("An error occurred when trying to access the path.")

    return steam_apps


func _get_steam_shortcuts_vdf_paths() -> Array[String]:
    var os_name := OS.get_name()
    var userdata_directory := ''

    #/home/adam/.steam/root/userdata/186177082/config/shortcuts.vdf
    if os_name == 'Windows':
        userdata_directory = 'C:\\Program Files (x86)\\Steam\\userdata'
    elif os_name == 'Linux':
        userdata_directory = OS.get_environment("HOME") + '/.steam/root/userdata'

    var shortcuts_vdf_paths: Array[String] = []
    var dir := DirAccess.open(userdata_directory)
    if dir:
        dir.list_dir_begin()
        var dir_name = dir.get_next()
        while dir_name != "":
            if dir.current_is_dir():
                var vdf_file_path := '%s/%s/config/shortcuts.vdf' % [dir.get_current_dir(), dir_name]
                if FileAccess.file_exists(vdf_file_path):
                    shortcuts_vdf_paths.push_back(vdf_file_path)
            dir_name = dir.get_next()
    else:
        print("An error occurred when trying to access directory: %s" % userdata_directory)

    return shortcuts_vdf_paths


func get_steam_apps_from_shortcuts_vdf_file(shortcuts_vdf_file_path: String) -> Dictionary:
    var vdf_dict := VDFParser.load_vdf(shortcuts_vdf_file_path)
    var shortcuts = vdf_dict['shortcuts']

    var steam_apps := {}
    for shortcut in shortcuts:
        var steam_app := SteamAppFactory.from_vdf_dict(shortcuts[shortcut])
        steam_apps[steam_app.id] = steam_app

    return steam_apps

func _on_steam_apps_item_list_item_selected(key: Variant) -> void:
    var steam_app: SteamApp = self._steam_apps[key]

    %AppNameLineEdit.text = steam_app.name
    %AppIdLineEdit.text = str(steam_app.id)
    %OpenGameDirectoryButton.disabled = false

    if OS.get_name() == 'Linux':
        %OpenCompatDataButton.disabled = false


func _on_steam_apps_item_list_item_activated(activated_item_key: Variant) -> void:
    var steam_app: SteamApp = self._steam_apps[activated_item_key]

    OS.shell_show_in_file_manager(steam_app.install_dir_path)


func _on_open_game_directory_button_pressed() -> void:
    var selected_item_key = %SteamAppsItemList.get_selected_item_key()
    var steam_app: SteamApp = self._steam_apps[selected_item_key]

    OS.shell_show_in_file_manager(steam_app.install_dir_path)


func _on_open_compat_data_button_pressed() -> void:
    var selected_item_key = %SteamAppsItemList.get_selected_item_key()
    var steam_app: SteamApp = self._steam_apps[selected_item_key]

    OS.shell_show_in_file_manager(steam_app.compatdata_dir_path)


func _on_app_name_line_edit_focus_entered() -> void:
    if not %SteamAppsItemList.is_anything_selected():
        return

    var selected_item_key = %SteamAppsItemList.get_selected_item_key()
    var steam_app: SteamApp = self._steam_apps[selected_item_key]

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

    var selected_item_key = %SteamAppsItemList.get_selected_item_key()
    var steam_app: SteamApp = self._steam_apps[selected_item_key]

    DisplayServer.clipboard_set(String.num(steam_app.id))
    ToastParty.show({
        "text": "Text copied to clipboard!",           # Text (emojis can be used)
        "bgcolor": Color(0, 0, 0, 0.7),     # Background Color
        "color": Color(1, 1, 1, 1),         # Text Color
        "gravity": "bottom",                   # top or bottom
        "direction": "center",               # left or center or right
    })
