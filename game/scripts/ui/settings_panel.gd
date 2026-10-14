class_name SettingsPanel
extends RefCounted
## Painel de configurações (engrenagem na barra superior): vários saves.
## Cada save mostra nível, capítulo e moedas; dá para jogar nele, torná-lo o padrão (o que o
## jogo abre ao iniciar), excluí-lo (com confirmação) ou começar um save novo.
## Trocar de save recarrega a cena principal: tudo é reconstruído a partir do estado carregado.


static func open() -> void:
	Events.sheet_requested.emit("Configurações", panel())


static func panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_child(UiKit.label("Saves", &"SectionLabel"))
		box.add_child(UiKit.label("Toque em Jogar para trocar de save.", &"SmallLabel"))
		for summary: Dictionary in SaveManager.list_slots():
			_slot_card(box, summary)
		if SaveManager.can_add_slot():
			var add := UiKit.button("+ Novo save", func() -> void:
				if SaveManager.new_slot() != 0:
					_restart(), &"PrimaryButton")
			add.name = "NewSave"
			box.add_child(add)
		else:
			box.add_child(UiKit.label("Máximo de %d saves. Exclua um para criar outro." % SaveManager.MAX_SLOTS, &"SmallLabel")))


static func _slot_card(box: VBoxContainer, summary: Dictionary) -> void:
	var slot := int(summary.slot)
	var card := UiKit.card(box, &"ReadyCardPanel" if summary.active else &"CardPanel")
	card.name = "Save_%d" % slot
	var title := UiKit.hbox(8)
	title.add_child(UiKit.fill_label("Save %d" % slot, &"SectionLabel"))
	if summary.active:
		title.add_child(UiKit.short_label("Jogando", &"SmallLabel", UiKit.GOOD))
	card.add_child(title)
	var chips := UiKit.flow(4)
	chips.add_child(UiKit.chip(UiKit.ui_icon("xp"), "Nível %d" % int(summary.level)))
	var chapter := "Completo" if summary.finished else "Cap. %d/%d" % [int(summary.chapter), int(summary.chapters)]
	chips.add_child(UiKit.chip(UiKit.ui_icon("tab_tasks"), chapter))
	chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), str(int(summary.coins))))
	card.add_child(chips)
	var row := UiKit.hbox(6)
	var play := UiKit.button("Jogando" if summary.active else "Jogar", func() -> void:
		SaveManager.switch_slot(slot)
		_restart(), &"PrimaryButton")
	play.name = "Play_%d" % slot
	play.disabled = summary.active
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(play)
	var default_button := UiKit.button("É o padrão" if summary.default else "Tornar padrão", func() -> void:
		SaveManager.set_default_slot(slot)
		Events.state_changed.emit())
	default_button.name = "Default_%d" % slot
	default_button.disabled = summary.default
	row.add_child(default_button)
	row.add_child(_delete_button(slot))
	card.add_child(row)


## Excluir pede um segundo toque ("Certeza?") para não apagar um save sem querer.
static func _delete_button(slot: int) -> Button:
	var button := UiKit.button("Excluir", func() -> void: pass)
	button.name = "Delete_%d" % slot
	button.pressed.connect(func() -> void:
		if not button.has_meta("armed"):
			button.set_meta("armed", true)
			button.text = "Certeza?"
			button.modulate = Color(1.0, 0.6, 0.55)
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
