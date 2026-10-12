extends Node
## Atualização do PWA (autoload "PwaUpdater"). Só tem efeito na Web.
##
## O service worker do Godot serve o jogo do cache primeiro; uma versão nova
## publicada fica "esperando" até o app fechar de vez (o que quase nunca acontece
## no iPhone). Aqui pedimos ao navegador para procurar atualização ao abrir, ao
## voltar para o app e periodicamente; quando há versão nova, emitimos
## Events.update_available e a interface oferece apply_update().

const CHECK_INTERVAL := 300.0

var update_ready := false


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.pwa_update_available.connect(_on_update_available)
	var timer := Timer.new()
	timer.wait_time = CHECK_INTERVAL
	timer.autostart = true
	timer.timeout.connect(check_for_update)
	add_child(timer)
	check_for_update()
	if JavaScriptBridge.pwa_needs_update():
		_on_update_available()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and OS.has_feature("web"):
		check_for_update()


## Pede ao navegador para baixar o service worker novo, se houver.
func check_for_update() -> void:
	JavaScriptBridge.eval(
		"navigator.serviceWorker && navigator.serviceWorker.getRegistration().then((r) => r && r.update());",
		true
	)


## Salva o progresso, troca para a versão nova e recarrega a página.
##
## Não usamos JavaScriptBridge.pwa_update(): ela manda uma mensagem ao service
## worker que ele ignora quando o navegador não informa a origem (Safari/iOS),
## e nada acontece. Em vez disso: remove o service worker e o cache do jogo,
## baixa os arquivos direto do servidor e recarrega. O save (IndexedDB) fica intacto.
func apply_update() -> void:
	if not OS.has_feature("web"):
		return
	Events.toast_requested.emit("Atualizando...")
	SaveManager.save_game()
	# Dá tempo do save ser sincronizado com o IndexedDB antes de recarregar.
	await get_tree().create_timer(1.0).timeout
	JavaScriptBridge.eval("""
		(async () => {
			try {
				const regs = await navigator.serviceWorker.getRegistrations();
				await Promise.all(regs.map((r) => r.unregister()));
				const keys = await caches.keys();
				await Promise.all(keys.map((k) => caches.delete(k)));
				const files = ['index.html', 'index.js', 'index.pck', 'index.wasm', 'index.service.worker.js'];
				await Promise.all(files.map((f) => fetch(f, { cache: 'reload' }).catch(() => null)));
			} catch (e) {
				console.error('Falha ao atualizar', e);
			}
			location.reload();
		})();
	""", true)


func _on_update_available() -> void:
	if update_ready:
		return
	update_ready = true
	Events.update_available.emit()
