# Clinical Voice Snapshot

**Acoustic voice measures for speech-language pathologists.**

Clinical Voice Snapshot is a guided script for the free program
[Praat](https://www.fon.hum.uva.nl/praat/). You record a client with the usual
CAPE-V-style tasks: a sustained /a/, six sentences, and conversational speech.
The script then measures F0, intensity, CPPS, HNR, jitter, shimmer and formants,
and gives you a plain-text summary you can paste into a report.

- **No Praat or scripting experience needed.** Dialog windows walk you through
  choosing the recordings and checking them.
- **Works with how you already record.** Use one file per task, or one long
  recording with everything in it.
- **Clinic-ready summary** to paste into a report, plus a **research-ready
  spreadsheet** (tidy CSV) for studies and caseload data.
- **Transparent.** Every setting is saved with the results. A measure that
  fails is reported with a reason, never as 0.

*Who it is for:* speech-language pathologists (SLPs/SLTs), voice clinics,
clinical researchers, and students. *Who it is not for:* it measures this
fixed protocol only (a sustained /a/, short sentences, and conversational
speech). It is not a general-purpose tool for any kind of recording.

The script file is `voice_acoustics.praat`. It writes the results in three forms:

| File | For | What it is |
|---|---|---|
| `<name>_results.json` | the CAPE-Vr rating web app (CART) | Machine-readable results with all settings. Always saved. |
| `<name>_summary.txt` | clinicians | Plain-text summary to read or paste into a report. Also shown in the Praat Info window. |
| `<name>_results_long.csv` + `<name>_parameters.csv` | researchers | One row per recording × measure ("long"/tidy format), plus every setting and analysis parameter. |

The text summary and the CSVs are on by default and can be switched off in the
last dialog before the analysis. The JSON is always written.

**Version:** script 0.1.0, results format 0.2.0. Tested with Praat 7.0.02.

---

## Contents

- [Installation](#installation)
- [Running the script](#running-the-script)
- [What is measured](#what-is-measured)
- [Output files](#output-files)
- [Speaker profiles and settings](#speaker-profiles-and-settings)
- [Use with the rating web app](#use-with-the-rating-web-app)
- [Important notes on interpretation](#important-notes-on-interpretation)
- [References](#references)
- [Citing and license](#citing-and-license)

---

## Installation

1. Install **Praat 7.0.02 or newer** from <https://www.fon.hum.uva.nl/praat/>.
   Older versions may work, but the results file will include a warning and some
   measures may fail.
2. Download `voice_acoustics.praat` from this repository's
   [Releases](../../releases) page (or the green **Code** button).

The script is a single file and needs no other files or plug-ins.

## Running the script

1. Open Praat. In the **Praat** menu choose **Open Praat script...** and select
   `voice_acoustics.praat`.
2. In the script window choose **Run > Run**.
3. If Praat asks whether you trust the script, allow it. The script needs this
   to save its results files.
4. Follow the dialogs. On Windows Praat may say "The phonetic font is not
   available". Click OK; it does not affect the analysis.

You can enter an optional **patient ID**. It appears in the results and is
used in the file names. Then choose how the tasks were recorded.

### Separate files (one sound file per task)

Choose the folder with the recordings, then choose which file is which task.
Files are filled in automatically when their names look like a task, for
example:

| Task | Recognized names (examples) |
|---|---|
| Sustained /a/ | `ah.wav`, `P01_vowel_a.wav`, `sustained.wav` |
| Sentences 1–6 | `sentence1.wav`, `P01_sent_3.wav` |
| Conversation | `conversation.wav`, `P01_extemp.wav`, `spontaneous.wav` |
| Extra takes (/a/ and conversation only) | add `_t2`, `_take2`, or `_take_2` at the end |

Up to three takes of /a/ and two conversation samples can be analyzed. Each
sentence has one take.

Please check the filled-in choices. **One by one...** lets you pick each file
with the file browser instead, which is useful if the files are in different
folders. Files do not need to be renamed or moved. Supported formats:
WAV, FLAC, MP3, AIFF/AIFC.

### One recording (all tasks in one file)

Choose the file. It opens in a sound window, and the script marks where it
thinks the vowel and the sentences are. For each mark, click its label and
**Listen**, then **Remove** any that are wrong. To add a mark, drag across a
task, choose what it is, and click **Mark**. Click **Done** at the end, and keep
the sound window open until then. Sentences are numbered in recording order.
Each marked part is analyzed as if it were its own file, and times in the
results are times in the full recording. The marks are saved as a TextGrid
next to the results.

### Before the analysis

A summary dialog lists what will be analyzed. There you choose:

- the **speaker profile**, which sets the pitch range and formant ceiling (see
  [below](#speaker-profiles-and-settings));
- **Advanced...** to set the pitch floor, pitch ceiling or formant ceiling
  yourself, and the other analysis settings (formants, vowel window, CPPS
  preset, HNR, jitter, shimmer, stereo; see
  [below](#speaker-profiles-and-settings));
- whether to also save the **spreadsheet (CSV)** and the **text summary**.

Click **Run analysis**. The results are saved in the same folder as the
recordings.

## What is measured

| Measure | Sustained /a/ | Sentences, conversation | Unit |
|---|:-:|:-:|---|
| F0 mean, F0 SD | ✓ | ✓ | Hz |
| Mean intensity | ✓ | ✓ (voiced parts) | dB, **uncalibrated** |
| CPPS (smoothed cepstral peak prominence) | ✓ | ✓ (voiced parts) | dB |
| HNR (harmonics-to-noise ratio) | ✓ | | dB |
| Jitter (local) | ✓ | | % |
| Shimmer (local; local, dB) | ✓ | | %, dB |
| F1–F3 mean, median, SD | ✓ | | Hz |

**Vowels.** The script finds where voicing starts and stops, so silence and
noise around the vowel are ignored. It analyzes the **middle 3 s** of the
voiced part, which leaves out the irregular onset and offset. If the voiced
part is shorter than 3 s, it analyzes the middle 50% and adds a note. It
also notes any long unvoiced stretch inside the analysis window, such as a
voice break or a cough.

**Connected speech.** F0 is measured over the whole recording. Intensity and
CPPS are measured on the voiced parts joined together.

**Takes** are reported separately, and nothing is averaged across takes.

## Output files

All files of one run share a name: `<recording>_…` for one recording, or
`<patient ID>_…` for separate files (`voice_…` without an ID). **Existing files
are never replaced.** If any file of that name exists, `_2`, `_3`, … is
added to all of them.

### Text summary (`_summary.txt`)

Example (shortened):

```
CLINICAL VOICE SNAPSHOT
Patient ID: P01
Date: 2026-11-10 12:51:16
Speaker profile: adult_female (pitch 100-500 Hz, formant ceiling 5500 Hz)
Analysis: Praat 7.0.02, voice_acoustics 0.1.0, CPPS method praat_default

Sustained /a/
  File: ah.wav
  Analyzed: 0.55 to 3.55 s, middle 3.0 s of the voiced part
  F0 mean .................... 210.00 Hz
  F0 SD ...................... 0.01 Hz
  Intensity mean (relative) .. 84.19 dB (uncalibrated)
  CPPS ....................... 10.20 dB
  HNR ........................ 40.83 dB
  ...

Sentence 1
  File: sentence1.wav
  Analyzed: the whole 3.21 s; voiced 1.27 s
  F0 mean .................... 171.95 Hz
  ...

Tasks not recorded: Sentence 3, Sentence 4

Intensity is relative (uncalibrated) dB, not dB SPL. Each take is reported
separately; nothing is averaged across takes.
```

Measures that could not be computed are listed as "not measured" with the
reason. They are never shown as 0.

### Long-format CSV (`_results_long.csv`)

One row per recording × measure. Every row repeats the speaker and settings
columns, so the files of many participants can be stacked into one table.

| Column | Description |
|---|---|
| `speakerID`, `speakerProfile` | as entered in the first dialogs |
| `pitchFloorHz`, `pitchCeilingHz`, `formantCeilingHz`, `cppsMethod` | analysis settings used |
| `runDate`, `scriptVersion`, `praatVersion` | provenance |
| `fileName`, `task`, `take`, `status` | `task` is `vowel_a`, `sentence_1`…`sentence_6`, or `extemporaneous`; `status` is `analyzed` or `error` |
| `durationSec`, `sampleRateHz` | of the recording (or marked part) |
| `analysisStartSec`, `analysisEndSec` | the part analyzed |
| `voicedDurationSec` | connected speech only (`NA` for vowels) |
| `measure`, `value`, `unit` | e.g. `cpps`, `13.55`, `dB` |
| `missingReason` | why `value` is `NA`; empty otherwise |

Missing values are `NA`. A recording that could not be opened still gets
one row (`measure` = `NA`, with the error in `missingReason`). Values have the
same rounding as the JSON. The file is UTF-8 without a byte-order mark.

Reading and stacking the files in R:

```r
library(tidyverse)
d <- list.files("data", pattern = "_results_long(_\\d+)?\\.csv$", full.names = TRUE) |>
  map(read_csv, col_types = cols(speakerID = "c", .default = col_guess())) |>
  list_rbind()

# One column per measure, if you need wide format:
wide <- d |> select(speakerID, task, take, measure, value) |>
  pivot_wider(names_from = measure, values_from = value)
```

In Python: `pd.concat(pd.read_csv(f, dtype={"speakerID": str}) for f in glob.glob("data/*_results_long*.csv"))`.

In Excel, if accented file names look wrong, open the file with
**Data > From Text/CSV** and choose UTF-8.

### Parameters CSV (`_parameters.csv`)

Columns `section`, `name`, `value`. Every setting (`section = settings`) and
every Praat analysis parameter actually used (`section = analysisParameters`)
are listed, for methods sections and reproducibility.

### JSON (`_results.json`)

The complete results, including all settings, analysis parameters, unrecognized
files, missing tasks and warnings. A failed measure is written as
`{"value": null, "unit": …, "reason": "…"}`. File type
`cape-vr-acoustic-results`, schema version `0.2.0`. This is the file to upload
to the rating web app.

## Speaker profiles and settings

| Profile | Pitch floor–ceiling | Formant ceiling |
|---|---|---|
| `child` | 100–600 Hz | 8000 Hz |
| `adult_female` (default) | 100–500 Hz | 5500 Hz |
| `adult_male` | 75–300 Hz | 5000 Hz |
| `trans_woman` | 75–500 Hz | 5250 Hz |
| `trans_man` | 75–500 Hz | 5250 Hz |
| `other_unspecified` | 75–600 Hz | 5250 Hz |

Values can be changed per run under **Advanced...**. Whether they were changed
is recorded in all outputs.

The **Advanced...** window (in the "Check before the analysis" dialog) also
sets the other analysis choices for the run. It has two pages: pitch, formants
and vowels first, then CPPS, intensity, HNR, jitter, shimmer and stereo
(**Next >** and **< Previous** move between them; **Discard changes** leaves
everything as it was):

| Setting | Default | Options |
|---|---|---|
| Number of formants | 5 | 3 or more |
| Formant window | `whole_trimmed` (mean, median, SD) | `midpoint` (one value at the middle) |
| Vowel window | 3 s | any length above 0 |
| Short vowel fraction | 0.5 | above 0, at most 1 |
| CPPS preset | `praat_default` | `maryn_weenink_2015` (AVQI v02.02 settings) |
| Speech CPPS / intensity from voiced parts only | yes | no (the whole recording) |
| Intensity averaging | `energy` | `dB` |
| HNR method | `cc` | `ac` |
| Jitter/shimmer period range | `derived` (from the pitch range) | `fixed` (0.1–20 ms, as in AVQI) |
| Jitter measures | `local` | any of `local`, `local_absolute`, `rap`, `ppq5`, `ddp` |
| Shimmer measures | `local,local_db` | any of `local`, `local_db`, `apq3`, `apq5`, `apq11`, `dda` |
| Stereo recordings | `average` of the channels | `left` channel only |

Changed settings are listed in the summary dialog before the analysis runs.
The Praat command parameters themselves are under **ANALYSIS PARAMETERS** near
the top of the script. Every value used is written to the JSON and the
parameters CSV.

## Use with the rating web app

`voice_acoustics.praat` is the stand-alone version of the analysis used by the
CAPE-Vr rating web app (CART). Upload
`_results.json` in the app with **Upload results.json**. The CSV and text
files are extra and are not read by the app. The JSON format is the same
whether or not they are saved.

## Important notes on interpretation

- **Intensity is uncalibrated, relative dB, never dB SPL.** It depends on the
  microphone, distance and gain, so compare it only between recordings made with
  the same setup.
- **No normative comparison is made.** The script reports measurements only.
  Interpret them with the recording conditions, the speaker, and perceptual
  ratings in mind.
- **Recording quality matters.** Sample rates below 10 kHz prevent CPPS, and
  sample rates below twice the formant ceiling prevent formant measures. In
  both cases a reason is given. Background noise, clipping and compressed
  formats (MP3) can bias HNR, jitter, shimmer and CPPS.
- **Check the notes.** Short vowels, voice breaks and other problems are
  listed under "Notes" in the summary and under `warnings` in the JSON.
- CPPS from the same file can differ by about 0.1 dB between runs.

## References

- Boersma, P. (1993). Accurate short-term analysis of the fundamental frequency
  and the harmonics-to-noise ratio of a sampled sound. *Proceedings of the
  Institute of Phonetic Sciences, 17*, 97–110. (pitch, HNR)
- Boersma, P., & Weenink, D. Praat: doing phonetics by computer.
  <https://www.praat.org>
- Maryn, Y., & Weenink, D. (2015). Objective dysphonia measures in the program
  Praat: Smoothed cepstral peak prominence and acoustic voice quality index.
  *Journal of Voice, 29*(1), 35–43. (CPPS, `maryn_weenink_2015` method, period
  settings)
- Praat manual: "Voice 2. Jitter" and "Voice 3. Shimmer" (period range).

## Citing and license

**Please cite this project** if you use the script or its results in
publications, presentations, theses, or clinical reports, and when you
share modified versions:

> Chan, M. P. Y. (2026). *Clinical Voice Snapshot: a guided Praat script for
> acoustic voice measures* (Version 0.1.0) [Computer software].
> <https://github.com/maypychan/clinical-voice-snapshot-praat>

Please also cite Praat (Boersma & Weenink) and the method papers listed under
[References](#references) for the measures you report. GitHub's **Cite this
repository** button (from [CITATION.cff](CITATION.cff)) gives this citation in
APA and BibTeX formats. The script version and Praat version to cite are in
every output file.

The script is released under the [MIT License](LICENSE). You may use, modify
and share it freely, as long as the copyright notice is kept.
