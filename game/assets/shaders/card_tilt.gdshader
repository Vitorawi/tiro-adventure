shader_type canvas_item;
// Carta inclinada em perspectiva (Fotos do Tiro, etapa 04). A textura é a carta inteira desenhada num SubViewport
// quadrado; o TextureRect que a mostra é MAIOR que a carta (folga para o giro). Para cada pixel da tela traçamos o raio
// até o plano da carta girado e lemos a textura no ponto atingido: perspectiva correta (sem a distorção diagonal de um
// quadrilátero), sem laços, barato no celular (Compatibility).
//   tilt  (-1..1): arrasto do dedo; x gira em torno do eixo vertical (até max_yaw), y em torno do horizontal (max_pitch)
//   spin  (graus): giro extra do "flip" (trocar de versão)
//   card_px: lado da carta na tela, em pixels; surface_px: tamanho do TextureRect em pixels.

uniform vec2 tilt = vec2(0.0);
uniform float spin = 0.0;
uniform float max_yaw = 22.0;
uniform float max_pitch = 10.0;
uniform float card_px = 280.0;
uniform vec2 surface_px = vec2(364.0);
uniform float distance_factor = 3.2;   // câmera a N larguras de carta
uniform float corner = 0.057;          // raio dos cantos da carta (na largura): mata o canto preto do foil aditivo

float rounded_mask(vec2 uv) {
	vec2 p = abs(uv - 0.5) - 0.5 + vec2(corner);
	float d = length(max(p, vec2(0.0))) + min(max(p.x, p.y), 0.0) - corner;
	return clamp(0.5 - d * card_px, 0.0, 1.0);
}

void fragment() {
	vec2 s = (UV - 0.5) * surface_px;
	float yaw = radians(tilt.x * max_yaw + spin);
	float pitch = radians(-tilt.y * max_pitch);
	float cy = cos(yaw);
	float sy = sin(yaw);
	float cp = cos(pitch);
	float sp = sin(pitch);
	// R = Ry(yaw) * Rx(pitch); colunas = eixos locais da carta no espaço da câmera
	vec3 ax = vec3(cy, 0.0, -sy);
	vec3 ay = vec3(sy * sp, cp, cy * sp);
	vec3 n = vec3(sy * cp, -sp, cy * cp);
	float d = card_px * distance_factor;
	vec3 dir = vec3(s, -d);
	float denom = dot(n, dir);
	float t = -n.z * d / denom;
	vec3 hit = vec3(0.0, 0.0, d) + t * dir;
	vec2 local = vec2(dot(hit, ax), dot(hit, ay));
	vec2 uv = local / card_px + 0.5;
	// borda suave (a cobertura é medida em pixels da tela)
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)) * card_px;
	float fw = max(fwidth(edge), 0.0001);
	float cover = clamp(edge / fw + 0.5, 0.0, 1.0) * step(0.0, t) * step(denom, -0.0001);
	vec4 c = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
	float a = c.a * cover * rounded_mask(clamp(uv, vec2(0.0), vec2(1.0)));
	COLOR = vec4(c.rgb, a);
}
