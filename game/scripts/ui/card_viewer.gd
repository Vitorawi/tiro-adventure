class_name CardViewer
extends Control
## A carta grande em tela cheia (Fotos do Tiro, etapa 04). A carta (`PhotoCard`) é desenhada num `SubViewport`
## (`CardStage`) e mostrada num `TextureRect` (`CardSurface`) com o shader `card_tilt` (perspectiva por pixel):
## arrastar o dedo inclina a carta e o foil dos níveis 3–4 acompanha (`tilt`). Soltar volta com uma mola de 0,35 s.
## Embaixo: as quatro versões (tidas coloridas, faltantes escuras; tocar numa tida escolhe a mostrada), Tentar a sorte
## (moedas), Melhorar (materiais), Pôr no varal e Antes e depois. Toda regra está no `GameState`; aqui só chamadas.
##
## `CardViewer.open(id, {host})` abre (um só por vez); `close()`, `CardViewer.is_open()`. Nós: `CardTitle`, `CloseViewer`,
## `CardInfo`, `CardSlot`/`CardSurface`/`CardStage`, `CardVersions` (`Version_1..4`), `CardActions` (`RerollButton`,
## `Locked_RerollButton`, `UpgradeButton`, `Locked_UpgradeButton`, `FeatureButton`, `CompareButton`, `CollectionComplete`).

const SURFACE_MARGIN := 1.3  ## o TextureRect é maior que a carta: folga para o giro e a perspectiva
const RENDER_SCALE := 2.0
const MAX_STAGE := 768
const TILT_RANGE := 0.4  ## fração da largura da carta que o dedo percorre para chegar à inclinação máxima
const SPRING := 0.35
const TAP_SLOP := 10.0
const TILT := preload("res://assets/shaders/card_tilt.gdshader")
const MAX_YAW := 22.0
const MAX_PITCH := 10.0
const REDUCED_YAW := 8.0
const REDUCED_PITCH := 4.0
const FLIP_ANGLE := 84.0
const FLIP_TIME := 0.125
const TILE := 52.0
const SEPARATION := 4
const HEADER_H := 44.0
const MARGIN := 16.0
## Nada do visualizador fica sobre o HUD: a coluna começa abaixo dele.
const VEIL_TOP := 94.0  ## o véu começa logo abaixo do quadradinho da engrenagem: só o cabeçalho do HUD (avatar, nome, moedas) fica à vista
const CONTENT_TOP := 100.0  ## a coluna da carta começa aqui, bem no alto
const BOTTOM := 64.0  ## folga de baixo: a carta não fica colada na borda

static var current: CardViewer

var photo_id := ""
var level := 0  ## versão exibida agora (a escolhida; depois de um sorteio, a nova)
var tilt := Vector2.ZERO
var _card_px := 280.0
var _stage_px := 0.0  ## tamanho com que o SubViewport da carta foi montado pela última vez
var _stage: SubViewport
var _surface: TextureRect
var _slot: Control
var _column: VBoxContainer
var _header_title: Control
var _info: PanelContainer
var _versions: HBoxContainer
var _board: PanelContainer
var _actions: VBoxContainer
var _mode := "main"  ## main, feature (escolher qual sai do varal) ou compare
var _signature := ""
var _pressing := false
var _moved := false
var _press_pos := Vector2.ZERO
var _spring: Tween
var _flip: Tween
var _material: ShaderMaterial
var revealing := false
var showing_back := false


## Abre a carta de `id`; devolve o visualizador (ou null se a foto não existe ou não há onde pendurar).
static func open(id: String, options: Dictionary = {}) -> CardViewer:
	if not GameState.album.has_photo(id):
		return null
	var host: Node = options.get("host") as Node
	if host == null:
		host = _main()
	if host == null:
		return null
	if is_open():
		current.close()
	var viewer := CardViewer.new()
	viewer.name = "CardViewer"
	viewer.photo_id = id
	viewer.revealing = bool(options.get("reveal", false))
	viewer.showing_back = viewer.revealing
	viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewer.z_index = 11  # acima da folha (10), abaixo dos avisos (12)
	host.add_child(viewer)
	current = viewer
	viewer._build()
	return viewer


static func is_open() -> bool:
	return current != null and is_instance_valid(current) and not current.is_queued_for_deletion()


