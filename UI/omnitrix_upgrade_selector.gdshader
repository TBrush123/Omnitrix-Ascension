shader_type canvas_item;

uniform vec4 glow_color : source_color =
    vec4(0.3, 1.0, 0.3, 1.0);

uniform float glow_size = 3.0;

void fragment()
{
    vec4 tex = texture(TEXTURE, UV);

    float glow = 0.0;

    for(float x = -glow_size; x <= glow_size; x++)
    {
        for(float y = -glow_size; y <= glow_size; y++)
        {
            glow += texture(
                TEXTURE,
                UV + vec2(x,y) * TEXTURE_PIXEL_SIZE
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