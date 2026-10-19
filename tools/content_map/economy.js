"use strict";
(() => {
  const el=id=>document.getElementById(id), E=(tag,cls,text)=>{const e=document.createElement(tag);if(cls)e.className=cls;if(text!=null)e.textContent=text;return e;};
  const fmt=n=>new Intl.NumberFormat("pt-BR",{maximumFractionDigits:1}).format(n||0), time=n=>n<60?`${fmt(n)} min`:`${fmt(n/60)} h`;
  const clean=s=>String(s).normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();
  const actions={sell:"Vendas",fulfill_order:"Encomendas",claim_quest:"Missões",claim_routine:"Rotinas",claim_daily_gift:"Presente diário",fulfill_wish:"Desejos",buy_upgrade:"Construções e melhorias",buy_animal:"Animais",buy_plot:"Canteiros",start_project:"Início de obras",contribute_project:"Materiais das obras",cook:"Produção",feed:"Alimentação",dig:"Achados",walk_return:"Volta de passeio",collect_walk:"Bagagem do passeio",give_friend:"Amigos",collect_station:"Coleta de produção",harvest_many:"Colheita",collect_gathering:"Coleta na Natureza",wait:"Durante espera",session_end:"Fim da sessão",sale:"Vendas",order:"Encomendas",daily_gift:"Presente diário",find:"Achados",friends:"Amigos",routine:"Rotinas",wish:"Desejos",bond:"Vínculo",chapter:"Capítulos",level:"Níveis",quest:"Missões"};
  const kindNames={upgrade:"Compra registrada",project:"Obra concluída",chapter:"Capítulo concluído",quest:"Missão concluída",item:"Primeira aquisição",recipe:"Primeiro preparo iniciado",world:"Mundo liberado",animal:"Animal comprado",event:"Marco registrado"};
  let payload,run,week=0,mode="diary",busy=false,active=true;
  function panel(){active=true;window.AtlasPacing?.suspend();el("economy-view").hidden=false;el("pacing-view").hidden=true;document.querySelector(".workspace").hidden=true;for(const id of ["economy","pacing","connections"])el("tab-"+id).classList.toggle("active",id==="economy");if(!payload)load();}
  for(const id of ["pacing","connections"])el("tab-"+id).addEventListener("click",()=>{active=false;el("economy-view").hidden=true;el("tab-economy").classList.remove("active");});
  el("tab-economy").onclick=panel;
  const option=(id,list,value)=>{el(id).replaceChildren(...list.map(x=>new Option(x.name,x.id)));el(id).value=value;};
  async function load(){
    if(busy)return;busy=true;
    try{
      const query=new URLSearchParams();for(const k of ["batch","profile","until"])if(el("eco-"+k).value)query.set(k,el("eco-"+k).value);
      const response=await fetch("/api/pacing?"+query,{cache:"no-store"});const p=await response.json();if(!response.ok)throw Error(p.error||"Falha ao ler resultados");
      payload=p;option("eco-batch",p.datasets.map(id=>({id,name:id.replace("etapa_","Etapa ")})),p.batch);option("eco-profile",p.profiles,p.profile);
      option("eco-until",p.horizons.map(id=>({id,name:({projects:"Obras comunitárias",campaign:"Todas as missões",days:"Limite de dias"})[id]||id})),p.until);
      const selected=el("eco-run").value;run=p.journeys?.find(r=>r.id===selected)||p.journeys?.[0];
      option("eco-run",(p.journeys||[]).map(r=>({id:r.id,name:`Semente ${r.seed} · ${r.status==="complete"?"objetivo concluído":"interrompida"}`})),run?.id||"");
      el("eco-validity").textContent=!run?"Nenhum resultado disponível neste recorte. Os arquivos do jogo continuam acessíveis em Conexões.":p.evidence.matching?"Relatório com os mesmos JSONs do jogo atual · leitura automática dos arquivos e resultados a cada 10 segundos.":"O jogo mudou desde esta simulação. Os números abaixo descrevem a versão do relatório; uma nova execução é necessária para medir o balanceamento atual.";
      el("eco-validity").classList.toggle("stale",!!run&&!p.evidence.matching);el("eco-error").hidden=true;el("eco-content").hidden=!run;if(run)render();
    }catch(error){el("eco-error").textContent=error.message+" · Última leitura preservada.";el("eco-error").hidden=false;}finally{busy=false;}
  }
  function allEvents(){return payload.rows.filter(r=>run.milestones[r.id]).map(r=>({...r,point:run.milestones[r.id]}));}
  function dayOf(r){return Math.floor((r.point.hours||0)/24)+1;}
  const inPeriod=day=>!week||Math.ceil(day/7)===week;
  function selectedDays(){return run.ledger.days.filter(d=>inPeriod(d.day));}
  function sums(days){const out={income:0,expense:0,active_min:0,items:{},storage:{},sources:{},sinks:{},waits:{}};
    for(const d of days){for(const key of ["income","expense","active_min"])out[key]+=d[key];for(const group of ["sources","sinks","waits"])for(const [k,v]of Object.entries(d[group]))out[group][k]=(out[group][k]||0)+v;
      for(const [id,v]of Object.entries(d.items)){const item=out.items[id]??={in:0,out:0,uses:{}};item.in+=v.in;item.out+=v.out;for(const [k,n]of Object.entries(v.uses))item.uses[k]=(item.uses[k]||0)+n;}
      for(const [id,v]of Object.entries(d.storage))if(v.ratio>(out.storage[id]?.ratio??-1))out.storage[id]=v;
    }return out;
  }
  function kpi(title,value,note){const card=E("div","eco-kpi");card.append(E("small","",title),E("strong","",value),E("span","",note));return card;}
  function render(){
    const end=run.end, events=allEvents(), count=Math.max(1,Math.ceil((end.days||0)/7),...run.ledger.days.map(d=>Math.ceil(d.day/7)));if(week>count)week=0;
    el("eco-kpis").replaceChildren(kpi("Dias corridos",`${fmt(end.days)} dias`,`${fmt(run.time.sessions)} sessões registradas`),kpi("Tempo ativo acumulado",time(run.time.active_min||0),"Ações do jogador automatizado"),kpi("Saldo final",`${fmt(end.coins)} moedas`,`${fmt(end.quests)} / ${fmt(end.quests_total)} missões concluídas`),kpi("Construções e melhorias",`${fmt(end.upgrades)} / ${fmt(end.upgrades_total)}`,run.status==="complete"?"Objetivo da execução concluído":"Execução interrompida · resultado parcial"));
    const weeks=el("eco-weeks");weeks.replaceChildren();for(let w=1;w<=count;w++){
      const ds=run.ledger.days.filter(d=>Math.ceil(d.day/7)===w), s=sums(ds), es=events.filter(r=>["upgrade","project","chapter"].includes(r.kind)&&Math.ceil(dayOf(r)/7)===w);
      const b=E("button","eco-week"+(week===w?" active":""));b.setAttribute("aria-pressed",week===w);b.append(E("strong","",`Semana ${w}`),E("small","",`Dias ${(w-1)*7+1}–${w*7}`),E("b","",`${es.length} construções / capítulos / obras`),E("span","",run.ledger.available?`${time(s.active_min)} ativos · saldo ${fmt(ds.at(-1)?.balance)} ◉`:"Sem histórico financeiro diário"));b.onclick=()=>{week=w;render();};weeks.append(b);
    }
    const ds=selectedDays(), s=sums(ds);el("eco-period").textContent=week?`Semana ${week} · dias ${(week-1)*7+1} a ${week*7}`:"Jornada inteira";el("eco-period-time").textContent=run.ledger.available?`${time(s.active_min)} ativos no período`:"Ledger indisponível";el("eco-source").textContent=run.id;
    renderMilestones();renderMoney(ds,s);renderResources(s);
    window.EconomyDiary.render({run,week,rows:payload.rows,actions,bars,openNode,showMilestone:id=>{mode="progress";for(const b of document.querySelectorAll("[data-eco-mode]"))b.classList.toggle("active",b.dataset.ecoMode===mode);render();window.EconomyTrail.choose(id);}});
    for(const key of ["diary","progress","money","resources"])el("eco-"+key).hidden=key!==mode;
  }
  function openNode(id){el("tab-connections").click();if(nodes.has(id))select(id);}
  function milestone(r,point){const b=E("button","eco-milestone");const node=nodes.get(r.node);if(node)b.append(icon(node));const box=E("div");box.append(E("small","",kindNames[r.kind]||r.kind),E("strong","",r.name));if(point){const day=Math.floor((point.hours||0)/24)+1;box.append(E("b","",`Semana ${Math.ceil(day/7)} · dia ${day}`),E("span","",`${time(point.active_min||0)} ativos · ${fmt(point.hours||0)} h corridas`));}else box.append(E("span","","Sem registro nesta execução"));b.append(box);b.onclick=()=>openNode(r.node);return b;}
  function renderMilestones(){const query=clean(el("eco-search").value),kind=el("eco-kind").value;
    const match=r=>(kind==="all"||kind==="main"&&["upgrade","chapter","project","animal"].includes(r.kind)||r.kind===kind)&&clean(r.name+" "+r.id).includes(query);
    const rows=allEvents().filter(r=>match(r)&&inPeriod(dayOf(r))).sort((a,b)=>a.point.active_min-b.point.active_min||a.point.hours-b.point.hours);
    const missing=payload.rows.filter(r=>match(r)&&!run.milestones[r.id]);el("eco-unreached-title").textContent=`${missing.length} elementos sem registro nesta execução`;
    window.EconomyTrail.render({run,rows:payload.rows,events:rows,missing,week,matching:payload.evidence.matching,card:milestone,openNode,redraw:renderMilestones});
  }
  function bars(root,values,label=key=>actions[key]||key,unit="",out=false){const sorted=Object.entries(values).filter(([,v])=>v>0).sort((a,b)=>b[1]-a[1]);if(!sorted.length){root.append(E("p","","Nenhum registro no período."));return;}const max=sorted[0][1];for(const [key,value]of sorted){const bar=E("div","eco-bar"+(out?" out":"")),head=E("header");head.append(E("span","",label(key)),E("strong","",`${fmt(value)}${unit}`));const track=E("div","eco-bar-track"),fill=E("div","eco-bar-fill");fill.style.width=`${value/max*100}%`;track.append(fill);bar.append(head,track);root.append(bar);}}
  function renderMoney(days,s){const root=el("eco-chart");root.replaceChildren();
    if(!run.ledger.available)root.append(E("div","eco-empty","Este relatório não possui ledger. O saldo final continua disponível no resumo."));
    else if(!days.length)root.append(E("div","eco-empty","Nenhum saldo registrado no período."));
    else{const values=days.filter(d=>d.balance!=null),max=Math.max(1,...values.map(d=>d.balance)),min=Math.min(0,...values.map(d=>d.balance)),width=620,height=260,pad=48;
      const chart=svg("svg",{viewBox:`0 0 ${width} ${height}`,class:"eco-chart-svg",role:"img","aria-label":"Saldo de moedas por dia"});
      const x=i=>pad+i*(width-pad*2)/Math.max(1,values.length-1),y=v=>height-pad-(v-min)/(max-min)*(height-pad*2);
      for(let i=0;i<3;i++){const val=min+(max-min)*i/2;chart.append(svg("line",{x1:pad,y1:y(val),x2:width-pad,y2:y(val),stroke:"#e8eddf"}),svg("text",{x:pad-8,y:y(val)+4,"text-anchor":"end",fill:"#7a8c73","font-size":10},fmt(val)));}
      chart.append(svg("polyline",{points:values.map((d,i)=>`${x(i)},${y(d.balance)}`).join(" "),fill:"none",stroke:"#6c9954","stroke-width":3}));
      values.forEach((d,i)=>{const dot=svg("circle",{cx:x(i),cy:y(d.balance),r:5,fill:"#527f3b",tabindex:0});dot.append(svg("title",{},`Dia ${d.day}: ${fmt(d.balance)} moedas`));chart.append(dot);if(values.length<=10||i%Math.ceil(values.length/8)===0||i===values.length-1)chart.append(svg("text",{x:x(i),y:height-19,"text-anchor":"middle",fill:"#7a8c73","font-size":11},`Dia ${d.day}`));});root.append(chart);
      const table=E("details"),summary=E("summary","","Ler valores por dia");table.append(summary);values.forEach(d=>table.append(E("p","",`Dia ${d.day}: ${fmt(d.balance)} moedas`)));root.append(table);
    }
    el("eco-flow-totals").replaceChildren(kpi("Entradas observadas",run.ledger.available?`+${fmt(s.income)}`:"—","moedas"),kpi("Saídas observadas",run.ledger.available?`−${fmt(s.expense)}`:"—","moedas"));const flows=el("eco-flows");flows.replaceChildren();flows.append(E("h4","","De onde vieram"));bars(flows,s.sources);flows.append(E("h4","","Para onde foram"));bars(flows,s.sinks,undefined,"",true);
    const official=el("eco-official-flow");official.replaceChildren();bars(official,Object.fromEntries(Object.entries(run.coin_flow).map(([k,v])=>[k,Math.abs(v)])),key=>{const [kind,action]=key.split(":");return `${({recurring:"Recorrente",unique:"Prêmio único",spend:"Gasto"})[kind]||kind} · ${actions[action]||action}`;});
  }
  function renderResources(s){const root=el("eco-items");root.replaceChildren();const query=clean(el("eco-item-search").value);const list=Object.entries(s.items).filter(([id])=>clean((nodes.get("item:"+id)?.name||id)+id).includes(query)).sort((a,b)=>(b[1].in+b[1].out)-(a[1].in+a[1].out));
    for(const [id,v]of list){const row=E("div","eco-item"),button=E("button"),node=nodes.get("item:"+id);if(node)button.append(icon(node));button.append(E("strong","",node?.name||id));button.onclick=()=>openNode("item:"+id);const values=E("div","eco-item-values");values.append(E("span","",`↓ Entraram ${fmt(v.in)}`),E("span","",`↑ Saíram ${fmt(v.out)}`));row.append(button,values,E("small","",Object.entries(v.uses).sort((a,b)=>b[1]-a[1]).map(([k,n])=>`${actions[k]||k}: ${fmt(n)}`).join(" · ")||"Sem saída registrada"));root.append(row);}if(!list.length)root.append(E("div","eco-empty","Nenhum material registrado neste filtro."));
    const storage=el("eco-storage");storage.replaceChildren();for(const [id,v]of Object.entries(s.storage)){const b=E("div","eco-bar"),head=E("header");head.append(E("span","",({silo:"Horta / silo",fridge:"Despensa / geladeira",warehouse:"Materiais / armazém",chest:"Passeio / baú"})[id]||id),E("strong","",`${fmt(v.ratio*100)}%`));const track=E("div","eco-bar-track"),fill=E("div","eco-bar-fill");fill.style.width=`${Math.min(100,v.ratio*100)}%`;if(v.ratio>=1)fill.style.background="#d6a36b";track.append(fill);b.append(head,track,E("small","",`${v.used} / ${v.capacity} espaços no pico observado`));storage.append(b);}if(!Object.keys(s.storage).length)storage.append(E("p","","Sem ocupação registrada."));
    const waits=el("eco-waits");waits.replaceChildren();bars(waits,s.waits,k=>({estacao:"Estações",lavoura:"Horta",natureza:"Natureza",passeio:"Passeio",desejo:"Desejos",faro:"Faro",necessidade:"Cuidados","recarga:care":"Recarga dos cuidados"})[k]||k," min");
  }
  for(const key of ["batch","profile","until"])el("eco-"+key).onchange=()=>{week=0;load();};
  el("eco-run").onchange=()=>{run=payload.journeys.find(r=>r.id===el("eco-run").value);week=0;render();};el("eco-all").onclick=()=>{week=0;render();};
  for(const b of document.querySelectorAll("[data-eco-mode]"))b.onclick=()=>{mode=b.dataset.ecoMode;for(const other of document.querySelectorAll("[data-eco-mode]"))other.classList.toggle("active",other===b);render();};
  el("eco-search").oninput=()=>run&&renderMilestones();el("eco-kind").onchange=()=>run&&renderMilestones();el("eco-item-search").oninput=()=>run&&renderResources(sums(selectedDays()));
  el("refresh").addEventListener("click",()=>{if(active)load();});setInterval(()=>{if(active&&!document.hidden)load();},10000);panel();
})();
