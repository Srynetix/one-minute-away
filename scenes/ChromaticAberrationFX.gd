extends ColorRect
class_name GameChromaticAberrationFX

export var enabled := true setget _set_enabled
export var amount := 1.0 setget _set_amount

func _set_enabled(value: bool) -> void:
    enabled = value
    _get_material().set_shader_param("apply", value)

func _set_amount(value: float) -> void:
    amount = value
    _get_material().set_shader_param("amount", value)

func _get_material() -> ShaderMaterial:
    if material == null:
        yield(self, "_ready")

    return material as ShaderMaterial