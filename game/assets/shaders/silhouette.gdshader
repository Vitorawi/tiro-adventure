shader_type canvas_item;
// Só alfa da imagem futura: nenhuma amostra RGB chega à saída.
uniform vec4 tint : source_color;
uniform vec4 outline : source_color;
uniform int stage = 0;
uniform bool ready = false;
uniform bool reduced = false;
uniform int ear_count = 0;
uniform int part_count = 0;
uniform vec4 parts[8];

void fragment() {
	float a = step(0.5, texture(TEXTURE, UV).a);
	vec2 edge_step = max(TEXTURE_PIXEL_SIZE, fwidth(UV));
	float lo = 1.0;
	float hi = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			float near_a = step(0.5, texture(TEXTURE, UV + vec2(float(x),float(y)) * edge_step).a);
			lo = min(lo, near_a);
			hi = max(hi, near_a);
		}
	}
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	float revealed = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= part_count) { break; }
		vec4 r = parts[i];
		bool inside = pixel.x >= r.x && pixel.y >= r.y && pixel.x < r.x+r.z && pixel.y < r.y+r.w;
		if (inside && ((i < ear_count && stage >= 1) || (i >= ear_count && stage >= 2))) {
			revealed = 1.0;
		}
	}
	float pulse = reduced ? 0.5 : (sin(TIME * 2.0) + 1.0) * 0.5;
	float glow = ready ? 0.5 + pulse * 0.2 : (stage >= 3 ? 0.15 + pulse * 0.1 : 0.0);
	vec3 ink = mix(tint.rgb, outline.rgb, revealed * 0.2 + glow);
	float edge = hi - lo;
	COLOR = vec4(mix(ink, outline.rgb, hi - a), stage == 0 ? edge : hi);
}
