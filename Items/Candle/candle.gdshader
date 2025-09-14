shader_type spatial;

uniform float time_speed : hint_range(0.0, 5.0) = 1.5;
uniform float flame_height : hint_range(0.1, 2.0) = 1.0;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec3 flame_color : source_color = vec3(1.0, 0.65, 0.2); // orange
uniform vec3 glow_color : source_color = vec3(1.0, 0.9, 0.6);   // yellow/white

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// Simple 2D noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void vertex() {
	// Billboard Mode: Y-Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);

	// Billboard Keep Scale: Enabled
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
    vec2 uv = UV;
    uv.y = 1.0 - uv.y;

    // Flame shape (tapered upwards)
    uv.y *= flame_height;
    float shape = 1.0 - pow(abs(uv.x - 0.5) * 2.0, 2.0) - uv.y;
    
    // Animate with noise
    float t = TIME * time_speed;
    float n = noise(uv * 3.0 + vec2(0.0, t));
    shape += (n - 0.5) * distortion_strength;
    
    // Clamp flame area
    float flame = smoothstep(0.0, 0.5, shape);
    
    // Color gradient (bottom = yellow/white, top = orange)
    vec3 col = mix(glow_color, flame_color, uv.y);
    
    ALBEDO = col * flame;
    ALPHA = flame; // transparency
}
