shader_type canvas_item;

// CRT Effect - Cheap scanlines overlay
// Simply draws horizontal lines

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_frequency : hint_range(1.0, 100.0) = 4.0;

void fragment() {
	// Create horizontal scanlines
	float line = mod(UV.y * scanline_frequency, 1.0);
	float scanline = step(0.5, line);
	
	// Black transparent lines
	vec4 color = vec4(0.0, 0.0, 0.0, scanline * scanline_intensity);
	
	COLOR = color;
}
