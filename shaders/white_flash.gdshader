shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float flash_duration : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	// Calculate flash effect based on intensity and duration
	float flash = flash_intensity * (1.0 - flash_duration);
	
	// Mix original color with retro green based on flash intensity
	vec3 flash_color = mix(original_color.rgb, vec3(0.176471, 0.996078, 0.223529), flash);
	
	COLOR = vec4(flash_color, original_color.a);
}
