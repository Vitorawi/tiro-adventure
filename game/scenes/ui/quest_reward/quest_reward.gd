class_name QuestReward
extends CanvasLayer
## Folha de um passo já pago (base: `RewardSheet`). A fila da casca é a única responsável por abri-la.

func _ready() -> void:
	layer = 24
	hide()

func open(id: String, next: String = "") -> void:
	if next == "": next = GameState.progress.current_main_quest()
	var quest: Dictionary = Database.quests[id]
	var next_quest: Dictionary = Database.quests.get(next, {})
	var npc := str(quest.get("npc", "lais"))
	var text := str(next_quest.get("dialogue", ""))
	if text == "": text = str(Database.npcs.get(npc, {}).get("greeting", ""))
	var sheet := RewardSheet.open(self, {"title": "Passo concluído!", "ribbon": Palette.GO, "ribbon_icon": "check",
		"speech": {"npc": npc, "text": text}, "haptic": ""})
	var chips := UiKit.flow(8)
	chips.name = "RewardChips"
	var rewards: Dictionary = quest.get("rewards", {})
	if int(rewards.get("coins", 0)) > 0: chips.add_child(RewardSheet.prize_chip("RewardChip_coins", UiKit.ui_icon("coin"), int(rewards.coins)))
	for item: String in rewards.get("items", {}):
		chips.add_child(RewardSheet.prize_chip("RewardChip_" + item, Database.item_icon(item), int(rewards.items[item]), Database.items.get(item, {}).get("category", "") == "keepsake"))
	sheet.body.add_child(chips)
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	if not Motion.reduced: RewardSheet.reveal_in(chips)
	if next != "":
		sheet.add(UiKit.section("Próximo passo"))
		sheet.add(ProgressionUi.next_step_card(next))
	var target := Places.quest_target(next) if next != "" else {}
	var actions := sheet.add_actions("Depois" if next != "" else "", close,
		"Ir para " + ProgressionUi.quest_place_name(target) if next != "" else "Que bom!", func() -> void:
			close()
			if next != "": Places.go(target))
	if actions.soft: (actions.soft as Button).name = "RewardLater"
	(actions.primary as Button).name = "RewardGo"
	show()
	Haptics.success()
	sheet.present()

func close() -> void:
	hide()
