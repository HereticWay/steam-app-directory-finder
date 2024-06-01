class_name SteamApp
extends Object

var name := '<app_name>'
var id := -1
var install_dir_path := '<app_install_dir>'
var compatdata_dir_path := '<app_compatdata_dir>'


var _app_name_regex := RegEx.create_from_string('(?<="name"\\t\\t")[^"]+')
var _app_install_dir_regex := RegEx.create_from_string('(?<="installdir"\\t\\t")[^"]+')


func _init(acf_file_path: String) -> void:
    var acf_file_base_dir_path := acf_file_path.get_base_dir()
    var acf_file := FileAccess.open(acf_file_path, FileAccess.READ)
    var acf_file_content := acf_file.get_as_text(true)

    self.name = _extract_app_name(acf_file_content)
    self.id = _extract_app_id(acf_file_path)

    var app_install_dir := _extract_app_install_dir(acf_file_content)
    self.install_dir_path = '%s/common/%s' % [acf_file_base_dir_path, app_install_dir]
    self.compatdata_dir_path = '%s/compatdata/%d' % [acf_file_base_dir_path, self.id]


func _extract_app_name(acf_file_content: String) -> String:
    var result := _app_name_regex.search(acf_file_content)
    return result.get_string()


func _extract_app_install_dir(acf_file_content: String) -> String:
    var result := _app_install_dir_regex.search(acf_file_content)
    return result.get_string()


func _extract_app_id(acf_file_path: String) -> int:
    var app_id_str := acf_file_path.get_file().get_basename().split('_')[1]
    return int(app_id_str)
