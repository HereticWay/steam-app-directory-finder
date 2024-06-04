class_name SteamApp
extends Object

var name := '<app_name>'
var id := -1
var install_dir_path := '<app_install_dir>'
var compatdata_dir_path := '<app_compatdata_dir>'


func _init(name_: String, id_: int, install_dir_path_: String, compatdata_dir_path_: String) -> void:
    self.name = name_
    self.id = id_
    self.install_dir_path = install_dir_path_
    self.compatdata_dir_path = compatdata_dir_path_
