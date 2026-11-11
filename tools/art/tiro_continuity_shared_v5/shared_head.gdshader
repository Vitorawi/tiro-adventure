shader_type canvas_item;
render_mode unshaded;

// Technical rig proof: the approved idle drawings are also the skin for tilt.
// Head is rigid; only the neck blends the inverse transform into the torso.
uniform float angle = 0.0;
uniform vec2 offset = vec2(0.0);
uniform vec2 pivot = vec2(369.0, 289.5);
uniform float blink = 0.0;
uniform sampler2D eyelids : source_color, filter_linear_mipmap;
uniform vec2 eye_left = vec2(328.5, 255.0);
uniform vec2 eye_right = vec2(413.0, 254.5);
uniform vec2 closed_left = vec2(328.5, 240.0);
uniform vec2 closed_right = vec2(413.0, 239.5);

vec4 close_eye(vec4 base, vec2 position, vec2 centre, vec2 source_centre) {
	vec2 local = position - centre;
	float mask = 1.0 - smoothstep(0.70, 1.0, length(local / vec2(27.0, 22.0)));
	vec4 patch = texture(eyelids, (source_centre + local) / vec2(768.0, 648.0));
	return mix(base, patch, mask * blink);
}

void fragment() {
	vec2 point = UV * vec2(768.0, 648.0);
	float weight = 1.0 - smoothstep(338.0, 406.0, point.y);
	vec2 delta = point - pivot - offset;
	float c = cos(angle);
	float s = sin(angle);
	vec2 local = pivot + vec2(c * delta.x + s * delta.y, -s * delta.x + c * delta.y);
	vec2 sample_point = mix(point, local, weight);
	vec4 skin = texture(TEXTURE, sample_point / vec2(768.0, 648.0));
	skin = close_eye(skin, sample_point, eye_left, closed_left);
	skin = close_eye(skin, sample_point, eye_right, closed_right);
	COLOR = skin;
}
