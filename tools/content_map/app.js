"use strict";

const $ = (id) => document.getElementById(id);
const NS = "http://www.w3.org/2000/svg";
const palette = {
  growth:["#b18098","#f7edf3","♥"], pillar:["#738e48","#f0f4e6","◆"], album:["#aa8b61","#f6efe3","▣"], house:["#aa8b61","#f6efe3","⌂"],
  item:["#738e48","#f0f4e6","◇"], recipe:["#b88a4e","#faf1e2","♨"], crop:["#60915e","#edf4e9","✿"],
  quest:["#9d7bb3","#f1ebf5","!"], upgrade:["#aa8e61","#f5f0e6","⌂"], station:["#b19463","#f6efe2","▦"],
  world:["#6e9aaa","#eaf3f4","◎"], place:["#6e9aaa","#edf4f4","⌖"], npc:["#b38b8d","#f8eeee","☺"],
  order:["#ab925a","#f7f2e5","▤"], storage:["#7e9273","#eef3e9","▣"], project:["#aa8b61","#f6efe3","⌂"],
  phase:["#aa8b61","#f6efe3","▱"], activity:["#609778","#eaf4ee","♧"], walk:["#6b9e95","#e9f3f0","↗"],
  wish:["#b18098","#f7edf3","♡"], routine:["#9d7bb3","#f1ebf5","✓"], collection:["#b18eaf","#f7edf6","✧"],
  chapter:["#9d7bb3","#f1ebf5","§"], resource:["#b99c52","#f8f3e2","●"], animal:["#b68b65","#f7efe6","♧"],
};
const family = {
  production:new Set(["input","output","station","storage"]),
  progression:new Set(["requirement","goal","sequence","shared","unlock","chapter","phase","counter"]),
  location:new Set(["location"]), rewards:new Set(["reward","random","sale","cost","care"]),
};
const relationNames = {input:"Material necessário",output:"Produção",station:"Estação",storage:"Armazenamento",requirement:"Requisito",goal:"Objetivo",sequence:"Sequência",shared:"Marco compartilhado",unlock:"Desbloqueio alternativo",chapter:"Capítulo",phase:"Etapa",counter:"Contador",location:"Local / personagem",reward:"Recompensa",random:"Sorteio condicional",sale:"Venda",cost:"Custo",care:"Cuidado"};
let data, nodes=new Map(), adjacency=new Map(), selected="", visible, viewMode="map", loading=false;
let transform={x:0,y:0,k:1}, graphBounds={width:800,height:500}, pendingSearch;
const norm = (s) => String(s).normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();
const color = (n) => palette[n.kind] || ["#829277","#f1f4ed","·"];
const typeName = (n) => data.kinds[n.kind] || n.kind;
const make = (tag,cls,text) => {const e=document.createElement(tag);if(cls)e.className=cls;if(text!==undefined)e.textContent=text;return e;};
const svg = (tag,attrs={},text) => {const e=document.createElementNS(NS,tag);for(const [k,v]of Object.entries(attrs))e.setAttribute(k,String(v));if(text!==undefined)e.textContent=text;return e;};
function icon(n){const e=make("span","node-icon");const [c,t,g]=color(n);e.style.setProperty("--color",c);e.style.setProperty("--tint",t);if(n.icon){const img=make("img");img.src=n.icon;img.alt="";img.loading="lazy";e.append(img);}else e.textContent=g;return e;}
function nodeButton(n,cls="catalog-node"){
  const b=make("button",cls);b.type="button";b.dataset.node=n.id;b.append(icon(n));const text=make("span","node-text");text.append(make("span","node-name",n.name),make("span","node-subtitle",typeName(n)));b.append(text);b.title=`${n.name} · ${n.id}`;b.onclick=()=>select(n.id);return b;
}
function setStatus(message,bad=false){$("status").textContent=message;$("live-dot").style.background=bad?"#c19755":"#58a27a";}
function reportError(message){$("error").hidden=false;$("error").textContent=message;setStatus("Falha ao atualizar",true);}
async function load(){
  if(loading)return;loading=true;$("refresh").disabled=true;
  try{
    const r=await fetch("/api/graph",{cache:"no-store"});const incoming=await r.json();if(!r.ok)throw Error(incoming.error||"Falha ao ler arquivos");
    data=incoming;nodes=new Map(data.nodes.map(n=>[n.id,n]));adjacency=new Map(data.nodes.map(n=>[n.id,[]]));
    for(const e of data.edges){adjacency.get(e.source)?.push(e);adjacency.get(e.target)?.push(e);}
    const oldKind=$("kind").value;$("kind").replaceChildren(new Option("Todas as categorias",""));
    const counts={};for(const n of data.nodes)counts[n.kind]=(counts[n.kind]||0)+1;
    for(const [kind,name]of Object.entries(data.kinds)){if(counts[kind])$("kind").append(new Option(`${name} (${counts[kind]})`,kind));}
    $("kind").value=oldKind;$("totals").textContent=`${data.nodes.length} elementos · ${data.edges.length} ligações`;
    $("error").hidden=true;
    const hash=decodeURIComponent(location.hash.slice(1));
    selected=nodes.has(selected)?selected:nodes.has(hash)?hash:nodes.has("recipe:carrot_snack")?"recipe:carrot_snack":data.nodes[0]?.id||"";
    if(selected)select(selected,false);else{renderCatalog();$("detail").textContent="Nenhum conteúdo encontrado.";}
    setStatus(`Atualizado às ${new Date().toLocaleTimeString("pt-BR",{hour:"2-digit",minute:"2-digit"})}`);
  }catch(e){reportError(e.message);}finally{loading=false;$("refresh").disabled=false;}
}
function renderCatalog(){
  if(!data)return;
  const query=norm($("search").value),kind=$("kind").value;
  const list=data.nodes.filter(n=>(!kind||kind===n.kind)&&(!query||norm(`${n.name} ${n.id} ${n.data?.line||""} ${n.data?.category||""}`).includes(query)));
  list.sort((a,b)=>a.name.localeCompare(b.name,"pt-BR"));
  $("result-count").textContent=`${list.length} elementos`;
  const fragment=document.createDocumentFragment();
  for(const n of list){const b=nodeButton(n);if(n.id===selected){b.classList.add("active");b.setAttribute("aria-current","true");}b.append(make("span","node-count",n.degree));fragment.append(b);}
  if(!list.length)fragment.append(make("p","detail-note","Nenhum resultado. Tente outro nome, ID ou categoria."));
  $("catalog-list").replaceChildren(fragment);
}
function select(id,writeHash=true){
  if(!nodes.has(id))return;selected=id;
  if(writeHash)history.replaceState(null,"",`#${encodeURIComponent(id)}`);
  $("map-title").textContent=nodes.get(id).name;renderCatalog();renderDetail();renderMap();
}
function fact(parent,label,value){const box=make("div","fact");box.append(make("span","",label),make("strong","",value));parent.append(box);}
function time(s){if(s<60)return `${s} s`;if(s<3600)return `${Number((s/60).toFixed(1))} min`;return `${Number((s/3600).toFixed(1))} h`;}
function renderDetail(){
  const n=nodes.get(selected),d=n.data||{},root=$("detail");root.replaceChildren();
  root.append(make("div","eyebrow","DETALHES DA PEÇA"));const tag=make("span","tag",typeName(n));const [c,t]=color(n);tag.style.setProperty("--color",c);tag.style.setProperty("--tint",t);
  const heading=make("div","detail-heading"),title=make("div");title.append(make("h2","",n.name),make("code","",n.id));heading.append(icon(n),title);root.append(heading,tag);
  if(d.description||d.dialogue||d.pitch)root.append(make("p","detail-description",d.description||d.dialogue||d.pitch));
  const facts=make("div","facts");
  if(d.seconds!==undefined)fact(facts,"Tempo base",time(d.seconds));
  if(d.cost!==undefined||d.price!==undefined)fact(facts,"Preço",`${d.cost??d.price} moedas`);
  if(d.sell_price!==undefined)fact(facts,"Venda unitária",`${d.sell_price} moedas`);
  if(d.cooldown!==undefined)fact(facts,"Recarga",time(d.cooldown));
  if(d.base!==undefined)fact(facts,"Capacidade base",d.base);
  if(d.prebuild_capacity!==undefined)fact(facts,d.prebuild_name||"Antes da compra",d.prebuild_capacity);
  if(d.slots!==undefined)fact(facts,"Vagas base",Array.isArray(d.slots)?d.slots.length:d.slots);
  if(d.line)fact(facts,"Linha de missões",d.line);
  if(d.chapter)fact(facts,"Capítulo",d.chapter);
  if(d.player_xp!==undefined)fact(facts,"XP do jogador",d.player_xp);
  if(d.skill_xp!==undefined&&typeof d.skill_xp==="number")fact(facts,"XP do atributo",d.skill_xp);
  if(d.greenhouse)fact(facts,"Estufa",d.greenhouse==="only"?"Exclusiva":"Também aceita");
  if(d.hidden)fact(facts,"Lugar no mapa","Oculto / atalho");
  root.append(facts);
  const edges=adjacency.get(selected)||[];
  for(const [incoming,label]of [[true,"De onde vem / o que precisa"],[false,"Para onde vai / o que libera"]]){
    const rows=edges.filter(e=>incoming?e.target===selected:e.source===selected);
    root.append(make("h3","section-title",`${label} · ${rows.length}`));
    if(!rows.length){root.append(make("p","","Nenhuma ligação catalogada nesta direção."));continue;}
    const ul=make("ul","related");
    for(const e of rows){const other=nodes.get(incoming?e.source:e.target);if(!other)continue;const li=make("li"),b=nodeButton(other,"related-node");b.querySelector(".node-subtitle").textContent=e.label;li.append(b);ul.append(li);}
    root.append(ul);
  }
  root.append(make("h3","section-title","Origem dos dados"));
  const source=make("div","source");
  if(n.file){const a=make("a","",n.file);a.href="/"+n.file;a.target="_blank";a.rel="noopener";source.append(a,make("code","",n.pointer));}
  else source.textContent=n.kind==="counter"?"Contador citado nos objetivos ou requisitos. Não representa saldo de um jogador.":"Relação derivada dos requisitos do conteúdo.";
  root.append(source);
  const details=make("details"),summary=make("summary","","Ver definição completa"),pre=make("pre","",JSON.stringify(n.data,null,2));details.append(summary,pre);root.append(details);
  root.append(make("p","detail-note","Leitura do projeto, atualizada automaticamente. Tempos são valores base; modificadores e condições estão na definição. As setas mostram relações, não garantem que uma ação já esteja disponível para um jogador."));
}
function allowed(e){
  const f=$("relation").value;
  if(!$("show-counters").checked&&nodes.get(selected)?.kind!=="counter"&&
    (nodes.get(e.source)?.kind==="counter"||nodes.get(e.target)?.kind==="counter"))return false;
  return f==="all"||family[f].has(e.relation);
}
function neighborhood(){
  const maxDepth=Number($("depth").value),direction=$("direction").value;
  const levels=new Map([[selected,0]]),distance=new Map([[selected,0]]),queue=[selected];let omitted=0;
  for(let i=0;i<queue.length;i++){
    const id=queue[i],dist=distance.get(id);if(dist>=maxDepth)continue;
    const edges=(adjacency.get(id)||[]).filter(allowed).sort((a,b)=>Number(b.source===selected||b.target===selected)-Number(a.source===selected||a.target===selected));
    for(const e of edges){
      if(direction==="in"&&e.target!==id||direction==="out"&&e.source!==id)continue;
      const next=e.source===id?e.target:e.source;if(levels.has(next))continue;
      if(levels.size>=120){omitted++;continue;}
      const sign=e.target===id?-1:1;
      const old=levels.get(id);levels.set(next,old===0?sign:old+Math.sign(old));distance.set(next,dist+1);queue.push(next);
    }
  }
  const edges=data.edges.filter(e=>allowed(e)&&levels.has(e.source)&&levels.has(e.target));
  return{levels,edges,omitted};
}
function renderEdgeLabels(scene,labels,positions,cardW,cardH){
  const occupied=[...positions.values()].map(p=>({x:p.x-9,y:p.y-9,width:cardW+18,height:cardH+18}));
  const overlaps=(a,b)=>a.x<b.x+b.width&&a.x+a.width>b.x&&a.y<b.y+b.height&&a.y+a.height>b.y;
  const layer=svg("g",{class:"edge-label-layer"});scene.append(layer);
  for(const {path,label} of labels){
    const badge=svg("g",{class:"edge-label-badge"}),text=svg("text",{class:"edge-label","text-anchor":"middle"});
    const words=label.split(/\s+/),lines=[];let line="";
    for(const word of words){if(line&&line.length+word.length+1>24){lines.push(line);line=word;}else line+=(line?" ":"")+word;}
    if(line)lines.push(line);
    lines.forEach((value,i)=>text.append(svg("tspan",{x:0,y:12+i*14},value)));
    badge.append(text);layer.append(badge);
    const bounds=text.getBBox(),width=bounds.width+16,height=lines.length*14+10;
    const length=path.getTotalLength();let placement;
    for(const fraction of [.5,.35,.65,.23,.77,.13,.87]){
      const point=path.getPointAtLength(length*fraction);
      const box={x:point.x-width/2,y:point.y-height/2,width,height};
      if(!occupied.some(other=>overlaps(box,other))){placement=box;break;}
    }
    // Se não houver espaço livre, a relação completa continua no detalhe e no título da seta.
    if(!placement){badge.remove();continue;}
    badge.setAttribute("transform",`translate(${placement.x+width/2},${placement.y+4})`);
    const background=svg("rect",{x:-width/2,y:-4,width,height,rx:5,class:"edge-label-background"});
    badge.insertBefore(background,text);badge.append(svg("title",{},label));
    occupied.push({...placement,x:placement.x-4,y:placement.y-4,width:width+8,height:height+8});
  }
}
function renderMap(){
  if(!data||!selected)return;visible=neighborhood();
  const{levels,edges,omitted}=visible;
  $("map-count").textContent=`${levels.size} peças · ${edges.length} ligações${omitted?" · limite de 120 peças; filtre":""}${!$("show-counters").checked?" · contadores ocultos no mapa":""}`;
  $("empty").hidden=edges.length>0;
  renderConnections(edges);
  const lanes=new Map();for(const [id,level]of levels){if(!lanes.has(level))lanes.set(level,[]);lanes.get(level).push(nodes.get(id));}
  for(const lane of lanes.values())lane.sort((a,b)=>a.kind.localeCompare(b.kind)||a.name.localeCompare(b.name,"pt-BR"));
  const columnWidth=414,rowHeight=102,cardW=222,cardH=66;
  const sortedLevels=[...lanes.keys()].sort((a,b)=>a-b),maxRows=Math.max(...[...lanes.values()].map(v=>v.length));
  graphBounds={width:(sortedLevels.length-1)*columnWidth+cardW+80,height:maxRows*rowHeight+125};
  const positions=new Map();
  const scene=$("scene");scene.replaceChildren();
  for(const [col,level]of sortedLevels.entries()){
    const lane=lanes.get(level),offset=(maxRows-lane.length)*rowHeight/2;
    scene.append(svg("text",{x:col*columnWidth+45,y:35,class:"lane-label"},level===0?"EM FOCO":level<0?`ORIGENS · ${Math.abs(level)}`:`DESTINOS · ${level}`));
    lane.forEach((n,index)=>positions.set(n.id,{x:col*columnWidth+35,y:65+offset+index*rowHeight}));
  }
  // Arestas primeiro para manter os cartões à frente.
  const edgeGroup=svg("g"),labels=[];scene.append(edgeGroup);
  for(const [index,e]of edges.entries()){
    const a=positions.get(e.source),b=positions.get(e.target);const forward=a.x<b.x;
    let x1=a.x+(forward?cardW:0),x2=b.x+(forward?0:cardW),y1=a.y+cardH/2,y2=b.y+cardH/2;
    let path;
    if(a.x===b.x){x1=a.x+cardW;x2=b.x+cardW;const bump=42+index%4*10;path=`M${x1},${y1} C${x1+bump},${y1} ${x2+bump},${y2} ${x2},${y2}`;}
    else{const bend=Math.max(35,Math.abs(x2-x1)*.5);path=`M${x1},${y1} C${x1+(forward?bend:-bend)},${y1} ${x2-(forward?bend:-bend)},${y2} ${x2},${y2}`;}
    const direct=e.source===selected||e.target===selected;
    const p=svg("path",{d:path,class:`graph-edge${direct?" focus":""}`,"marker-end":"url(#arrow)"});p.append(svg("title",{},`${nodes.get(e.source).name} → ${nodes.get(e.target).name}: ${e.label}`));
    if(e.relation==="requirement"||e.relation==="sequence")p.setAttribute("stroke-dasharray","4 3");
    edgeGroup.append(p);
    if(direct&&edges.length<45)labels.push({path:p,label:e.label});
  }
  for(const [id,pos]of positions){
    const n=nodes.get(id),[c,t,glyph]=color(n);
    const g=svg("g",{transform:`translate(${pos.x},${pos.y})`,class:`graph-node${id===selected?" selected":""}`,tabindex:0,role:"button","aria-label":`${n.name}, ${typeName(n)}`,"data-node":id});
    g.append(svg("title",{},`${n.name}\n${n.id}`),svg("rect",{class:"card",width:cardW,height:cardH,rx:11}),svg("rect",{x:12,y:15,width:35,height:35,rx:10,fill:t}));
    if(n.icon)g.append(svg("image",{href:n.icon,x:15,y:18,width:29,height:29}));else g.append(svg("text",{x:29.5,y:33,class:"glyph",fill:c},glyph));
    const name=n.name.length>25?n.name.slice(0,23)+"…":n.name;
    g.append(svg("text",{x:58,y:29,class:"title"},name),svg("text",{x:58,y:46,class:"subtitle"},typeName(n).length>27?typeName(n).slice(0,25)+"…":typeName(n)));
    g.onclick=()=>{if(!dragMoved)select(id);};g.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();select(id);}};
    scene.append(g);
  }
  // Etiquetas por último, em espaços livres entre os cartões.
  renderEdgeLabels(scene,labels,positions,cardW,cardH);
  fit();
}
function renderConnections(edges){
  const root=$("connection-list");root.replaceChildren();
  for(const e of edges){const row=make("div","connection-card"),a=nodes.get(e.source),b=nodes.get(e.target);const left=make("button","",a.name),right=make("button","",b.name);left.onclick=()=>select(a.id);right.onclick=()=>select(b.id);row.append(left,make("span","arrow-label",`${e.label} →`),right);row.title=relationNames[e.relation]||e.relation;root.append(row);}
  if(!edges.length)root.append(make("p","detail-note","Nenhuma ligação neste filtro."));
}
function updateTransform(){
  $("scene").setAttribute("transform",`translate(${transform.x},${transform.y}) scale(${transform.k})`);
  $("zoom-value").textContent=Math.round(transform.k*100)+"%";
}
function fit(){
  const r=$("graph-wrap").getBoundingClientRect();if(!r.width||!r.height)return;
  const k=Math.min(1.18,(r.width-50)/graphBounds.width,(r.height-85)/graphBounds.height);
  transform={k:Math.max(.08,k),x:(r.width-graphBounds.width*k)/2,y:(r.height-graphBounds.height*k)/2+20};updateTransform();
}
function zoom(factor,cx,cy){const r=$("graph").getBoundingClientRect();cx??=r.width/2;cy??=r.height/2;const old=transform.k,k=Math.min(2.5,Math.max(.06,old*factor));transform.x=cx-(cx-transform.x)*k/old;transform.y=cy-(cy-transform.y)*k/old;transform.k=k;updateTransform();}
let drag=null,dragMoved=false;
$("graph").addEventListener("pointerdown",e=>{if(e.button!==0||e.target.closest(".graph-node"))return;drag={x:e.clientX,y:e.clientY,tx:transform.x,ty:transform.y};dragMoved=false;$("graph").setPointerCapture(e.pointerId);$("graph").classList.add("dragging");});
$("graph").addEventListener("pointermove",e=>{if(!drag)return;const dx=e.clientX-drag.x,dy=e.clientY-drag.y;if(Math.abs(dx)+Math.abs(dy)>4)dragMoved=true;transform.x=drag.tx+dx;transform.y=drag.ty+dy;updateTransform();});
function endDrag(){drag=null;$("graph").classList.remove("dragging");setTimeout(()=>dragMoved=false,0);}
$("graph").addEventListener("pointerup",endDrag);$("graph").addEventListener("pointercancel",endDrag);
$("graph").addEventListener("wheel",e=>{e.preventDefault();const r=$("graph").getBoundingClientRect();zoom(Math.exp(-e.deltaY*.0015),e.clientX-r.left,e.clientY-r.top);},{passive:false});
$("zoom-in").onclick=()=>zoom(1.25);$("zoom-out").onclick=()=>zoom(.8);$("fit").onclick=fit;
$("search").oninput=()=>{clearTimeout(pendingSearch);pendingSearch=setTimeout(renderCatalog,90);};
$("kind").onchange=renderCatalog;$("clear").onclick=()=>{$("search").value="";$("kind").value="";renderCatalog();};
for(const id of ["relation","depth","direction","show-counters"])$(id).onchange=renderMap;
$("refresh").onclick=load;
function mode(value){viewMode=value;$("mode-map").classList.toggle("active",value==="map");$("mode-list").classList.toggle("active",value==="list");$("graph-wrap").hidden=value!=="map";$("connection-list").hidden=value!=="list";if(value==="map")renderMap();}
$("mode-map").onclick=()=>mode("map");$("mode-list").onclick=()=>mode("list");
new ResizeObserver(()=>{if(viewMode==="map")fit();}).observe($("graph-wrap"));
window.addEventListener("hashchange",()=>{try{select(decodeURIComponent(location.hash.slice(1)),false);}catch{}});
setInterval(async()=>{
  if(document.hidden||loading)return;
  try{const r=await fetch("/api/revision",{cache:"no-store"});const v=await r.json();if(!r.ok)throw Error(v.error||"Falha ao ler os arquivos");if(!data||v.revision!==data.revision)await load();else{setStatus(`Leitura automática · ${data.sources.length} arquivos`);$("error").hidden=true;}}
  catch(e){reportError(`Não foi possível atualizar. ${data?"Última leitura preservada. ":""}${e.message}`);}
},3000);
load();
