# Proiectul 2: voci KittenTTS 2 și separarea vorbitorilor (MATLAB)

Proiect de 7 săptămâni. Toate vocile sunt produse de un model neuronal de
sinteză vocală (text-to-speech), KittenTTS 2: voci predefinite, o clonă a unei
înregistrări reale, vorbitori în engleză și în română. Studenții analizează o
voce, o clonează, amestecă mai mulți vorbitori într-un singur semnal, îi
separă cu patru rețele neuronale și evaluează rezultatul prin SNR, prin
transcriere automată (rata de eroare pe cuvinte) și prin audiție.

| Document | Conținut |
|---|---|
| [student_instructions](student_instructions.md) | rularea, verificarea, interpretarea rezultatelor, limitările |
| [project_roadmap_7_weeks](project_roadmap_7_weeks.md) | planul pe săptămâni și întrebările pentru raport |
| [student_project_report](student_project_report.md) | șablonul raportului |

```matlab
main                       % rulează săptămânile 1..LAST_WEEK (setat la începutul lui main.m)
run_all_tests              % testele automate
```

| Săpt. | Funcție | Subiect |
|---|---|---|
| 1 | `w1_reference_voice` | vocea de referință, verificarea calității, ferestre STFT, spectrograma mel |
| 2 | `w2_voice_fingerprint` | frecvența fundamentală, formanți, spectrul mediu pe termen lung, MFCC |
| 3 | `w3_clone_voice` | KittenTTS 2: voci predefinite, clonarea unei voci, limba română |
| 4 | `w4_make_mixtures` | cinci vorbitori KittenTTS, verificarea genului, mixturi, spectrograme |
| 5 | `w5_separate_mixtures` | patru modele de separare; SNR, SNRi, SI-SNR; inversări de permutare |
| 6 | `w6_evaluate_separation` | transcriere cu Whisper și WER, fișa de audiție, variația nivelului |
| 7 | `w7_real_recordings`, `w7_dashboard` | înregistrări cu boxe sau cu vorbitori reali; panoul final |

Tabelele (CSV) și figurile (PNG) pentru raport se salvează în `results/`.

---

## Cele patru modele de separare