static func _main() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var node := tree.root.get_node_or_null("Main")
	return node if node != null else tree.current_scene


static func _screen() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size


## Topo da coluna: abaixo do HUD (a pílula do nome e o X nunca cobrem a placa "Tiro").
static func top_offset() -> float:
	return CONTENT_TOP


var _hidden_close: Control
var _shrink := 0.0  ## o quanto a carta já encolheu por falta de altura medida no painel de ações


## O X da folha que está atrás (Álbum, Caderninho) some enquanto a carta está aberta: só um X na tela.
## O X do Álbum/Caderninho aberto atrás da carta (o quadro é refeito a cada mudança: quem o monta também consulta isto).
static func sheet_close() -> Control:
	var main := _main()
	if main == null:
		return null
	for panel_name: String in ["AlbumScreen", "PetNotebook"]:
		var panel := main.find_child(panel_name, true, false)
		if panel != null:
			return panel.find_child("CloseButton", true, false) as Control
	return null


func _hide_sheet_close() -> void:
	var close := sheet_close()
	if close != null and close.visible:
		_hidden_close = close
		close.modulate.a = 0.0


func _restore_sheet_close() -> void:
	var close := sheet_close()
	if close != null:
		close.modulate.a = 1.0
	_hidden_close = null


func close() -> void:
	_restore_sheet_close()
	if _spring != null:
		_spring.kill()
	if _flip != null:
		_flip.kill()
	if current == self:
		current = null
	if Events.state_changed.is_connected(_on_state):
		Events.state_changed.disconnect(_on_state)
	if Events.photo_rolled.is_connected(_on_rolled):
		Events.photo_rolled.disconnect(_on_rolled)
	if Events.sheet_closed.is_connected(_on_sheet_closed):
		Events.sheet_closed.disconnect(_on_sheet_closed)
	if Events.world_requested.is_connected(_on_world_requested):
		Events.world_requested.disconnect(_on_world_requested)
	if Events.screen_requested.is_connected(_on_screen_requested):
		Events.screen_requested.disconnect(_on_screen_requested)
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()  # o SubViewport vai junto: só existe com o visualizador aberto


# --- Montagem -------------------------------------------------------------------------------

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = load("res://assets/theme/main_theme.tres") as Theme
	level = GameState.photo_shown_rarity(photo_id)
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# O véu começa na altura do fim do quadradinho da engrenagem: o cabeçalho do HUD fica limpo, sem escurecer.
	var veil_top := VEIL_TOP
	dim.offset_top = veil_top
	# Abaixo do cabeçalho o fundo é um bege madeirado translúcido: a folha atrás (Álbum, Caderninho) aparece só como um véu.
	var deep := ColorRect.new()
	deep.name = "DeepDim"
	deep.color = Color(0.9, 0.76, 0.56, 0.72)
	deep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(deep)
	deep.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deep.offset_top = veil_top
	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override("separation", SEPARATION)
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column.offset_left = MARGIN
	_column.offset_right = -MARGIN
	_column.offset_top = top_offset()
	_hide_sheet_close()
	_column.offset_bottom = -BOTTOM
	_column.add_child(_make_header())
	_info = PanelContainer.new()
	_info.name = "CardInfo"
	_info.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_info.mouse_filter = Control.MOUSE_FILTER_STOP
	var pill := StyleBoxFlat.new()
	pill.bg_color = Palette.PAPER
	pill.border_color = Color("c9935f")
	pill.set_border_width_all(2)
	pill.set_corner_radius_all(16)
	pill.content_margin_left = 12.0
	pill.content_margin_right = 12.0
	pill.content_margin_top = 4.0
	pill.content_margin_bottom = 4.0
	_info.add_theme_stylebox_override("panel", pill)
	_column.add_child(_info)
	_slot = Control.new()
	_slot.name = "CardSlot"
	_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_slot)
	_surface = TextureRect.new()
	_surface.name = "CardSurface"
	_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_surface.stretch_mode = TextureRect.STRETCH_SCALE
	_surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = TILT
	_surface.material = _material
	_slot.add_child(_surface)
	_versions = HBoxContainer.new()
	_versions.name = "CardVersions"
	_versions.alignment = BoxContainer.ALIGNMENT_CENTER
	_versions.mouse_filter = Control.MOUSE_FILTER_STOP
	_versions.add_theme_constant_override("separation", SEPARATION)
	_column.add_child(_versions)
	_board = PanelContainer.new()
	_board.name = "CardBoard"
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_board.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var art := SellUi.nine("card", Vector4i(75, 75, 75, 75), "Art", null, "item_")
	_board.add_child(art)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_board.add_child(margin)
	_actions = VBoxContainer.new()
	_actions.name = "CardActions"
	_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actions.add_theme_constant_override("separation", 4)
	margin.add_child(_actions)
	_column.add_child(_board)
	_refresh(true)
	_layout()
	_layout.call_deferred()  # os tamanhos mínimos só assentam no quadro seguinte
	_layout_later.call_deferred()
	Events.state_changed.connect(_on_state)
	Events.photo_rolled.connect(_on_rolled)
	Events.sheet_closed.connect(_on_sheet_closed)
	Events.world_requested.connect(_on_world_requested)
	Events.screen_requested.connect(_on_screen_requested)
	get_viewport().size_changed.connect(_layout)


