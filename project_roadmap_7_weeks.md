# Proiectul 2: planul pe 7 săptămâni

**Voci KittenTTS 2 și separarea vorbitorilor.** Toate vocile din proiect sunt
produse de un model neuronal de sinteză vocală, KittenTTS 2: voci predefinite,
o clonă a unei înregistrări reale, vorbitori în engleză și în română. Pentru
că semnalul curat și textul fiecărui vorbitor sunt cunoscute, toate
măsurătorile au o valoare de referință exactă: cât de apropiată este o clonă
de vocea originală, cât de bine separă patru rețele neuronale vorbitorii
amestecați (SNR) și dacă vorbirea separată mai poate fi înțeleasă (rata de
eroare pe cuvinte).

Totul pornește din `main.m`. Setați `LAST_WEEK` la săptămâna la care ați
ajuns. Sintezele, separările și transcrierile se salvează pe disc, așa că
săptămânile deja parcurse se reiau în câteva secunde. Tabelele (CSV) și
figurile (PNG) pentru raport se salvează în `results/`.

Proiectul se termină în cel mult 7 săptămâni. Codul pe care îl scrieți în
fiecare săptămână (apelurile `todo(...)`) este descris în
[START_AICI](START_AICI.md).

---

## 1. Pe scurt

```
[SĂPTĂMÂNA 1] w1_reference_voice.m
  * vocea de referință: proba din Audio Toolbox, un fișier WAV propriu
    sau o înregistrare nouă
  * verificarea calității: durată, nivel maxim, saturare, SNR, procent de vorbire
  * ferestre STFT de 5 / 25 / 100 ms și spectrograma mel
        |
        v
[SĂPTĂMÂNA 2] w2_voice_fingerprint.m
  * frecvența fundamentală F0 (mediana și dispersia în semitonuri)
  * formanții F1-F3 prin LPC
  * spectrul mediu pe termen lung, MFCC, centroidul spectral
        |
        v
[SĂPTĂMÂNA 3] w3_clone_voice.m
  * KittenTTS 2: două voci predefinite, pentru comparație, și o clonă
  * distanțe față de referință: este clona mai apropiată decât celelalte voci?
  * clona vorbind în română (limbă nedeclarată de model)
  * rata de eroare pe cuvinte (WER) prin distanța de editare
        |
        v
[SĂPTĂMÂNA 4] w4_make_mixtures.m
  * cinci vorbitori: 2 bărbați și o femeie în engleză, un bărbat și o femeie în română
  * verificarea genului prin F0 măsurat
  * mixturi prin adunarea semnalelor: bărbat+femeie, bărbat+bărbat, română,
    engleză+română, 3 vorbitori
  * spectrograme: se vede că vorbesc doi oameni?
        |
        v
[SĂPTĂMÂNA 5] w5_separate_mixtures.m
  * patru modele: Conv-TasNet și SepFormer (separateSpeakers din MATLAB),
    MossFormer2 și TIGER (Python)
  * SNR, îmbunătățirea SNR, SI-SNR, toate la 8 kHz
  * inversări de permutare: schimbă modelul vorbitorii între ei pe parcurs?
        |
        v
[SĂPTĂMÂNA 6] w6_evaluate_separation.m
  * transcriere cu Whisper large-v3 (engleză și română), rata de eroare
  * test de audiție, note de la 1 la 5
  * variația nivelului: un vorbitor mai încet sau mai tare (-12 ... +12 dB)
        |
        v
[SĂPTĂMÂNA 7] w7_real_recordings.m + w7_dashboard.m
  * două boxe și un microfon; două persoane care vorbesc în același timp
  * panoul final: SNRi, WER, variația nivelului, distanțele clonei
  * raportul (student_project_report.md)
```

---

## 2. Pe săptămâni

### Săptămâna 1. Vocea de referință și spectrograma

**Scop.** Să vă cunoașteți înregistrarea înainte de a o clona și să înțelegeți
spectrograma, pe care o veți folosi în toate săptămânile următoare.

**Rulare.** `LAST_WEEK = 1` în `main.m`. Dacă vreți să folosiți vocea voastră,
setați `REFERENCE_SOURCE = "record"` (12 s, într-o cameră liniștită, la
aproximativ 20 cm de microfon).

**Întrebări pentru raport.**
- Ce verificări de calitate trec și ce verificări dau avertisment pentru
  înregistrarea voastră? De ce? (La clonare se copiază și ecoul camerei,
  brumul de rețea și distorsiunile de saturare.)
- De la ce lungime a ferestrei apar armonicele ca linii separate? Legați
  răspunsul de F0-ul pe care îl veți măsura în săptămâna 2 (o fereastră de T
  secunde are o rezoluție de aproximativ 1/T Hz).
- De ce folosesc modelele de sinteză vocală spectrograme mel și nu
  spectrograme liniare?

### Săptămâna 2. Amprenta vocală

**Scop.** Să descrieți o voce prin mărimi măsurabile, fiecare cu o
semnificație fizică precisă.

**Întrebări.**
- Care sunt F0 median și dispersia lui pentru vocea de referință? Valoarea se
  încadrează în intervalul tipic pentru bărbați (85–155 Hz) sau pentru femei
  (165–255 Hz)?
- De ce depind F1 și F2? De ce se raportează separat de F0?
- De ce se calculează F0 doar pe cadrele sonore? (Algoritmul de estimare
  întoarce o valoare și pentru liniște.)

