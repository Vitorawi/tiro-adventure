shader_type canvas_item;
render_mode unshaded;

uniform sampler2D next_skin : source_color, filter_linear_mipmap;
uniform sampler2D repaired_skin : source_color, filter_linear_mipmap;
uniform vec2 outline[20];
uniform sampler2D rest_skin : source_color, filter_linear_mipmap;
uniform float phase_mix;
uniform float paw_lift;
uniform vec2 head_offset;
uniform float pitch;
uniform float mouth;

const vec2 canvas = vec2(768., 648.);

vec4 skin(sampler2D current, vec2 point) {
	vec2 uv = point / canvas;
	vec4 breathing = mix(texture(current, uv), texture(next_skin, uv), phase_mix);
	return mix(breathing, texture(rest_skin, uv), smoothstep(450., 500., point.y));
}

float head_mask(vec2 p) {
	float x = p.x - 369.;
	float chin = 364. - 0.0047 * x * x;
	return 1. - smoothstep(chin - 2., chin + 2., p.y);
}

float leg_mask(vec2 p) {
	if (paw_lift <= 0. || p.x < 380. || p.x > 456. || p.y < 422. || p.y > 561.) {
		return 0.;
	}
	bool inside = false;
	float edge = 1000.;
	for (int i = 0; i < 20; i++) {
		vec2 a = outline[i], b = outline[(i+1)%20], ab = b-a;
		float t = clamp(dot(p-a,ab)/dot(ab,ab),0.,1.);
		edge = min(edge,length(p-a-t*ab));
		if ((a.y > p.y) != (b.y > p.y)) {
			if (p.x < a.x + (p.y-a.y)*ab.x/ab.y) { inside = !inside; }
		}
	}
	return smoothstep(-2.,0.,inside ? edge : -edge) * smoothstep(0.,0.055,paw_lift);
}

void fragment() {
	vec2 p = UV * canvas;
	vec4 body = skin(TEXTURE, p);
	body = mix(body, texture(repaired_skin, UV), leg_mask(p));
	// Move the painted head over the chest. The feet never enter this transform.
	vec2 pivot = vec2(369., 328.);
	vec2 q = pivot + (p - head_offset - pivot) / vec2(1. - .035*pitch, 1. - .17*pitch);
	vec2 oral = (q - vec2(369.,328.)) / vec2(22.,19.);
	q.y -= mouth * exp(-dot(oral,oral)) * clamp((q.y-315.)/15.,0.,1.);
	vec4 head = skin(TEXTURE,q);
	float cover = head_mask(q);
	// Keep the shared seam opaque in the rest pose.
	body.a *= 1. - head_mask(p) * smoothstep(0., 1., length(head_offset));
	float a = head.a * cover;
	float out_a = a + body.a * (1.-a);
	vec3 rgb = (head.rgb*a + body.rgb*body.a*(1.-a)) / max(out_a,.0001);
	COLOR = length(head_offset) < .001 ? body : vec4(rgb,out_a);
}

