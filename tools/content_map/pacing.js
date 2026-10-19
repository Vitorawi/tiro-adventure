"use strict";
(() => {
  const el=id=>document.getElementById(id),element=(tag,cls,text)=>{const e=document.createElement(tag);if(cls)e.className=cls;if(text!==undefined)e.textContent=text;return e;};
  const clean=s=>String(s).normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();
  const number=n=>new Intl.NumberFormat("pt-BR",{maximumFractionDigits:1}).format(n);
  const minutes=n=>n<60?`${number(n)} min`:`${Math.floor(Math.round(n)/60)} h${Math.round(n)%60?` ${Math.round(n)%60} min`:""}`;
  const range=v=>!v?"Sem registro":Math.abs(v.max-v.min)<.11?minutes(v.median):`${minutes(v.min)} – ${minutes(v.max)}`;
  const targetText=t=>!t||t.min==null&&t.max==null?"Definir meta":t.min==null?`Até ${minutes(t.max)}`:t.max==null?`A partir de ${minutes(t.min)}`:`${minutes(t.min)} – ${minutes(t.max)}`;
  let payload,draft={},dirty=false,chosen="",busy=false,active=false,saveBusy=false,invalid=false,editorOpen=false;
  const labels={early:"Antes da faixa",late:"Depois da faixa",within:"Dentro da faixa",stale:"Dados de outra versão",unmeasured:"Sem registro",no_target:"Sem meta definida"};
  function panel(pacing){active=pacing;el("pacing-view").hidden=!pacing;document.querySelector(".workspace").hidden=pacing;el("tab-pacing").classList.toggle("active",pacing);el("tab-connections").classList.toggle("active",!pacing);if(pacing&&!payload)load();if(!pacing&&typeof renderMap==="function")renderMap();}
  function options(id,list,selected){el(id).replaceChildren(...list.map(v=>new Option(v.name||v.id,v.id)));el(id).value=selected;}
  function error(text){el("pacing-error").textContent=text;el("pacing-error").hidden=false;}
  function status(row){
    const target=draft[row.id];if(!target||target.min==null&&target.max==null)return "no_target";
    if(!row.active)return "unmeasured";if(!payload.evidence.matching)return "stale";
    return target.min!=null&&row.active.median<target.min?"early":target.max!=null&&row.active.median>target.max?"late":"within";
  }
  async function load(){
    if(busy||saveBusy)return;busy=true;el("pacing-reload").disabled=true;
    try{
      const query=new URLSearchParams();for(const key of ["batch","profile","until"]){const value=el("pacing-"+key).value;if(value)query.set(key,value);}
      const response=await fetch("/api/pacing?"+query,{cache:"no-store"}),value=await response.json();if(!response.ok)throw Error(value.error||"Falha ao ler arquivos");
      payload=value;if(!dirty)draft=structuredClone(value.plan.targets);
      options("pacing-batch",value.datasets.map(id=>({id,name:id.replace("etapa_","Etapa ")})),value.batch);
      options("pacing-profile",value.profiles,value.profile);
      options("pacing-until",value.horizons.map(id=>({id,name:{projects:"Obras comunitárias",campaign:"Todas as missões",days:"Horizonte em dias"}[id]||id})),value.until);
      const evidence=value.evidence;
      const valid=evidence.runs?evidence.matching?"JSONs iguais aos atuais":"ATENÇÃO: JSONs diferentes dos atuais":"Nenhum relatório neste recorte";
      el("pacing-evidence").textContent=`Referência SIMULADA já gravada · ${evidence.runs} jornada(s) · ${valid}.`;
      el("pacing-evidence").classList.toggle("stale",!!evidence.runs&&!evidence.matching);el("pacing-error").hidden=true;
      if(!chosen||!value.rows.some(r=>r.id===chosen))chosen="upgrade:stove";
      render();editor();sources();if(editorOpen)el("pacing-editor-close").focus();
    }catch(e){error(e.message+". Confira se o painel está rodando com a versão nova do servidor.");}
    finally{busy=false;el("pacing-reload").disabled=false;}
  }
  function filtered(){
    const kind=el("pacing-kind").value,query=clean(el("pacing-search").value),attention=el("pacing-attention").checked;
    return payload.rows.filter(r=>(kind==="all"||kind==="highlights"&&r.highlight||kind==="targets"&&draft[r.id]&&(draft[r.id].min!=null||draft[r.id].max!=null)||r.kind===kind)&&(!query||clean(r.name+" "+r.id).includes(query))&&(!attention||["early","late"].includes(status(r))))
      .sort((a,b)=>(a.active?.median??draft[a.id]?.max??draft[a.id]?.min??1e9)-(b.active?.median??draft[b.id]?.max??draft[b.id]?.min??1e9)||a.name.localeCompare(b.name,"pt-BR"));
  }
  function render(){
    if(!payload)return;
    const stats=el("pacing-stats");stats.replaceChildren();
    const counts={early:0,late:0,within:0};for(const r of payload.rows){const s=status(r);if(s in counts)counts[s]++;}
    for(const [value,title,note]of [[Object.values(draft).filter(t=>t.min!=null||t.max!=null).length,"Metas definidas","Faixas acumuladas desde o início"],[counts.early,"Antes da faixa","Pode haver conteúdo apresentado cedo"],[counts.late,"Depois da faixa","Investigar esperas e dependências"],[payload.evidence.runs,"Jornadas de referência","Amostra automatizada, sem teste humano"]]){
      const card=element("div","pacing-stat");card.append(element("strong","",value),element("span","",title),element("small","",note));stats.append(card);
    }
    const rows=filtered(),max=Math.max(60,...rows.flatMap(r=>[r.active?.max||0,draft[r.id]?.max||draft[r.id]?.min||0]));
    const scale=n=>Math.log1p(n)/Math.log1p(max)*100;
    el("pacing-axis").replaceChildren();for(const tick of [0,10,60,360,1440].filter(v=>v<=max)){const text=element("span","",number(tick));text.style.left=scale(tick)+"%";el("pacing-axis").append(text);}
    const body=el("pacing-rows");body.replaceChildren();
    for(const row of rows){
      const tr=element("tr",row.id===chosen?"selected":"");tr.dataset.milestone=row.id;
      const title=element("td"),name=element("button","milestone-name",row.name);name.onclick=()=>chooseMilestone(row.id);title.append(name,element("small","",row.id));
      const target=element("td"),edit=element("button","target-button",targetText(draft[row.id]));edit.onclick=name.onclick;target.append(edit);
      const observed=element("td");observed.append(element("strong","",range(row.active)),element("small","",row.active?`${row.reached}/${row.total} jornada(s) alcançaram`:"Não alcançado ou não registrado"));
      const calendar=element("td");calendar.append(element("strong","",row.hours?row.hours.median<24?`${number(row.hours.median)} h`:`${number(row.hours.median/24)} dias`:"—"),element("small","",row.sessions?`Sessão ${number(row.sessions.median)}`:"Calendário não estimado"));
      const timeline=element("td"),track=element("div","pacing-track"),t=draft[row.id];
      if(t&&(t.min!=null||t.max!=null)){const band=element("span","target-band");band.style.left=scale(t.min||0)+"%";band.style.width=Math.max(.7,scale(t.max??max)-scale(t.min||0))+"%";band.title="Meta: "+targetText(t);track.append(band);}
      if(row.active){const mark=element("span","observed-dot");mark.style.left=scale(row.active.median)+"%";mark.title="Registrado: "+range(row.active);track.append(mark);}
      timeline.append(track);const judgment=element("td"),s=status(row);judgment.append(element("span","pacing-badge "+s,labels[s]));
      if(t?.basis&&t.basis!=="user")judgment.append(element("small","",t.basis==="R1"?"Meta do plano R1":"Referência acumulada provisória"));
      tr.append(title,target,observed,calendar,timeline,judgment);body.append(tr);
    }
    if(!rows.length){const tr=element("tr"),td=element("td","","Nenhum marco neste filtro.");td.colSpan=6;tr.append(td);body.append(tr);}
    window.PacingCalendar.render({payload,rows,targets:draft,status,choose:chooseMilestone,time:minutes,chosen});
    el("pacing-table-note").textContent=`${rows.length} marcos neste recorte. Toque em uma conquista para ver o tempo jogado e editar a meta. ${payload.evidence.runs===1?"Esta referência vem de uma única jornada automatizada.":"Os tempos registrados são medianas da amostra."}`;
    el("pacing-save").disabled=!dirty||saveBusy||invalid;
    if(el("pacing-editor-save"))el("pacing-editor-save").disabled=!dirty||saveBusy||invalid;
  }
  function chooseMilestone(id){if(saveBusy)return;chosen=id;editorOpen=true;render();editor();el("pacing-editor-close").focus();}
  function closeEditor(){editorOpen=false;invalid=false;el("pacing-editor").hidden=true;el("pacing-editor-backdrop").hidden=true;document.body.classList.remove("pacing-editing");if(payload)render();const focus=[...document.querySelectorAll('[data-calendar-milestone], [data-milestone] .milestone-name')].find(node=>(node.dataset.calendarMilestone||node.closest('[data-milestone]')?.dataset.milestone)===chosen&&node.getClientRects().length);(focus||el("tab-pacing")).focus();}
  function editor(){
    const root=el("pacing-editor");root.replaceChildren();invalid=false;if(!payload)return;
    root.hidden=!editorOpen;el("pacing-editor-backdrop").hidden=!editorOpen;document.body.classList.toggle("pacing-editing",editorOpen);
    root.setAttribute("role","dialog");root.setAttribute("aria-modal","true");root.setAttribute("aria-labelledby","pacing-editor-title");
    const row=payload.rows.find(r=>r.id===chosen);if(!row)return;
    const close=element("button","pacing-editor-close","×");close.id="pacing-editor-close";close.setAttribute("aria-label","Fechar edição da meta");close.onclick=closeEditor;root.append(close);
    root.append(element("div","eyebrow","META DE TEMPO"),element("h2","",row.name),element("p","","Defina a faixa de tempo ativo acumulado em que essa conquista deve acontecer."));
    root.querySelector("h2").id="pacing-editor-title";
    const target=draft[row.id]||{},form=element("div","target-form");
    for(const [field,label]of [["min","Não antes de · minutos"],["max","Até · minutos"]]){const l=element("label","",label),input=element("input");input.type="number";input.min="0";input.max="100000";input.step="0.1";input.id="target-"+field;input.value=target[field]??"";input.placeholder=field==="min"?"Sem mínimo":"Sem máximo";l.append(input);form.append(l);}
    const noteLabel=element("label","","Intenção / hipótese"),notes=element("textarea");notes.id="target-note";notes.maxLength=1000;notes.rows=4;notes.value=target.note||"";noteLabel.append(notes);form.append(noteLabel);root.append(form);
    const feedback=element("div","target-feedback",dirty?"Há alterações pendentes de salvar.":"Metas guardadas em arquivo separado do jogo.");feedback.id="target-feedback";
    const commit=()=>{
      const low=el("target-min").value,high=el("target-max").value,min=low===""?null:Number(low),max=high===""?null:Number(high);
      if([...form.querySelectorAll("input")].some(i=>!i.validity.valid)||[min,max].some(v=>v!==null&&(!Number.isFinite(v)||v<0||v>100000))||min!==null&&max!==null&&min>max){invalid=true;el("pacing-save").disabled=true;if(el("pacing-editor-save"))el("pacing-editor-save").disabled=true;feedback.textContent="Confira a faixa: o mínimo deve ser menor ou igual ao máximo.";return;}
      invalid=false;draft[row.id]={min,max,note:notes.value,basis:"user"};dirty=true;feedback.textContent="Alteração pendente. Use Salvar metas para guardar no projeto.";render();budget();
    };
    for(const input of form.querySelectorAll("input,textarea"))input.addEventListener("input",commit);root.append(feedback);
    const budgetBox=element("div","budget-box");budgetBox.append(element("h3","section-title","Equivalência em sessões"));
    const agenda=window.PacingCalendar.agenda();
    for(const [id,label,value]of [["budget-sessions","Sessões por dia",agenda.sessions],["budget-minutes","Minutos por sessão",agenda.minutes]]){const l=element("label","",label),input=element("input");input.type="number";input.min="1";input.max=id==="budget-sessions"?24:240;input.value=value;input.id=id;input.oninput=()=>{const sessions=Number(el("budget-sessions").value),minutes=Number(el("budget-minutes").value);if(sessions>=1&&sessions<=24&&Number.isInteger(sessions)&&minutes>=1&&minutes<=240)window.PacingCalendar.setAgenda({sessions,minutes});budget();};l.append(input);budgetBox.append(l);}
    const projection=element("p");projection.id="budget-result";budgetBox.append(projection,element("small","","Conversão de orçamento ativo. Não calcula timers, renda, ausências nem disponibilidade; não é previsão do calendário."));root.append(budgetBox);budget();
    const reading=element("div","pacing-reading");reading.append(element("h3","section-title","O que já está registrado"));
    reading.append(element("p","",row.active?`${range(row.active)} ativos; ${row.hours?number(row.hours.median/24)+" dias de calendário":"calendário não registrado"}. ${row.reached}/${row.total} jornada(s) alcançaram este marco.`:"Ainda não há registro deste marco no recorte escolhido. É possível definir a meta mesmo assim."));
    if(row.id==="upgrade:stove")reading.append(element("p","","O plano fala em cozinha operando; aqui medimos a compra do fogão. Use como indicador aproximado, sem alongar o tutorial só para bater a faixa."));
    if(row.kind==="recipe")reading.append(element("p","","Este marco registra o primeiro preparo iniciado, não a primeira coleta do produto pronto."));
    if(row.kind==="world")reading.append(element("p","","Mundos indicam liberação, não a primeira visita. Sem evento explícito, usamos o momento em que os requisitos conhecidos foram concluídos, apenas com os mesmos JSONs."));
    root.append(reading);
    const saveButton=element("button","pacing-editor-save","Salvar metas");saveButton.id="pacing-editor-save";saveButton.disabled=!dirty||saveBusy;saveButton.onclick=save;root.append(saveButton);
    const inspect=element("button","inspect-milestone","Ver conexões deste marco");inspect.onclick=()=>{closeEditor();panel(false);if(typeof select==="function")select(row.node);};root.append(inspect);
  }
  function budget(){
    if(!el("budget-result"))return;const sessions=Number(el("budget-sessions").value),duration=Number(el("budget-minutes").value),t=draft[chosen];
    if(!(sessions>0&&sessions<=24&&duration>0&&duration<=240)){el("budget-result").textContent="Informe uma agenda válida.";return;}
    if(!t||t.min==null&&t.max==null){el("budget-result").textContent="Defina uma faixa para converter em orçamento diário.";return;}
    const a=t.min==null?"0":number(t.min/(sessions*duration)),b=t.max==null?"sem teto":number(t.max/(sessions*duration));
    el("budget-result").textContent=`${a} – ${b} dias equivalentes de ${sessions*duration} min de jogo. O calendário registrado pode ser maior.`;
  }
  function sources(){
    const root=el("pacing-sources");root.replaceChildren(element("p","",payload.notice),element("p","",`Metas: ${payload.plan.source}. Valores não definidos permanecem em branco. Não criamos tempos fictícios para completar a tabela.`));
    for(const source of payload.evidence.sources)root.append(element("p","",`${source.file} · semente ${source.seed} · ${source.status}${source.stall?" · "+source.stall:""}`));
    root.append(element("p","",`Hash atual: ${payload.current_hash}. Hash dos registros: ${payload.evidence.hash||"ausente"}. Comparações com conteúdo diferente ficam sem avaliação de ritmo atual.`));
  }
  async function save(){
    if(!dirty||saveBusy||invalid)return;saveBusy=true;el("pacing-save").disabled=true;if(el("pacing-editor-save"))el("pacing-editor-save").disabled=true;for(const control of el("pacing-editor").querySelectorAll("input,textarea"))control.disabled=true;
    try{const response=await fetch("/api/pacing/plan",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({targets:draft})}),result=await response.json();if(!response.ok)throw Error(result.error||"Falha ao salvar");draft=result.plan.targets;dirty=false;el("pacing-error").hidden=true;saveBusy=false;await load();if(el("target-feedback"))el("target-feedback").textContent="Metas salvas no projeto. O conteúdo do jogo continua sendo apenas consultado.";}
    catch(e){error(e.message);if(el("target-feedback"))el("target-feedback").textContent="Não foi possível salvar: "+e.message;}finally{saveBusy=false;el("pacing-save").disabled=!dirty||invalid;if(el("pacing-editor-save"))el("pacing-editor-save").disabled=!dirty||invalid;for(const control of el("pacing-editor").querySelectorAll("input,textarea"))control.disabled=false;}
  }
  el("tab-pacing").onclick=()=>panel(true);el("tab-connections").onclick=()=>panel(false);el("pacing-save").onclick=save;el("pacing-reload").onclick=load;
  el("refresh").addEventListener("click",()=>{if(active)load();});
  el("pacing-editor-backdrop").onclick=closeEditor;
  document.addEventListener("keydown",event=>{
    if(!editorOpen)return;
    if(event.key==="Escape"){event.preventDefault();closeEditor();return;}
    if(event.key==="Tab"){const items=[...el("pacing-editor").querySelectorAll("button,input,textarea,select,a[href]")].filter(n=>!n.disabled);const first=items[0],last=items.at(-1);if(!el("pacing-editor").contains(document.activeElement)){event.preventDefault();first?.focus();}else if(event.shiftKey&&document.activeElement===first){event.preventDefault();last?.focus();}else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first?.focus();}}
  });
  for(const id of ["pacing-batch","pacing-profile","pacing-until"])el(id).onchange=load;
  for(const id of ["pacing-search","pacing-kind","pacing-attention"])el(id).addEventListener(id==="pacing-search"?"input":"change",()=>{if(payload)render();});
  setInterval(()=>{if(active&&!document.hidden&&!dirty&&!invalid&&!el("pacing-editor").contains(document.activeElement))load();},10000);
  window.AtlasPacing={open:()=>panel(true),suspend:()=>{active=false;}};
})();