| Model | Unde rulează | Date de antrenare | Frecvență de eșantionare | Vorbitori |
|---|---|---|---|---|
| Conv-TasNet | MATLAB `separateSpeakers`, fără `NumSpeakers` | LibriMix, câte un vorbitor pe rând | 8 kHz | determină singur numărul |
| SepFormer | MATLAB `separateSpeakers`, `NumSpeakers` 2 sau 3 | Libri2Mix / Libri3Mix | 8 kHz | 2 sau 3 |
| MossFormer2 | Python, [ClearerVoice-Studio](https://github.com/modelscope/ClearerVoice-Studio) | WSJ0-2mix | 16 kHz | 2 |
| TIGER | Python, [JusperLee/TIGER](https://github.com/JusperLee/TIGER) (ICLR 2025) | EchoSet (ecou și zgomot) | 16 kHz | 2 |

Câteva alegeri care influențează rezultatele:

- SNR-ul se calculează la 8 kHz pentru toate modelele. Modelele din MATLAB nu
  produc nimic peste 4 kHz, iar la 16 kHz ar fi dezavantajate doar din cauza
  benzii.
- Nivelul ieșirilor se stabilește după aceeași regulă pentru toate modelele.
  `separateSpeakers` își scalează ieșirile prin metoda celor mai mici pătrate,
  astfel încât suma lor să refacă mixtura (`ConserveEnergy`). Modelele Python
  întorc semnale la o scară oarecare, așa că `p2_separate.m` le aplică aceeași
  regulă; altfel SNR-ul lor nu ar fi comparabil.
- Fiecare mixtură este separată dintr-o singură trecere. Biblioteca ClearVoice
  împarte intrarea lui MossFormer2 în segmente de 2 s, iar vorbitorii își pot
  schimba locul de la un segment la altul. De aceea `separate_bridge.py`
  aplică rețeaua direct pe tot semnalul.
- Timpul de separare nu include încărcarea modelului. `separateSpeakers` își
  construiește rețeaua la fiecare apel, așa că timpul de încărcare se măsoară
  separat și se scade. Scriptul Python face un apel de încălzire a plăcii
  video înainte de măsurare.
- `separateSpeakers` alege rețeaua numai după `NumSpeakers`: fără parametru
  sau cu 1 folosește Conv-TasNet, cu 2 sau 3 folosește SepFormer.


---

## Despre KittenTTS 2 (informații verificate pe 2026-10-18)

Din pagina modelului, <https://huggingface.co/KittenML/kitten-tts-2>:

- Model de limbaj pentru vorbire, cu 1,7 miliarde de parametri: textul este
  transformat în coduri audio (codec S3), apoi în semnal la 24 kHz.
- Poate clona o voce pe baza a 5–30 s de înregistrare cu un singur vorbitor
  (`reference=`), fără antrenare suplimentară.
- Limbi declarate: engleză (implicit), arabă, chineză, franceză, germană,
  hindi, italiană, portugheză, rusă, spaniolă. Româna nu este printre ele, așa
  că partea în română din săptămâna 3 este un experiment, nu o funcție
  garantată de model.
- Are 47 de voci predefinite (`kitten_bridge.py voices`), unele cu nume de
  limbi (`French`, `German`, `Russian` etc.). Numele nu indică genul: vocea
  `Italian` este masculină (F0 median 148 Hz).
- Pentru clonare, modelul are nevoie de textul rostit în înregistrarea de
  referință. Acesta se dă prin `'ReferenceText'`; dacă lipsește, înregistrarea
  este transcrisă cu Whisper (încă o descărcare).
- Opțiunea `normalize=True` (implicită) transformă numerele și simbolurile în
  cuvinte englezești. Pentru text în română se folosește `'Normalize', false`.
- La prima utilizare se descarcă în cache-ul Hugging Face
  `KittenML/kitten-tts-2` (circa 0,95 GB) și `ResembleAI/chatterbox-turbo`
  (circa 1 GB, necesar pentru codecul audio; verificați și licența lui).
- Licența modelului este Stellon Labs Community License: gratuită pentru
  cercetare și uz necomercial, cu restricții pentru uz comercial în funcție de
  venituri sau finanțare. Pachetul `kittenml` are licență Apache-2.0.

## Instalare (o singură dată)

Aveți nevoie de MATLAB cu Audio Toolbox și Signal Processing Toolbox, de
Python 3.12 (lansatorul `py`) și de aproximativ 8 GB pe disc (PyTorch cu CUDA
circa 4 GB, modelele de sinteză circa 2 GB, modelele de separare circa 1 GB).
O placă video NVIDIA nu este obligatorie, dar este folosită automat dacă
există; fără ea, sinteza durează minute în loc de secunde. Pe un laptop cu
RTX 4060, încărcarea KittenTTS durează circa 40 s la fiecare apel.

```powershell
cd <folderul proiectului>
powershell -ExecutionPolicy Bypass -File .\setup_tts.ps1          # cu suport GPU
powershell -ExecutionPolicy Bypass -File .\setup_tts.ps1 -Cpu     # doar CPU, instalare mai mică
powershell -ExecutionPolicy Bypass -File .\setup_separation.ps1   # pentru săptămânile 5-7
```

Săptămânile 1 și 2 au nevoie doar de MATLAB. Din săptămâna 3 este necesar
`setup_tts.ps1`, iar pentru săptămânile 5–7 și `setup_separation.ps1`.

`setup_separation.ps1` descarcă modelele `separateSpeakers` de la MathWorks
(circa 200 MB) în `models\separateSpeakers`, instalează MossFormer2 în `.venv`
și descarcă codul TIGER în `models\TIGER`. Ponderile rețelelor se descarcă la
prima utilizare: MossFormer2 (circa 640 MB) în `models\clearvoice`, TIGER
(circa 3 MB) în `models\TIGER_cache`. Pachetul `clearvoice` se instalează
intenționat fără dependențele lui: printre ele se află `numpy<2` și o versiune
de PyTorch doar pentru CPU, care ar strica instalarea KittenTTS.

## Fișiere

```
Project 2 Redesign/
├── main.m                    programul principal (săptămânile 1..LAST_WEEK)
├── w1_reference_voice.m      săptămâna 1
├── w2_voice_fingerprint.m    săptămâna 2
├── w3_clone_voice.m          săptămâna 3
├── w4_make_mixtures.m        săptămâna 4
├── w5_separate_mixtures.m    săptămâna 5
├── w6_evaluate_separation.m  săptămâna 6
├── w7_real_recordings.m      săptămâna 7 (înregistrări)
├── w7_dashboard.m            săptămâna 7 (panoul final)
├── run_all_tests.m, run_tests.m
├── tests/                    test_w1.m ... test_w7.m, p2_test_helpers.m
├── todo.m                    oprește programul la o porțiune încă nescrisă
├── START_AICI.md             documentul de pornire pentru studenți
├── kitten_bridge.py          legătura MATLAB → KittenTTS 2 și Whisper
├── separate_bridge.py        legătura MATLAB → MossFormer2 / TIGER
├── setup_tts.ps1             creează .venv cu PyTorch și kittenml
├── setup_separation.ps1      instalează modelele de separare
├── student_instructions.md, project_roadmap_7_weeks.md, student_project_report.md
├── lib/                      funcții auxiliare (p2_*): audio, profiluri, figuri,
│                             mixare, separare, SNR, transcriere, WER, salvare
├── models/                   modelele de separare și ponderile lor
├── results/                  tabele CSV și figuri PNG pentru raport
├── audio/                    sintezele, separările și transcrierile salvate
│   └── sep/                  sources/, mixtures/, separated/ (săptămânile 4-7)
└── *.html                    varianta pentru browser a fiecărui document .md
```


### Windows și codarea UTF-8

Pe Windows, Python citește implicit fișierele text în codarea cp1252, iar
încărcarea modelului se oprea cu `UnicodeDecodeError: 'charmap' codec can't
decode byte 0x9d`. Ambele scripturi Python se repornesc singure cu
`python -X utf8`, deci nu trebuie configurat nimic.

### De ce rulează Python ca proces separat și nu prin `pyenv`

MATLAB poate încărca o singură versiune de Python pe sesiune și acceptă doar
anumite versiuni, iar PyTorch nu suportă imediat versiunile noi de Python.
Modelele rulează de aceea în mediul `.venv` al proiectului, apelate prin
`system()`: MATLAB transmite o linie de comandă, iar Python scrie fișiere WAV
și o linie JSON cu rezultatul.

### Când memoria plăcii video nu ajunge

Pe Windows, driverul plăcii video limitează memoria pe care o poate folosi un
singur proces, iar alte programe care folosesc placa (figurile MATLAB, un
browser, o altă sesiune MATLAB) reduc această limită. KittenTTS 2 nu se mai
poate încărca și apare `CUDA out of memory`, chiar dacă placa raportează
memorie liberă. În acest caz `kitten_bridge.py` reia automat sinteza pe
procesor (mai lent, cu nevoie de circa 7 GB de RAM liberi). Dacă nici așa nu
merge, închideți celelalte programe și rulați din nou. Pentru cine scrie
scripturi: Windows șterge o variabilă de mediu cu valoare vidă, așa că placa
video se dezactivează cu `CUDA_VISIBLE_DEVICES=-1`, nu cu `""`.

## Rularea directă a scripturilor Python

```powershell
.venv\Scripts\python kitten_bridge.py voices
.venv\Scripts\python kitten_bridge.py say   --text "Hello." --out a.wav --voice Bruno
.venv\Scripts\python kitten_bridge.py clone --text "Hello." --out b.wav --reference me.wav
.venv\Scripts\python kitten_bridge.py transcribe --audio b.wav c.wav --language ro
.venv\Scripts\python separate_bridge.py --model tiger --mix mix.wav --outdir out
```

## Acordul pentru clonarea vocii

Clonați doar vocea voastră sau vocea unei persoane care și-a dat acordul.
Implicit se folosește o înregistrare inclusă în Audio Toolbox
(`Counting-16-44p1-mono-15secs.wav`).
