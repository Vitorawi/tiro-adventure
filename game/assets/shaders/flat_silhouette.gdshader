shader_type canvas_item;
// Silhueta de cor única para fotos ainda não tiradas: só o alfa da imagem passa para a saída.
uniform vec4 tint : source_color = vec4(0.62, 0.6, 0.57, 1.0);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(tint.rgb, a * tint.a);
}
