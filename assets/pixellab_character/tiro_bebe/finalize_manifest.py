import sys
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE/'python_libs'))
from PIL import Image
manifest_path=HERE/'animations/manifest_animacoes.json'
m=json.loads(manifest_path.read_text(encoding='utf-8-sig'))
choices=json.loads((HERE/'final_choices.json').read_text())
audit=json.loads((HERE/'review/pixel_audit.json').read_text())
rejected={
 'belly_kick':'Riscos claros; versão anterior preservada, final obrigatória v2.',
 'sleep':'Risco branco e resíduos coloridos; deitava em três quartos.',
 'scratch':'Risco branco junto à pata e rabo listrado.',
 'scratch_v2':'Pata dianteira levada à bochecha, movimento de coçar pouco claro.',
 'scratch_v3':'Levanta e mexe o corpo sem coçar a orelha.',
 'pet_head':'Mão humana indesejada, apesar de prompt sem mão.',
 'shake_off':'Orelhas excessivamente longas/eretas no movimento.',
 'head_tilt':'Inclinação lateral insuficiente.',
 'head_tilt_v2':'Vira a cabeça para o lado em vez de inclinar lateralmente.',
 'chase_tail':'Giro incompleto e rabo com marcações alteradas.',
 'chase_tail_v2':'Anda de frente em vez de girar.',
 'chase_tail_v3':'Giro melhor, mas risco curvo e claro ao lado do rabo no frame 08.',
 'sniff':'Brilhos amarelos/claros ao redor do focinho.',
 'sniff_v2':'Nuvem branca de sopro nos frames 03–07.',
 'look_around':'Quase só pisca, pouco movimento de olhar.'
}
traces={'belly_kick','sleep','scratch','chase_tail_v3','sniff','sniff_v2'}
for e in m['animations']:
 name=e['nome'];base=name.split('_v')[0]
 fs=sorted((HERE/'animations'/name).glob('frame_*.png'))
 e['frames']=len(fs);e['numero_frames']=len(fs)
 if fs:e['canvas']=list(Image.open(fs[0]).size)
 e['tem_tracos']='sim' if name in traces else 'nao'
 e['versao_final']=choices.get(base,name)
 e['revisao_visual']='reprovada_preservada' if name in rejected else 'aprovada'
 e['observacao_visual']=rejected.get(name,'Todos os frames conferidos ampliados 2×; movimento e identidade aceitos, sem cortes nem efeitos soltos.')
 e['conferencia']='../review/'+name+'_all.png'
 rows=audit[name]
 e['quase_brancos_fora_componente_corpo']=sum(r['quase_brancos_fora_componente_corpo'] for r in rows)
 e['quase_brancos_expostos_ao_fundo']=sum(r['quase_brancos_expostos_ao_fundo'] for r in rows)
 e['auditoria_pixels']='../review/pixel_audit.json'
 # Semantic correction after seeing the sheets: overlapping clouds/lines are effects,
 # even when connected to or covering the dog's silhouette. Bowl highlights are allowed props.
 if name in {'belly_kick','sleep','scratch','sniff_v2','eat'}:
  e['quase_brancos_fora_corpo']=sum(r['quase_brancos_total'] for r in rows)
  e['criterio_fora_corpo']='Conferência visual: efeito ou tigela; inclui sobreposição ao corpo.'
 else:
  e['quase_brancos_fora_corpo']=e['quase_brancos_fora_componente_corpo']
  e['criterio_fora_corpo']='Componentes separados + inspeção visual do contorno; dentes/olhos internos excluídos.'
 for row in rows:
  row['quase_brancos_fora_corpo_revisao_visual']=row['quase_brancos_total'] if name in {'belly_kick','sleep','scratch','sniff_v2','eat'} else row['quase_brancos_fora_componente_corpo']
 if name=='scratch_v4':e['observacao_visual']='Sem riscos ou cortes; coça a lateral da bochecha com a pata levantada. Variante aceita para scratch; não reproduz exatamente a pata traseira atrás da orelha.'
 if name=='eat':e['integracao']='Frame 00 normalizado recebeu composição da tigela do frame 01 com máscara poligonal; fonte PixelLab intacta.'
 if name=='sleep_belly':e['integracao']='Pose única: frame 04 da geração, instalado como sleep_belly/frame_00.png; nove frames da fonte preservados.';e['frames_instalados']=1
m['versoes_finais']=choices
m['status']='completed'
m['total_frames']=sum(e['frames'] for e in m['animations'])
m['integracao']={'backup':'assets/backup_tiro_pet_puppy_20261024','canvas':[256,216],'escala_unica':1,'clipes':22,'frames_instalados':206,'normalizacao':'../normalization_audit.json','sem_commit_push':True}
m['validation']='Todos os frames de todas as versões vistos em pranchas 2×. Contagem R,G,B>220 com alpha>0: componente principal e exposição ao fundo; inspeção visual também cobre riscos conectados, efeitos coloridos, identidade e pose. Dentes/olhos e tigela não são defeitos.'
manifest_path.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'review/pixel_audit.json').write_text(json.dumps(audit,indent=2)+'\n')
lines=['# Troca local do Filhotinho — 24/10/2026','','21 clipes + sleep_belly; 206 PNGs em 256×216, escala 1:1. Backup completo preservado (207 PNGs contando a imagem idle_front separada).','','| Clipe | Versão final | animation_id | Frames no jogo |','|---|---|---|---|']
entries={e['nome']:e for e in m['animations']}
for clip,source in choices.items():
 e=entries[source];lines.append(f"| {clip} | {source} | `{e['animation_id']}` | {1 if clip=='sleep_belly' else e['frames']} |")
lines+=['','## Versões rejeitadas e preservadas','']+[f'- **{n}:** {why}' for n,why in rejected.items()]
lines+=['','## Normalização','','Escala única 1:1: bebê sentado = 137 px de altura, anterior = 139 px. Só translação por frame para alinhar centro horizontal e linha inferior aos quadros originais. Os saltos seguem as linhas de apoio antigas; poses deitadas usam o apoio antigo correspondente. Nenhum pixel opaco cortado. `.import` e `tiro_pet_puppy_idle_front.png` preservados.','', 'Eat: tigela do frame 01 composta no frame 00, com máscara que acompanha seu contorno. Fontes brutas intactas. Sleep_belly: somente a pose 04 instalada como frame_00; os nove quadros da geração permanecem na fonte.']
lines+=['','## Ressalva visual','','scratch_v4 coça a lateral da bochecha com a pata levantada; após quatro tentativas, não reproduz exatamente a pata traseira atrás da orelha. A pose inicial customizada estabilizou o gesto e removeu riscos; diferença registrada, sem mascarar como reprodução idêntica.']
(HERE/'RELATORIO.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('Manifest/report updated:',len(m['animations']),'entries preserved')
