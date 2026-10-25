class_name SettingsPanel
extends RefCounted
## Painel de configurações (engrenagem na barra superior): Vibrar, Menos animação e vários saves.
## Cada save mostra nível, capítulo e moedas; dá para jogar nele, torná-lo o padrão (o que o
## jogo abre ao iniciar), excluí-lo (com confirmação) ou começar um save novo.
## Trocar de save recarrega a cena principal: tudo é reconstruído a partir do estado carregado.


static func open() -> void:
	Events.sheet_requested.emit("Configurações", panel())


static func panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_child(UiKit.section("Jogo"))
		var prefs := UiKit.list_card(box)
		prefs.get_parent().name = "Preferences"
		_toggle_row(prefs, "Vibrar", "Vibrate", SaveManager.vibrate_enabled, SaveManager.set_vibrate)
		_toggle_row(prefs, "Menos animação", "ReducedMotion", SaveManager.reduced_motion, SaveManager.set_reduced_motion)
		_toggle_row(prefs, "Texto maior", "LargeText", SaveManager.large_text, SaveManager.set_large_text)
		box.add_child(UiKit.section("Saves"))
		var saves := UiKit.list_card(box)
		saves.get_parent().name = "SaveList"
		for summary: Dictionary in SaveManager.list_slots():
			_slot_card(saves, summary)
		if SaveManager.can_add_slot():
			var add := UiKit.button("+ Novo save", func() -> void:
				if SaveManager.new_slot() != 0:
					_restart(), &"PrimaryButton")
			add.name = "NewSave"
			box.add_child(add)
		else:
			box.add_child(UiKit.label("Máximo de %d saves. Exclua um para criar outro." % SaveManager.MAX_SLOTS, &"SmallLabel"))
		box.add_child(_version_label()))


## Linha "texto  [Sim] [Não]": preferência do aparelho (SaveManager grava em settings.json).
static func _toggle_row(parent: VBoxContainer, text: String, key: String, enabled: bool, apply: Callable) -> void:
	var row := UiKit.hbox(8)
	row.name = key + "Row"
	row.custom_minimum_size = Vector2(0, 56)
	row.add_child(UiKit.fill_label(text, &"StrongLabel"))
	var toggle := UiKit.toggle(enabled, func(on: bool) -> void:
		apply.call(on)
		Events.state_changed.emit())
	toggle.name = key + "Toggle"
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(toggle)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_child(row)
	parent.add_child(margin)


## Rodapé com a versão do jogo. Atalho de emergência: tocar nela força a atualização.
static func _version_label() -> Label:
	var version := UiKit.label("v%s %s" % [Database.version.get("version", "?"), Database.version.get("date", "")], &"SmallLabel", Palette.INK_SOFT)
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
	# Linha de lista: ✓ + nome, chips de capítulo/moedas e a ação; o save em uso é a linha pronta (GO_SOFT).
	var card := VBoxContainer.new()
	card.name = "Save_%d" % slot
	var body := UiKit.vbox(8)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(body)
	card.add_child(margin)
	box.add_child(card)
	var title := UiKit.hbox(8)
	title.add_child(UiKit.fill_label("Save %d" % slot, &"StrongLabel"))
	if summary.active:
		title.add_child(UiKit.chip(null, "Jogando", null, "have"))
	var chips := UiKit.flow(4)
	var chapter := "Completo" if summary.finished else "Cap. %d/%d" % [int(summary.chapter), int(summary.chapters)]
	chips.add_child(UiKit.chip(UiKit.ui_icon("tab_tasks"), chapter))
	chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), str(int(summary.coins))))
	body.add_child(title)
	body.add_child(chips)
	var row := UiKit.hbox(6)
	var play := UiKit.soft("Jogando" if summary.active else "Jogar", func() -> void:
		SaveManager.switch_slot(slot)
		_restart(), null, true)
	play.name = "Play_%d" % slot
	play.disabled = summary.active
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(play)
	var default_button := UiKit.soft("É o padrão" if summary.default else "Tornar padrão", func() -> void:
		SaveManager.set_default_slot(slot)
		Events.state_changed.emit(), null, true)
	default_button.name = "Default_%d" % slot
	default_button.disabled = summary.default
	row.add_child(default_button)
	row.add_child(_delete_button(slot))
	body.add_child(row)


## Excluir pede um segundo toque ("Certeza?") para não apagar um save sem querer.
static func _delete_button(slot: int) -> Button:
	var button := UiKit.soft("Excluir", func() -> void: pass, null, true)
	button.name = "Delete_%d" % slot
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
