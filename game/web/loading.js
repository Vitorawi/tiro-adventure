/* Tela anterior ao motor. O save continua no IndexedDB; aqui há só uma dica visual. */
(() => {
  'use strict';
  const phases = ['newborn', 'puppy', 'teething', 'explorer', 'young', 'adult'];
  const scope = location.pathname.replace(/index\.html$/, '').replace(/\/$/, '') + '/';
  const key = 'tiro:loading:v1:' + scope;
  const scene = document.getElementById('loading-scene');
  const overlay = document.getElementById('loading');
  const meter = document.getElementById('loading-meter');
  const fill = document.getElementById('loading-fill');
  const label = document.getElementById('loading-label');
  let value = 0;
  let finished = false;
  function normalize(phase) { return phases.includes(phase) ? phase : 'newborn'; }
  function read() {
    try { return normalize(localStorage.getItem(key)); } catch (_) { return 'newborn'; }
  }
  const phase = read();
  scene.src = 'loading/' + (['newborn', 'puppy'].includes(phase) ? 'puppy' : 'farm') + '.webp';
  overlay.dataset.phase = phase;
  window.TiroLoading = {
    remember(phase) {
      try { localStorage.setItem(key, normalize(phase)); } catch (_) { /* Navegação privada/sem espaço. */ }
    },
    progress(current, total) {
      if (finished) return;
      if (total > 0) {
        // O download pode terminar antes da inicialização. Não inventa porcentagem nessa etapa.
        value = Math.max(value, Math.min(1, current / total));
        fill.style.clipPath = `inset(0 ${(1 - value) * 100}% 0 0)`;
        meter.setAttribute('aria-valuenow', String(Math.round(value * 100)));
        label.textContent = value === 1 ? 'Preparando o cantinho do Tiro…' : 'Carregando… ' + Math.round(value * 100) + '%';
      } else {
        label.textContent = 'Preparando o cantinho do Tiro…';
        meter.removeAttribute('aria-valuenow');
      }
    },
    ready() {
      if (finished) return;
      finished = true;
      fill.style.clipPath = 'inset(0 0 0 0)';
      meter.setAttribute('aria-valuenow', '100');
      overlay.classList.add('finished');
      setTimeout(() => overlay.remove(), matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 220);
    },
    fail(error) {
      if (finished) return;
      console.error(error);
      label.textContent = 'Não foi possível abrir o jogo. Confira a conexão e tente novamente.';
      document.getElementById('loading-retry').hidden = false;
      meter.hidden = true;
    }
  };
  document.getElementById('loading-retry').onclick = () => location.reload();
})();
