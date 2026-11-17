# Raport. Proiectul 2: voci KittenTTS 2 și separarea vorbitorilor

> Înlocuiți textul dintre `<...>` cu rezultatele și observațiile voastre.
> Raportul se scrie de mână și face parte din evaluare.

**Student:** `<nume, grupa>`
**Vocea de referință:** `<proba din Audio Toolbox / înregistrare proprie>`
**Data rulării:** `<zz.ll.aaaa>`
**Calculator:** `<GPU sau CPU>`

---

## 1. Obiectiv

`<În 3–5 rânduri: ce măsoară proiectul și de ce folosirea unor voci sintetice
permite măsurători exacte.>`

---

## 2. Săptămâna 1. Vocea de referință

| Verificare | Valoare | Stare |
|---|---|---|
| Duration (s) | `<...>` | `<OK/WARN>` |
| Peak level (dBFS) | `<...>` | `<...>` |
| Clipped samples (%) | `<...>` | `<...>` |
| Estimated SNR (dB) | `<...>` | `<...>` |
| Speech share (%) | `<...>` | `<...>` |

Figuri: `results/w1_figures_*.png`.

`<La ce lungime a ferestrei apar armonicele separat și cum se leagă aceasta de
F0-ul vocii voastre? De ce folosesc modelele de sinteză spectrograme mel?>`

---

## 3. Săptămâna 2. Amprenta vocală

| F0 median (Hz) | Dispersia F0 (semitonuri) | F1 / F2 / F3 (Hz) | Centroid (Hz) | Cadre sonore (%) |
|---|---|---|---|---|
| `<...>` | `<...>` | `<...>` | `<...>` | `<...>` |

`<Interpretare.>`

---

## 4. Săptămâna 3. Clonarea

Tabelul din `results/w3_clone_comparison.csv`:

| Voce | dF0_st | dRange_st | dF1_pct | dF2_pct | ltasRms_dB | mfccDist |
|---|---|---|---|---|---|---|
| clona | `<...>` | | | | | |
| voce predefinită `<A>` | | | | | | |
| voce predefinită `<B>` | | | | | | |

`<Este clona mai apropiată de referință decât ambele voci predefinite, pe
fiecare coloană? Ce ați auzit înainte de a face măsurătorile?>`

**Româna.** Transcrierea Whisper: „`<...>`” (WER `<...>`).
`<Identitatea vocii sau pronunția: ce s-a pierdut mai întâi? Comentați ș, ă și
accentul.>`

---

## 5. Săptămâna 4. Vorbitori și mixturi

| Id | Voce | Gen presupus / măsurat | F0 median (Hz) | Limbă |
|---|---|---|---|---|
| `<...>` | | | | |

`<Se văd doi vorbitori în spectrograma bărbat + femeie? Dar în cea bărbat +
bărbat?>`

---

## 6. Săptămâna 5. Separarea

Îmbunătățirea medie a SNR (dB), din `results/w5_summary_snri.csv`:

| Mixtură | Conv-TasNet | SepFormer | MossFormer2 | TIGER |
|---|---|---|---|---|
| A bărbat + femeie, EN | | | | |
| B bărbat + bărbat, EN | | | | |
| C bărbat + femeie, RO | | | | |
| D femeie + femeie, EN+RO | | | | |
| E 3 vorbitori, EN | | | – | – |
| F 3 vorbitori, EN+RO | | | – | – |

`<Care model dă cele mai bune rezultate și în ce situații? Comparați: același
gen sau genuri diferite, engleză sau română, 2 sau 3 vorbitori. Ați observat o
inversare de permutare? Cât de repede lucrează fiecare model?>`

---

## 7. Săptămâna 6. Transcriere, audiție, variația nivelului

WER mediu al vorbitorilor separați (`results/w6_summary_wer.csv`):

`<tabel>`

Notele de la testul de audiție (1–5):

| Model | Sursă | Notă |
|---|---|---|
| `<...>` | | |

`<Un SNR mare înseamnă întotdeauna un WER mic? De la ce nivel începe fiecare
model să greșească?>`

---

## 8. Săptămâna 7. Înregistrări reale și panoul final

`<Ce ați înregistrat (boxe sau vorbitori reali), ce model s-a descurcat cel mai
bine, ce WER ați obținut.>`

`<Inserați aici figura results/w7_dashboard.png și comentați-o.>`

---

## 9. Limitări

`<Cel puțin cele șase limitări din student_instructions.md, secțiunea 5,
formulate de voi și susținute cu valorile voastre.>`

---

## 10. Concluzii

`<Ce ați învățat și ce ați mai măsura dacă ați continua proiectul.>`
