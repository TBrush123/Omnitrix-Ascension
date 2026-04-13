shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.5;
uniform vec4 fill_color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Omnitrix Green
uniform float bubble_speed : hint_range(0.0, 5.0) = 1.5;

// Simple function to create "bubbles" using a pseudo-random noise
float bubbles(vec2 uv, float time) {
    float n = sin(uv.x * 20.0 + time * bubble_speed) * cos(uv.y * 20.0 + time);
    return smoothstep(0.9, 1.0, n);
}

void fragment() {
    vec4 mask_tex = texture(TEXTURE, UV);
    vec2 uv = UV;
    
    // Create a waving "water line"
    float wave = sin(uv.x * 10.0 + TIME * 2.0) * 0.02;
    float fill_line = 1.0 - progress + wave;
    
    // Define the liquid area
    float liquid = step(fill_line, uv.y);
    
    // Add bubbles within the liquid area
    float b = bubbles(uv + vec2(0.0, TIME * 0.2), TIME);
    vec4 final_color = fill_color;
    final_color.rgb += b * 0.3; // Make bubbles slightly brighter green
    
    // Apply the liquid color, bubbles, and the original texture's shape (mask)
    COLOR = vec4(final_color.rgb, liquid * mask_tex.a);
}