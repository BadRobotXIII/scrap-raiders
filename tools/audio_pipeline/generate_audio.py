"""Original SCRAP Raiders PCM foundations. Python standard library only.
Seeded synthesis; no sampled recordings or external source assets.
Run from the project root; existing generated WAVs are overwritten deliberately.
"""
from pathlib import Path
import array, hashlib, json, math, random, wave
ROOT=Path(__file__).resolve().parents[2]
RATE=22050
NAMES={
 'weapons/player_01':('player',.13), 'weapons/player_02':('player',.13),
 'weapons/raider_01':('rifle',.15), 'weapons/raider_02':('rifle',.15),
 'weapons/guard_01':('guard',.16), 'weapons/guard_02':('guard',.16),
 'impacts/metal':('metal',.20), 'impacts/concrete':('dust',.17),
 'impacts/equipment':('metal',.22), 'impacts/machine_armor':('armor',.19),
 'impacts/raider_gear':('gear',.13), 'impacts/hard_surface':('dust',.12),
 'actors/raider_hurt':('gear',.18), 'actors/player_hurt':('armor',.22),
 'actors/machine_hurt':('armor',.23), 'actors/machine_destroy':('destroy',.6),
 'actors/raider_death':('gear',.3),
 'machines/player_servo_loop':('servo',2), 'machines/guard_drive_loop':('drive',2),
 'machines/scout_rotor_loop':('rotor',2), 'environment/yard_wind_loop':('wind',3),
 'environment/vent_loop':('vent',3), 'environment/machinery_loop':('machinery',3),
 'interface/hit_confirm':('hit',.065), 'interface/recovered':('recover',.16),
 'interface/objective_complete':('complete',.24), 'interface/recall_complete':('complete',.35),
 'interface/deployment_failed':('failed',.3), 'signals/death_flare':('flare',.5)}
def synth(name,kind,duration):
 seed=int.from_bytes(hashlib.sha256(name.encode()).digest()[:8],'little')
 rng=random.Random(seed); noise=[rng.uniform(-1,1) for _ in range(int(RATE*duration))]
 loop=name.endswith('_loop'); filtered=0; samples=[]
 for i,n in enumerate(noise):
  t=i/RATE; u=t/duration; filtered=filtered*.92+n*.08
  env=1 if loop else min(1,t/.003)*(1-u)**2
  if kind=='player': x=.45*math.sin(math.tau*(180*t-190*t*t))+.20*n*math.exp(-t*70)
  elif kind=='rifle': x=.35*n*math.exp(-t*24)+.32*math.sin(math.tau*110*t)*math.exp(-t*32)
  elif kind=='guard': x=.35*math.sin(math.tau*(340*t-350*t*t))+.16*n*math.exp(-t*38)
  elif kind in ('metal','armor'): x=.22*n*math.exp(-t*35)+.17*sum(math.sin(math.tau*f*t) for f in ([630,1140,2050] if kind=='metal' else [190,470,1090]))
  elif kind=='dust': x=.5*filtered+.12*n*math.exp(-t*45)
  elif kind=='gear': x=.5*filtered+.14*math.sin(math.tau*85*t)*math.exp(-t*24)
  elif kind=='destroy': x=.5*filtered+.20*n*math.exp(-t*13)+.13*math.sin(math.tau*(90*t-30*t*t))
  elif kind in ('servo','drive','rotor'):
   f={'servo':96,'drive':64,'rotor':120}[kind]
   x=(.15*math.sin(math.tau*f*t)+.06*math.sin(math.tau*f*2*t))*(.7+.3*math.sin(math.tau*(4 if kind=='rotor' else 2)*t))
  elif kind in ('wind','vent','machinery'):
   # Crossfade the final noise tail below; tonal periods divide the loop length.
   x=.3*filtered+(.05*math.sin(math.tau*(80 if kind=='machinery' else 40)*t) if kind!='wind' else 0)
  elif kind=='hit': x=.35*math.sin(math.tau*1200*t)+.12*math.sin(math.tau*2400*t)
  elif kind in ('recover','complete'): x=.27*math.sin(math.tau*(660 if u<.5 else 880)*t)
  elif kind=='failed': x=.3*math.sin(math.tau*(220*t-110*t*t))
  else: x=.25*math.sin(math.tau*(400*t+700*t*t))
  samples.append(x*env)
 if loop and kind in ('wind','vent','machinery'):
  # Keep a seamless periodic endpoint without a silent gap.
  count=int(RATE*.08)
  for i in range(count):
   w=i/count;samples[-count+i]=samples[-count+i]*(1-w)+samples[i]*w
 peak=max(abs(x) for x in samples) or 1
 gain=min(1,.82/peak)
 return array.array('h',(int(max(-.95,min(.95,x*gain))*32767) for x in samples))
def main():
 manifest=[]
 for name,(kind,duration) in NAMES.items():
  p=ROOT/'assets/audio'/f'{name}.wav';p.parent.mkdir(parents=True,exist_ok=True)
  data=synth(name,kind,duration)
  with wave.open(str(p),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(data.tobytes())
  # Godot writes the import sidecar on first import. On regeneration, retain
  # forward-loop configuration explicitly instead of resetting it to disabled.
  sidecar=Path(str(p)+'.import')
  if name.endswith('_loop') and sidecar.exists():
   import re
   sidecar.write_text(re.sub(r'edit/loop_mode=\d+', 'edit/loop_mode=2', sidecar.read_text(encoding='utf-8')),encoding='utf-8')
  manifest.append({'path':p.relative_to(ROOT).as_posix(),'kind':kind,'duration':duration,'loop':name.endswith('_loop'),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 (ROOT/'assets/audio/manifest.json').write_text(json.dumps({'author':'Original project synthesis','source':'tools/audio_pipeline/generate_audio.py','sample_rate':RATE,'license':'Original project assets; no third-party recordings or samples.','assets':manifest},indent=2)+'\n',encoding='utf-8')
 print(f'Generated {len(manifest)} original mono PCM WAVs')
if __name__=='__main__':main()