### Săptămâna 3. Clonarea cu KittenTTS 2

**Scop.** Să clonați vocea de referință și să măsurați cât de apropiată este
clona, în loc să apreciați doar după ureche.

**Întrebări.**
- În `w3_clone_comparison.csv`, este clona mai aproape de referință decât
  ambele voci predefinite, pe fiecare coloană? Ce caracteristică este redată
  cel mai slab?
- Ascultați înainte de a măsura. Corespunde impresia auditivă cu valorile
  măsurate?
- Când clona vorbește în română, își păstrează vocea (F0 și spectru apropiate
  de clona în engleză)? Ascultați *ș* (șase, șapte), *ă* (nouă) și accentul.
  Ce se pierde mai întâi: identitatea vocii sau pronunția?
- De ce clona nu rostește același text ca înregistrarea de referință?
  (Vedeți textul de ajutor al funcției `w3_clone_voice`.)

### Săptămâna 4. Vorbitori și mixturi

**Scop.** Să construiți semnale de test pentru care rezultatul corect este
cunoscut.

**Întrebări.**
- Are fiecare voce genul presupus (`MeasuredGender`)? Numele vocii nu
  garantează acest lucru.
- În spectrograma mixturii bărbat + femeie, găsiți un moment în care vorbesc
  amândoi. Se văd două serii de armonice, cu distanțe diferite între linii?
- În mixtura bărbat + bărbat se mai pot deosebi cele două serii? Ați putea
  spune câți vorbitori sunt doar privind mixtura?

### Săptămâna 5. Separarea și SNR

**Scop.** Să comparați patru rețele de separare pe aceleași mixturi.

$$\mathrm{SNR} = 10\log_{10}\frac{\sum_n s^2[n]}{\sum_n \left(s[n]-s_r[n]\right)^2}\ \text{dB}$$

**Întrebări.**
- Este mixtura bărbat + bărbat (B) mai greu de separat decât bărbat + femeie
  (A), pentru toate modelele? De ce ar îngreuna separarea două frecvențe
  fundamentale apropiate?
- Scade SNR-ul pentru română (C) sau pentru o pereche de limbi diferite (D)?
  Rețelele au fost antrenate pe cărți audio în engleză.
- Cu 3 vorbitori, a găsit Conv-TasNet trei voci (coloana `Outputs`)? Comparați
  cu SepFormer, care primește numărul de vorbitori ca parametru.
- Găsiți în figura de permutare un loc în care modelul schimbă vorbitorii între
  ei. De ce scade SNR-ul, deși fiecare porțiune este bine separată?

### Săptămâna 6. Transcriere, audiție, variația nivelului

**Scop.** Să verificați dacă o separare bună înseamnă și o vorbire
inteligibilă.

**Întrebări.**
- Cât din WER-ul mixturii se recuperează prin separare?
- De ce, pentru română, comparați `WER_extracted` cu `WER_clean` și nu cu 0?
- Un SNR mare înseamnă întotdeauna un WER mic? Găsiți un rând în care cele
  două nu corespund și ascultați semnalul.
- La variația nivelului, de la ce valoare începe fiecare model să greșească?

### Săptămâna 7. Înregistrări reale, panoul final, raportul

**Scop.** Să testați modelele pe sunet înregistrat, apoi să adunați
rezultatele.

**Rulare.** Setați `DO_LOUDSPEAKERS = true` (două boxe la circa 1 m una de
alta, cu microfonul în fața lor) și/sau `DO_LIVE = true` (două persoane își
citesc propozițiile în același timp).

**Întrebări.**
- De ce nu se poate calcula un SNR exact pentru o înregistrare? Ce folosiți în
  schimb?
- Ce model se descurcă cel mai bine pe sunet înregistrat? (TIGER a fost
  antrenat pe semnale cu ecou și zgomot, celelalte în principal pe vorbire
  curată.)
- Completați [student_project_report](student_project_report.md) și includeți
  figura `results/w7_dashboard.png`.

---

## 3. Testele automate

```matlab
run_all_tests                % testele rapide, 1-2 minute
run_all_tests('Week', 5)     % testele unei singure săptămâni
setenv("P2_SLOW_TESTS", "1"); run_all_tests   % și testele lente: sinteză, Whisper, modelele Python
```

Testele verifică intrările și ieșirile fiecărei săptămâni și proprietățile pe
care se sprijină măsurătorile: SNR-ul pentru semnale cunoscute, asocierea
corectă dintre ieșiri și surse, detectarea unei inversări de permutare, F0-ul
unei voci sintetice, rata de eroare pe cuvinte (inclusiv pentru diacriticele
românești) și salvarea rezultatelor intermediare.

---

## 4. Cum interpretați rezultatele

- O distanță (săptămâna 3) sau un SNR (săptămâna 5) nu spune mult luat
  separat. Prezentați-l întotdeauna alături de valoarea de comparație: clona
  alături de vocile predefinite, semnalul separat alături de mixtura inițială
  (`SNRin_dB`, `SNRi_dB`).
- Din șase mixturi se pot vedea tendințe, dar nu se poate face un clasament.
  Schimbarea unei singure propoziții poate modifica rezultatul unui model cu
  peste 10 dB. Menționați acest lucru în raport.
- Vocile sintetice sunt mai curate decât cele reale, așa că rezultatele pe
  mixturi KittenTTS sunt mai bune decât cele pe înregistrări reale. Săptămâna
  7 arată cât de mare este diferența.