func _make_header() -> Control:
	var header := Control.new()
	header.name = "CardHeader"
	header.custom_minimum_size.y = HEADER_H
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := str(Database.photo(photo_id).get("title", ""))
	_header_title = MissionUi.chapter_pill(title, minf(_screen().x - 2.0 * MARGIN - 96.0, 280.0))
	_header_title.name = "CardTitle"
	header.add_child(_header_title)
	var close := BagUi.plain_button(close_pressed)
	close.name = "CloseViewer"
	close.custom_minimum_size = Vector2(44, 44)
	var picture := SellUi.soft(TextureRect.new())
	picture.texture = MissionUi.tex("close")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	picture.offset_left = -19.0
	picture.offset_right = 19.0
	picture.offset_top = -19.0
	picture.offset_bottom = 19.0
	header.add_child(close)
	close.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	close.offset_left = -44.0
	close.offset_right = 0.0
	close.offset_top = -22.0
	close.offset_bottom = 22.0
	header.resized.connect(func() -> void:
		_header_title.position = Vector2((header.size.x - _header_title.size.x) / 2.0, (header.size.y - _header_title.size.y) / 2.0))
	return header


func close_pressed() -> void:
	close()


## Os chips de custo quebram de linha só depois de ter largura: mede de novo dois quadros depois,
## com a altura que o painel realmente ocupa, para o botão de baixo nunca sair da tela.
func _layout_later() -> void:
	for _i in 2:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		_layout()


## Altura a mais quando os chips de custo não cabem numa linha (o FlowContainer só informa a altura de uma).
func _wrapped_cost_extra(screen_width: float) -> float:
	var chips := _board.find_child("UpgradeCost", true, false) as Control
	if chips == null:
		return 0.0
	var room := screen_width - 2.0 * MARGIN - 28.0 - 24.0  # margens do painel e da moldura
	var rows := 1
	var used := 0.0
	for child in chips.get_children():
		var width := (child as Control).get_combined_minimum_size().x
		if used > 0.0 and used + 6.0 + width > room:
			rows += 1
			used = width
		else:
			used += (6.0 if used > 0.0 else 0.0) + width
	var already := maxf(0.0, chips.get_combined_minimum_size().y - 44.0)
	return maxf(0.0, (rows - 1) * 48.0 - already)


