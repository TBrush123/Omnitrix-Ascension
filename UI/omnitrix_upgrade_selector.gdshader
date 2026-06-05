shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.3, 1.0, 0.3, 1.0);
uniform float glow_size = 0.2;

uniform int MAX_RADIUS = 1;

void fragment()
{
    vec4 tex = texture(TEXTURE, UV);
    float glow = 0.0;

    for (int x = -MAX_RADIUS; x <= MAX_RADIUS; x++)
    {
        for (int y = -MAX_RADIUS; y <= MAX_RADIUS; y++)
        {
            glow += texture(
                TEXTURE,
                UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * glow_size
            ).a;
        }
    }

    glow = clamp(glow, 0.0, 1.0);
    COLOR = mix(
        glow_color * glow,
        tex,
        tex.a
    );
}