shader_type canvas_item;
render_mode blend_add;
// Efeito da carta (Fotos do Tiro, etapa 03). Vai num ColorRect transparente por cima da carta inteira
// (arte + moldura + papel) e SÓ soma luz: não amostra textura, então não briga com a arte própria da foto.
//   level 3 (Rara): faixa de luz diagonal a cada ~3 s + cintilas pequenas.
//   level 4 (Holográfica): reflexo arco-íris em faixas finas que segue `tilt` e o tempo.
// `tilt` (-1..1) vem do dedo na etapa 04; `still` congela num quadro bonito (Menos animação).
// Sem laços e sem texture(): barato no celular (Compatibility).

uniform int level = 3;
uniform vec2 tilt = vec2(0.0);
uniform float strength = 1.0;
uniform bool still = false;
uniform float corner = 0.057; // raio dos cantos da carta (30/528), na largura
uniform vec4 window = vec4(0.0682, 0.0682, 0.8636, 0.7273); // janela da foto na carta (x, y, largura, altura em UV)

float rounded_mask(vec2 uv) {
	vec2 p = abs(uv - 0.5) - 0.5 + vec2(corner);
	float d = length(max(p, vec2(0.0))) + min(max(p.x, p.y), 0.0) - corner;
	return clamp(0.5 - d * 300.0, 0.0, 1.0);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

vec3 hue(float h) {
	vec3 k = clamp(abs(fract(vec3(h) + vec3(0.0, 0.6667, 0.3333)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
	return k;
}

void fragment() {
	float t = still ? 0.35 : TIME;
	float mask = rounded_mask(UV);
	vec3 add = vec3(0.0);
	if (level == 3) {
		// faixa de luz: sai de um canto e cruza a carta em ~1,2 s, depois descansa até fechar 3 s
		float cycle = fract(t / 3.0);
		float pos = mix(-0.4, 1.4, clamp(cycle / 0.4, 0.0, 1.0)) + tilt.x * 0.35;
		float diag = (UV.x * 0.8 + UV.y * 0.6) - pos;
		float band = exp(-diag * diag * 90.0) * 0.30;
		// cintilas: células fixas que acendem uma de cada vez
		vec2 cell = floor(UV * 9.0);
		float r = hash(cell);
		vec2 local = fract(UV * 9.0) - 0.5;
		float star = max(0.0, 1.0 - (abs(local.x) + abs(local.y)) * 3.2);
		float on = max(0.0, sin(t * 1.6 + r * 40.0));
		on = r > 0.82 ? on * on : 0.0;
		add = vec3(1.0, 0.92, 0.62) * (band + star * on * 0.45);
	} else if (level == 4) {
		// Só faixas finas e brilhos que passam POR CIMA da imagem; o resto da arte fica como está.
		float flow = UV.x * 0.9 + UV.y * 0.7 + tilt.x * 0.55 + tilt.y * 0.3 + t * 0.05;
		float streak = pow(0.5 + 0.5 * sin(flow * 14.0), 8.0);   // ~15% da área, faixas finas
		float soft = pow(0.5 + 0.5 * sin(flow * 5.0 + 1.3), 4.0); // véu muito leve entre as faixas
		vec3 rainbow = hue(flow * 1.6);
		vec2 cell = floor(UV * 11.0);
		float r = hash(cell);
		vec2 local = fract(UV * 11.0) - 0.5;
		float star = max(0.0, 1.0 - (abs(local.x) + abs(local.y)) * 3.4);
		float on = max(0.0, sin(t * 1.4 + r * 50.0));
		on = r > 0.84 ? on * on : 0.0;
		add = rainbow * (streak * 0.30 + soft * 0.035) + vec3(1.0) * star * on * 0.40;
		float cycle = fract(t / 4.0);
		float sweep = (UV.x * 0.8 + UV.y * 0.6) - (mix(-0.4, 1.4, clamp(cycle / 0.35, 0.0, 1.0)) + tilt.x * 0.35);
		add += vec3(1.0) * exp(-sweep * sweep * 130.0) * 0.10;
	}
	if (level == 4) {
		// holográfico: só dentro da foto, a moldura e o papel ficam sem efeito
		vec2 w = (UV - window.xy) / window.zw;
		mask *= step(0.0, w.x) * step(w.x, 1.0) * step(0.0, w.y) * step(w.y, 1.0);
	}
	COLOR = vec4(add * strength * mask, 1.0);
}