## Tamanho da carta: 78% da largura, menor se faltar altura. Chamado depois de montar tudo e quando a tela muda.
func _layout() -> void:
	var screen := _screen()
	_header_title.size = _header_title.custom_minimum_size
	var plate := _header_title.get_node_or_null("Frame") as NinePatchRect
	if plate != null:
		plate.position = Vector2.ZERO
		plate.size = _header_title.size * 3.0  # a moldura 3x é desenhada em escala 1/3 (o `resized` dela não dispara aqui)
	var other := _column.get_combined_minimum_size().y - _slot.custom_minimum_size.y
	other += _wrapped_cost_extra(screen.x)
	var room := screen.y - top_offset() - BOTTOM - other - 4.0
	# Rede de segurança: se o painel de ações realmente passou da borda (chips quebrados, texto de 2 linhas), a carta encolhe o que faltou.
	if _board.is_inside_tree() and _board.size.y > 0.0:
		var overflow := _board.get_global_rect().end.y - (screen.y - BOTTOM)
		if overflow > 1.0:
			_shrink += overflow
	_card_px = clampf(minf(screen.x * 0.78, room) - _shrink, 150.0, 460.0)
	_slot.custom_minimum_size = Vector2(_card_px, _card_px)
	var surface := _card_px * SURFACE_MARGIN
	_surface.size = Vector2(surface, surface)
	_surface.position = Vector2(_card_px - surface, _card_px - surface) / 2.0
	_surface.pivot_offset = _surface.size / 2.0
	_material.set_shader_parameter("tilt", tilt)
	_material.set_shader_parameter("spin", 0.0)
	_material.set_shader_parameter("card_px", _card_px)
	_material.set_shader_parameter("surface_px", Vector2(surface, surface))
	_apply_motion_limits()
	if _stage == null or not is_equal_approx(_stage_px, _card_px):  # só redesenha se o tamanho mudou
		_stage_px = _card_px
		_build_stage()


func _apply_motion_limits() -> void:
	_material.set_shader_parameter("max_yaw", REDUCED_YAW if Motion.reduced else MAX_YAW)
	_material.set_shader_parameter("max_pitch", REDUCED_PITCH if Motion.reduced else MAX_PITCH)


## (Re)desenha a carta da versão exibida no SubViewport.
func _build_stage() -> void:
	if _stage != null:
		remove_child(_stage)
		_stage.queue_free()
	var px := mini(int(round(_card_px * RENDER_SCALE)), MAX_STAGE)
	_stage = SubViewport.new()
	_stage.name = "CardStage"
	_stage.size = Vector2i(px, px)
	_stage.transparent_bg = true
	_stage.gui_disable_input = true
	_stage.disable_3d = true
	_stage.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(_stage)
	var card := PhotoCard.make(photo_id, float(px), {"level": level, "effects": true, "thumb": false, "tilt": tilt})
	card.theme = theme
	_stage.add_child(card)
	if showing_back:
		card.hide()
		var back := TextureRect.new()
		back.name = "CardBack"
		back.texture = load("res://assets/sprites/ui/album/card_back.png")
		back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back.size = Vector2(px, px)
		_stage.add_child(back)
	_surface.texture = _stage.get_texture()
	_sync_foil()


func _foil_material() -> ShaderMaterial:
	if _stage == null:
		return null
	var foil := _stage.find_child("CardFoil", true, false) as Control
	return foil.material as ShaderMaterial if foil != null else null


## O foil do nível 3–4 anima sozinho (TIME): o SubViewport desenha sempre. Nos outros casos, só quando algo muda.
func _animated() -> bool:
	return _foil_material() != null and not Motion.reduced


func _sync_foil() -> void:
	var foil := _foil_material()
	if foil != null:
		foil.set_shader_parameter("tilt", tilt)
	_stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _animated() else SubViewport.UPDATE_ONCE


# --- Inclinação -----------------------------------------------------------------------------

func surface_material() -> ShaderMaterial:
	return _material


## Retângulo da carta na tela (coordenadas deste Control).
func card_rect() -> Rect2:
	return Rect2(_slot.global_position - global_position, _slot.size)


func _set_tilt(value: Vector2) -> void:
	tilt = value
	_material.set_shader_parameter("tilt", tilt)
	_sync_foil()


func _set_spin(degrees: float) -> void:
	_material.set_shader_parameter("spin", degrees)
	if _stage != null and not _animated():
		_stage.render_target_update_mode = SubViewport.UPDATE_ONCE


func touch_down(pos: Vector2) -> void:
	if revealing: return
	_pressing = card_rect().has_point(pos)
	_moved = false
	_press_pos = pos
	if _pressing and _spring != null:
		_spring.kill()


func touch_move(pos: Vector2) -> void:
	if not _pressing:
		return
	var delta := pos - _press_pos
	if not _moved and delta.length() < TAP_SLOP:
		return
	_moved = true
	_set_tilt(Vector2(clampf(delta.x / (_card_px * TILT_RANGE), -1.0, 1.0), clampf(delta.y / (_card_px * TILT_RANGE), -1.0, 1.0)))


