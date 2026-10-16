class_name Haptics
extends RefCounted
## Vibração leve do celular (tap/success/big/error). Preferência do aparelho: "Vibrar" nas
## configurações (SaveManager grava em settings.json). iPhone/Safari ignora vibração na web: tudo bem.
## `calls` guarda as durações (ms) que de fato foram pedidas — os testes olham por ali.

const TAP_MS := 12
const SUCCESS_MS := 30
const BIG_MS := 60
const ERROR_MS := 20
const ERROR_GAP := 0.08  # intervalo entre as duas vibrações do erro

static var enabled := true
static var calls: Array[int] = []


## Toque pequeno: cada canteiro do arrasto.
static func tap() -> void:
	_buzz(TAP_MS)


## Colher / pegar.
static func success() -> void:
	_buzz(SUCCESS_MS)


## Nível, capítulo, tesouro, raro.
static func big() -> void:
	_buzz(BIG_MS)


## "Não dá": duas vibrações curtas.
static func error() -> void:
	if not enabled:
		return
	_buzz(ERROR_MS)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.create_timer(ERROR_GAP).timeout.connect(_buzz.bind(ERROR_MS))
	else:
		_buzz(ERROR_MS)


static func _buzz(ms: int) -> void:
	if not enabled:
		return
	calls.append(ms)
	Input.vibrate_handheld(ms)
