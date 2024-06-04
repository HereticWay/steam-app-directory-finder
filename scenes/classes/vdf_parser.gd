class_name VDFParser
extends Object
# Ported from https://github.com/Skizzium/binary-vdf-parser/tree/main


static func _get_string(buffer: PackedByteArray, offset: int):
    var string_end_offset = buffer.size()
    for i in range(offset, buffer.size()):
        string_end_offset = i
        if buffer[i] == 0x00:
            break

    var string := buffer.slice(offset, string_end_offset).get_string_from_utf8()
    return {'string': string, 'length': string_end_offset - offset}


static func _get_number(buffer: PackedByteArray, offset: int):
    return buffer.decode_u32(offset)


static func _get_property(buffer: PackedByteArray, offset: int):
    match buffer[offset]:
        # Property containing object (of more properties)
        0x00:
            offset += 1 # Skip newmap byte

            # Read key name
            var key_info = _get_string(buffer, offset)
            var key = key_info['string']
            var key_length = key_info['length']
            offset += key_length + 1 # String length + null terminator

            # Get properties in value
            var property := {'key': key, 'value': {}}
            while buffer[offset] != 0x08:
                var property_info = _get_property(buffer, offset)
                property['value'][property_info['property']['key']] = property_info['property']['value']
                offset = property_info['offset']

            offset += 1
            return {'offset': offset, 'property': property}

        # Property containing string
        0x01:
            offset += 1
            var key_info = _get_string(buffer, offset)
            var key = key_info['string']
            var key_length = key_info['length']
            offset += key_length + 1

            var value_info = _get_string(buffer, offset)
            var value = value_info['string']
            var value_length = value_info['length']
            offset += value_length + 1

            var property = { 'key': key, 'value': value }
            return { 'offset': offset, 'property': property }

        # Property containing number
        0x02:
            offset += 1
            var key_info = _get_string(buffer, offset)
            var key = key_info['string']
            var key_length = key_info['length']
            offset += key_length + 1

            var value = _get_number(buffer, offset)
            offset += 4

            var property = { 'key': key, 'value': value }
            return { 'offset': offset, 'property': property }

        # Something went wrong
        _:
            printerr('Error: Unknown type (%X)' % buffer[offset])

static func load_vdf(vdf_file_path: String) -> Dictionary:
    var file := FileAccess.open(vdf_file_path, FileAccess.READ)
    file.big_endian = false  # VDF files are little-endian

    var buffer := file.get_buffer(file.get_length())
    var offset := 0
    var result_dict := {}

    while offset < buffer.size():
        var property_info = _get_property(buffer, offset)
        var property = property_info['property']
        var key_value = {
            property['key']: property['value']
        }

        result_dict.merge(key_value)
        offset += property_info['offset']

        if offset == (buffer.size() - 1):
            break

    return result_dict


#func _main(argv, data):
    #var result_dict = load_vdf('/home/adam/.steam/root/userdata/186177082/config/shortcuts.vdf')
    #print(result_dict)