func touch_up(pos: Vector2) -> void:
	if revealing: return
	var was_pressing := _pressing
	_pressing = false
	if was_pressing:
		if _moved:
			_release_tilt()
		return
	# Toque fora da carta (e fora dos controles, que consomem o próprio toque): fecha.
	if (pos - _press_pos).length() < TAP_SLOP:
		close()


func _release_tilt() -> void:
	if _spring != null:
		_spring.kill()
	if Motion.reduced or tilt == Vector2.ZERO:
		_set_tilt(Vector2.ZERO)
		return
	_spring = create_tween()
	_spring.tween_method(_set_tilt, tilt, Vector2.ZERO, SPRING).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if (event as InputEventMouseButton).pressed:
			touch_down((event as InputEventMouseButton).position)
		else:
			touch_up((event as InputEventMouseButton).position)
		accept_event()
	elif event is InputEventMouseMotion:
		touch_move((event as InputEventMouseMotion).position)
		accept_event()


func _input(event: InputEvent) -> void:
	# A ajuda do material está por cima: Escape pertence à folha, não à carta atrás dela.
	if z_index < 10:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


# --- Versões, informações e ações -------------------------------------------------------------

func _on_state() -> void:
	if revealing: return
	if not GameState.album.has_photo(photo_id):
		return
	_refresh(false)


func _on_sheet_closed() -> void:
	z_index = 11


func _on_world_requested(_world: String, _place: String) -> void:
	close()


func _on_screen_requested(_screen: StringName) -> void:
	close()


func _make_signature() -> String:
	var up := GameState.upgrade_cost(photo_id)
	var parts: Array = [GameState.photo_variants(photo_id), GameState.photo_rarity(photo_id), level, _mode,
		GameState.reroll_photo_error(photo_id), GameState.reroll_cost(photo_id), GameState.upgrade_photo_error(photo_id), up,
		GameState.album.featured, GameState.featured_photos()]
	for item: String in up.get("items", {}):
		parts.append(GameState.inventory.count(item))
	return str(parts)


func _refresh(force: bool) -> void:
	var key := _make_signature()
	if not force and key == _signature:
		return
	_signature = key
	_build_info()
	_build_versions()
	_build_actions()
	if not force:
		_shrink = 0.0  # o conteúdo mudou (versão, passo do tutorial): mede de novo
		_layout_later.call_deferred()


func _build_info() -> void:
	for child in _info.get_children():
		_info.remove_child(child)
		child.queue_free()
	var box := HBoxContainer.new()  # uma linha só: nível + data (a carta ganha a altura)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	var badge := PhotoCard.rarity_badge(level, 22)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(badge)
	var info := GameState.photo_info(photo_id)
	var phase_name := ""
	for phase: Dictionary in Database.growth.phases:
		if str(phase.id) == str(info.get("phase", "")):
			phase_name = str(phase.name)
	# Só o dia (sem a hora): com "Holográfica" a linha inteira passava da largura da tela e empurrava o painel de baixo.
	var day := PhotoCard.date_text(float(info.get("at", 0.0))).get_slice(",", 0)
	var line := StationWood.text("%s · %s" % [day, phase_name], 12, Palette.INK_SOFT)
	line.name = "CardWhen"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(line)
	_info.add_child(box)


func _build_versions() -> void:
	for child in _versions.get_children():
		_versions.remove_child(child)
		child.queue_free()
	var owned := GameState.photo_variants(photo_id)
	for version in [1, 2, 3, 4]:
		_versions.add_child(_version_tile(version, version in owned))


func _version_tile(version: int, owned: bool) -> Control:
	var button := BagUi.plain_button(_tap_version.bind(version, owned))
	button.name = "Version_%d" % version
	button.custom_minimum_size = Vector2(TILE, TILE)
	button.set_meta("owned", owned)
	var card := PhotoCard.make(photo_id, TILE - 8.0, {"level": version, "effects": false, "thumb": true})
	card.position = Vector2(4, 4)
	if not owned:
		card.modulate = Color(0.22, 0.2, 0.2, 1.0)  # escura: a versão que ainda falta
	button.add_child(card)
	if not owned:
		var lock := TextureRect.new()
		lock.name = "VersionLock"
		lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lock)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.offset_left = -12.0
		lock.offset_right = 12.0
		lock.offset_top = -12.0
		lock.offset_bottom = 12.0
	if version == level:
		var ring := Panel.new()
		ring.name = "Selected"
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Palette.HONEY
		style.set_border_width_all(3)
		style.set_corner_radius_all(10)
		ring.add_theme_stylebox_override("panel", style)
		button.add_child(ring)
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return button


