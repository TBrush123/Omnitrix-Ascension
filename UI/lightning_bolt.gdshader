shader_type canvas_item;

uniform vec4 bolt_color : source_color =
vec4(0.5, 0.9, 1.0, 1.0);

float rand(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898,78.233)))
           * 43758.5453);
}

void fragment()
{
    vec2 uv = UV;

    float center =
        0.5 +
        sin(uv.y * 25.0 + TIME * 15.0) * 0.05 +
        sin(uv.y * 60.0 - TIME * 25.0) * 0.02;

    float bolt =
        smoothstep(0.08, 0.0,
        abs(uv.x - center));

    float glow =
        smoothstep(0.2, 0.0,
        abs(uv.x - center));

    COLOR =
        bolt_color * bolt +
        bolt_color * glow * 0.4;
}