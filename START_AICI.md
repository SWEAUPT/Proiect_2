# Proiectul 2: voci KittenTTS 2 și separarea vorbitorilor. Începeți de aici

Acesta este folderul de lucru pentru proiectul de 7 săptămâni. Toate vocile
din proiect sunt produse de un model neuronal de sinteză vocală, KittenTTS 2:
voci predefinite, o clonă a unei înregistrări reale, vorbitori în engleză și în
română. Veți analiza aceste voci, veți clona una dintre ele, veți amesteca mai
mulți vorbitori, îi veți separa cu patru rețele neuronale și veți evalua
rezultatul.

Documentele există în două variante, `.md` și `.html`. Varianta `.html` se
deschide cu dublu-clic în orice browser sau, din MATLAB, cu
`web("START_AICI.html")`.

Citiți documentele în această ordine:

1. acest fișier: instalarea și codul pe care îl aveți de scris;
2. [student_instructions](student_instructions.md): rularea, verificarea, interpretarea rezultatelor, limitările;
3. [project_roadmap_7_weeks](project_roadmap_7_weeks.md): planul pe săptămâni și întrebările pentru raport;
4. [README](README.md): detalii tehnice despre modele, instalare și scripturile Python;
5. [student_project_report](student_project_report.md): șablonul raportului, pe care îl completați la final.

---

## 1. Instalare

1. MATLAB R2026b, cu Audio Toolbox, Signal Processing Toolbox și Deep Learning
   Toolbox.
2. Deschideți folderul proiectului în MATLAB și rulați:
   ```matlab
   run_all_tests('Week', 1)
   ```
   La început testele eșuează cu mesajul `TODO 1.1 not implemented`. Este
   normal: ele vor trece după ce scrieți codul cerut.
3. Până în săptămâna 3 instalați KittenTTS 2 și Whisper (aproximativ 6 GB, o
   singură dată). Din PowerShell, în folderul proiectului:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup_tts.ps1
   ```
4. Până în săptămâna 5 instalați modelele de separare (aproximativ 1 GB):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup_separation.ps1
   ```

În primele două săptămâni aveți nevoie doar de MATLAB.

---

## 2. Ce aveți de scris

Partea de infrastructură este deja scrisă: apelurile către KittenTTS și
Whisper (prin scripturi Python), cele patru modele de separare, salvarea
rezultatelor intermediare, figurile, `main.m` și testele. Voi scrieți
calculele propriu-zise. Locurile respective sunt marcate în cod prin apeluri
`todo('N.k', ...)`, care opresc programul cu un mesaj explicit până când le
înlocuiți. Ce trebuie calculat este descris în comentariile de deasupra
fiecărui apel și în antetul fișierului.

| Săpt. | Fișiere | TODO | Ce calculați |
|:--:|---|:--:|---|
| 1 | `lib/p2_quality_report.m`, `w1_reference_voice.m` | 1.1 – 1.3 | energia pe cadre, estimarea SNR, criteriile de calitate, spectrograma mel |
| 2 | `lib/p2_voice_profile.m` | 2.1 – 2.2 | cadrele sonore, F0 median și dispersia lui în semitonuri, formanții din polii LPC |
| 3 | `lib/p2_compare_profiles.m`, `lib/p2_wer.m` | 3.1 – 3.2 | distanța dintre clonă și referință; rata de eroare pe cuvinte (distanța de editare) |
| 4 | `lib/p2_mix.m`, `lib/p2_gender_from_f0.m` | 4.1 – 4.2 | mixarea prin adunarea semnalelor, la niveluri date; genul estimat din F0 |
| 5 | `lib/p2_separation_snr.m`, `w5_separate_mixtures.m` | 5.1 – 5.4 | SNR, SI-SNR, asocierea optimă dintre ieșiri și surse, evaluarea la 8 kHz |
| 6 | `w6_evaluate_separation.m` | 6.1 – 6.3 | WER pentru semnalul curat și pentru mixtură, variația nivelului |
| 7 | `w7_dashboard.m`, `w7_real_recordings.m` | 7.1 – 7.3 | panoul final, redarea pe două boxe, WER pe înregistrarea reală |

Ca să găsiți TODO-urile rămase, folosiți în editorul MATLAB **Find Files**
(Ctrl+Shift+F) și căutați `todo(`.

### Cum lucrați într-o săptămână

1. Citiți antetul fișierului și comentariile din jurul fiecărui `todo(...)`.
2. Înlocuiți fiecare `todo(...)` cu codul cerut.
3. Rulați `run_all_tests('Week', N)` până când trec toate testele.
4. Setați `LAST_WEEK = N` în `main.m` și rulați `main`.
5. Răspundeți la întrebările săptămânii din [project_roadmap_7_weeks](project_roadmap_7_weeks.md).
6. Treceți la săptămâna următoare numai după aceea, pentru că fiecare
   săptămână folosește rezultatele celei anterioare.

Testele raportate ca „skipped” sunt cele care durează mult (sinteza, Whisper,
modelele Python). Le puteți rula cu
`setenv("P2_SLOW_TESTS", "1"); run_all_tests('Week', N)`.

### La final

```matlab
main             % toate cele 7 săptămâni
run_all_tests    % toate testele
```

Completați [student_project_report](student_project_report.md) cu rezultatele
obținute de voi (folderul `results/`).

---

## 3. Probleme frecvente

| Mesaj sau simptom | Cauza |
|---|---|
| `TODO 2.1 not implemented: ...` | ați ajuns la o porțiune de cod pe care trebuie să o scrieți voi |
| `Project Python environment not found` | nu ați rulat `setup_tts.ps1` |
| `Unrecognized function or variable 'separateSpeakers'` | nu ați rulat `setup_separation.ps1` |
| `Python ended ... most likely out of memory` | închideți programele care consumă multă memorie (de exemplu alte sesiuni MATLAB); scriptul încearcă automat și pe CPU |
| sinteza durează câteva minute | rulează pe CPU, ceea ce este normal fără o placă NVIDIA |
| un test apare ca „skipped” | este un test lent, care rulează doar cu `P2_SLOW_TESTS=1`; nu este o eroare |
| o voce sau o separare greșită se repetă la fiecare rulare | rezultatul este salvat în `audio/`: ștergeți fișierul respectiv și rulați din nou |
