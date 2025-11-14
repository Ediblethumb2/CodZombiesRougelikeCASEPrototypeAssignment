extends ColorRect

@export var mask_viewport_path: NodePath
@export var fog_alpha: float = 1.0
@export var ambient_reveal: float = 0.0

@onready var mask_viewport: SubViewport = mask_viewport_path.is_empty() ? null : get_node(mask_viewport_path) as SubViewport
@onready var mat: ShaderMaterial = material

func _ready() -> void:
        # Fill the entire minimap viewport and stay on top of the map content.
        anchor_left = 0.0
        anchor_top = 0.0
        anchor_right = 1.0
        anchor_bottom = 1.0
        offset_left = 0.0
        offset_top = 0.0
        offset_right = 0.0
        offset_bottom = 0.0
        z_index = 100
        z_as_relative = false
        mouse_filter = Control.MOUSE_FILTER_IGNORE

        _update_material_params()

func _process(_dt: float) -> void:
        # The mask viewport may be recreated or resized at runtime (for example if the
        # minimap resolution changes). Update the shader parameters lazily so the
        # overlay always samples the latest reveal texture.
        _update_material_params()

func _update_material_params() -> void:
        if mat == null:
                return

        if mask_viewport == null and not mask_viewport_path.is_empty():
                mask_viewport = get_node(mask_viewport_path) as SubViewport

        if mask_viewport:
                mat.set_shader_parameter("reveal_texture", mask_viewport.get_texture())
                mat.set_shader_parameter("fog_alpha", fog_alpha)
                mat.set_shader_parameter("ambient_reveal", ambient_reveal)
