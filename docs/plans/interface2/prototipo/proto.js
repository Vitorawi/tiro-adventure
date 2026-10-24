// Protótipo: ícones de controle vetoriais (traços no estilo Lucide, licença ISC) e anéis de progresso.
const ICONS = {
  x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  chev: '<path d="m9 18 6-6-6-6"/>',
  down: '<path d="m6 9 6 6 6-6"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  lock: '<rect width="16" height="11" x="4" y="11" rx="3"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
  plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
  minus: '<path d="M5 12h14"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  help: '<circle cx="12" cy="12" r="9"/><path d="M9.3 9a2.8 2.8 0 0 1 5.4 1c0 1.9-2.7 2.5-2.7 2.5"/><path d="M12 16.5h.01"/>',
  list: '<path d="M9 6h11"/><path d="M9 12h11"/><path d="M9 18h11"/><path d="M4 6h.01"/><path d="M4 12h.01"/><path d="M4 18h.01"/>',
  arrow: '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
  spark: '<path d="M12 3.5l1.8 4.9 4.9 1.8-4.9 1.8L12 17l-1.8-5-4.9-1.8 4.9-1.8z"/><path d="M19 15.5l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z"/>',
  gear: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
};

function ringSvg(size, width, progress, color, track) {
  const r = (size - width) / 2;
  const c = 2 * Math.PI * r;
  return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
    <circle cx="${size / 2}" cy="${size / 2}" r="${r}" stroke="${track}" stroke-width="${width}" fill="none"/>
    <circle cx="${size / 2}" cy="${size / 2}" r="${r}" stroke="${color}" stroke-width="${width}" fill="none"
      stroke-linecap="round" stroke-dasharray="${c * progress} ${c}"/></svg>`;
}

document.querySelectorAll('i[data-ic]').forEach((el) => {
  const size = el.dataset.size || 20;
  const stroke = el.dataset.stroke || 2.4;
  el.outerHTML = `<svg class="ic" style="width:${size}px;height:${size}px;stroke-width:${stroke}" viewBox="0 0 24 24">${ICONS[el.dataset.ic]}</svg>`;
});

// <div class="ringbox" data-ring="tamanho,espessura,progresso,cor[,trilho]">conteúdo</div>
document.querySelectorAll('[data-ring]').forEach((el) => {
  const [size, width, progress, color, track] = el.dataset.ring.split(',');
  el.style.width = size + 'px';
  el.style.height = size + 'px';
  el.insertAdjacentHTML('afterbegin', ringSvg(+size, +width, +progress, color, track || '#F6EDE0'));
});

// <nav class="tabbar" data-active="tasks" data-badges="map:4,tasks:2"></nav>: quatro abas, todas com nome.
const TABS = [['pet', 'tab_pet', 'Tiro'], ['map', 'tab_map', 'Mapa'], ['tasks', 'tab_tasks', 'Missões'], ['bag', 'tab_bag', 'Mochila']];
document.querySelectorAll('nav.tabbar').forEach((nav) => {
  const badges = Object.fromEntries((nav.dataset.badges || '').split(',').filter(Boolean).map((b) => b.split(':')));
  nav.innerHTML = TABS.map(([id, icon, label]) => `<div class="tab ${id === nav.dataset.active ? 'on' : ''}"><div class="ico">
    <img class="px" src="../../../../game/assets/sprites/ui/icons/${icon}.png">${badges[id] ? `<span class="badge">${badges[id]}</span>` : ''}</div>
    <span class="l">${label}</span></div>`).join('');
});
if (location.hash.includes('escuro')) document.body.classList.add('nav-dark');