func _tap_version(version: int, owned: bool) -> void:
	if not owned:
		Events.toast_requested.emit("Tente a sorte ou melhore para conseguir")
		return
	var error := GameState.set_photo_variant(photo_id, version)
	if error != "":
		Events.toast_requested.emit(error)
		return
	flip_to(version)


## Troca a versão exibida com um giro rápido (sem giro em "Menos animação").
func flip_to(version: int) -> void:
	if version == level:
		return
	if _flip != null:
		_flip.kill()
	if Motion.reduced:
		level = version
		_set_spin(0.0)
		_build_stage()
		_refresh(true)
		return
	_flip = create_tween()
	_flip.tween_method(_set_spin, 0.0, FLIP_ANGLE, FLIP_TIME).set_ease(Tween.EASE_IN)
	_flip.tween_callback(func() -> void:
		level = version
		_build_stage()
		_refresh(true))
	_flip.tween_method(_set_spin, -FLIP_ANGLE, 0.0, FLIP_TIME).set_ease(Tween.EASE_OUT)
	_flip.tween_callback(func() -> void: Motion.bounce(_surface))


## Resultado de Tentar a sorte / Melhorar: versão nova vira a exibida; repetida só avisa.
func _on_rolled(id: String, result: Dictionary) -> void:
	if id != photo_id:
		return
	CardReveal.play_result(id, result)


func _clear_actions() -> void:
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()


func _build_actions() -> void:
	_clear_actions()
	match _mode:
		"feature":
			_build_feature_choice()
		"compare":
			_build_compare()
		_:
			_build_main_actions()


func _build_main_actions() -> void:
	if GameState.photo_styles_complete(photo_id):
		var done := UiKit.hbox(8)
		done.name = "CollectionComplete"
		done.alignment = BoxContainer.ALIGNMENT_CENTER
		done.mouse_filter = Control.MOUSE_FILTER_IGNORE
		done.add_child(StepCardUi.done_medal(32.0))
		done.add_child(StationWood.text("Coleção completa!", 19))
		_actions.add_child(done)
	else:
		_actions.add_child(_reroll_row())
		if GameState.photo_rarity(photo_id) < 4:
			_add_upgrade()
	_actions.add_child(_secondary_row())


func _coin_chip(cost: int) -> Control:
	return StepCardUi.wood_chip(UiKit.ui_icon("coin"), str(cost), "have" if GameState.coins >= cost else "missing")


func _reroll_row() -> Control:
	var row := UiKit.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var error := GameState.reroll_photo_error(photo_id)
	var cost := int(GameState.reroll_cost(photo_id).coins)
	if error == "":
		var button := WelcomeSheet._button("Tentar a sorte", false, 170.0, "RerollButton", _reroll)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		row.add_child(_coin_chip(cost))
	else:
		var lock := StepCardUi.locked_button("Faltam %d moedas" % maxi(cost - GameState.coins, 1) if GameState.coins < cost else error, UiKit.ui_icon("coin") if GameState.coins < cost else null)
		lock.name = "Locked_RerollButton"
		row.add_child(lock)
	return row


func _reroll() -> void:
	var error := GameState.reroll_photo(photo_id)
	if error != "":
		Events.toast_requested.emit(error)


