class_name SettingsPanel
extends RefCounted
## Painel de configurações (engrenagem na barra superior): Vibrar, Menos animação, Texto maior e vários saves.
## Visual de madeira ilustrada: folha `sheet_wood`, cartões de papel, interruptores de madeira, chips e botões de madeira.
## Cada save mostra capítulo e moedas; dá para jogar nele, torná-lo o padrão (o que o jogo abre ao iniciar),
## excluí-lo (com confirmação) ou começar um save novo (o único botão verde da folha).
## Trocar de save recarrega a cena principal: tudo é reconstruído a partir do estado carregado.
## Nós: `Preferences`, `<chave>Row`, `<chave>Toggle`, `SaveList`, `Save_<n>`, `Playing_<n>`, `Play_<n>`, `Default_<n>`,
## `DefaultState_<n>`, `Delete_<n>`, `NewSave`, `VersionLabel`.


static func open() -> void:
	Events.sheet_requested.emit("Configurações", panel())


static func panel() -> Control:
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_theme_constant_override("separation", 10)
		box.add_child(_heading("Jogo"))
		var prefs := StepCardUi.inner_card(box, "Preferences", Vector4i(14, 4, 14, 4))
		prefs.add_theme_constant_override("separation", 0)
		_toggle_row(prefs, "Vibrar", "Vibrate", SaveManager.vibrate_enabled, SaveManager.set_vibrate, true)
		_toggle_row(prefs, "Menos animação", "ReducedMotion", SaveManager.reduced_motion, SaveManager.set_reduced_motion, true)
		_toggle_row(prefs, "Texto maior", "LargeText", SaveManager.large_text, SaveManager.set_large_text, false)
		box.add_child(_heading("Saves"))
		var saves := UiKit.vbox(8)
		saves.name = "SaveList"
		box.add_child(saves)
		for summary: Dictionary in SaveManager.list_slots():
			_slot_card(saves, summary)
		if SaveManager.can_add_slot():
			var add := StepCardUi.go_button("+ Novo save", func() -> void:
				if SaveManager.new_slot() != 0:
					_restart())
			add.name = "NewSave"
			box.add_child(add)
		else:
			var full := StepCardUi.wood("Máximo de %d saves. Exclua um para criar outro." % SaveManager.MAX_SLOTS, 15)
			full.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(full)
		box.add_child(_version_label()))
	live.set_meta("sheet_wood", true)
	live.set_meta("sheet_fit_content", true)
	return live


## Título de seção: texto marrom na fonte da madeira, alinhado à esquerda.
static func _heading(text: String) -> Label:
	var label := StepCardUi.wood(text, 17)
	label.name = "Heading_" + text
	return label


## Linha "texto  [interruptor]": preferência do aparelho (SaveManager grava em settings.json).
static func _toggle_row(parent: VBoxContainer, text: String, key: String, enabled: bool, apply: Callable, divider: bool) -> void:
	var row := UiKit.hbox(8)
	row.name = key + "Row"
	row.custom_minimum_size = Vector2(0, 56)
	var label := StepCardUi.wood(text, 18)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var toggle := _wood_toggle(enabled, func(on: bool) -> void:
		apply.call(on)
		Events.state_changed.emit())
	toggle.name = key + "Toggle"
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(toggle)
	parent.add_child(row)
	if divider:
		var line := ColorRect.new()
		line.color = WelcomeSheet.LINE_COLOR
		line.custom_minimum_size.y = 2.0
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(line)


