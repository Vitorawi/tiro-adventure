class_name Motion
extends RefCounted
## Microanimações da interface, todas por Tween (sem shaders nem AnimationPlayer).
## Tempos e curvas fixos em docs/plans/interface/01_REGRAS_E_ESTILO.md (seção C).
## Regras: pivô no centro, nunca animar `size` de container (só scale/position/modulate) e a animação
## nunca bloqueia o toque. Cada função devolve o Tween (para parar um `pulse`, por exemplo).

## Com `reduced` ligado, as funções aplicam o estado final na hora, sem animar.
## Desligado por padrão; a tela de configurações poderá ligar numa etapa futura.
static var reduced := false

const PRESS_DOWN := 0.08
const PRESS_UP := 0.14
const POP_IN := 0.22
const POP_OUT := 0.14
const SLIDE := 0.26
const BOUNCE := 0.25
const PULSE := 0.9
const COUNT := 0.5
const SHAKE := 0.24
const FLOAT := 0.7
const FADE := 0.12  # conteúdo novo entrando num painel que já está aberto
const RESIZE := 0.18  # painel que acompanha o tamanho do conteúdo (e volta ao lugar depois de arrastado)
const CLOSE := 0.2  # painel que desce ao fechar


## Pivô no centro para Controls (Node2D já gira/escala pela origem).
static func _pivot(node: CanvasItem) -> void:
	if node is Control:
		(node as Control).pivot_offset = (node as Control).size / 2.0


## Tween já encerrado: devolvido quando `reduced` está ligado, para quem guarda/mata o resultado.
static func _finished(node: Node) -> Tween:
	var tween := node.create_tween()
	tween.kill()
	return tween


## Botão que afunda ao tocar: escala 0,94 ao apertar e volta ao soltar. Só conecta os sinais.
static func press(button: BaseButton) -> void:
	if reduced:
		return
	button.button_down.connect(func() -> void:
		_pivot(button)
		button.create_tween().tween_property(button, "scale", Vector2.ONE * 0.94, PRESS_DOWN))
	button.button_up.connect(func() -> void:
		_pivot(button)
		button.create_tween().tween_property(button, "scale", Vector2.ONE, PRESS_UP) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


## Aparece crescendo de 0,6 a 1,0 com o alfa de 0 a 1.
static func pop_in(node: CanvasItem) -> Tween:
	if reduced:
		node.set("scale", Vector2.ONE)
		node.modulate.a = 1.0
		return _finished(node)
	_pivot(node)
	node.set("scale", Vector2.ONE * 0.6)
	node.modulate.a = 0.0
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "scale", Vector2.ONE, POP_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, POP_IN)
	return tween


## Aparece só com o alfa de 0 a 1 (troca de conteúdo dentro de um painel aberto).
static func fade_in(node: CanvasItem) -> Tween:
	if reduced:
		node.modulate.a = 1.0
		return _finished(node)
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, FADE)
	return tween


## Some encolhendo para 0,8 com o alfa indo a 0; `free` remove o nó no fim.
static func pop_out(node: CanvasItem, free: bool = true) -> Tween:
	if reduced:
		node.modulate.a = 0.0
		if free:
			node.queue_free()
		return _finished(node)
	_pivot(node)
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "scale", Vector2.ONE * 0.8, POP_OUT)
	tween.tween_property(node, "modulate:a", 0.0, POP_OUT)
	if free:
		tween.chain().tween_callback(node.queue_free)
	return tween


## Sobe de `from_y` pixels abaixo até a posição atual do nó.
static func slide_up(node: Control, from_y: float = 80.0) -> Tween:
	if reduced:
		return _finished(node)
	var target := node.position.y
	node.position.y = target + from_y
	var tween := node.create_tween()
	tween.tween_property(node, "position:y", target, SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tween


## Pulinho: sobe 6 px e volta.
static func bounce(node: CanvasItem) -> Tween:
	if reduced:
		return _finished(node)
	var base_y: float = node.position.y
	var tween := node.create_tween()
	tween.tween_property(node, "position:y", base_y - 6.0, BOUNCE / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", base_y, BOUNCE / 2.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tween


## Pulsar contínuo 1,00 ↔ 1,04. Devolve o Tween: `kill()` para parar (e devolva `scale` a Vector2.ONE).
static func pulse(node: CanvasItem) -> Tween:
	if reduced:
		return _finished(node)
	_pivot(node)
	var tween := node.create_tween().set_loops()
	tween.tween_property(node, "scale", Vector2.ONE * 1.04, PULSE / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2.ONE, PULSE / 2.0).set_trans(Tween.TRANS_SINE)
	return tween


## Número que conta de `from` a `to`; `fmt` recebe um inteiro (ex.: "%d", "+%d", "%d/6").
static func count_up(label: Label, from: int, to: int, fmt: String = "%d") -> Tween:
	if reduced or from == to:
		label.text = fmt % to
		return _finished(label)
	label.text = fmt % from
	var tween := label.create_tween()
	tween.tween_method(func(value: float) -> void: label.text = fmt % roundi(value), float(from), float(to), COUNT) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: label.text = fmt % to)
	return tween


## "Não dá": balança 4 px para os lados três vezes.
static func shake(node: CanvasItem) -> Tween:
	if reduced:
		return _finished(node)
	var base_x: float = node.position.x
	var step := SHAKE / 6.0
	var tween := node.create_tween()
	for side: float in [4.0, -4.0, 4.0, -4.0, 4.0]:
		tween.tween_property(node, "position:x", base_x + side, step)
	tween.tween_property(node, "position:x", base_x, step)
	return tween


## "+3" que sobe 28 px e some. O rótulo é de `parent` e se apaga sozinho.
static func float_text(parent: Node, pos: Vector2, text: String, color: Color) -> Tween:
	if reduced:
		return _finished(parent)
	var label := Label.new()
	label.text = text
	label.position = pos
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Palette.INK)
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", pos.y - 28.0, FLOAT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, FLOAT).set_delay(FLOAT * 0.4)
	tween.chain().tween_callback(label.queue_free)
	return tween