func _add_upgrade() -> void:
	var cost := GameState.upgrade_cost(photo_id)
	if cost.is_empty():
		return
	var target := int(cost.level)
	var error := GameState.upgrade_photo_error(photo_id)
	var chips := HFlowContainer.new()
	chips.name = "UpgradeCost"
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 4)
	if int(cost.coins) > 0:
		chips.add_child(_coin_chip(int(cost.coins)))
	var missing_item := ""
	for item: String in cost.items:
		var need := int(cost.items[item])
		var have := GameState.inventory.count(item)
		if have < need and missing_item == "":
			missing_item = item
		var chip := StepCardUi.wood_chip(Database.item_icon(item), "%d/%d" % [have, need], "have" if have >= need else "missing", _help_for.bind(item), "Cost_" + item)
		chip.custom_minimum_size.y = 44.0
		chip.set_meta("card_touch_target", true)
		chips.add_child(chip)
	var name_text: String = PhotoCard.LEVEL_NAMES.get(target, "")
	if error == "":
		var button := WelcomeSheet._button("Melhorar → " + name_text, true, 250.0, "UpgradeButton", _upgrade)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_actions.add_child(button)
	else:
		var text := error
		var icon: Texture2D = null
		var on_tap := Callable()
		if missing_item != "":
			text = "Falta %s" % Database.item_name(missing_item)
			icon = Database.item_icon(missing_item)
			on_tap = _help_for.bind(missing_item)
		elif GameState.coins < int(cost.coins):
			text = "Faltam %d moedas" % (int(cost.coins) - GameState.coins)
			icon = UiKit.ui_icon("coin")
		var lock := StepCardUi.locked_button(text, icon, on_tap)
		lock.name = "Locked_UpgradeButton"
		_actions.add_child(lock)
	_actions.add_child(chips)


## Abre o "Como fazer" do material por cima do visualizador (que desce atrás da folha e volta quando ela fecha).
func _help_for(item: String) -> void:
	z_index = 9
	TaskHelp.open("item", item)


func _upgrade() -> void:
	var error := GameState.upgrade_photo(photo_id)
	if error != "":
		Events.toast_requested.emit(error)


func _secondary_row() -> Control:
	var row := UiKit.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var featured: bool = photo_id in GameState.album.featured
	var caption := "Tirar do varal" if featured else "Pôr no varal"
	var feature := WelcomeSheet._button(caption, false, 140.0, "FeatureButton", _toggle_feature)
	feature.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(feature)
	var before := str(Database.photo(photo_id).get("photo", {}).get("compare", ""))
	if before != "" and GameState.album.has_photo(before):
		var compare := WelcomeSheet._button("Antes e depois", false, 140.0, "CompareButton", _set_mode.bind("compare"))
		compare.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(compare)
	return row


func _toggle_feature() -> void:
	if photo_id in GameState.album.featured:
		GameState.unfeature_photo(photo_id)
		_refresh(true)
		return
	var error := GameState.feature_photo_error(photo_id)
	if error == "":
		GameState.feature_photo(photo_id)
		Events.toast_requested.emit("Ela foi para o varal")
		_refresh(true)
	elif error == "Escolha qual sai":
		_set_mode("feature")
	else:
		Events.toast_requested.emit(error)


func _set_mode(mode: String) -> void:
	_mode = mode
	_refresh(true)


func _build_feature_choice() -> void:
	var title := StationWood.text("Escolha qual sai do varal", 17)
	title.name = "FeatureChoiceTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_actions.add_child(title)
	var row := UiKit.hbox(10)
	row.name = "FeatureChoice"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for old: String in GameState.album.featured:
		var button := BagUi.plain_button(_swap_feature.bind(old))
		button.name = "Swap_" + old
		button.custom_minimum_size = Vector2(72, 72)
		var card := PhotoCard.make(old, 64.0, {"effects": false, "thumb": true})
		card.position = Vector2(4, 4)
		button.add_child(card)
		row.add_child(button)
	_actions.add_child(row)
	var back := WelcomeSheet._button("Voltar", false, 140.0, "FeatureBack", _set_mode.bind("main"))
	_actions.add_child(back)


func _swap_feature(old: String) -> void:
	GameState.unfeature_photo(old)
	var error := GameState.feature_photo(photo_id)
	if error != "":
		Events.toast_requested.emit(error)
	_mode = "main"
	_refresh(true)


func _build_compare() -> void:
	var before := str(Database.photo(photo_id).get("photo", {}).get("compare", ""))
	var row := UiKit.hbox(10)
	row.name = "BeforeAfterPhotos"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var old := PhotoCard.make(before, 104.0, {"effects": false})
	old.name = "BeforePhoto"
	row.add_child(old)
	row.add_child(StationWood.text("→", 26))
	row.add_child(PhotoCard.make(photo_id, 104.0, {"level": level, "effects": false}))
	_actions.add_child(row)
	_actions.add_child(WelcomeSheet._button("Voltar", false, 140.0, "CompareBack", _set_mode.bind("main")))
