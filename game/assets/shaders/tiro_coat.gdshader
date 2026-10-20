shader_type canvas_item;
// Pelagem do Tiro (protótipo na etapa 01, integrado a todos os corpos na etapa 05).
// coat = 0: a sela azul-acinzentada do adulto fica com os MESMOS pretos do jovem (saída do jovem).
// coat = 1: arte original, idêntica pixel a pixel (Azul e Dourado). No meio, o preto vai azulando.
// O dourado, o contorno, os olhos, o nariz e a língua não mudam (pedido do Vitor: nada de "torrado").

uniform float coat : hint_range(0.0, 1.0) = 1.0;
// Pretos da paleta do Tiro, do mais escuro ao mais claro (tiro_coat_darks.png, gerado por tests/growth_art_shots.gd).
uniform sampler2D darks : filter_nearest;
// Pelagem de seda: 0 = sem brilho, 0,33/0,66/1 = níveis I–III. `reduced` (Menos animação) deixa a faixa parada.
uniform float sheen : hint_range(0.0, 1.0) = 0.0;
uniform bool reduced = false;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

vec3 rgb_to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	COLOR = src;
	if (coat < 1.0 && src.a > 0.0) {
		vec3 hsv = rgb_to_hsv(src.rgb);
		// Sela: pouca saturação e brilho médio (mesma regra do jovem em growth_art_shots.gd → _blacken).
		float saddle = step(hsv.y, 0.22) * step(0.22, hsv.z) * step(hsv.z, 0.66);
		if (saddle > 0.5) {
			float n = float(textureSize(darks, 0).x);
			float t = clamp((hsv.z - 0.22) / 0.44, 0.0, 1.0);
			float index = min(floor(t * n), n - 1.0);
			vec3 black = texture(darks, vec2((index + 0.5) / n, 0.5)).rgb;
			COLOR = vec4(mix(black, src.rgb, coat), src.a);
		}
	}
	// Pelagem de seda (etapa 17): faixa de brilho que desliza no pelo claro; sheen 0 não muda um pixel.
	if (sheen > 0.0 && src.a > 0.0) {
		float lum = max(src.r, max(src.g, src.b));
		float pos = reduced ? 0.5 : fract(TIME * 0.3) * 1.6 - 0.3;
		float band = 1.0 - smoothstep(0.0, 0.12, abs((UV.x + UV.y * 0.5) / 1.5 - pos));
		float shine = band * sheen * step(0.3, lum) * 0.45;
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.97, 0.85), shine);
	}
	COLOR *= vertex_tint;
}
