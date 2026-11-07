"""Teste do HTML exportado em Chrome: fases, progresso, falhas, layout e partida real.

Requer playwright; inicia servidor local próprio e usa perfis descartáveis.
"""
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import threading
from playwright.sync_api import sync_playwright

root = Path(__file__).resolve().parents[1]
shots = root / 'build/screenshots/loading'
shots.mkdir(parents=True, exist_ok=True)
class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass

server = ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(root / 'build/web')))
threading.Thread(target=server.serve_forever, daemon=True).start()
url = 'http://127.0.0.1:%d/' % server.server_port
stub = '''window.Engine = class {
 static getMissingFeatures() {return []}
 startGame(options) {window.testProgress = options.onProgress; return new Promise(()=>{});}
};'''
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe', headless=True)
        context = browser.new_context(viewport={'width': 360, 'height': 780}, service_workers='block')
        context.route('**/index.js', lambda route: route.fulfill(body=stub, content_type='application/javascript'))
        page = context.new_page()
        errors = []
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.goto(url)
        for phase, art in [('newborn', 'puppy'), ('puppy', 'puppy'), ('teething', 'farm'), ('explorer', 'farm'), ('young', 'farm'), ('adult', 'farm'), ('invalid', 'puppy')]:
            page.evaluate('(phase) => TiroLoading.remember(phase)', phase)
            page.reload()
            page.wait_for_function('document.getElementById("loading-scene").complete && document.getElementById("loading-scene").naturalWidth > 0')
            assert page.locator('#loading-scene').get_attribute('src') == 'loading/' + art + '.webp', phase
        for width, height in [(360, 780), (390, 844), (412, 915)]:
            page.set_viewport_size({'width': width, 'height': height})
            for phase in ['puppy', 'teething']:
                page.evaluate('(phase) => TiroLoading.remember(phase)', phase)
                page.reload()
                page.wait_for_function('[...document.images].every(i => i.complete && i.naturalWidth > 0)')
                page.evaluate('testProgress(50, 100)')
                assert page.locator('#loading-meter').get_attribute('aria-valuenow') == '50'
                assert page.locator('#loading-fill').evaluate('(e) => e.style.clipPath') == 'inset(0px 50% 0px 0px)'
                logo = page.locator('#loading-logo').bounding_box()
                bar = page.locator('#loading-meter').bounding_box()
                assert logo['y'] + logo['height'] < height * .25
                assert bar['y'] > height * .85
                page.screenshot(path=str(shots / ('%s_%d.png' % (phase, width))))
        page.evaluate('testProgress(100, 100)')
        assert page.locator('#loading').is_visible(), 'Download completo espera primeiro frame'
        assert 'Preparando' in page.locator('#loading-label').inner_text()
        page.evaluate('TiroLoading.ready()')
        page.wait_for_selector('#loading', state='detached')
        page.goto(url + 'dev/')
        assert page.locator('#loading').get_attribute('data-phase') == 'newborn', 'Dev isolada da publicada'
        page.evaluate('TiroLoading.fail("falha simulada")')
        assert page.locator('#loading-retry').is_visible()
        assert not page.locator('#loading-meter').is_visible()
        page.reload()
        page.evaluate('Object.defineProperty(window, "localStorage", {get() {throw new Error("bloqueado")}})')
        page.add_script_tag(url=url + 'loading.js')
        assert page.locator('#loading').get_attribute('data-phase') == 'newborn'
        page.evaluate('TiroLoading.remember("adult")')
        assert not errors, errors
        context.close()
        print('LOADING HTML: fases, canais, progresso, falhas e 6 capturas PASS', flush=True)
        real = browser.new_context(viewport={'width': 390, 'height': 844})
        game = real.new_page()
        real_errors = []
        game.on('pageerror', lambda e: real_errors.append(str(e)))
        game.goto(url + 'dev/', wait_until='domcontentloaded')
        game.wait_for_selector('#loading', state='detached', timeout=120000)
        assert game.locator('canvas').is_visible()
        assert game.evaluate('localStorage.getItem("tiro:loading:v1:/dev/")') == 'newborn'
        game.screenshot(path=str(shots / 'game_ready.png'))
        assert not real_errors, real_errors
        print('LOADING WEB: motor real, primeiro frame e dica de fase PASS', flush=True)
        game.evaluate('navigator.serviceWorker.ready')
        # O SW padrão do Godot só controla a próxima navegação (não usa clients.claim).
        game.reload(wait_until='domcontentloaded')
        game.wait_for_selector('#loading', state='detached', timeout=120000)
        game.wait_for_function('navigator.serviceWorker.controller !== null', timeout=60000)
        real.set_offline(True)
        game.reload(wait_until='domcontentloaded')
        game.wait_for_selector('#loading', state='detached', timeout=120000)
        assert not real_errors, real_errors
        print('LOADING OFFLINE: reload completo com artes e motor em cache PASS', flush=True)
        browser.close()
finally:
    server.shutdown()
