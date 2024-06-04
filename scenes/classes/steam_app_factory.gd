class_name SteamAppFactory
extends Object

static var _app_name_regex := RegEx.create_from_string('(?<="name"\\t\\t")[^"]+')
static var _app_install_dir_regex := RegEx.create_from_string('(?<="installdir"\\t\\t")[^"]+')


static func from_acf_file(acf_file_path: String) -> SteamApp:
    var acf_file_base_dir_path := acf_file_path.get_base_dir()
    var acf_file := FileAccess.open(acf_file_path, FileAccess.READ)
    var acf_file_content := acf_file.get_as_text(true)

    var name := _extract_app_name(acf_file_content)
    var id := _extract_app_id(acf_file_path)

    var app_install_dir := _extract_app_install_dir(acf_file_content)
    var install_dir_path := '%s/common/%s' % [acf_file_base_dir_path, app_install_dir]
    var compatdata_dir_path := '%s/compatdata/%d' % [acf_file_base_dir_path, id]
    return SteamApp.new(name, id, install_dir_path, compatdata_dir_path)


static func _extract_app_name(acf_file_content: String) -> String:
    var result := _app_name_regex.search(acf_file_content)
    return result.get_string()


static func _extract_app_install_dir(acf_file_content: String) -> String:
    var result := _app_install_dir_regex.search(acf_file_content)
    return result.get_string()


static func _extract_app_id(acf_file_path: String) -> int:
    var app_id_str := acf_file_path.get_file().get_basename().split('_')[1]
    return int(app_id_str)


static func from_vdf_dict(vdf_dict: Dictionary) -> SteamApp:
    var name = vdf_dict['AppName']
    var id = vdf_dict['appid']
    var install_dir_path = vdf_dict['Exe'].replace('\"', '').get_base_dir()

    var os_name := OS.get_name()
    var compatdata_dir_path = ''
    if os_name == 'Windows':
        compatdata_dir_path = 'C:\\Program Files (x86)\\Steam\\steamapps\\compatdata\\%d' % id
    elif os_name == 'Linux':
        compatdata_dir_path = OS.get_environment("HOME") + '/.steam/root/steamapps/compatdata/%d' % id

    return SteamApp.new(name, id, install_dir_path, compatdata_dir_path)
