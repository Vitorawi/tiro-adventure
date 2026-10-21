"use strict";
window.EconomyTrail=(()=>{
  const E=(tag,cls,text)=>{const e=document.createElement(tag);if(cls)e.className=cls;if(text!=null)e.textContent=text;return e;};
  const el=id=>document.getElementById(id),fmt=n=>new Intl.NumberFormat("pt-BR",{maximumFractionDigits:1}).format(n);
  const day=p=>Math.floor(p.hours/24)+1,clock=p=>`Dia ${day(p)} · ${fmt(p.active_min)} min ativos acumulados`;
  let context,chosen="",scope="",expanded=new Set();
  const allowed=new Set(["requirement","sequence","shared","goal","input","cost","station","phase"]);
  function dependencies(row){
    if(row.kind==="chapter")return context.rows.filter(r=>r.kind==="quest"&&r.definition.kind==="main"&&Number(r.definition.chapter)===Number(row.node.split(":")[1])).map(r=>({source:r.node,target:row.node,label:"concluir missão do capítulo",relation:"goal"}));
    return (adjacency.get(row.node)||[]).filter(e=>e.target===row.node&&allowed.has(e.relation));
  }
  function evidence(edge,target){
    const node=nodes.get(edge.source),kind=node?.kind;
    const recorded=context.run.milestones[edge.source];
    const transaction=context.run.transactions?.[target.id];
    if(kind==="item"){
      const amount=transaction?.items[node.key];
      if(amount)return {state:"done",text:`${amount} consumido(s) · dia ${day(transaction)}`,point:transaction};
      return {state:"unknown",text:recorded?`1ª aquisição: dia ${day(recorded)} · quantidade não comprovada`:"Quantidade exigida sem data comprovada"};
    }
    if(["growth","upgrade","quest","project","animal","world"].includes(kind)&&recorded){
      if(!context.matching)return {state:"historical",text:`Registro histórico · dia ${day(recorded)}`,point:recorded};
      if(target.point&&recorded.active_min>target.point.active_min+.051)return {state:"unknown",text:`Registro posterior · dia ${day(recorded)}`,point:recorded};
      return {state:"done",text:clock(recorded),point:recorded};
    }
    return {state:"unknown",text:kind==="resource"?"Custo atual · sem instante de liberação":kind==="chapter"?"Exige entrada no capítulo, não sua conclusão":"Regra atual · sem data comprovada"};
  }
  function pick(id,scroll=true){chosen=id;renderDetail();context.redraw();if(scroll)el("eco-trail-detail").scrollIntoView({behavior:"smooth",block:"start"});}
  function rowFor(id){return context.rows.find(r=>r.id===id||r.node===id);}
  function edgeButton(edge,target){
    const n=nodes.get(edge.source),v=evidence(edge,target),b=E("button","trail-requirement "+v.state);if(n)b.append(icon(n));
    const text=E("span");text.append(E("strong","",n?.name||edge.source),E("small","",edge.label),E("b","",`${v.state==="done"?"✓ ":v.state==="historical"?"◷ ":"○ "}${v.text}`));b.append(text);
    const related=rowFor(edge.source);b.onclick=()=>related?pick(related.id):context.openNode(edge.source);return b;
  }
  function renderDetail(){
    const root=el("eco-trail-detail"),base=rowFor(chosen);root.hidden=!base;if(!base)return;
    const target={...base,point:context.run.milestones[base.id]},deps=dependencies(target);root.replaceChildren();
    const head=E("header","trail-detail-heading"),title=E("div");title.append(E("small","","CAMINHO ATÉ ESTE MARCO"),E("h3","",target.name));const close=E("button","","Fechar ×");close.onclick=()=>{chosen="";root.hidden=true;context.redraw();};head.append(title,close);root.append(head);
    root.append(E("p","trail-reading",context.matching?"✓ = evento observado na execução. ○ = condição sem momento comprovado. Os requisitos podem ser simultâneos; os tempos abaixo não medem espera causada por cada um.":"Regras do jogo atual × registros de outra versão. As datas históricas não comprovam que estes requisitos valiam naquela execução."));
    const chain=E("div","trail-chain"),before=E("section","trail-before");before.append(E("h4","","1 · O que precisava acontecer"));
    const progression=deps.filter(e=>!["input","cost","phase"].includes(e.relation));
    progression.sort((a,b)=>(evidence(a,target).point?.active_min??Infinity)-(evidence(b,target).point?.active_min??Infinity));
    for(const edge of progression)before.append(edgeButton(edge,target));
    if(!progression.length)before.append(E("p","","Nenhuma condição de progressão direta cadastrada para este marco."));
    const costs=deps.filter(e=>["input","cost","phase"].includes(e.relation));
    if(costs.length){before.append(E("h4","","Materiais, moedas e etapas"));for(const edge of costs){before.append(edgeButton(edge,target));if(edge.relation==="phase")for(const material of (adjacency.get(edge.source)||[]).filter(e=>e.target===edge.source&&e.relation==="input"))before.append(edgeButton(material,target));}}
    const arrival=E("section","trail-arrival");arrival.append(E("h4","","2 · Marco alcançado"));const n=nodes.get(target.node);if(n)arrival.append(icon(n));arrival.append(E("h3","",target.name));
    if(target.point){arrival.append(E("strong","",`Semana ${Math.ceil(day(target.point)/7)} · dia ${day(target.point)}`),E("p","",`${fmt(target.point.hours)} h corridas desde o início${target.point.approximate?" (dia aproximado do resumo)":""}\n${fmt(target.point.active_min)} min ativos acumulados`));
      const known=progression.map(e=>evidence(e,target)).filter(v=>v.state==="done"&&v.point&&v.point.active_min<=target.point.active_min&&v.point.hours<=target.point.hours);
      if(known.length){const last=known.reduce((a,b)=>a.point.hours>b.point.hours?a:b);arrival.append(E("small","",`${fmt(target.point.hours-last.point.hours)} h corridas entre o último requisito com registro anterior e este marco. Isso não identifica a causa da demora.`));}
    }else arrival.append(E("p","","Marco sem registro nesta execução."));
    const tx=context.run.transactions?.[target.id];if(tx&&tx.before!=null&&tx.after!=null)arrival.append(E("div","trail-wallet",`Moedas na compra\n${fmt(tx.before)} → ${fmt(tx.after)}\nSaldo observado, incluindo prêmios da ação.`));
    const map=E("button","","Ver todas as conexões ↗");map.onclick=()=>context.openNode(target.node);arrival.append(map);
    const after=E("section","trail-after");after.append(E("h4","","3 · Ajuda a abrir"));const seen=new Set();
    for(const edge of adjacency.get(target.node)||[]){if(edge.source!==target.node||!["requirement","sequence","shared","goal","station"].includes(edge.relation)||seen.has(edge.target))continue;seen.add(edge.target);const related=rowFor(edge.target),node=nodes.get(edge.target),p=related&&context.run.milestones[related.id],b=E("button","trail-next");b.append(E("strong","",node?.name||edge.target),E("small","",p?clock(p):"Sem evento registrado"),E("small","",edge.label));b.onclick=()=>related?pick(related.id):context.openNode(edge.target);after.append(b);}
    if(!seen.size)after.append(E("p","","Nenhum próximo marco direto identificado."));else after.append(E("p","","Pode haver outros requisitos para cada próximo marco."));chain.append(before,arrival,after);root.append(chain);
  }
  function decorate(row,point){const button=context.card(row,point);button.classList.toggle("trail-selected",chosen===row.id);button.onclick=()=>pick(row.id);button.setAttribute("aria-expanded",chosen===row.id);
    const deps=dependencies(row),checked=deps.filter(e=>evidence(e,{...row,point}).state==="done");if(deps.length){const chips=E("div","trail-chips");for(const edge of deps.slice(0,3)){const v=evidence(edge,{...row,point});chips.append(E("span",v.state,`${v.state==="done"?"✓":"○"} ${nodes.get(edge.source)?.name||edge.source}`));}if(deps.length>3)chips.append(E("span","",`+${deps.length-3} requisitos`));button.append(chips,E("small","trail-card-action",`${checked.length} / ${deps.length} com registro · ver caminho →`));}else button.append(E("small","trail-card-action","Ver caminho →"));return button;}
  function render(c){context=c;const key=`${c.run.id}:${c.run.seed}`;if(scope!==key){scope=key;chosen="";expanded.clear();}
    const root=el("eco-milestones"),nav=el("eco-day-nav");root.replaceChildren();nav.replaceChildren();
    const groups=new Map();for(const r of c.events){const d=day(r.point);if(!groups.has(d))groups.set(d,[]);groups.get(d).push(r);}
    const last=Math.max(1,Math.floor((c.run.end.days||0))+1,...[...groups.keys()]);const start=c.week?(c.week-1)*7+1:1,end=c.week?Math.min(c.week*7,last):last;
    for(let d=start;d<=end;d++){
      const rows=groups.get(d)||[],b=E("button","trail-day-tab"+(rows.length?"":" quiet"));b.append(E("strong","",`Dia ${d}`),E("span","",`${rows.length} marcos`));b.onclick=()=>el(`trail-day-${d}`)?.scrollIntoView({behavior:"smooth",block:"start"});nav.append(b);
      const section=E("section","trail-day"+(rows.length?"":" quiet"));section.id=`trail-day-${d}`;const heading=E("header","trail-day-heading");heading.append(E("strong","",`Dia ${d}`),E("span","",`Semana ${Math.ceil(d/7)}`),E("small","",`${rows.length} marcos neste filtro`));section.append(heading);
      const cards=E("div","eco-milestones");for(const r of (expanded.has(d)?rows:rows.slice(0,6)))cards.append(decorate(r,r.point));section.append(cards);
      if(!rows.length)section.append(E("p","","Sem novo marco neste filtro. Pode haver produção e outras atividades neste dia."));
      if(rows.length>6){const more=E("button","trail-more",expanded.has(d)?"Recolher dia":`Mostrar mais ${rows.length-6} marcos deste dia`);more.onclick=()=>{expanded.has(d)?expanded.delete(d):expanded.add(d);c.redraw();};section.append(more);}root.append(section);
    }
    if(!c.events.length)root.prepend(E("p","eco-empty","Nenhum marco registrado neste filtro e período."));
    el("eco-unreached").replaceChildren(...c.missing.map(r=>decorate(r)));
    renderDetail();
  }
  return {render,choose:pick};
})();
