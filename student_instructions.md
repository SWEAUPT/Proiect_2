# Ghidul studentului. Proiectul 2: voci KittenTTS 2 și separarea vorbitorilor

În acest proiect toate vocile sunt produse de un model neuronal de sinteză
vocală, KittenTTS 2: voci predefinite, o clonă a unei înregistrări reale,
vorbitori în engleză și în română. Veți analiza vocile, veți clona una dintre
ele, veți amesteca mai mulți vorbitori într-un singur semnal, îi veți separa cu
patru rețele neuronale și veți evalua rezultatul.

Proiectul se termină în cel mult 7 săptămâni. Planul pe săptămâni și
întrebările la care răspundeți în raport sunt în
[project_roadmap_7_weeks](project_roadmap_7_weeks.md).

---

## 0. Înainte de a începe

- Codul pe care îl scrieți în fiecare săptămână (apelurile `todo(...)`) este
  descris în [START_AICI](START_AICI.md). Citiți acel document primul.
- Instalarea se face o singură dată și ocupă aproximativ 8 GB pe disc (vezi
  [README](README.md)): întâi `setup_tts.ps1`, apoi `setup_separation.ps1`.
  Pentru săptămânile 1 și 2 este suficient MATLAB.
- Clonați doar vocea voastră sau vocea unei persoane care și-a dat acordul.
  Implicit, proiectul folosește o înregistrare inclusă în Audio Toolbox.
- Dacă aveți o placă video NVIDIA, ea este folosită automat. Fără ea proiectul
  funcționează la fel, doar că sinteza durează minute în loc de secunde. Dacă
  memoria plăcii nu ajunge, sinteza se reia automat pe procesor.
- Cât timp rulează sinteza, închideți alte sesiuni MATLAB. Modelul are 1,7
  miliarde de parametri și are nevoie de circa 4 GB pe placa video sau de
  circa 7 GB de RAM.
- Nu ștergeți folderul `audio/` decât dacă vreți să refaceți totul. Acolo se
  păstrează fiecare voce sintetizată, fiecare separare și fiecare transcriere.
  Dacă ștergeți un singur fișier, se reface doar acela.

---

## 1. Rularea proiectului

```matlab
main
```

La începutul fișierului `main.m`, setați `LAST_WEEK` la săptămâna la care ați
ajuns.

| Săpt. | Funcție | Ce face |
|-------|---------|---------|
| 1 | `w1_reference_voice()` | încarcă sau înregistrează vocea de referință, verifică calitatea, compară ferestre STFT, spectrograma mel |
| 2 | `w2_voice_fingerprint(x, fs, label)` | F0, formanți, spectrul mediu pe termen lung, MFCC |
| 3 | `w3_clone_voice(ref, refProfile)` | voci predefinite, clona, textul în română; distanțele față de referință |
| 4 | `w4_make_mixtures()` | cinci vorbitori KittenTTS, verificarea genului, mixturi, spectrograme |
| 5 | `w5_separate_mixtures(mixes, spk)` | patru modele de separare, SNR / SNRi / SI-SNR, verificarea permutărilor |
| 6 | `w6_evaluate_separation(spk, x, mixes, sepOut)` | transcriere și WER, fișa de audiție, variația nivelului |
| 7 | `w7_real_recordings(spk, x, ...)`, `w7_dashboard(...)` | înregistrări cu boxe sau cu vorbitori reali, panoul final |

Fiecare funcție are un text de ajutor care explică metoda (de exemplu
`help w5_separate_mixtures`). Citiți-l la începutul săptămânii. Funcțiile
auxiliare sunt în `lib/` și au prefixul `p2_`. Codul și mesajele afișate în
consolă sunt în engleză.

Alte setări din `main.m`:

| Setare | Semnificație |
|---|---|
| `REFERENCE_SOURCE` | `"sample"`, `"file"` (fișierul WAV indicat de `REFERENCE_FILE`) sau `"record"` |
| `MODELS` | modelele de separare comparate |
| `DO_LOUDSPEAKERS`, `DO_LIVE` | înregistrările din săptămâna 7 (aveți nevoie de boxe și microfon) |
| `PLAY_AUDIO` | `false` dacă lucrați pe un calculator fără sunet |
| `SEED` | cu aceeași valoare și același text se obține același semnal sintetizat |

---

## 2. Verificarea

