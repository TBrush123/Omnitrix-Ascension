shader_type canvas_item;

uniform sampler2D existing_screen_texture : hint_screen_texture, filter_linear_mipmap;

const vec3 light_green = vec3(182.0/255.0, 254.0/255.0, 82.0/255.0);
const vec3 dark_green  = vec3(104.0/255.0, 179.0/255.0, 0.0);
const vec3 wheel_green = vec3(155.0/255.0, 255.0/255.0, 32.0/255.0);
const vec3 wheel_dark_green = vec3(88.0/255.0, 151.0/255.0, 0.0/255.0);

void fragment() {
    vec3 color = texture(existing_screen_texture, SCREEN_UV).rgb;

    float tolerance = 0.2;
	if (distance(color, wheel_green) < tolerance) {
		color = wheel_dark_green;
	}
    else if (distance(color, light_green) < tolerance) {
        color = dark_green;
    }
    else if (distance(color, dark_green) < tolerance) {
        color = light_green;
    }

    COLOR.rgb = color;
}