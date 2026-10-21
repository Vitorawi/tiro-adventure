"use strict";
(() => {
  const el=id=>document.getElementById(id);
  const make=(tag,cls,text)=>{const node=document.createElement(tag);if(cls)node.className=cls;if(text!==undefined)node.textContent=text;return node;};
  const weekdays=["Segunda","Terça","Quarta","Quinta","Sexta","Sábado","Domingo"];
  let mode="actual",week=0,context=null,lastScope="",maxWeek=0;
  const expanded=new Set();
  function budget(){
    const sessions=Number(el("calendar-sessions").value),minutes=Number(el("calendar-minutes").value);
    return Number.isInteger(sessions)&&sessions>=1&&sessions<=24&&Number.isFinite(minutes)&&minutes>=1&&minutes<=240?sessions*minutes:null;
  }
  function targetDay(minutes,daily){return Math.max(0,Math.ceil(minutes/daily)-1);}
  function dayFor(row){
    if(mode==="actual")return row.hours?Math.max(0,Math.floor(row.hours.median/24)):null;
    const target=context.targets[row.id],daily=budget();
    if(!daily||!target||target.min==null&&target.max==null)return null;
    return targetDay(target.max??target.min,daily);
  }
  function card(row,unplaced=false){
    const button=make("button","calendar-card"+(row.id===context.chosen?" selected":""));
    button.dataset.calendarMilestone=row.id;button.type="button";
    const top=make("span","calendar-card-top");
    const dataNode=typeof nodes!=="undefined"?nodes.get(row.node):null;
    const icon=make("span","calendar-card-icon");
    if(dataNode?.icon){const image=make("img");image.src=dataNode.icon;image.alt="";icon.append(image);}
    else icon.textContent={growth:"♥",quest:"✓",world:"◎",upgrade:"⌂",project:"✿",event:"★",recipe:"♨",chapter:"§",item:"◇"}[row.kind]||"·";
    top.append(icon,make("strong","",row.name));button.append(top);
    if(!unplaced){
      if(mode==="actual"){
        button.append(make("span","calendar-card-time",row.active?`${context.time(row.active.median)} jogados até aqui`:"Tempo ativo não registrado"));
        const state=context.status(row);if(state==="early"||state==="late")button.append(make("span","calendar-card-flag "+state,state==="early"?"Antes da meta":"Depois da meta"));
      }else{
        const target=context.targets[row.id],daily=budget();
        let text=target.min==null?`Até ${context.time(target.max)}`:target.max==null?`A partir de ${context.time(target.min)}`:`${context.time(target.min)} – ${context.time(target.max)}`;
        button.append(make("span","calendar-card-time",text+" de jogo ativo"));
        if(target.min!=null&&target.max!=null&&targetDay(target.min,daily)!==targetDay(target.max,daily))button.append(make("span","calendar-card-window",`Faixa: dias ${targetDay(target.min,daily)+1} a ${targetDay(target.max,daily)+1}`));
        if(target.max==null)button.append(make("span","calendar-card-window","Sem prazo máximo"));
      }
    }
    button.onclick=()=>context.choose(row.id);return button;
  }
  function paint(){
    if(!context)return;
    el("pacing-calendar").hidden=mode==="table";el("pacing-table-view").hidden=mode!=="table";
    for(const key of ["actual","targets","table"]){el("calendar-"+key).classList.toggle("active",mode===key);el("calendar-"+key).setAttribute("aria-pressed",String(mode===key));}
    el("calendar-budget").hidden=mode!=="targets";
    if(mode==="table")return;
    const days=new Map(),unplaced=[];
    for(const row of context.rows){const day=dayFor(row);if(day==null){unplaced.push(row);continue;}if(!days.has(day))days.set(day,[]);days.get(day).push(row);}
    maxWeek=Math.floor(Math.max(0,...days.keys())/7);week=Math.max(0,Math.min(week,maxWeek));
    el("calendar-week-title").textContent=`Semana ${week+1}`;
    el("calendar-week-range").textContent=`Dias ${week*7+1} a ${week*7+7} da jornada · ${maxWeek+1} semana(s) neste recorte`;
    el("calendar-week-number").value=week+1;el("calendar-week-number").max=maxWeek+1;
    el("calendar-prev").disabled=week===0;el("calendar-next").disabled=week===maxWeek;
    el("calendar-explanation").textContent=mode==="actual"?
      "Conquistas nos dias registrados no relatório SIMULADO. Dia 1 = primeiras 24 horas. Os dias da semana são uma referência visual, escolhida por você.":
      "Planejamento por orçamento de jogo. O cartão fica no último dia da faixa desejada. Estes dias não preveem o calendário real: timers, ausências e escolhas podem alongá-lo.";
    const daily=budget();el("calendar-daily-budget").textContent=daily?`${daily} minutos de jogo por dia` : "Informe uma agenda válida para distribuir as metas.";
    const root=el("calendar-days");root.replaceChildren();let total=0,withMilestones=0;
    const start=Number(el("calendar-start").value)||0;
    for(let i=0;i<7;i++){
      const day=week*7+i,weekday=(start+i)%7,rows=days.get(day)||[],column=make("section","calendar-day"+(weekday>=5?" weekend":""));
      column.dataset.day=day+1;
      const heading=make("header","calendar-day-heading");heading.append(make("span","",weekdays[weekday]),make("strong","",`Dia ${day+1}`),make("small","",rows.length?`${rows.length} conquista${rows.length===1?"":"s"}`:""));column.append(heading);
      const stack=make("div","calendar-day-cards"),key=`${lastScope}:${mode}:${day}`;
      const order=row=>mode==="actual"?row.hours?.median||0:context.targets[row.id]?.max??context.targets[row.id]?.min??0;
      const sorted=[...rows].sort((a,b)=>order(a)-order(b)||a.name.localeCompare(b.name,"pt-BR"));
      const shown=expanded.has(key)?sorted:sorted.slice(0,4);
      for(const row of shown)stack.append(card(row));
      if(!rows.length)stack.append(make("p","calendar-day-empty","Sem conquista neste recorte"));
      if(rows.length>4){const toggle=make("button","calendar-more",expanded.has(key)?"Mostrar menos":`+ ${rows.length-4} conquistas`);toggle.onclick=()=>{expanded.has(key)?expanded.delete(key):expanded.add(key);paint();};stack.append(toggle);}
      column.append(stack);root.append(column);total+=rows.length;if(rows.length)withMilestones++;
    }
    el("calendar-week-summary").textContent=`${total} conquistas nesta semana · ${withMilestones} de 7 dias com marcos neste recorte. Dias vazios não significam ausência de atividades no jogo.`;
    el("calendar-unplaced").hidden=unplaced.length===0;
    el("calendar-unplaced-title").textContent=mode==="actual"?`${unplaced.length} marcos sem tempo registrado`:!daily?`${unplaced.length} marcos aguardam uma agenda válida`:`${unplaced.length} marcos sem meta definida`;
    el("calendar-unplaced-cards").replaceChildren(...unplaced.map(row=>card(row,true)));
  }
  for(const key of ["actual","targets","table"])el("calendar-"+key).onclick=()=>{mode=key;week=0;paint();};
  el("calendar-prev").onclick=()=>{week--;paint();};el("calendar-next").onclick=()=>{week++;paint();};
  el("calendar-week-number").onchange=()=>{const value=Number(el("calendar-week-number").value);if(Number.isInteger(value))week=value-1;paint();};
  el("calendar-start").value=localStorage.getItem("atlas:calendar-start")||"0";
  el("calendar-start").onchange=()=>{localStorage.setItem("atlas:calendar-start",el("calendar-start").value);paint();};
  for(const id of ["calendar-sessions","calendar-minutes"]){el(id).value=localStorage.getItem("atlas:"+id)||el(id).value;el(id).oninput=()=>{localStorage.setItem("atlas:"+id,el(id).value);week=0;paint();};}
  window.PacingCalendar={render(value){
    context=value;const scope=`${value.payload.batch}:${value.payload.profile}:${value.payload.until}`;
    if(scope!==lastScope){lastScope=scope;week=0;expanded.clear();}
    paint();
  },isTable:()=>mode==="table",targetDay,
  agenda:()=>({sessions:Number(el("calendar-sessions").value),minutes:Number(el("calendar-minutes").value)}),
  setAgenda(value){el("calendar-sessions").value=value.sessions;el("calendar-minutes").value=value.minutes;for(const id of ["calendar-sessions","calendar-minutes"])localStorage.setItem("atlas:"+id,el(id).value);week=0;paint();}};
})();
