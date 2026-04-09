shader_type canvas_item;

uniform bool invert = false;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (invert) {
        tex.rgb = vec3(1.0) - tex.rgb;
    }

    COLOR = tex;
}