## Interruptor de madeira: calha marrom com contorno de cobre (verde quando ligado) e botão creme. Continua sendo um
## Button com `toggle_mode` e `button_pressed`, como o `UiKit.toggle`.
static func _wood_toggle(on: bool, on_change: Callable) -> Button:
	var result := BagUi.plain_button(func() -> void: pass)
	result.custom_minimum_size = Vector2(60, 44)
	result.toggle_mode = true
	result.button_pressed = on
	var track := Panel.new()
	track.name = "Track"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.size = Vector2(56, 32)
	result.add_child(track)
	var knob := Panel.new()
	knob.name = "Knob"
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.size = Vector2(24, 24)
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Palette.WOOD_CREAM
	knob_style.border_color = Color("c9935f")
	knob_style.set_border_width_all(2)
	knob_style.set_corner_radius_all(12)
	knob.add_theme_stylebox_override("panel", knob_style)
	track.add_child(knob)
	var update := func(animate: bool) -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("5fae4a") if result.button_pressed else Color("b9895a")
		style.border_color = Color("5a3418") if result.button_pressed else Color("8a5a30")
		style.set_border_width_all(2)
		style.set_corner_radius_all(16)
		track.add_theme_stylebox_override("panel", style)
		var target := Vector2(28 if result.button_pressed else 4, 4)
		if result.has_meta("tween"):
			(result.get_meta("tween") as Tween).kill()
		if animate and not Motion.reduced:
			var tween := result.create_tween()
			tween.tween_property(knob, "position", target, 0.15)
			result.set_meta("tween", tween)
		else:
			knob.position = target
	result.resized.connect(func() -> void: track.position = (result.size - track.size) / 2)
	result.toggled.connect(func(value: bool) -> void:
		update.call(true)
		on_change.call(value))
	update.call(false)
	return result


## Rodapé com a versão do jogo. Atalho de emergência: tocar nela força a atualização.
static func _version_label() -> Label:
	var version := StepCardUi.wood("v%s %s" % [Database.version.get("version", "?"), Database.version.get("date", "")], 13, Color(Palette.WOOD_INK, 0.7))
	version.name = "VersionLabel"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.mouse_filter = Control.MOUSE_FILTER_STOP
	version.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed:
			PwaUpdater.apply_update())
	return version


static func _slot_card(box: VBoxContainer, summary: Dictionary) -> void:
	var slot := int(summary.slot)
	# Cartão de papel por save: nome + chip "Jogando" (o save em uso), chips de capítulo/moedas e as ações.
	var wrap := VBoxContainer.new()
	wrap.name = "Save_%d" % slot
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(wrap)
	var body := StepCardUi.inner_card(wrap, "SaveCard_%d" % slot, Vector4i(14, 12, 14, 12))
	var title := UiKit.hbox(8)
	var name_label := StepCardUi.wood("Save %d" % slot, 19)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(name_label)
	if summary.active:
		title.add_child(StepCardUi.wood_chip(null, "Jogando", "have", Callable(), "Playing_%d" % slot))
	body.add_child(title)
	var chips := UiKit.flow(6)
	var chapter := "Completo" if summary.finished else "Cap. %d/%d" % [int(summary.chapter), int(summary.chapters)]
	chips.add_child(StepCardUi.wood_chip(UiKit.ui_icon("tab_tasks"), chapter))
	chips.add_child(StepCardUi.wood_chip(UiKit.ui_icon("coin"), str(int(summary.coins))))
	body.add_child(chips)
	# Flow: com Texto maior os botões quebram de linha em vez de alargar a folha além da tela.
	var row := UiKit.flow(6)
	if not summary.active:
		row.add_child(WelcomeSheet._button("Jogar", false, 88.0, "Play_%d" % slot, func() -> void:
			SaveManager.switch_slot(slot)
			_restart()))
	if summary.default:
		row.add_child(StepCardUi.wood_chip(null, "É o padrão", "have", Callable(), "DefaultState_%d" % slot))
	else:
		row.add_child(WelcomeSheet._button("Tornar padrão", false, 136.0, "Default_%d" % slot, func() -> void:
			SaveManager.set_default_slot(slot)
			Events.state_changed.emit()))
	row.add_child(_delete_button(slot))
	body.add_child(row)


## Excluir pede um segundo toque ("Certeza?") para não apagar um save sem querer.
static func _delete_button(slot: int) -> Button:
	var button := WelcomeSheet._button("Excluir", false, 88.0, "Delete_%d" % slot, func() -> void: pass)
	button.pressed.connect(func() -> void:
		if not button.has_meta("armed"):
			button.set_meta("armed", true)
			button.text = "Certeza?"
			button.modulate = Palette.WARN_TINT
			return
		var was_active: bool = slot == SaveManager.active_slot
		SaveManager.delete_slot(slot)
		if was_active:
			_restart()
		else:
			Events.state_changed.emit())
	return button


static func _restart() -> void:
	Events.sheet_close_requested.emit()
	var tree := Engine.get_main_loop() as SceneTree
	tree.reload_current_scene.call_deferred()