```matlab
run_all_tests              % toate testele rapide
run_all_tests('Week', 3)   % doar testele săptămânii 3
```

Unele teste sunt raportate ca „skipped”. Testele lente (sinteză, Whisper,
modelele Python) rulează numai după `setenv("P2_SLOW_TESTS", "1")`, iar câteva
au nevoie de fișiere care apar abia după ce ați rulat `main`. Un test omis nu
este un test picat.

---

## 3. Interpretarea rezultatelor

**Săptămâna 3: distanțele clonei.** Fiecare coloană măsoară distanța față de
vocea de referință (0 înseamnă identic). Clona este reușită doar dacă iese
clar mai aproape de referință decât vocile predefinite, care nu au nicio
legătură cu ea.

**Săptămâna 5: separarea.**

| Coloană | Semnificație |
|---|---|
| `SNRin_dB` | SNR-ul mixturii, fără nicio separare: aproximativ 0 dB pentru 2 vorbitori la același nivel, −3 dB pentru 3 |
| `SNR_dB` | $10\log_{10}\left(\sum s^2 / \sum (s - s_r)^2\right)$ |
| `SNRi_dB` | `SNR_dB − SNRin_dB`, adică îmbunătățirea adusă de separare; este valoarea cea mai potrivită pentru comparații |
| `SISNR_dB` | nu ține cont de nivel; dacă este mult peste `SNR_dB`, vocea a fost separată bine, dar are alt nivel decât originalul |

**Săptămâna 6: rata de eroare pe cuvinte.** `WER = (S + D + I) / N`, unde S, D
și I sunt cuvintele înlocuite, omise și adăugate, iar N este numărul de
cuvinte rostite. Comparați `WER_extracted` cu `WER_clean` (vocea sintetizată,
înainte de mixare), nu cu zero: vocile în română au erori chiar înainte de
mixare.

---

## 4. Raportul

Completați [student_project_report](student_project_report.md) cu:

- rezultatele voastre (tabelele `results/*.csv` și figurile `results/*.png`);
- răspunsurile la întrebările din [project_roadmap_7_weeks](project_roadmap_7_weeks.md);
- limitările din secțiunea 5;
- concluziile voastre.

Raportul îl scrieți voi; programul nu îl generează.

---

## 5. Limitări care trebuie discutate în raport

1. Vocile sintetice sunt mai curate decât vocile reale. Rezultatele separării
   pe mixturi KittenTTS sunt, de aceea, mai bune decât cele pe care le-ați
   obține pe înregistrări reale; săptămâna 7 arată diferența.
2. Numărul de mixturi este mic. Din șase mixturi se pot vedea tendințe, dar nu
   se poate face un clasament. Este suficient să schimbați o singură
   propoziție a unui vorbitor pentru ca rezultatul unui model pe o mixtură să
   se modifice cu peste 10 dB.
3. Româna nu se află printre limbile declarate pentru KittenTTS 2. Vocile în
   română au accent (de exemplu *toamnă* este auzit ca *doamna*), deci o parte
   din erorile de transcriere vin din sinteză, nu din separare.
4. SNR-ul se calculează față de semnalul sintetizat, așa că nu spune nimic
   despre cât de naturală este vocea.
5. Trăsăturile folosite pentru a descrie o voce (F0, formanți, spectru) sunt
   alese manual. Sistemele folosite în practică compară vocile prin
   reprezentări învățate (speaker embeddings). Acestea recunosc mai bine
   vorbitorul, dar nu arată prin ce anume diferă două voci.
6. KittenTTS 2 poate greși atunci când textul seamănă cu înregistrarea de
   referință. Pusă să numere la fel ca în referință, clona s-a repetat sau s-a
   oprit; din acest motiv în săptămâna 3 se folosește o propoziție obișnuită.
   Ascultați clona de fiecare dată.

---

## 6. Cerințe

- MATLAB cu Audio Toolbox, Signal Processing Toolbox și Deep Learning Toolbox
  (acesta din urmă pentru `separateSpeakers`)
- Python 3.12 (lansatorul `py`), pentru KittenTTS, Whisper, MossFormer2 și TIGER
- opțional: o placă video NVIDIA; boxe și microfon pentru săptămâna 7

Proiectul a fost testat cu MATLAB R2026b pe un laptop cu placă RTX 4060.
