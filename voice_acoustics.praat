# ======================================================================
# Clinical Voice Snapshot   (voice_acoustics.praat, version 0.1.0,
#                            developed for Praat 7.0.02)
#
# Copyright (c) 2026 May Pik Yu Chan. MIT License (see LICENSE).
# If you use this script, please cite it; see README.md or CITATION.cff:
#   Chan, M. P. Y. (2026). Clinical Voice Snapshot (Version 0.1.0)
#   [Computer software]. https://github.com/maypychan/clinical-voice-snapshot-praat
#
# Measures voice recordings (sustained /a/, sentences, conversational
# speech) and saves the results in a .json file for the rating web page.
# It can also save a spreadsheet (.csv) for research and a plain-text
# summary that can be pasted into a report.
#
# HOW TO RUN
#   1. In Praat: Praat menu > Open Praat script... > choose this file.
#   2. In the script window: Run > Run.
#   3. If Praat asks whether you trust this script, allow it: the script
#      saves a results file.
#   4. Follow the dialogs. On Windows, Praat may say "The phonetic font is
#      not available"; click OK (this does not affect the analysis).
#   5. Upload the results file on the rating web page.
#
# CHOOSING THE RECORDINGS
#   Separate files: choose their folder, then which file is which task.
#     Files whose names look like a task (for example "ah.wav",
#     "sentence1.wav") are filled in. "One by one..." asks for each file
#     in turn instead.
#   One recording: choose the file; it opens in a sound window. The script
#     marks where it thinks the vowel and the sentences are. Check each
#     mark (click its label, then Listen) and remove wrong ones (Remove).
#     To add a mark, drag across a task, choose what it is, and click Mark.
#     Click Done at the end; keep the sound window open until then.
#     Sentences are numbered in recording order. Each marked part is
#     analyzed as if it were its own file; times are times in the recording.
#
# RESULTS
#   Saved next to the recording(s): <recording>_results.json (one
#   recording, with the marks in <recording>_marks.TextGrid) or
#   <patient ID>_results.json (separate files; voice_results.json without
#   an ID). An existing file is never replaced: _2, _3, ... is added.
#   Also saved, unless switched off in the dialog before the analysis
#   (the .json file is always saved; the rating web page reads only that):
#     <name>_results_long.csv   one row per recording and measure ("long"
#        or "tidy" format), for R, Python, SPSS or Excel. Missing values
#        are NA, with the reason in the missingReason column. Every row
#        repeats the patient ID and settings, so the files of several
#        patients can be stacked into one table.
#     <name>_parameters.csv   the settings and analysis parameters used.
#     <name>_summary.txt   the results as plain text, to read or paste into
#        a report. It is also shown in the Praat Info window.
#   - Intensity is uncalibrated dB (relative), never SPL.
#   - A measure that fails is written as null with a reason, never as 0.
#   - Takes are reported separately; nothing is averaged across takes.
#
# SPEAKER PROFILES (pitch floor / ceiling, formant ceiling)
#   child 100/600 Hz, 8000 Hz
#   adult_female 100/500 Hz, 5500 Hz (default); adult_male 75/300 Hz, 5000 Hz
#   trans_woman, trans_man 75/500 Hz, 5250 Hz; other_unspecified 75/600 Hz, 5250 Hz
#   Other values, and the other analysis settings (formants, vowel window,
#   CPPS preset, HNR, jitter/shimmer, stereo), can be set under
#   "Advanced..." in the summary dialog.
# ======================================================================

scriptVersion$ = "0.1.0"
resultsSchemaVersion$ = "0.2.0"
# Version of the settings format written to the results.
settingsSchemaVersion$ = "0.1.0"
testedPraatVersion = 7002
testedPraatVersion$ = "7.0.02"

# ----------------------------------------------------------------------
# ANALYSIS PARAMETERS (all are written to the results)
# ----------------------------------------------------------------------

# Pitch: To Pitch (cc), Praat defaults (Boersma 1993). "(cc)" is the
# older name of "raw cross-correlation"; it also works in older Praat.
pitchTimeStep = 0
pitchMaxCandidates = 15
pitchVeryAccurate$ = "no"
pitchSilenceThreshold = 0.03
pitchVoicingThreshold = 0.45
pitchOctaveCost = 0.01
pitchOctaveJumpCost = 0.35
pitchVoicedUnvoicedCost = 0.14

# Voiced/unvoiced intervals: PointProcess: To TextGrid (vuv).
vuvMaxPeriod = 0.02
vuvMeanPeriod = 0.01

# Intensity: minimum pitch = pitch floor, automatic time step, mean subtracted.
intensityTimeStep = 0
intensitySubtractMean$ = "yes"

# CPPS: Maryn & Weenink (2015), J Voice 29(1):35-43.
cppsPitchFloor = 60
cppsTimeStep = 0.002
cppsMaxFrequency = 5000
cppsPreEmphasis = 50
cppsMinSampleRate = 2 * cppsMaxFrequency

# CPPS preset "maryn_weenink_2015": the values of the AVQI v02.02 script
# (Maryn & Weenink 2015), including its 0-34 Hz filter before CPPS.
mwHighPassHz = 34
mwHighPassSmoothing = 0.1
mwSubtractTrend$ = "no"
mwTimeAveraging = 0.01
mwQuefrencyAveraging = 0.001
mwPeakMinHz = 60
mwPeakMaxHz = 330
mwTolerance = 0.05
mwInterpolation$ = "parabolic"
mwTrendFrom = 0.001
mwTrendTo = 0
mwTrendType$ = "Straight"
mwFitMethod$ = "Robust"

# CPPS preset "praat_default": the Get CPPS defaults of Praat 7.0.02.
pdSubtractTrend$ = "yes"
pdTimeAveraging = 0.02
pdQuefrencyAveraging = 0.0005
pdPeakMinHz = 60
pdPeakMaxHz = 330
pdTolerance = 0.05
pdInterpolation$ = "parabolic"
pdTrendFrom = 0.001
pdTrendTo = 0.05
pdTrendType$ = "Exponential decay"
pdFitMethod$ = "Robust slow"

# HNR: Praat defaults (Boersma 1993).
hnrTimeStep = 0.01
hnrSilenceThreshold = 0.1
hnrPeriodsPerWindowCc = 1.0
hnrPeriodsPerWindowAc = 4.5

# Jitter and shimmer: Praat manual ("Voice 2. Jitter", "Voice 3. Shimmer");
# the fixed period range and the factors are those of the AVQI script.
fixedShortestPeriod = 0.0001
fixedLongestPeriod = 0.02
maxPeriodFactor = 1.3
maxAmplitudeFactor = 1.6

# Vowels: warn (only) if the analysis window contains an unvoiced
# stretch at least this long.
vowelGapWarningSec = 0.1

# Formants: To Formant (burg), Praat defaults.
formantTimeStep = 0
formantWindowLength = 0.025
formantPreEmphasis = 50

# ----------------------------------------------------------------------
# TASK LABELS (as used by the web page). "reading" is optional.
# ----------------------------------------------------------------------
task$[1] = "vowel_a"
task$[2] = "vowel_i"
task$[3] = "sentence_1"
task$[4] = "sentence_2"
task$[5] = "sentence_3"
task$[6] = "sentence_4"
task$[7] = "sentence_5"
task$[8] = "sentence_6"
task$[9] = "extemporaneous"
task$[10] = "reading"
nTasks = 10
for t to nTasks
    taskFound[t] = 0
    taskRequired[t] = 1
endfor
taskRequired[10] = 0


# ----------------------------------------------------------------------
# TASKS: one slot per recording. Extra takes are optional.
# ----------------------------------------------------------------------
nSlots = 11
#   slot, task label, task number (of 8), take, short label, long label, prompt, parent slot (0 = none)
@defineSlot: 1, "vowel_a", 1, 1, "Sustained /a/", "Sustained vowel /a/", "Sustain an /a/ vowel for 3 to 5 seconds.", 0
@defineSlot: 2, "vowel_a", 1, 2, "Sustained /a/ (take 2)", "Sustained vowel /a/, take 2 (optional)", "Another /a/ take, if you recorded one. Otherwise click Skip.", 1
@defineSlot: 3, "vowel_a", 1, 3, "Sustained /a/ (take 3)", "Sustained vowel /a/, take 3 (optional)", "Another /a/ take, if you recorded one. Otherwise click Skip.", 2
# Only the task names are shown, not the sentences themselves.
@defineSlot: 4, "sentence_1", 2, 1, "Sentence 1", "Sentence 1", "The first of the six sentences.", 0
@defineSlot: 5, "sentence_2", 3, 1, "Sentence 2", "Sentence 2", "The second of the six sentences.", 0
@defineSlot: 6, "sentence_3", 4, 1, "Sentence 3", "Sentence 3", "The third of the six sentences.", 0
@defineSlot: 7, "sentence_4", 5, 1, "Sentence 4", "Sentence 4", "The fourth of the six sentences.", 0
@defineSlot: 8, "sentence_5", 6, 1, "Sentence 5", "Sentence 5", "The fifth of the six sentences.", 0
@defineSlot: 9, "sentence_6", 7, 1, "Sentence 6", "Sentence 6", "The sixth of the six sentences.", 0
@defineSlot: 10, "extemporaneous", 8, 1, "Conversation", "Conversational speech", "The conversational speech sample.", 0
@defineSlot: 11, "extemporaneous", 8, 2, "Conversation (2)", "Conversational speech, recording 2 (optional)", "A second conversational speech sample, if you recorded one. Otherwise click Skip.", 10
nTaskSteps = 8

# Speaker profiles (adult_female, number 2, is the default; see profileChoice).
nProfiles = 6
@defineProfile: 1, "child", 100, 600, 8000
@defineProfile: 2, "adult_female", 100, 500, 5500
@defineProfile: 3, "adult_male", 75, 300, 5000
@defineProfile: 4, "trans_woman", 75, 500, 5250
@defineProfile: 5, "trans_man", 75, 500, 5250
@defineProfile: 6, "other_unspecified", 75, 600, 5250

# Sound files recognized in a folder.
soundExtensions$ = "|wav|flac|mp3|aif|aiff|aifc|"

# One recording: a mark must be at least this long, so that a click
# without dragging is not taken as a mark.
minMarkSec = 0.25

# Pause windows have a fixed width: longer text is wrapped at this length.
maxCommentChars = 75
# File names in a drop-down list: about 36 characters fit.
maxMenuChars = 34

# One recording: the task kind chosen in the marking dialog
# (1 = vowel /a/, 2 = sentence, 3 = conversation).
markChoice = 2

# One recording: the marks (markType 1 = vowel /a/, 2 = sentence,
# 3 = conversation). Each kind fills its slots groupFirst..groupLast in
# recording order.
nMarks = 0
groupName$[1] = "vowel /a/"
groupFirst[1] = 1
groupLast[1] = 3
groupName$[2] = "sentence"
groupFirst[2] = 4
groupLast[2] = 9
groupName$[3] = "conversation"
groupFirst[3] = 10
groupLast[3] = 11

# One recording: the first guesses of the vowel and the sentences. They
# are checked by the user and change no measurement. Stretches of sound
# between silences are classified: mostly voiced with a steady pitch =
# vowel; other stretches of sentence length = sentence.
#   Silence detection (To TextGrid (silences)): minimum pitch, silence
#   threshold below the loudest part, shortest silence, shortest sound.
guessMinPitch = 100
guessSilenceDb = -25
guessMinSilenceSec = 0.3
guessMinSoundingSec = 0.1
#   Pitch range used only for the guess (wide enough for children and adults).
guessPitchFloor = 75
guessPitchCeiling = 600
#   A vowel: at least this long, this voiced, and this steady in pitch.
guessVowelMinSec = 0.8
guessVowelMinVoiced = 0.6
guessVowelMaxSdSt = 1.5
#   A sentence: between these lengths, and at least this voiced.
guessSentenceMinSec = 0.4
guessSentenceMaxSec = 6
guessSentenceMinVoiced = 0.2
#   Each guessed mark is widened by this much on both sides.
guessPadSec = 0.05

# Separate files: the chosen folder ("" = none yet), and oneByOne = 1
# when the files are chosen one by one.
recFolder$ = ""
oneByOne = 0
nFolderFiles = 0
nPrefilled = 0
# One recording: what the guess found, shown once in the marking dialog.
guessMessage$ = ""

# ======================================================================
# START
# ======================================================================
folder$ = defaultDirectory$

writeInfoLine: "Voice acoustics script ", scriptVersion$, " (Praat ", praatVersion$, ")"

# Warnings collected during the run, written to results.json.
nWarnings = 0

if praatVersion < testedPraatVersion
    @addWarning: "This Praat version (" + praatVersion$ + ") is older than the tested version (" + testedPraatVersion$ + "). Results may differ, and some measures may fail."
endif

# ----------------------------------------------------------------------
# CHOOSE THE RECORDINGS
# ----------------------------------------------------------------------
# inputMode: 1 = separate files, 2 = one recording with marks.
inputMode = 0
longSound = 0
marksGrid = 0
longPath$ = ""
longName$ = ""
speakerID$ = ""
startProblem$ = ""
while inputMode = 0
    # No default button, so that neither choice is emphasized.
    beginPause: "Voice acoustic analysis"
        if startProblem$ <> ""
            @wrapComment: "PLEASE NOTE: " + startProblem$
        endif
        comment: "This script measures voice recordings: a sustained /a/,"
        comment: "sentences, and conversational speech."
        comment: "Patient ID (optional; it is shown in the results):"
        sentence: "Patient ID", speakerID$
        comment: ""
        comment: "How were the tasks recorded?  Click one of the buttons below."
        comment: "   Separate files:  one sound file for each task."
        comment: "         You choose their folder, then which file is which."
        comment: "   One recording:  all tasks in one sound file."
        comment: "         You choose it, then check where each task is."
        comment: "The files do not need to be renamed or moved."
        comment: "The results are saved next to them."
    clicked = endPause: "Cancel", "Separate files", "One recording", 0, 1
    speakerID$ = patient_ID$
    startProblem$ = ""
    if clicked = 1
        @cancelRun
    elsif clicked = 2
        inputMode = 1
    else
        longPath$ = chooseReadFile$: "Choose the recording that contains all the tasks"
        if longPath$ = ""
            startProblem$ = "no recording was chosen."
        else
            @openLongRecording
            if openLongRecording.ok
                inputMode = 2
                # First guesses for the vowel and the sentences.
                @guessMarks
            else
                startProblem$ = "Praat could not open " + longName$ + " as a sound. Please choose another file."
            endif
        endif
    endif
endwhile

# Settings chosen in the summary dialog: adult_female profile, no
# overrides, and the default analysis settings (see "Advanced...").
profileChoice = 2
pitchFloorOverride = 0
pitchCeilingOverride = 0
formantCeilingOverride = 0
@resetAnalysisSettings
# Extra outputs chosen in the summary dialog (on unless switched off).
saveCsv = 1
saveSummary = 1

confirmed = 0
while not confirmed
    if inputMode = 1
        # One dialog with a list per task, or a file browser per task.
        if not oneByOne
            @fileDialog
        endif
        if oneByOne
            for s to nSlots
                if slotParent[s] = 0
                    @askSlot: s
                elsif slotPath$[slotParent[s]] <> "" or slotPath$[s] <> ""
                    @askSlot: s
                endif
            endfor
        endif
    else
        @markTasks
    endif
    @summaryDialog
    confirmed = summaryDialog.run
endwhile

# ----------------------------------------------------------------------
# SETTINGS TABLE (written to the results)
# ----------------------------------------------------------------------
p = profileChoice
useFloor = profFloor[p]
useCeiling = profCeiling[p]
useFormant = profFormant[p]
if pitchFloorOverride > 0
    useFloor = pitchFloorOverride
endif
if pitchCeilingOverride > 0
    useCeiling = pitchCeilingOverride
endif
if formantCeilingOverride > 0
    useFormant = formantCeilingOverride
endif
pitchOverridden$ = "no"
if useFloor <> profFloor[p] or useCeiling <> profCeiling[p]
    pitchOverridden$ = "yes"
endif
formantOverridden$ = "no"
if useFormant <> profFormant[p]
    formantOverridden$ = "yes"
endif

@isoNow
settingsTable = Create Table with column names: "settings", 0, "name value"
@addSettingRow: settingsTable, "schemaVersion", settingsSchemaVersion$
@addSettingRow: settingsTable, "appVersion", "guided script"
@addSettingRow: settingsTable, "createdAt", isoNow.result$
@addSettingRow: settingsTable, "speakerID", speakerID$
@addSettingRow: settingsTable, "speakerProfile", profile$[p]
@addSettingRow: settingsTable, "pitchFloorHz", string$ (useFloor)
@addSettingRow: settingsTable, "pitchCeilingHz", string$ (useCeiling)
@addSettingRow: settingsTable, "pitchOverridden", pitchOverridden$
@addSettingRow: settingsTable, "formantCeilingHz", string$ (useFormant)
@addSettingRow: settingsTable, "formantOverridden", formantOverridden$
@addSettingRow: settingsTable, "formantCount", string$ (setFormantCount)
@addSettingRow: settingsTable, "vowelWindowSec", string$ (setVowelWindowSec)
@addSettingRow: settingsTable, "vowelShortFraction", string$ (setVowelShortFraction)
@addSettingRow: settingsTable, "formantWindow", setFormantWindow$
@addSettingRow: settingsTable, "cppsMethod", setCppsMethod$
@addSettingRow: settingsTable, "cppsSpeechVoicedOnly", setCppsSpeechVoicedOnly$
@addSettingRow: settingsTable, "intensitySpeechVoicedOnly", setIntensitySpeechVoicedOnly$
@addSettingRow: settingsTable, "intensityAveraging", setIntensityAveraging$
@addSettingRow: settingsTable, "hnrMethod", setHnrMethod$
@addSettingRow: settingsTable, "periodRangeMode", setPeriodRangeMode$
@addSettingRow: settingsTable, "jitterMeasures", setJitterMeasures$
@addSettingRow: settingsTable, "shimmerMeasures", setShimmerMeasures$
@addSettingRow: settingsTable, "channelHandling", setChannelHandling$
if inputMode = 1
    @addSettingRow: settingsTable, "taskSelection", "guided"
else
    @addSettingRow: settingsTable, "taskSelection", "guided_one_recording"
endif
settingsSource$ = "dialog"

# ----------------------------------------------------------------------
# WHERE TO SAVE THE RESULTS (next to the recordings, never replacing a file)
# ----------------------------------------------------------------------
if inputMode = 2
    @baseName: longPath$
    saveFolder$ = baseName.folder$
    saveStem$ = longName$
    if rindex (saveStem$, ".") > 1
        saveStem$ = left$ (saveStem$, rindex (saveStem$, ".") - 1)
    endif
else
    saveFolder$ = recFolder$
    if oneByOne or saveFolder$ = ""
        # The folder of the first chosen recording.
        saveFolder$ = ""
        for s to nSlots
            if saveFolder$ = "" and slotPath$[s] <> ""
                @baseName: slotPath$[s]
                saveFolder$ = baseName.folder$
            endif
        endfor
    endif
    # Only letters, digits, - and _ from the patient ID go into the name.
    saveStem$ = replace_regex$ (speakerID$, "[^A-Za-z0-9_-]", "_", 0)
    if saveStem$ = ""
        saveStem$ = "voice"
    endif
endif
if saveFolder$ = ""
    saveFolder$ = defaultDirectory$
endif
saveNumber = 1
saveSuffix$ = ""
repeat
    resultsPath$ = saveFolder$ + "/" + saveStem$ + "_results" + saveSuffix$ + ".json"
    marksPath$ = saveFolder$ + "/" + saveStem$ + "_marks" + saveSuffix$ + ".TextGrid"
    csvPath$ = saveFolder$ + "/" + saveStem$ + "_results_long" + saveSuffix$ + ".csv"
    paramsCsvPath$ = saveFolder$ + "/" + saveStem$ + "_parameters" + saveSuffix$ + ".csv"
    summaryPath$ = saveFolder$ + "/" + saveStem$ + "_summary" + saveSuffix$ + ".txt"
    # All files of one run share one number, so none of them may exist yet.
    taken = fileReadable (resultsPath$) or (inputMode = 2 and fileReadable (marksPath$))
    taken = taken or fileReadable (csvPath$) or fileReadable (paramsCsvPath$) or fileReadable (summaryPath$)
    if taken
        saveNumber = saveNumber + 1
        saveSuffix$ = "_" + string$ (saveNumber)
    endif
until not taken
if inputMode = 1
    marksPath$ = ""
endif
if not saveCsv
    csvPath$ = ""
    paramsCsvPath$ = ""
endif
if not saveSummary
    summaryPath$ = ""
endif
appendInfoLine: "Results will be saved to: ", resultsPath$

# ----------------------------------------------------------------------
# READ AND CHECK SETTINGS
# ----------------------------------------------------------------------
@getText: "speakerID"
speakerID$ = getText.value$
@getChoice: "speakerProfile", "adult_male|adult_female|child|trans_woman|trans_man|other_unspecified"
speakerProfile$ = getChoice.value$
@getText: "appVersion"
appVersion$ = getText.value$

@getNumber: "pitchFloorHz"
pitchFloor = getNumber.value
@getNumber: "pitchCeilingHz"
pitchCeiling = getNumber.value
if pitchFloor <= 0 or pitchCeiling <= pitchFloor
    exitScript: "pitchFloorHz must be above 0 and below pitchCeilingHz."
endif
@getChoice: "pitchOverridden", "yes|no"

@getNumber: "formantCeilingHz"
formantCeiling = getNumber.value
if formantCeiling <= 0
    exitScript: "formantCeilingHz must be above 0."
endif
@getChoice: "formantOverridden", "yes|no"
@getNumber: "formantCount"
formantCount = getNumber.value
if formantCount < 3
    exitScript: "formantCount must be at least 3 (F1 to F3 are reported)."
endif

@getNumber: "vowelWindowSec"
vowelWindowSec = getNumber.value
if vowelWindowSec <= 0
    exitScript: "vowelWindowSec must be above 0 (default 3 = the middle 3 s of the voiced vowel)."
endif
@getNumber: "vowelShortFraction"
vowelShortFraction = getNumber.value
if vowelShortFraction <= 0 or vowelShortFraction > 1
    exitScript: "vowelShortFraction must be above 0 and at most 1 (0.5 = middle 50% of a short vowel)."
endif

@getChoice: "formantWindow", "whole_trimmed|midpoint"
formantWindow$ = getChoice.value$
@getChoice: "cppsMethod", "maryn_weenink_2015|praat_default"
cppsMethod$ = getChoice.value$
@getChoice: "cppsSpeechVoicedOnly", "yes|no"
cppsSpeechVoicedOnly$ = getChoice.value$
@getChoice: "intensitySpeechVoicedOnly", "yes|no"
intensitySpeechVoicedOnly$ = getChoice.value$
@getChoice: "intensityAveraging", "energy|dB"
intensityAveraging$ = getChoice.value$
@getChoice: "hnrMethod", "cc|ac"
hnrMethod$ = getChoice.value$
@getChoice: "periodRangeMode", "derived|fixed"
periodRangeMode$ = getChoice.value$
@getChoice: "channelHandling", "average|left"
channelHandling$ = getChoice.value$
@getList: "jitterMeasures", "local|local_absolute|rap|ppq5|ddp"
jitterMeasures$ = getList.value$
@getList: "shimmerMeasures", "local|local_db|apq3|apq5|apq11|dda"
shimmerMeasures$ = getList.value$

# Period range for jitter and shimmer.
if periodRangeMode$ = "derived"
    # Praat manual, "Voice 2. Jitter": 0.8 / pitch ceiling and 1.25 / pitch floor.
    shortestPeriod = 0.8 / pitchCeiling
    longestPeriod = 1.25 / pitchFloor
else
    shortestPeriod = fixedShortestPeriod
    longestPeriod = fixedLongestPeriod
endif

# An analysis segment must be long enough for Praat's analysis windows
# at the lowest pitch floor used (6.4 periods).
minAnalysisDuration = max (6.4 / pitchFloor, 6.4 / cppsPitchFloor)

# ----------------------------------------------------------------------
# THE RECORDINGS TO ANALYZE
# Takes are numbered within each task. /i/ and reading are never reported
# as missing.
# ----------------------------------------------------------------------
taskRequired[2] = 0
nWav = 0
nUnrecognized = 0
for s to nSlots
    if slotPath$[s] <> ""
        nWav = nWav + 1
        wavPath$[nWav] = slotPath$[s]
        @baseName: slotPath$[s]
        wavName$[nWav] = baseName.result$
        # One recording: the marked part (times in the long recording).
        # The file name shown in the results includes the times.
        wavOffset[nWav] = 0
        if inputMode = 2
            wavStart[nWav] = slotStart[s]
            wavEnd[nWav] = slotEnd[s]
            wavOffset[nWav] = slotStart[s]
            wavName$[nWav] = longName$ + ", " + fixed$ (slotStart[s], 2) + "-" + fixed$ (slotEnd[s], 2) + " s"
        endif
        wavTask$[nWav] = slotTask$[s]
        wavShort$[nWav] = slotShort$[s]
        takeCount = 0
        for f to nWav
            if wavTask$[f] = slotTask$[s]
                takeCount = takeCount + 1
            endif
        endfor
        wavTake[nWav] = takeCount
        for t to nTasks
            if task$[t] = slotTask$[s]
                taskFound[t] = 1
            endif
        endfor
    endif
endfor

appendInfoLine: "Analyzing ", nWav, " recording(s)."

# ----------------------------------------------------------------------
# ANALYZE EACH RECORDING
# ----------------------------------------------------------------------
filesJson$ = ""
# The rows of the long CSV (without the columns shared by all rows, which
# are added when the file is written), and the text summary of each file.
nCsvRows = 0
summaryFiles$ = ""
for f to nWav
    fileName$ = wavName$[f]
    currentTask$ = wavTask$[f]
    isVowel = (currentTask$ = "vowel_a" or currentTask$ = "vowel_i")
    appendInfoLine: "Analyzing ", fileName$, " (", currentTask$, ", take ", wavTake[f], ") ..."

    measures$ = ""
    measuresCount = 0
    status$ = "analyzed"
    errorReason$ = ""
    duration = undefined
    sampleRate = undefined
    channels = undefined
    analysisStart = undefined
    analysisEnd = undefined
    voicedDuration = undefined
    voicedOnset = undefined
    voicedOffset = undefined
    windowRule$ = ""

    # One recording: take the marked part (its times start at 0).
    # Separate files: try to open the file without stopping the whole
    # script if it fails.
    soundOk = 0
    if inputMode = 2
        selectObject: longSound
        original = Extract part: wavStart[f], wavEnd[f], "rectangular", 1, "no"
        soundOk = 1
    else
        selectObject: settingsTable
        nocheck Read from file: wavPath$[f]
        if startsWith (selected$ (), "Sound ")
            original = selected ("Sound")
            soundOk = 1
        endif
    endif
    if not soundOk
        status$ = "error"
        errorReason$ = "Praat could not open this file as a sound (it may be damaged or not a real WAV file)."
        appendInfoLine: "   ERROR: ", errorReason$
    else
        selectObject: original
        duration = Get total duration
        sampleRate = Get sampling frequency
        channels = Get number of channels
        if channels > 1
            selectObject: original
            if channelHandling$ = "average"
                sound = Convert to mono
            else
                sound = Extract one channel: 1
            endif
            removeObject: original
        else
            sound = original
        endif

        if isVowel
            @analyzeVowel
        else
            @analyzeSpeech
        endif
        removeObject: sound
    endif

    # Build this file's JSON entry.
    @jsonString: fileName$
    entry$ = "    {" + newline$
    entry$ = entry$ + "      ""fileName"": " + jsonString.result$ + "," + newline$
    entry$ = entry$ + "      ""task"": """ + currentTask$ + """," + newline$
    entry$ = entry$ + "      ""take"": " + string$ (wavTake[f]) + "," + newline$
    entry$ = entry$ + "      ""status"": """ + status$ + """," + newline$
    if status$ = "error"
        @jsonString: errorReason$
        entry$ = entry$ + "      ""errorReason"": " + jsonString.result$ + "," + newline$
    endif
    @jsonNumber: duration, 3
    entry$ = entry$ + "      ""durationSec"": " + jsonNumber.result$ + "," + newline$
    @jsonNumber: sampleRate, 0
    entry$ = entry$ + "      ""sampleRateHz"": " + jsonNumber.result$ + "," + newline$
    @jsonNumber: channels, 0
    entry$ = entry$ + "      ""channels"": " + jsonNumber.result$ + "," + newline$
    # Times are in the file (separate files) or in the long recording (one
    # recording: wavOffset is the start of the marked part).
    @jsonNumber: analysisStart + wavOffset[f], 3
    entry$ = entry$ + "      ""analysisStartSec"": " + jsonNumber.result$ + "," + newline$
    @jsonNumber: analysisEnd + wavOffset[f], 3
    entry$ = entry$ + "      ""analysisEndSec"": " + jsonNumber.result$ + "," + newline$
    if isVowel and status$ = "analyzed"
        @jsonNumber: voicedOnset + wavOffset[f], 3
        entry$ = entry$ + "      ""voicedOnsetSec"": " + jsonNumber.result$ + "," + newline$
        @jsonNumber: voicedOffset + wavOffset[f], 3
        entry$ = entry$ + "      ""voicedOffsetSec"": " + jsonNumber.result$ + "," + newline$
        if windowRule$ = ""
            entry$ = entry$ + "      ""analysisWindowRule"": null," + newline$
        else
            @jsonString: windowRule$
            entry$ = entry$ + "      ""analysisWindowRule"": " + jsonString.result$ + "," + newline$
        endif
    endif
    if not isVowel
        @jsonNumber: voicedDuration, 3
        entry$ = entry$ + "      ""voicedDurationSec"": " + jsonNumber.result$ + "," + newline$
    endif
    if measuresCount = 0
        entry$ = entry$ + "      ""measures"": {}" + newline$
    else
        entry$ = entry$ + "      ""measures"": {" + newline$ + measures$ + newline$ + "      }" + newline$
    endif
    entry$ = entry$ + "    }"

    if f > 1
        filesJson$ = filesJson$ + "," + newline$
    endif
    filesJson$ = filesJson$ + entry$

    # The same file as rows of the long CSV: the columns about the file,
    # then one row per measure. A file that could not be analyzed gets one
    # row without a measure, so that it is not lost from the table.
    @csvField: fileName$
    csvFile$ = csvField.result$ + "," + currentTask$ + "," + string$ (wavTake[f]) + "," + status$
    @csvNumber: duration, 3
    csvFile$ = csvFile$ + "," + csvNumber.result$
    @csvNumber: sampleRate, 0
    csvFile$ = csvFile$ + "," + csvNumber.result$
    @csvNumber: analysisStart + wavOffset[f], 3
    csvFile$ = csvFile$ + "," + csvNumber.result$
    @csvNumber: analysisEnd + wavOffset[f], 3
    csvFile$ = csvFile$ + "," + csvNumber.result$
    if isVowel
        csvFile$ = csvFile$ + ",NA"
    else
        @csvNumber: voicedDuration, 3
        csvFile$ = csvFile$ + "," + csvNumber.result$
    endif
    if measuresCount = 0
        if status$ = "error"
            @csvField: errorReason$
        else
            @csvField: "no measures"
        endif
        nCsvRows = nCsvRows + 1
        csvRow$[nCsvRows] = csvFile$ + ",NA,NA,NA," + csvField.result$
    endif
    for k to measuresCount
        @csvField: csvUnit$[k]
        csvUnitField$ = csvField.result$
        @csvField: csvReason$[k]
        nCsvRows = nCsvRows + 1
        csvRow$[nCsvRows] = csvFile$ + "," + csvKey$[k] + "," + csvValue$[k] + "," + csvUnitField$ + "," + csvField.result$
    endfor

    # The same file in the text summary.
    block$ = wavShort$[f] + newline$
    block$ = block$ + "  File: " + fileName$ + newline$
    if status$ = "error"
        block$ = block$ + "  Could not be analyzed: " + errorReason$ + newline$
    elsif isVowel
        if voicedOnset = undefined
            block$ = block$ + "  Analyzed: no voiced part was found" + newline$
        else
            ruleText$ = ""
            if windowRule$ <> ""
                ruleText$ = ", " + windowRule$
            endif
            block$ = block$ + "  Analyzed: " + fixed$ (analysisStart + wavOffset[f], 2) + " to " + fixed$ (analysisEnd + wavOffset[f], 2) + " s" + ruleText$ + newline$
        endif
    else
        voicedText$ = ""
        if voicedDuration <> undefined
            voicedText$ = "; voiced " + fixed$ (voicedDuration, 2) + " s"
        endif
        block$ = block$ + "  Analyzed: the whole " + fixed$ (duration, 2) + " s" + voicedText$ + newline$
    endif
    # If every measure is missing for the same reason, say it once.
    sameReason = measuresCount > 1
    for k to measuresCount
        if csvValue$[k] <> "NA" or csvReason$[k] <> csvReason$[1]
            sameReason = 0
        endif
    endfor
    if sameReason
        block$ = block$ + "  Not measured: " + csvReason$[1] + newline$
        measuresShown = 0
    else
        measuresShown = measuresCount
    endif
    for k to measuresShown
        @measureLabel: csvKey$[k]
        @padRight: measureLabel.result$ + " ", 28, "."
        if csvValue$[k] = "NA"
            block$ = block$ + "  " + padRight.result$ + " not measured (" + csvReason$[k] + ")" + newline$
        else
            block$ = block$ + "  " + padRight.result$ + " " + csvValue$[k] + " " + csvUnit$[k] + newline$
        endif
    endfor
    summaryFiles$ = summaryFiles$ + newline$ + block$
endfor

# ----------------------------------------------------------------------
# WRITE results.json
# ----------------------------------------------------------------------
@isoNow
runDate$ = isoNow.result$

json$ = "{" + newline$
json$ = json$ + "  ""schemaVersion"": """ + resultsSchemaVersion$ + """," + newline$
json$ = json$ + "  ""fileType"": ""cape-vr-acoustic-results""," + newline$
json$ = json$ + "  ""scriptVersion"": """ + scriptVersion$ + """," + newline$
json$ = json$ + "  ""scriptName"": ""voice_acoustics""," + newline$
@jsonString: praatVersion$
json$ = json$ + "  ""praatVersion"": " + jsonString.result$ + "," + newline$
json$ = json$ + "  ""runDate"": """ + runDate$ + """," + newline$
@jsonString: appVersion$
json$ = json$ + "  ""appVersion"": " + jsonString.result$ + "," + newline$
@jsonString: speakerID$
json$ = json$ + "  ""speakerID"": " + jsonString.result$ + "," + newline$
json$ = json$ + "  ""speakerProfile"": """ + speakerProfile$ + """," + newline$
json$ = json$ + "  ""settingsSource"": """ + settingsSource$ + """," + newline$

# Settings: every row of the settings table, as text.
json$ = json$ + "  ""settings"": {" + newline$
selectObject: settingsTable
nRows = Get number of rows
for r to nRows
    selectObject: settingsTable
    rowName$ = Get value: r, "name"
    rowValue$ = Get value: r, "value"
    @jsonString: rowName$
    rowNameJson$ = jsonString.result$
    @jsonString: rowValue$
    json$ = json$ + "    " + rowNameJson$ + ": " + jsonString.result$
    if r < nRows
        json$ = json$ + ","
    endif
    json$ = json$ + newline$
endfor
json$ = json$ + "  }," + newline$

# Analysis parameters actually used (fixed values and values worked out
# from the settings).
params$ = ""
nParams = 0
@addParamText: "pitchCommand", "To Pitch (cc)"
@addParamNumber: "pitchTimeStep", pitchTimeStep, 4
@addParamNumber: "pitchFloorHz", pitchFloor, 2
@addParamNumber: "pitchCeilingHz", pitchCeiling, 2
@addParamNumber: "pitchMaxCandidates", pitchMaxCandidates, 0
@addParamText: "pitchVeryAccurate", pitchVeryAccurate$
@addParamNumber: "pitchSilenceThreshold", pitchSilenceThreshold, 3
@addParamNumber: "pitchVoicingThreshold", pitchVoicingThreshold, 3
@addParamNumber: "pitchOctaveCost", pitchOctaveCost, 3
@addParamNumber: "pitchOctaveJumpCost", pitchOctaveJumpCost, 3
@addParamNumber: "pitchVoicedUnvoicedCost", pitchVoicedUnvoicedCost, 3
@addParamNumber: "vuvMaxPeriodSec", vuvMaxPeriod, 4
@addParamNumber: "vuvMeanPeriodSec", vuvMeanPeriod, 4
@addParamNumber: "intensityMinimumPitchHz", pitchFloor, 2
@addParamNumber: "intensityTimeStep", intensityTimeStep, 4
@addParamText: "intensitySubtractMean", intensitySubtractMean$
@addParamText: "intensityAveraging", intensityAveraging$
@addParamNumber: "cepstrogramPitchFloorHz", cppsPitchFloor, 1
@addParamNumber: "cepstrogramTimeStepSec", cppsTimeStep, 4
@addParamNumber: "cepstrogramMaxFrequencyHz", cppsMaxFrequency, 0
@addParamNumber: "cepstrogramPreEmphasisHz", cppsPreEmphasis, 0
@addParamText: "cppsMethod", cppsMethod$
if cppsMethod$ = "maryn_weenink_2015"
    @addParamText: "cppsHighPassFilter", "Filter (stop Hann band) 0-" + fixed$ (mwHighPassHz, 0) + " Hz, smoothing " + fixed$ (mwHighPassSmoothing, 1) + " Hz"
    @addParamText: "cppsSubtractTrendBeforeSmoothing", mwSubtractTrend$
    @addParamNumber: "cppsTimeAveragingSec", mwTimeAveraging, 4
    @addParamNumber: "cppsQuefrencyAveragingSec", mwQuefrencyAveraging, 4
    @addParamNumber: "cppsPeakSearchMinHz", mwPeakMinHz, 0
    @addParamNumber: "cppsPeakSearchMaxHz", mwPeakMaxHz, 0
    @addParamNumber: "cppsTolerance", mwTolerance, 3
    @addParamText: "cppsInterpolation", mwInterpolation$
    @addParamNumber: "cppsTrendFromSec", mwTrendFrom, 4
    @addParamNumber: "cppsTrendToSec", mwTrendTo, 4
    @addParamText: "cppsTrendType", mwTrendType$
    @addParamText: "cppsFitMethod", mwFitMethod$
else
    @addParamText: "cppsHighPassFilter", "none"
    @addParamText: "cppsSubtractTrendBeforeSmoothing", pdSubtractTrend$
    @addParamNumber: "cppsTimeAveragingSec", pdTimeAveraging, 4
    @addParamNumber: "cppsQuefrencyAveragingSec", pdQuefrencyAveraging, 4
    @addParamNumber: "cppsPeakSearchMinHz", pdPeakMinHz, 0
    @addParamNumber: "cppsPeakSearchMaxHz", pdPeakMaxHz, 0
    @addParamNumber: "cppsTolerance", pdTolerance, 3
    @addParamText: "cppsInterpolation", pdInterpolation$
    @addParamNumber: "cppsTrendFromSec", pdTrendFrom, 4
    @addParamNumber: "cppsTrendToSec", pdTrendTo, 4
    @addParamText: "cppsTrendType", pdTrendType$
    @addParamText: "cppsFitMethod", pdFitMethod$
endif
@addParamText: "hnrMethod", hnrMethod$
@addParamNumber: "hnrTimeStepSec", hnrTimeStep, 4
@addParamNumber: "hnrMinimumPitchHz", pitchFloor, 2
@addParamNumber: "hnrSilenceThreshold", hnrSilenceThreshold, 3
if hnrMethod$ = "cc"
    @addParamNumber: "hnrPeriodsPerWindow", hnrPeriodsPerWindowCc, 2
else
    @addParamNumber: "hnrPeriodsPerWindow", hnrPeriodsPerWindowAc, 2
endif
@addParamText: "periodRangeMode", periodRangeMode$
@addParamNumber: "shortestPeriodSec", shortestPeriod, 6
@addParamNumber: "longestPeriodSec", longestPeriod, 6
@addParamNumber: "maximumPeriodFactor", maxPeriodFactor, 2
@addParamNumber: "maximumAmplitudeFactor", maxAmplitudeFactor, 2
@addParamNumber: "formantTimeStep", formantTimeStep, 4
@addParamNumber: "formantCount", formantCount, 1
@addParamNumber: "formantCeilingHz", formantCeiling, 0
@addParamNumber: "formantWindowLengthSec", formantWindowLength, 4
@addParamNumber: "formantPreEmphasisHz", formantPreEmphasis, 0
@addParamNumber: "vowelWindowSec", vowelWindowSec, 3
@addParamNumber: "vowelShortFraction", vowelShortFraction, 3
@addParamNumber: "vowelGapWarningSec", vowelGapWarningSec, 3
@addParamNumber: "minAnalysisDurationSec", minAnalysisDuration, 3
json$ = json$ + "  ""analysisParameters"": {" + newline$ + params$ + newline$ + "  }," + newline$

if nWav = 0
    json$ = json$ + "  ""files"": []," + newline$
else
    json$ = json$ + "  ""files"": [" + newline$ + filesJson$ + newline$ + "  ]," + newline$
endif

if nUnrecognized = 0
    json$ = json$ + "  ""unrecognizedFiles"": []," + newline$
else
    json$ = json$ + "  ""unrecognizedFiles"": [" + newline$
    for u to nUnrecognized
        @jsonString: unrecName$[u]
        uName$ = jsonString.result$
        @jsonString: unrecReason$[u]
        json$ = json$ + "    { ""fileName"": " + uName$ + ", ""reason"": " + jsonString.result$ + " }"
        if u < nUnrecognized
            json$ = json$ + ","
        endif
        json$ = json$ + newline$
    endfor
    json$ = json$ + "  ]," + newline$
endif

# Missing required tasks
missing$ = ""
nMissing = 0
for t to nTasks
    if taskRequired[t] and taskFound[t] = 0
        if nMissing > 0
            missing$ = missing$ + ", "
        endif
        missing$ = missing$ + """" + task$[t] + """"
        nMissing = nMissing + 1
    endif
endfor
json$ = json$ + "  ""missingTasks"": [" + missing$ + "]," + newline$

if nWarnings = 0
    json$ = json$ + "  ""warnings"": []" + newline$
else
    json$ = json$ + "  ""warnings"": [" + newline$
    for w to nWarnings
        @jsonString: warning$[w]
        json$ = json$ + "    " + jsonString.result$
        if w < nWarnings
            json$ = json$ + ","
        endif
        json$ = json$ + newline$
    endfor
    json$ = json$ + "  ]" + newline$
endif
json$ = json$ + "}"

# All text is escaped to plain ASCII by @jsonString, so the file is valid
# UTF-8 whatever Praat's text-writing preference is.
writeFileLine: resultsPath$, json$

# ----------------------------------------------------------------------
# WRITE THE LONG CSV AND THE PARAMETERS CSV (optional)
# Same values and rounding as results.json. Written as UTF-8 without a
# byte-order mark (plain ASCII unless a name has other characters), which
# R, Python and SPSS read directly. Excel: use Data > From Text/CSV if
# accented names look wrong.
# ----------------------------------------------------------------------
if csvPath$ <> ""
    @csvField: speakerID$
    csvShared$ = csvField.result$ + "," + speakerProfile$ + "," + fixed$ (pitchFloor, 2) + "," + fixed$ (pitchCeiling, 2) + "," + fixed$ (formantCeiling, 0) + "," + cppsMethod$ + "," + runDate$ + "," + scriptVersion$
    @csvField: praatVersion$
    csvShared$ = csvShared$ + "," + csvField.result$
    csv$ = "speakerID,speakerProfile,pitchFloorHz,pitchCeilingHz,formantCeilingHz,cppsMethod,runDate,scriptVersion,praatVersion,"
    csv$ = csv$ + "fileName,task,take,status,durationSec,sampleRateHz,analysisStartSec,analysisEndSec,voicedDurationSec,"
    csv$ = csv$ + "measure,value,unit,missingReason"
    for r to nCsvRows
        csv$ = csv$ + newline$ + csvShared$ + "," + csvRow$[r]
    endfor
    writeFileLine: csvPath$, csv$

    pcsv$ = "section,name,value"
    selectObject: settingsTable
    nRows = Get number of rows
    for r to nRows
        selectObject: settingsTable
        rowName$ = Get value: r, "name"
        rowValue$ = Get value: r, "value"
        @csvField: rowValue$
        pcsv$ = pcsv$ + newline$ + "settings," + rowName$ + "," + csvField.result$
    endfor
    for r to nParams
        @csvField: paramCsvValue$[r]
        pcsv$ = pcsv$ + newline$ + "analysisParameters," + paramCsvName$[r] + "," + csvField.result$
    endfor
    writeFileLine: paramsCsvPath$, pcsv$
endif
removeObject: settingsTable

# ----------------------------------------------------------------------
# WRITE THE TEXT SUMMARY (optional), also shown in the Info window
# ----------------------------------------------------------------------
if summaryPath$ <> ""
    summary$ = "CLINICAL VOICE SNAPSHOT" + newline$
    if speakerID$ = ""
        summary$ = summary$ + "Patient ID: (none)" + newline$
    else
        summary$ = summary$ + "Patient ID: " + speakerID$ + newline$
    endif
    summary$ = summary$ + "Date: " + replace$ (runDate$, "T", " ", 1) + newline$
    summary$ = summary$ + "Speaker profile: " + speakerProfile$ + " (pitch " + fixed$ (pitchFloor, 0) + "-" + fixed$ (pitchCeiling, 0) + " Hz, formant ceiling " + fixed$ (formantCeiling, 0) + " Hz"
    if pitchOverridden$ = "yes" or formantOverridden$ = "yes"
        summary$ = summary$ + ", changed from the profile defaults"
    endif
    summary$ = summary$ + ")" + newline$
    summary$ = summary$ + "Analysis: Praat " + praatVersion$ + ", voice_acoustics " + scriptVersion$ + ", CPPS method " + cppsMethod$ + newline$
    if nWav = 0
        summary$ = summary$ + newline$ + "No recordings were analyzed." + newline$
    else
        summary$ = summary$ + summaryFiles$
    endif
    if nMissing > 0
        # The names shown in the dialogs (the first take of each task).
        missingText$ = ""
        for t to nTasks
            if taskRequired[t] and taskFound[t] = 0
                missingName$ = task$[t]
                for s to nSlots
                    if slotTask$[s] = task$[t] and slotParent[s] = 0
                        missingName$ = slotShort$[s]
                    endif
                endfor
                if missingText$ <> ""
                    missingText$ = missingText$ + ", "
                endif
                missingText$ = missingText$ + missingName$
            endif
        endfor
        summary$ = summary$ + newline$ + "Tasks not recorded: " + missingText$ + newline$
    endif
    if nUnrecognized > 0
        summary$ = summary$ + newline$ + "Files not used:" + newline$
        for u to nUnrecognized
            summary$ = summary$ + "  " + unrecName$[u] + ": " + unrecReason$[u] + newline$
        endfor
    endif
    if nWarnings > 0
        summary$ = summary$ + newline$ + "Notes:" + newline$
        for w to nWarnings
            summary$ = summary$ + "  - " + warning$[w] + newline$
        endfor
    endif
    summary$ = summary$ + newline$ + "Intensity is relative (uncalibrated) dB, not dB SPL. Each take is reported" + newline$
    summary$ = summary$ + "separately; nothing is averaged across takes."
    writeFileLine: summaryPath$, summary$
endif

# One recording: save the marks next to results.json, then close the sound
# window (removing the objects closes it).
if inputMode = 2
    selectObject: marksGrid
    nocheck Save as text file: marksPath$
    removeObject: longSound, marksGrid
    longSound = 0
    marksGrid = 0
endif

appendInfoLine: ""
appendInfoLine: "Done. results.json written to: ", resultsPath$
if marksPath$ <> ""
    appendInfoLine: "The marks were saved to: ", marksPath$
endif
if csvPath$ <> ""
    appendInfoLine: "Spreadsheet (long format) saved to: ", csvPath$
    appendInfoLine: "Settings and parameters saved to: ", paramsCsvPath$
endif
if summaryPath$ <> ""
    appendInfoLine: "Text summary saved to: ", summaryPath$
endif
appendInfoLine: "Files analyzed: ", nWav, "; unrecognized: ", nUnrecognized, "; missing tasks: ", nMissing, "; warnings: ", nWarnings
for w to nWarnings
    appendInfoLine: "WARNING: ", warning$[w]
endfor
if summaryPath$ <> ""
    appendInfoLine: ""
    appendInfoLine: "----- Summary (can be copied from here) -----"
    appendInfoLine: summary$
endif

beginPause: "Analysis finished"
    @baseName: resultsPath$
    resultsFile$ = baseName.result$
    resultsFolder$ = baseName.folder$
    comment: "Done. The results were saved as:"
    @wrapComment: resultsFile$
    comment: "in the same folder as the recordings:"
    @wrapComment: resultsFolder$
    comment: ""
    comment: "Upload this file on the rating web page (Upload results.json)."
    if marksPath$ <> ""
        @baseName: marksPath$
        @wrapComment: "The marked tasks were saved next to it, as " + baseName.result$ + " (you can open it in Praat)."
    endif
    if csvPath$ <> ""
        @baseName: csvPath$
        doneCsvName$ = baseName.result$
        @baseName: paramsCsvPath$
        @wrapComment: "Spreadsheet for research: " + doneCsvName$ + " (one row per measure), with the settings in " + baseName.result$ + "."
    endif
    if summaryPath$ <> ""
        @baseName: summaryPath$
        @wrapComment: "Text summary to read or paste into a report: " + baseName.result$ + " (also in the Praat Info window)."
    endif
    if nWarnings > 0
        @wrapComment: string$ (nWarnings) + " note(s) about the recordings are in the Praat Info window and in the results."
    endif
endPause: "OK", 1

# ======================================================================
# ANALYSIS PROCEDURES
# They use the global variables sound, duration, sampleRate, and the settings.
# ======================================================================

# --- Vowels: all vowel measures on the middle of the voiced part -------
# Where the vowel starts and ends is found with Praat's voicing detection,
# so silence or noise before or after the vowel is ignored.
#   - Voiced part at least vowelWindowSec long (default 3 s): analyze the
#     middle vowelWindowSec of it. This skips the voice onset and offset,
#     whose irregular first and last cycles would bias jitter, shimmer, HNR,
#     and CPPS.
#   - Voiced part shorter: analyze the middle vowelShortFraction (default
#     50%) of it, and add a warning.
procedure analyzeVowel
    # 1. Find the voiced part of the whole file.
    selectObject: sound
    .fullPitch = To Pitch (cc): pitchTimeStep, pitchFloor, pitchMaxCandidates, pitchVeryAccurate$, pitchSilenceThreshold, pitchVoicingThreshold, pitchOctaveCost, pitchOctaveJumpCost, pitchVoicedUnvoicedCost, pitchCeiling
    selectObject: sound, .fullPitch
    .fullPulses = To PointProcess (cc)
    .grid = To TextGrid (vuv): vuvMaxPeriod, vuvMeanPeriod
    removeObject: .fullPitch, .fullPulses
    @voicedSpan: .grid
    if voicedSpan.found = 0
        removeObject: .grid
        @nullVowelMeasures: "no voicing was found in this file"
    else
        voicedOnset = voicedSpan.onset
        voicedOffset = voicedSpan.offset
        .span = voicedOffset - voicedOnset

        # 2. Choose the analysis window inside the voiced part.
        if .span >= vowelWindowSec
            .mid = (voicedOnset + voicedOffset) / 2
            .start = .mid - vowelWindowSec / 2
            .end = .mid + vowelWindowSec / 2
            windowRule$ = "middle " + fixed$ (vowelWindowSec, 1) + " s of the voiced part"
        else
            .trim = .span * (1 - vowelShortFraction) / 2
            .start = voicedOnset + .trim
            .end = voicedOffset - .trim
            windowRule$ = "middle " + fixed$ (vowelShortFraction * 100, 0) + "% of the voiced part (voiced part shorter than " + fixed$ (vowelWindowSec, 1) + " s)"
            @addWarning: fileName$ + ": the voiced part of the vowel is only " + fixed$ (.span, 3) + " s long (less than " + fixed$ (vowelWindowSec, 3) + " s), so the middle " + fixed$ (vowelShortFraction * 100, 0) + "% of it was analyzed."
        endif

        # 3. Warn about long unvoiced stretches inside the window
        #    (voice breaks, or a cough or noise detected as voicing).
        @longestUnvoicedGap: .grid, .start, .end
        if longestUnvoicedGap.gap >= vowelGapWarningSec
            @addWarning: fileName$ + ": the analysis window (" + fixed$ (.start, 2) + "-" + fixed$ (.end, 2) + " s) contains an unvoiced stretch of " + fixed$ (longestUnvoicedGap.gap, 2) + " s. Please check the recording in Praat (voice break, or a cough or noise detected as voicing?)."
        endif
        removeObject: .grid
        @measureVowelWindow: .start, .end
    endif
endproc

# The first voiced moment and the last voiced moment in a vuv TextGrid.
procedure voicedSpan: .grid
    selectObject: .grid
    .n = Get number of intervals: 1
    .found = 0
    .onset = undefined
    .offset = undefined
    for .k to .n
        .label$ = Get label of interval: 1, .k
        if .label$ = "V"
            if .found = 0
                .onset = Get start time of interval: 1, .k
            endif
            .offset = Get end time of interval: 1, .k
            .found = 1
        endif
    endfor
endproc

# The longest unvoiced stretch that lies inside [.from, .to].
procedure longestUnvoicedGap: .grid, .from, .to
    selectObject: .grid
    .n = Get number of intervals: 1
    .gap = 0
    for .k to .n
        .label$ = Get label of interval: 1, .k
        if .label$ <> "V"
            .t1 = Get start time of interval: 1, .k
            .t2 = Get end time of interval: 1, .k
            .overlap = min (.t2, .to) - max (.t1, .from)
            if .overlap > .gap
                .gap = .overlap
            endif
        endif
    endfor
endproc

# Measure everything on the vowel between .start and .end.
procedure measureVowelWindow: .start, .end
    analysisStart = .start
    analysisEnd = .end
    .segDur = .end - .start
    if .segDur < minAnalysisDuration
        .reason$ = "analysis segment (" + fixed$ (.segDur, 3) + " s) is shorter than the " + fixed$ (minAnalysisDuration, 3) + " s minimum"
        @nullVowelMeasures: .reason$
    else
        selectObject: sound
        .seg = Extract part: .start, .end, "rectangular", 1, "no"
        .pitch = To Pitch (cc): pitchTimeStep, pitchFloor, pitchMaxCandidates, pitchVeryAccurate$, pitchSilenceThreshold, pitchVoicingThreshold, pitchOctaveCost, pitchOctaveJumpCost, pitchVoicedUnvoicedCost, pitchCeiling
        @measureF0: .pitch
        @measureIntensity: .seg, ""
        @measureCpps: .seg, ""
        @measureHnr: .seg
        selectObject: .seg, .pitch
        .pulses = To PointProcess (cc)
        @measureJitter: .pulses
        @measureShimmer: .seg, .pulses
        @measureFormants: .seg, .segDur
        removeObject: .seg, .pitch, .pulses
    endif
endproc

# --- Sentences, extemporaneous speech, reading -------------------------
procedure analyzeSpeech
    analysisStart = 0
    analysisEnd = duration
    if duration < minAnalysisDuration
        .reason$ = "file (" + fixed$ (duration, 3) + " s) is shorter than the " + fixed$ (minAnalysisDuration, 3) + " s minimum"
        @addMeasure: "f0Mean", undefined, 2, "Hz", .reason$
        @addMeasure: "f0SD", undefined, 2, "Hz", .reason$
        @addMeasure: "intensityMean", undefined, 2, "dB (uncalibrated)", .reason$
        @addMeasure: "cpps", undefined, 2, "dB", .reason$
    else
        selectObject: sound
        .pitch = To Pitch (cc): pitchTimeStep, pitchFloor, pitchMaxCandidates, pitchVeryAccurate$, pitchSilenceThreshold, pitchVoicingThreshold, pitchOctaveCost, pitchOctaveJumpCost, pitchVoicedUnvoicedCost, pitchCeiling
        @measureF0: .pitch
        selectObject: sound, .pitch
        .pulses = To PointProcess (cc)
        @extractVoiced: .pulses
        .voiced = extractVoiced.sound
        voicedDuration = extractVoiced.duration

        if intensitySpeechVoicedOnly$ = "yes"
            @measureIntensity: .voiced, "no voiced segments found"
        else
            @measureIntensity: sound, ""
        endif
        if cppsSpeechVoicedOnly$ = "yes"
            @measureCpps: .voiced, "no voiced segments found"
        else
            @measureCpps: sound, ""
        endif

        removeObject: .pitch, .pulses
        if .voiced <> 0
            removeObject: .voiced
        endif
    endif
endproc

# --- Voiced parts joined into one sound (0 if there are none) ---------
procedure extractVoiced: .pulses
    .sound = 0
    .duration = 0
    selectObject: .pulses
    .grid = To TextGrid (vuv): vuvMaxPeriod, vuvMeanPeriod
    .nIntervals = Get number of intervals: 1
    .nParts = 0
    for .k to .nIntervals
        selectObject: .grid
        .label$ = Get label of interval: 1, .k
        if .label$ = "V"
            .t1 = Get start time of interval: 1, .k
            .t2 = Get end time of interval: 1, .k
            selectObject: sound
            .nParts = .nParts + 1
            .part[.nParts] = Extract part: .t1, .t2, "rectangular", 1, "no"
            .duration = .duration + (.t2 - .t1)
        endif
    endfor
    removeObject: .grid
    if .nParts > 0
        selectObject: .part[1]
        if .nParts = 1
            .sound = Copy: "voiced"
        else
            for .k from 2 to .nParts
                plusObject: .part[.k]
            endfor
            .sound = Concatenate
        endif
        for .k to .nParts
            removeObject: .part[.k]
        endfor
    endif
endproc

# --- F0 mean and SD over voiced frames ---------------------------------
procedure measureF0: .pitch
    selectObject: .pitch
    .nVoiced = Count voiced frames
    if .nVoiced = 0
        @addMeasure: "f0Mean", undefined, 2, "Hz", "no voiced frames found"
        @addMeasure: "f0SD", undefined, 2, "Hz", "no voiced frames found"
    else
        .mean = Get mean: 0, 0, "Hertz"
        .sd = Get standard deviation: 0, 0, "Hertz"
        @addMeasure: "f0Mean", .mean, 2, "Hz", ""
        @addMeasure: "f0SD", .sd, 2, "Hz", "fewer than 2 voiced frames"
    endif
endproc

# --- Mean intensity, uncalibrated dB ------------------------------------
procedure measureIntensity: .snd, .missingReason$
    .unit$ = "dB (uncalibrated)"
    if .snd = 0
        @addMeasure: "intensityMean", undefined, 2, .unit$, .missingReason$
    else
        selectObject: .snd
        .dur = Get total duration
        if .dur < minAnalysisDuration
            @addMeasure: "intensityMean", undefined, 2, .unit$, "sound analyzed (" + fixed$ (.dur, 3) + " s) is shorter than the " + fixed$ (minAnalysisDuration, 3) + " s minimum"
        else
            .int = To Intensity: pitchFloor, intensityTimeStep, intensitySubtractMean$
            .mean = Get mean: 0, 0, intensityAveraging$
            removeObject: .int
            @addMeasure: "intensityMean", .mean, 2, .unit$, ""
        endif
    endif
endproc

# --- CPPS ---------------------------------------------------------------
procedure measureCpps: .snd, .missingReason$
    if .snd = 0
        @addMeasure: "cpps", undefined, 2, "dB", .missingReason$
    elsif sampleRate < cppsMinSampleRate
        @addMeasure: "cpps", undefined, 2, "dB", "sample rate " + fixed$ (sampleRate, 0) + " Hz is below the " + fixed$ (cppsMinSampleRate, 0) + " Hz needed for CPPS"
    else
        selectObject: .snd
        .dur = Get total duration
        if .dur < minAnalysisDuration
            @addMeasure: "cpps", undefined, 2, "dB", "sound analyzed (" + fixed$ (.dur, 3) + " s) is shorter than the " + fixed$ (minAnalysisDuration, 3) + " s minimum"
        else
            if cppsMethod$ = "maryn_weenink_2015"
                # As in the AVQI v02.02 script: high-pass filter first
                # (removes 0-34 Hz), then the cepstrogram. CPPS only.
                .filtered = Filter (stop Hann band): 0, mwHighPassHz, mwHighPassSmoothing
                .cep = To PowerCepstrogram: cppsPitchFloor, cppsTimeStep, cppsMaxFrequency, cppsPreEmphasis
                .v = Get CPPS: mwSubtractTrend$, mwTimeAveraging, mwQuefrencyAveraging, mwPeakMinHz, mwPeakMaxHz, mwTolerance, mwInterpolation$, mwTrendFrom, mwTrendTo, mwTrendType$, mwFitMethod$
                removeObject: .filtered
            else
                .cep = To PowerCepstrogram: cppsPitchFloor, cppsTimeStep, cppsMaxFrequency, cppsPreEmphasis
                .v = Get CPPS: pdSubtractTrend$, pdTimeAveraging, pdQuefrencyAveraging, pdPeakMinHz, pdPeakMaxHz, pdTolerance, pdInterpolation$, pdTrendFrom, pdTrendTo, pdTrendType$, pdFitMethod$
            endif
            removeObject: .cep
            @addMeasure: "cpps", .v, 2, "dB", ""
        endif
    endif
endproc

# --- HNR (vowels) ---------------------------------------------------------
procedure measureHnr: .seg
    selectObject: .seg
    if hnrMethod$ = "cc"
        .h = To Harmonicity (cc): hnrTimeStep, pitchFloor, hnrSilenceThreshold, hnrPeriodsPerWindowCc
    else
        .h = To Harmonicity (ac): hnrTimeStep, pitchFloor, hnrSilenceThreshold, hnrPeriodsPerWindowAc
    endif
    .v = Get mean: 0, 0
    removeObject: .h
    @addMeasure: "hnr", .v, 2, "dB", ""
endproc

# --- Jitter (vowels) ------------------------------------------------------
procedure measureJitter: .pulses
    .why$ = "Praat returned undefined (too few usable periods)"
    .list$ = "," + jitterMeasures$ + ","
    if index (.list$, ",local,") > 0
        selectObject: .pulses
        .v = Get jitter (local): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor
        @addMeasure: "jitterLocal", .v * 100, 3, "%", .why$
    endif
    if index (.list$, ",local_absolute,") > 0
        selectObject: .pulses
        .v = Get jitter (local, absolute): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor
        @addMeasure: "jitterLocalAbsolute", .v, 8, "s", .why$
    endif
    if index (.list$, ",rap,") > 0
        selectObject: .pulses
        .v = Get jitter (rap): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor
        @addMeasure: "jitterRap", .v * 100, 3, "%", .why$
    endif
    if index (.list$, ",ppq5,") > 0
        selectObject: .pulses
        .v = Get jitter (ppq5): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor
        @addMeasure: "jitterPpq5", .v * 100, 3, "%", .why$
    endif
    if index (.list$, ",ddp,") > 0
        selectObject: .pulses
        .v = Get jitter (ddp): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor
        @addMeasure: "jitterDdp", .v * 100, 3, "%", .why$
    endif
endproc

# --- Shimmer (vowels) -----------------------------------------------------
procedure measureShimmer: .seg, .pulses
    .why$ = "Praat returned undefined (too few usable periods)"
    .list$ = "," + shimmerMeasures$ + ","
    if index (.list$, ",local,") > 0
        selectObject: .seg, .pulses
        .v = Get shimmer (local): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor, maxAmplitudeFactor
        @addMeasure: "shimmerLocal", .v * 100, 3, "%", .why$
    endif
    if index (.list$, ",local_db,") > 0
        selectObject: .seg, .pulses
        .v = Get shimmer (local_dB): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor, maxAmplitudeFactor
        @addMeasure: "shimmerLocalDb", .v, 3, "dB", .why$
    endif
    if index (.list$, ",apq3,") > 0
        selectObject: .seg, .pulses
        .v = Get shimmer (apq3): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor, maxAmplitudeFactor
        @addMeasure: "shimmerApq3", .v * 100, 3, "%", .why$
    endif
    if index (.list$, ",apq5,") > 0
        selectObject: .seg, .pulses
        .v = Get shimmer (apq5): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor, maxAmplitudeFactor
        @addMeasure: "shimmerApq5", .v * 100, 3, "%", .why$
    endif
    if index (.list$, ",apq11,") > 0
        selectObject: .seg, .pulses
        .v = Get shimmer (apq11): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor, maxAmplitudeFactor
        @addMeasure: "shimmerApq11", .v * 100, 3, "%", .why$
    endif
    if index (.list$, ",dda,") > 0
        selectObject: .seg, .pulses
        .v = Get shimmer (dda): 0, 0, shortestPeriod, longestPeriod, maxPeriodFactor, maxAmplitudeFactor
        @addMeasure: "shimmerDda", .v * 100, 3, "%", .why$
    endif
endproc

# --- Formants F1-F3 (vowels) ---------------------------------------------
procedure measureFormants: .seg, .segDur
    if sampleRate < 2 * formantCeiling
        @nullFormants: "sample rate " + fixed$ (sampleRate, 0) + " Hz is too low: formants need at least " + fixed$ (2 * formantCeiling, 0) + " Hz (twice the " + fixed$ (formantCeiling, 0) + " Hz formant ceiling)"
    else
        selectObject: .seg
        .fm = To Formant (burg): formantTimeStep, formantCount, formantCeiling, formantWindowLength, formantPreEmphasis
        for .n to 3
            .f$ = "f" + string$ (.n)
            selectObject: .fm
            if formantWindow$ = "whole_trimmed"
                .mean = Get mean: .n, 0, 0, "hertz"
                .median = Get quantile: .n, 0, 0, "hertz", 0.5
                .sd = Get standard deviation: .n, 0, 0, "hertz"
                @addMeasure: .f$ + "Mean", .mean, 2, "Hz", ""
                @addMeasure: .f$ + "Median", .median, 2, "Hz", ""
                @addMeasure: .f$ + "SD", .sd, 2, "Hz", ""
            else
                .v = Get value at time: .n, .segDur / 2, "hertz", "linear"
                @addMeasure: .f$ + "Midpoint", .v, 2, "Hz", ""
            endif
        endfor
        removeObject: .fm
    endif
endproc

procedure nullFormants: .reason$
    for .n to 3
        .f$ = "f" + string$ (.n)
        if formantWindow$ = "whole_trimmed"
            @addMeasure: .f$ + "Mean", undefined, 2, "Hz", .reason$
            @addMeasure: .f$ + "Median", undefined, 2, "Hz", .reason$
            @addMeasure: .f$ + "SD", undefined, 2, "Hz", .reason$
        else
            @addMeasure: .f$ + "Midpoint", undefined, 2, "Hz", .reason$
        endif
    endfor
endproc

# --- All vowel measures as null (no voicing, or segment too short) -----
procedure nullVowelMeasures: .reason$
    @addMeasure: "f0Mean", undefined, 2, "Hz", .reason$
    @addMeasure: "f0SD", undefined, 2, "Hz", .reason$
    @addMeasure: "intensityMean", undefined, 2, "dB (uncalibrated)", .reason$
    @addMeasure: "cpps", undefined, 2, "dB", .reason$
    @addMeasure: "hnr", undefined, 2, "dB", .reason$
    .j$ = "," + jitterMeasures$ + ","
    if index (.j$, ",local,") > 0
        @addMeasure: "jitterLocal", undefined, 3, "%", .reason$
    endif
    if index (.j$, ",local_absolute,") > 0
        @addMeasure: "jitterLocalAbsolute", undefined, 8, "s", .reason$
    endif
    if index (.j$, ",rap,") > 0
        @addMeasure: "jitterRap", undefined, 3, "%", .reason$
    endif
    if index (.j$, ",ppq5,") > 0
        @addMeasure: "jitterPpq5", undefined, 3, "%", .reason$
    endif
    if index (.j$, ",ddp,") > 0
        @addMeasure: "jitterDdp", undefined, 3, "%", .reason$
    endif
    .s$ = "," + shimmerMeasures$ + ","
    if index (.s$, ",local,") > 0
        @addMeasure: "shimmerLocal", undefined, 3, "%", .reason$
    endif
    if index (.s$, ",local_db,") > 0
        @addMeasure: "shimmerLocalDb", undefined, 3, "dB", .reason$
    endif
    if index (.s$, ",apq3,") > 0
        @addMeasure: "shimmerApq3", undefined, 3, "%", .reason$
    endif
    if index (.s$, ",apq5,") > 0
        @addMeasure: "shimmerApq5", undefined, 3, "%", .reason$
    endif
    if index (.s$, ",apq11,") > 0
        @addMeasure: "shimmerApq11", undefined, 3, "%", .reason$
    endif
    if index (.s$, ",dda,") > 0
        @addMeasure: "shimmerDda", undefined, 3, "%", .reason$
    endif
    @nullFormants: .reason$
endproc

# ======================================================================
# HELPER PROCEDURES
# ======================================================================

# Add one measure to the current file's "measures" object.
# If .value is undefined, it is written as null with .reason$ (or a
# generic reason if .reason$ is empty).
procedure addMeasure: .key$, .value, .decimals, .unit$, .reason$
    @jsonString: .unit$
    .unitJson$ = jsonString.result$
    if .value = undefined
        if .reason$ = ""
            .reason$ = "Praat returned undefined"
        endif
        @jsonString: .reason$
        .entry$ = "{ ""value"": null, ""unit"": " + .unitJson$ + ", ""reason"": " + jsonString.result$ + " }"
    else
        .entry$ = "{ ""value"": " + fixed$ (.value, .decimals) + ", ""unit"": " + .unitJson$ + ", ""reason"": null }"
    endif
    if measuresCount > 0
        measures$ = measures$ + "," + newline$
    endif
    measures$ = measures$ + "        """ + .key$ + """: " + .entry$
    measuresCount = measuresCount + 1
    # The same measure for the CSV and the text summary (same rounding).
    csvKey$[measuresCount] = .key$
    csvUnit$[measuresCount] = .unit$
    if .value = undefined
        csvValue$[measuresCount] = "NA"
        csvReason$[measuresCount] = .reason$
    else
        csvValue$[measuresCount] = fixed$ (.value, .decimals)
        csvReason$[measuresCount] = ""
    endif
endproc

procedure addParamNumber: .name$, .value, .decimals
    @jsonNumber: .value, .decimals
    @addParamRaw: .name$, jsonNumber.result$
    @csvNumber: .value, .decimals
    paramCsvValue$[nParams] = csvNumber.result$
endproc

procedure addParamText: .name$, .value$
    @jsonString: .value$
    @addParamRaw: .name$, jsonString.result$
    paramCsvValue$[nParams] = .value$
endproc

procedure addParamRaw: .name$, .json$
    if nParams > 0
        params$ = params$ + "," + newline$
    endif
    params$ = params$ + "    """ + .name$ + """: " + .json$
    nParams = nParams + 1
    paramCsvName$[nParams] = .name$
endproc

# A number as CSV text, or NA if undefined.
procedure csvNumber: .value, .decimals
    if .value = undefined
        .result$ = "NA"
    else
        .result$ = fixed$ (.value, .decimals)
    endif
endproc

# A text as one CSV field (RFC 4180): in quotes, with quotes doubled, if it
# contains a comma, a quote, or a line break; otherwise as it is.
procedure csvField: .s$
    if index (.s$, ",") > 0 or index (.s$, """") > 0 or index (.s$, newline$) > 0 or index (.s$, tab$) > 0
        .result$ = """" + replace$ (.s$, """", """""", 0) + """"
    else
        .result$ = .s$
    endif
endproc

# A text padded on the right with .fill$ to .width characters (for the
# columns of the text summary). Longer texts are left as they are.
procedure padRight: .s$, .width, .fill$
    .result$ = .s$
    while length (.result$) < .width
        .result$ = .result$ + .fill$
    endwhile
endproc

# The name of a measure as shown in the text summary.
procedure measureLabel: .key$
    .result$ = .key$
    if .key$ = "f0Mean"
        .result$ = "F0 mean"
    elsif .key$ = "f0SD"
        .result$ = "F0 SD"
    elsif .key$ = "intensityMean"
        .result$ = "Intensity mean (relative)"
    elsif .key$ = "cpps"
        .result$ = "CPPS"
    elsif .key$ = "hnr"
        .result$ = "HNR"
    elsif .key$ = "jitterLocal"
        .result$ = "Jitter (local)"
    elsif .key$ = "jitterLocalAbsolute"
        .result$ = "Jitter (local, absolute)"
    elsif .key$ = "jitterRap"
        .result$ = "Jitter (RAP)"
    elsif .key$ = "jitterPpq5"
        .result$ = "Jitter (PPQ5)"
    elsif .key$ = "jitterDdp"
        .result$ = "Jitter (DDP)"
    elsif .key$ = "shimmerLocal"
        .result$ = "Shimmer (local)"
    elsif .key$ = "shimmerLocalDb"
        .result$ = "Shimmer (local, dB)"
    elsif .key$ = "shimmerApq3"
        .result$ = "Shimmer (APQ3)"
    elsif .key$ = "shimmerApq5"
        .result$ = "Shimmer (APQ5)"
    elsif .key$ = "shimmerApq11"
        .result$ = "Shimmer (APQ11)"
    elsif .key$ = "shimmerDda"
        .result$ = "Shimmer (DDA)"
    elsif length (.key$) > 2 and left$ (.key$, 1) = "f" and index ("123", mid$ (.key$, 2, 1)) > 0
        # f1Mean, f2Median, f3SD, f1Midpoint, ...
        .rest$ = mid$ (.key$, 3, length (.key$) - 2)
        if .rest$ = "Midpoint"
            .rest$ = "at midpoint"
        elsif .rest$ <> "SD"
            @toLower: .rest$
            .rest$ = toLower.result$
        endif
        .result$ = "F" + mid$ (.key$, 2, 1) + " " + .rest$
    endif
endproc

procedure addWarning: .text$
    nWarnings = nWarnings + 1
    warning$[nWarnings] = .text$
endproc

# A number as JSON text, or null if undefined.
procedure jsonNumber: .value, .decimals
    if .value = undefined
        .result$ = "null"
    else
        .result$ = fixed$ (.value, .decimals)
    endif
endproc

# A text as a JSON string in quotes. Quotes and backslashes are escaped,
# and every character outside plain ASCII is written as \uXXXX, so the
# output is always plain ASCII.
procedure jsonString: .s$
    .out$ = ""
    for .i to length (.s$)
        .c$ = mid$ (.s$, .i, 1)
        .code = unicode (.c$)
        if .c$ = """"
            .out$ = .out$ + "\"""
        elsif .c$ = "\"
            .out$ = .out$ + "\\"
        elsif .code < 32 or .code > 126
            if .code > 65535
                # Characters outside the Basic Multilingual Plane: surrogate pair.
                .rest = .code - 65536
                @hex4: 55296 + floor (.rest / 1024)
                .out$ = .out$ + "\u" + hex4.result$
                @hex4: 56320 + (.rest mod 1024)
                .out$ = .out$ + "\u" + hex4.result$
            else
                @hex4: .code
                .out$ = .out$ + "\u" + hex4.result$
            endif
        else
            .out$ = .out$ + .c$
        endif
    endfor
    .result$ = """" + .out$ + """"
endproc

# Four lowercase hexadecimal digits.
procedure hex4: .n
    .result$ = ""
    for .d to 4
        .digit = .n mod 16
        .result$ = mid$ ("0123456789abcdef", .digit + 1, 1) + .result$
        .n = floor (.n / 16)
    endfor
endproc

# Lowercase A-Z only (enough for file names and task labels).
procedure toLower: .s$
    .upper$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    .lower$ = "abcdefghijklmnopqrstuvwxyz"
    .result$ = ""
    for .i to length (.s$)
        .c$ = mid$ (.s$, .i, 1)
        .p = index (.upper$, .c$)
        if .p > 0
            .c$ = mid$ (.lower$, .p, 1)
        endif
        .result$ = .result$ + .c$
    endfor
endproc

# Current local date and time as ISO 8601 (no time zone; Praat does not
# report it). Built from date$(), e.g. "Fri Sep 25 14:03:07 2026".
procedure isoNow
    .d$ = date$ ()
    .months$ = "JanFebMarAprMayJunJulAugSepOctNovDec"
    .month = (index (.months$, mid$ (.d$, 5, 3)) + 2) / 3
    .day = number (mid$ (.d$, 9, 2))
    .monthText$ = string$ (.month)
    if .month < 10
        .monthText$ = "0" + .monthText$
    endif
    .dayText$ = string$ (.day)
    if .day < 10
        .dayText$ = "0" + .dayText$
    endif
    .result$ = right$ (.d$, 4) + "-" + .monthText$ + "-" + .dayText$ + "T" + mid$ (.d$, 12, 8)
endproc

procedure addSettingRow: .table, .name$, .value$
    selectObject: .table
    Append row
    .row = Get number of rows
    Set string value: .row, "name", .name$
    Set string value: .row, "value", .value$
endproc

# --- Reading settings -----------------------------------------------------
procedure getText: .name$
    selectObject: settingsTable
    .row = Search column: "name", .name$
    if .row = 0
        exitScript: "Internal error: the setting """ + .name$ + """ is missing."
    endif
    .value$ = Get value: .row, "value"
    # Praat shows empty table cells as "?".
    if .value$ = "?"
        .value$ = ""
    endif
endproc

procedure getNumber: .name$
    @getText: .name$
    .value = number (getText.value$)
    if .value = undefined
        exitScript: "Setting """ + .name$ + """ must be a number (with a period as the decimal point), but it is """ + getText.value$ + """."
    endif
endproc

procedure getChoice: .name$, .allowed$
    @getText: .name$
    .value$ = getText.value$
    if index ("|" + .allowed$ + "|", "|" + .value$ + "|") = 0
        exitScript: "Setting """ + .name$ + """ is """ + .value$ + """, but it must be one of: " + replace$ (.allowed$, "|", ", ", 0)
    endif
endproc

# A comma-separated list; every item must be allowed. May be empty.
procedure getList: .name$, .allowed$
    @getText: .name$
    .value$ = getText.value$
    .rest$ = .value$ + ","
    while .rest$ <> ""
        .p = index (.rest$, ",")
        .item$ = left$ (.rest$, .p - 1)
        .rest$ = mid$ (.rest$, .p + 1, length (.rest$) - .p)
        if .item$ <> "" and index ("|" + .allowed$ + "|", "|" + .item$ + "|") = 0
            exitScript: "Setting """ + .name$ + """ contains """ + .item$ + """, but items must be from: " + replace$ (.allowed$, "|", ", ", 0)
        endif
    endwhile
endproc

# ======================================================================
# RECORDING SELECTION PROCEDURES
# ======================================================================

procedure defineSlot: .s, .task$, .taskNo, .take, .short$, .label$, .prompt$, .parent
    slotTask$[.s] = .task$
    slotTaskNo[.s] = .taskNo
    slotTake[.s] = .take
    slotShort$[.s] = .short$
    slotLabel$[.s] = .label$
    slotPrompt$[.s] = .prompt$
    slotParent[.s] = .parent
    slotPath$[.s] = ""
    # One recording: the marked part, in seconds.
    slotStart[.s] = 0
    slotEnd[.s] = 0
endproc

procedure defineProfile: .p, .name$, .floor, .ceiling, .formant
    profile$[.p] = .name$
    profFloor[.p] = .floor
    profCeiling[.p] = .ceiling
    profFormant[.p] = .formant
endproc

# The file name and folder of a full path (either kind of slash).
procedure baseName: .path$
    .p = max (rindex (.path$, "/"), rindex (.path$, "\"))
    .result$ = mid$ (.path$, .p + 1, length (.path$) - .p)
    if .p > 0
        .folder$ = left$ (.path$, .p - 1)
    else
        .folder$ = ""
    endif
endproc

# Ask for one recording. The dialog shows what is chosen now (filled in
# automatically, chosen earlier, or nothing).
procedure askSlot: .s
    .done = 0
    while not .done
        if slotPath$[.s] <> ""
            @baseName: slotPath$[.s]
            .file$ = baseName.result$
            .dir$ = baseName.folder$
        endif
        beginPause: "Choose the recordings"
            comment: "Task " + string$ (slotTaskNo[.s]) + " of " + string$ (nTaskSteps) + ":  " + slotLabel$[.s]
            comment: slotPrompt$[.s]
            comment: ""
            if slotPath$[.s] = ""
                comment: "Recording:  (none chosen)"
            else
                @wrapComment: "Recording:  " + .file$
                @wrapComment: "In folder:  " + .dir$
            endif
        if slotPath$[.s] = ""
            # Required tasks default to choosing a file; extra takes default to Skip.
            if slotParent[.s] = 0
                .default = 3
            else
                .default = 2
            endif
            .clicked = endPause: "Cancel", "Skip", "Choose file...", .default, 1
            if .clicked = 1
                exitScript: "Cancelled. Nothing was analyzed."
            elsif .clicked = 2
                .done = 1
            else
                @chooseFor: .s
                .done = chooseFor.chosen
            endif
        else
            .clicked = endPause: "Cancel", "Remove", "Other file...", "Use this", 4, 1
            if .clicked = 1
                exitScript: "Cancelled. Nothing was analyzed."
            elsif .clicked = 2
                slotPath$[.s] = ""
                .done = 1
            elsif .clicked = 3
                @chooseFor: .s
                .done = chooseFor.chosen
            else
                .done = 1
            endif
        endif
    endwhile
endproc

# The system file browser. If it is closed without a choice, the task's
# dialog is shown again.
procedure chooseFor: .s
    .path$ = chooseReadFile$: "Choose the recording for: " + slotLabel$[.s]
    .chosen = 0
    if .path$ <> ""
        slotPath$[.s] = .path$
        .chosen = 1
    endif
endproc

# Summary before the analysis: the recordings, and the speaker profile
# (adult_female unless changed). Sets .run = 1 to analyze, 0 to go back.
procedure summaryDialog
    .run = 0
    .problem$ = ""
    .decided = 0
    while not .decided
        # The same file chosen for two tasks is pointed out (not an error).
        # One recording: overlapping marks are pointed out instead.
        .dup$ = ""
        for .a to nSlots - 1
            for .b from .a + 1 to nSlots
                if .dup$ = "" and slotPath$[.a] <> "" and slotPath$[.a] = slotPath$[.b]
                    if inputMode = 1
                        .dup$ = "NOTE: the same file is used for " + slotShort$[.a] + " and " + slotShort$[.b] + "."
                    elsif slotStart[.a] < slotEnd[.b] and slotStart[.b] < slotEnd[.a]
                        .dup$ = "NOTE: the parts marked for " + slotShort$[.a] + " and " + slotShort$[.b] + " overlap."
                    endif
                endif
            endfor
        endfor
        .count = 0
        for .k to nSlots
            .line$[.k] = ""
            if slotPath$[.k] <> ""
                .count = .count + 1
                if inputMode = 1
                    @baseName: slotPath$[.k]
                    .line$[.k] = "      " + slotShort$[.k] + ":   " + baseName.result$
                else
                    .line$[.k] = "      " + slotShort$[.k] + ":   " + fixed$ (slotStart[.k], 2) + " to " + fixed$ (slotEnd[.k], 2) + " s"
                endif
            elsif slotParent[.k] = 0
                if inputMode = 1
                    .line$[.k] = "      " + slotShort$[.k] + ":   (skipped)"
                else
                    .line$[.k] = "      " + slotShort$[.k] + ":   (not marked)"
                endif
            endif
        endfor

        beginPause: "Check before the analysis"
            if .problem$ <> ""
                @wrapComment: "PLEASE FIX: " + .problem$
            endif
            if inputMode = 1
                comment: "These recordings will be analyzed:"
            else
                @wrapComment: "These parts of " + longName$ + " will be analyzed:"
            endif
            for .k to nSlots
                if .line$[.k] <> ""
                    @wrapComment: .line$[.k]
                endif
            endfor
            if .dup$ <> ""
                @wrapComment: .dup$
            endif
            # One recording: sentences are numbered in recording order, so a
            # missing sentence shifts the numbers after it.
            if inputMode = 2
                .nSent = 0
                for .k from groupFirst[2] to groupLast[2]
                    if slotPath$[.k] <> ""
                        .nSent = .nSent + 1
                    endif
                endfor
                if .nSent > 0 and .nSent < 6
                    @wrapComment: "NOTE: only " + string$ (.nSent) + " of 6 sentences are marked. They are numbered in recording order."
                endif
            endif
            comment: "Speaker profile (adult_female is the default):"
            optionMenu: "Speaker profile", profileChoice
                for .k to nProfiles
                    option: profile$[.k]
                endfor
            # The Advanced values are only shown when they were changed.
            @describeAnalysisChanges
            if pitchFloorOverride <> 0 or pitchCeilingOverride <> 0 or formantCeilingOverride <> 0 or describeAnalysisChanges.result$ <> ""
                .adv$ = "Changed under Advanced:"
                if pitchFloorOverride <> 0
                    .adv$ = .adv$ + " pitch floor " + string$ (pitchFloorOverride) + " Hz,"
                endif
                if pitchCeilingOverride <> 0
                    .adv$ = .adv$ + " pitch ceiling " + string$ (pitchCeilingOverride) + " Hz,"
                endif
                if formantCeilingOverride <> 0
                    .adv$ = .adv$ + " formant ceiling " + string$ (formantCeilingOverride) + " Hz,"
                endif
                .adv$ = .adv$ + describeAnalysisChanges.result$
                @wrapComment: left$ (.adv$, length (.adv$) - 1) + "."
            endif
            comment: "Also save, next to the results.json file (which is always saved):"
            boolean: "Spreadsheet for research (CSV)", saveCsv
            boolean: "Text summary to paste into a report", saveSummary
        if inputMode = 1
            .clicked = endPause: "Cancel", "Change files", "Advanced...", "Run analysis", 4, 1
        else
            .clicked = endPause: "Cancel", "Edit marks", "Advanced...", "Run analysis", 4, 1
        endif
        if .clicked = 1
            @cancelRun
        endif
        profileChoice = speaker_profile
        saveCsv = spreadsheet_for_research
        saveSummary = text_summary_to_paste_into_a_report

        if .clicked = 2
            .decided = 1
        elsif .clicked = 3
            @advancedDialog
            .problem$ = ""
        else
            .useFloor = profFloor[profileChoice]
            .useCeiling = profCeiling[profileChoice]
            if pitchFloorOverride > 0
                .useFloor = pitchFloorOverride
            endif
            if pitchCeilingOverride > 0
                .useCeiling = pitchCeilingOverride
            endif
            if .count = 0 and inputMode = 1
                .problem$ = "no recording is chosen. Click ""Change files""."
            elsif .count = 0
                .problem$ = "no task is marked. Click ""Edit marks""."
            elsif pitchFloorOverride < 0 or pitchCeilingOverride < 0 or formantCeilingOverride < 0
                .problem$ = "the Hz values cannot be negative. Click ""Advanced..."" to change them."
            elsif .useFloor >= .useCeiling
                .problem$ = "the pitch floor (" + string$ (.useFloor) + " Hz) must be below the pitch ceiling (" + string$ (.useCeiling) + " Hz). Click ""Advanced..."" to change them."
            else
                .run = 1
                .decided = 1
            endif
        endif
    endwhile
endproc

# A comment in a pause window, wrapped at maxCommentChars characters.
# Words longer than a line (for example a folder path) are broken.
procedure wrapComment: .text$
    .line$ = ""
    .rest$ = .text$
    while .rest$ <> ""
        .sp = index (.rest$, " ")
        if .sp = 0
            .word$ = .rest$
            .rest$ = ""
        else
            .word$ = left$ (.rest$, .sp - 1)
            .rest$ = mid$ (.rest$, .sp + 1, length (.rest$) - .sp)
        endif
        if .word$ <> ""
            if .line$ = ""
                .line$ = .word$
            elsif length (.line$) + 1 + length (.word$) <= maxCommentChars or length (.word$) > maxCommentChars
                .line$ = .line$ + " " + .word$
            else
                comment: .line$
                .line$ = .word$
            endif
            while length (.line$) > maxCommentChars
                comment: left$ (.line$, maxCommentChars)
                .line$ = mid$ (.line$, maxCommentChars + 1, length (.line$) - maxCommentChars)
            endwhile
        endif
    endwhile
    if .line$ <> ""
        comment: .line$
    endif
endproc

# Stop the script. In "one recording" mode the long recording and its marks
# are removed from the Objects list first (this also closes the sound window).
procedure cancelRun
    if marksGrid <> 0
        removeObject: marksGrid
        marksGrid = 0
    endif
    if longSound <> 0
        removeObject: longSound
        longSound = 0
    endif
    exitScript: "Cancelled. Nothing was analyzed."
endproc

# ======================================================================
# ONE RECORDING PROCEDURES
# ======================================================================

# Open longPath$ as a Sound, make an empty TextGrid for the marks, and show
# both in a sound window. Sets .ok = 1 if this worked.
procedure openLongRecording
    .ok = 0
    @baseName: longPath$
    longName$ = baseName.result$
    # A placeholder object, so that a failed read can be recognized.
    .marker = Create Table with column names: "marker", 0, "x"
    nocheck Read from file: longPath$
    if startsWith (selected$ (), "Sound ")
        longSound = selected ("Sound")
        .ok = 1
    else
        # Not a sound (or several objects): remove whatever was read.
        .n = numberOfSelected ()
        for .k to .n
            .id[.k] = selected (.k)
        endfor
        for .k to .n
            if .id[.k] <> .marker
                removeObject: .id[.k]
            endif
        endfor
    endif
    removeObject: .marker
    if .ok
        selectObject: longSound
        marksGrid = To TextGrid: "tasks", ""
        selectObject: longSound, marksGrid
        View & Edit
    endif
endproc

# One dialog for all marks: drag across a task in the sound window,
# choose what it is, then click Mark. Repeat, then click Done.
procedure markTasks
    .problem$ = ""
    # The first time: what the script guessed.
    .last$ = guessMessage$
    guessMessage$ = ""
    .done = 0
    while not .done
        for .g to 3
            .n[.g] = 0
        endfor
        for .i to nMarks
            .n[markType[.i]] = .n[markType[.i]] + 1
        endfor
        beginPause: "Mark the tasks"
            if .problem$ <> ""
                @wrapComment: "PLEASE FIX: " + .problem$
            elsif .last$ <> ""
                @wrapComment: "OK: " + .last$
            endif
            comment: "CHECK a mark: click its label in the sound window, then click Listen."
            comment: "Wrong? Click Remove. (To remove several, drag across them first.)"
            comment: "ADD a mark: drag the mouse across the task in the sound window,"
            comment: "choose below what it is, then click Mark."
            comment: "Zoom: the in / out / all buttons at the bottom left of the sound window."
            comment: ""
            comment: "Marked:  vowel /a/ " + string$ (.n[1]) + " (up to 3),  sentences " + string$ (.n[2]) + " of 6,  conversation " + string$ (.n[3]) + " (up to 2)"
            comment: "Sentences are numbered in the order in which they come in the recording."
            comment: "When everything is right, click Done. Keep the sound window open until then."
            choice: "This part is", markChoice
                option: "Vowel /a/"
                option: "Sentence"
                option: "Conversation"
        # Buttons: 1 Cancel, 2 Remove, 3 Listen, 4 Mark, 5 Done.
        .clicked = endPause: "Cancel", "Remove", "Listen", "Mark", "Done", 0, 1
        markChoice = this_part_is
        .problem$ = ""
        .last$ = ""
        if .clicked = 1
            @cancelRun
        elsif .clicked = 5
            if nMarks = 0
                .problem$ = "nothing is marked yet. Drag across a task in the sound window, choose what it is, then click Mark."
            else
                .done = 1
            endif
        elsif .clicked = 2
            @removeMark
            if removeMark.removed$ = ""
                .problem$ = "no mark is selected. Click the label of the mark in the sound window first, then click Remove."
            else
                .last$ = "removed " + removeMark.removed$ + "."
            endif
        elsif .clicked = 3
            @editorSelection
            if editorSelection.t2 - editorSelection.t1 < minMarkSec
                .problem$ = "nothing is selected to listen to. Click a label, or drag across a part, in the sound window first."
            else
                @editorPlay: editorSelection.t1, editorSelection.t2
                .last$ = "playing " + fixed$ (editorSelection.t1, 2) + " to " + fixed$ (editorSelection.t2, 2) + " s."
            endif
        else
            .type = markChoice
            @editorSelection
            .t1 = editorSelection.t1
            .t2 = editorSelection.t2
            .same = 0
            for .i to nMarks
                if abs (markStart[.i] - .t1) < 0.0005 and abs (markEnd[.i] - .t2) < 0.0005
                    .same = .i
                endif
            endfor
            .max = groupLast[.type] - groupFirst[.type] + 1
            if .t2 - .t1 < minMarkSec
                .problem$ = "nothing (or only a very short part) is selected. First drag the mouse across the task in the sound window."
            elsif .same > 0
                @markLabel: .same
                .problem$ = "this part is already marked (" + markLabel.result$ + "). Drag across the next task first."
            elsif .n[.type] >= .max
                .problem$ = "the " + groupName$[.type] + " marks are all used (" + string$ (.max) + "). To change one, remove it first."
            else
                nMarks = nMarks + 1
                markType[nMarks] = .type
                markStart[nMarks] = .t1
                markEnd[nMarks] = .t2
                @redrawMarks
                @markLabel: nMarks
                .last$ = "marked " + markLabel.result$ + ", " + fixed$ (.t1, 2) + " to " + fixed$ (.t2, 2) + " s. (Wrong? Click Remove now.)"
            endif
        endif
    endwhile
endproc

# First guesses of the vowel and the sentences (see the "guess" settings
# at the top). The conversation is not guessed.
procedure guessMarks
    selectObject: longSound
    .end = Get end time
    .sil = To TextGrid (silences): guessMinPitch, 0, guessSilenceDb, guessMinSilenceSec, guessMinSoundingSec, "silent", "sounding"
    selectObject: longSound
    .pitch = To Pitch (cc): pitchTimeStep, guessPitchFloor, pitchMaxCandidates, pitchVeryAccurate$, pitchSilenceThreshold, pitchVoicingThreshold, pitchOctaveCost, pitchOctaveJumpCost, pitchVoicedUnvoicedCost, guessPitchCeiling
    selectObject: longSound, .pitch
    .pulses = To PointProcess (cc)
    .vuv = To TextGrid (vuv): vuvMaxPeriod, vuvMeanPeriod
    removeObject: .pulses

    # Every stretch of sound: its times, how much of it is voiced, and how
    # steady its pitch is (SD in semitones).
    .nc = 0
    selectObject: .sil
    .n = Get number of intervals: 1
    for .k to .n
        selectObject: .sil
        .lab$ = Get label of interval: 1, .k
        if .lab$ = "sounding"
            .nc = .nc + 1
            .c1[.nc] = Get start time of interval: 1, .k
            .c2[.nc] = Get end time of interval: 1, .k
            @voicedIn: .vuv, .c1[.nc], .c2[.nc]
            .cv[.nc] = voicedIn.dur / (.c2[.nc] - .c1[.nc])
            selectObject: .pitch
            .cs[.nc] = Get standard deviation: .c1[.nc], .c2[.nc], "semitones"
        endif
    endfor
    removeObject: .sil, .pitch, .vuv

    # Which stretches look like a sustained vowel.
    .anyVowel = 0
    for .c to .nc
        .d = .c2[.c] - .c1[.c]
        .isVowel[.c] = 0
        if .d >= guessVowelMinSec and .cv[.c] >= guessVowelMinVoiced and .cs[.c] <> undefined
            if .cs[.c] <= guessVowelMaxSdSt
                .isVowel[.c] = 1
                .anyVowel = 1
            endif
        endif
    endfor
    # None steady enough (for example a very rough voice): take the most
    # voiced stretch of at least 1.5 s, if it is mostly voiced.
    if not .anyVowel
        .best = 0
        for .c to .nc
            if .c2[.c] - .c1[.c] >= 1.5 and .cv[.c] >= guessVowelMinVoiced
                if .best = 0
                    .best = .c
                elsif .cv[.c] > .cv[.best]
                    .best = .c
                endif
            endif
        endfor
        if .best > 0
            .isVowel[.best] = 1
        endif
    endif

    # Mark them, in recording order: up to 3 vowels and 6 sentences.
    .nV = 0
    .nS = 0
    .nOther = 0
    for .c to .nc
        .d = .c2[.c] - .c1[.c]
        .type = 0
        if .isVowel[.c] and .nV < 3
            .type = 1
            .nV = .nV + 1
        elsif not .isVowel[.c] and .d >= guessSentenceMinSec and .d <= guessSentenceMaxSec and .cv[.c] >= guessSentenceMinVoiced and .nS < 6
            .type = 2
            .nS = .nS + 1
        else
            .nOther = .nOther + 1
        endif
        if .type > 0
            nMarks = nMarks + 1
            markType[nMarks] = .type
            markStart[nMarks] = max (0, .c1[.c] - guessPadSec)
            markEnd[nMarks] = min (.end, .c2[.c] + guessPadSec)
        endif
    endfor
    @redrawMarks

    if .nV + .nS = 0
        guessMessage$ = "the script could not find the tasks by itself. Please mark them as described below."
    else
        guessMessage$ = "the script guessed " + string$ (.nV) + " vowel(s) and " + string$ (.nS) + " sentence(s), labelled in the sound window. Please check each one."
    endif
    appendInfoLine: "Guessed marks: ", .nV, " vowel(s), ", .nS, " sentence(s); ", .nOther, " other stretch(es) of sound not marked."
endproc

# The total voiced time (vuv TextGrid, label "V") between .from and .to.
procedure voicedIn: .grid, .from, .to
    selectObject: .grid
    .n = Get number of intervals: 1
    .dur = 0
    for .k to .n
        .label$ = Get label of interval: 1, .k
        if .label$ = "V"
            .t1 = Get start time of interval: 1, .k
            .t2 = Get end time of interval: 1, .k
            .overlap = min (.t2, .to) - max (.t1, .from)
            if .overlap > 0
                .dur = .dur + .overlap
            endif
        endif
    endfor
endproc

# Play a part of the recording from the sound window (the dialog stays
# usable while it plays).
procedure editorPlay: .t1, .t2
    editor: marksGrid
        Play: .t1, .t2
    endeditor
endproc

# Remove the marks inside a dragged selection; if there are none, the one
# mark the selection overlaps most (or the mark under the cursor).
# Sets .removed$ ("" = none found).
procedure removeMark
    .removed$ = ""
    @editorSelection
    .t1 = editorSelection.t1
    .t2 = editorSelection.t2
    # Clicking a label selects exactly its mark.
    if .t2 - .t1 >= minMarkSec
        .nInside = 0
        for .i to nMarks
            .inside[.i] = markStart[.i] >= .t1 - 0.01 and markEnd[.i] <= .t2 + 0.01
            if .inside[.i]
                .nInside = .nInside + 1
                @markLabel: .i
                .one$ = markLabel.result$
            endif
        endfor
        if .nInside > 0
            if .nInside = 1
                .removed$ = "the mark " + .one$
            else
                .removed$ = string$ (.nInside) + " marks"
            endif
            .kept = 0
            for .i to nMarks
                if not .inside[.i]
                    .kept = .kept + 1
                    markType[.kept] = markType[.i]
                    markStart[.kept] = markStart[.i]
                    markEnd[.kept] = markEnd[.i]
                endif
            endfor
            nMarks = .kept
            @redrawMarks
        endif
    endif
    if .removed$ = ""
        @removeOneMark: .t1, .t2
        .removed$ = removeOneMark.removed$
    endif
endproc

# No mark lies inside the selection: remove the one mark it overlaps most,
# or (for a click without dragging) the mark under the cursor.
procedure removeOneMark: .t1, .t2
    .removed$ = ""
    .best = 0
    .bestOverlap = 0
    for .i to nMarks
        if .t2 - .t1 < minMarkSec
            # Under the cursor: the shortest such mark wins (e.g. a sentence
            # inside a marked conversation).
            if markStart[.i] <= .t1 and .t1 <= markEnd[.i]
                .overlap = 1 / (markEnd[.i] - markStart[.i])
            else
                .overlap = 0
            endif
        else
            .overlap = min (markEnd[.i], .t2) - max (markStart[.i], .t1)
        endif
        if .overlap > .bestOverlap
            .best = .i
            .bestOverlap = .overlap
        endif
    endfor
    if .best > 0
        @markLabel: .best
        .removed$ = "the mark " + markLabel.result$
        for .i from .best to nMarks - 1
            markType[.i] = markType[.i + 1]
            markStart[.i] = markStart[.i + 1]
            markEnd[.i] = markEnd[.i + 1]
        endfor
        nMarks = nMarks - 1
        @redrawMarks
    endif
endproc

# Turn the marks into the task slots: each kind of mark, in the order of
# the recording, fills that kind's slots (Sentence 1, Sentence 2, ...).
procedure assignMarks
    for .s to nSlots
        slotPath$[.s] = ""
        slotMark[.s] = 0
    endfor
    for .i to nMarks
        .used[.i] = 0
    endfor
    for .g to 3
        for .s from groupFirst[.g] to groupLast[.g]
            .best = 0
            for .i to nMarks
                if markType[.i] = .g and .used[.i] = 0
                    if .best = 0
                        .best = .i
                    elsif markStart[.i] < markStart[.best]
                        .best = .i
                    endif
                endif
            endfor
            if .best > 0
                .used[.best] = 1
                slotPath$[.s] = longPath$
                slotStart[.s] = markStart[.best]
                slotEnd[.s] = markEnd[.best]
                slotMark[.s] = .best
            endif
        endfor
    endfor
endproc

# The task name of mark .i (after assignMarks), e.g. "Sentence 3".
procedure markLabel: .i
    .result$ = groupName$[markType[.i]]
    for .s to nSlots
        if slotMark[.s] = .i and slotPath$[.s] <> ""
            .result$ = slotShort$[.s]
        endif
    endfor
endproc

# The selection in the sound window, kept inside the recording.
procedure editorSelection
    editor: marksGrid
        .t1 = Get start of selection
        .t2 = Get end of selection
    endeditor
    selectObject: longSound
    .end = Get end time
    .t1 = max (.t1, 0)
    .t2 = min (.t2, .end)
endproc

# Show the marked tasks as labelled intervals in the sound window.
# The TextGrid is cleared and filled again from the marks.
procedure redrawMarks
    @assignMarks
    selectObject: marksGrid
    .n = Get number of intervals: 1
    while .n > 1
        Remove left boundary: 1, .n
        .n = .n - 1
    endwhile
    Set interval text: 1, 1, ""
    for .k to nSlots
        if slotPath$[.k] <> ""
            # nocheck: a boundary may already be there (touching marks) or
            # be at the very start or end of the recording.
            nocheck Insert boundary: 1, slotStart[.k]
            nocheck Insert boundary: 1, slotEnd[.k]
        endif
    endfor
    for .k to nSlots
        if slotPath$[.k] <> ""
            .i = Get interval at time: 1, (slotStart[.k] + slotEnd[.k]) / 2
            .old$ = Get label of interval: 1, .i
            if .old$ = ""
                Set interval text: 1, .i, slotShort$[.k]
            else
                Set interval text: 1, .i, .old$ + " + " + slotShort$[.k]
            endif
        endif
    endfor
endproc

# The analysis settings that can be changed under "Advanced...", set to
# their defaults. They go into the settings table and so into all outputs.
procedure resetAnalysisSettings
    setFormantCount = 5
    setVowelWindowSec = 3
    setVowelShortFraction = 0.5
    setFormantWindow$ = "whole_trimmed"
    setCppsMethod$ = "praat_default"
    setCppsSpeechVoicedOnly$ = "yes"
    setIntensitySpeechVoicedOnly$ = "yes"
    setIntensityAveraging$ = "energy"
    setHnrMethod$ = "cc"
    setPeriodRangeMode$ = "derived"
    setJitterMeasures$ = "local"
    setShimmerMeasures$ = "local,local_db"
    setChannelHandling$ = "average"
endproc

# The analysis settings that differ from their defaults, as text for the
# summary dialog ("" if none).
procedure describeAnalysisChanges
    .r$ = ""
    if setFormantCount <> 5
        .r$ = .r$ + " number of formants " + string$ (setFormantCount) + ","
    endif
    if setVowelWindowSec <> 3
        .r$ = .r$ + " vowel window " + string$ (setVowelWindowSec) + " s,"
    endif
    if setVowelShortFraction <> 0.5
        .r$ = .r$ + " short vowel fraction " + string$ (setVowelShortFraction) + ","
    endif
    if setFormantWindow$ <> "whole_trimmed"
        .r$ = .r$ + " formant window " + setFormantWindow$ + ","
    endif
    if setCppsMethod$ <> "praat_default"
        .r$ = .r$ + " CPPS preset " + setCppsMethod$ + ","
    endif
    if setCppsSpeechVoicedOnly$ <> "yes"
        .r$ = .r$ + " speech CPPS from the whole recording,"
    endif
    if setIntensitySpeechVoicedOnly$ <> "yes"
        .r$ = .r$ + " speech intensity from the whole recording,"
    endif
    if setIntensityAveraging$ <> "energy"
        .r$ = .r$ + " intensity averaging " + setIntensityAveraging$ + ","
    endif
    if setHnrMethod$ <> "cc"
        .r$ = .r$ + " HNR method " + setHnrMethod$ + ","
    endif
    if setPeriodRangeMode$ <> "derived"
        .r$ = .r$ + " period range " + setPeriodRangeMode$ + ","
    endif
    if setJitterMeasures$ = ""
        .r$ = .r$ + " no jitter measures,"
    elsif setJitterMeasures$ <> "local"
        .r$ = .r$ + " jitter " + setJitterMeasures$ + ","
    endif
    if setShimmerMeasures$ = ""
        .r$ = .r$ + " no shimmer measures,"
    elsif setShimmerMeasures$ <> "local,local_db"
        .r$ = .r$ + " shimmer " + setShimmerMeasures$ + ","
    endif
    if setChannelHandling$ <> "average"
        .r$ = .r$ + " stereo " + setChannelHandling$ + " channel,"
    endif
    .result$ = .r$
endproc

# The position (1, 2, ...) of .value$ in a "|"-separated list (1 if absent).
procedure choiceIndex: .allowed$, .value$
    .result = 1
    .rest$ = .allowed$ + "|"
    .k = 0
    while .rest$ <> ""
        .k = .k + 1
        .bar = index (.rest$, "|")
        if left$ (.rest$, .bar - 1) = .value$
            .result = .k
        endif
        .rest$ = mid$ (.rest$, .bar + 1, length (.rest$) - .bar)
    endwhile
endproc

# The text of a menu option up to the first space (the setting's value).
procedure firstWord: .text$
    .sp = index (.text$, " ")
    if .sp = 0
        .result$ = .text$
    else
        .result$ = left$ (.text$, .sp - 1)
    endif
endproc

# A comma-separated list typed by the user: spaces removed, every item
# checked against .allowed$. .result$ is the cleaned list; .bad$ is the
# first item that is not allowed ("" if all are).
procedure cleanList: .text$, .allowed$
    .rest$ = replace$ (.text$, " ", "", 0) + ","
    .result$ = ""
    .bad$ = ""
    while .rest$ <> ""
        .c = index (.rest$, ",")
        .item$ = left$ (.rest$, .c - 1)
        .rest$ = mid$ (.rest$, .c + 1, length (.rest$) - .c)
        if .item$ <> ""
            if index ("|" + .allowed$ + "|", "|" + .item$ + "|") = 0
                if .bad$ = ""
                    .bad$ = .item$
                endif
            elsif index ("," + .result$ + ",", "," + .item$ + ",") = 0
                if .result$ = ""
                    .result$ = .item$
                else
                    .result$ = .result$ + "," + .item$
                endif
            endif
        endif
    endwhile
endproc

# Advanced settings, on two pages so that the window fits on small
# screens: (1) pitch, formants and vowels, (2) CPPS, intensity, HNR,
# jitter, shimmer and stereo. Pitch and formant ceiling 0 = the speaker
# profile's value. "Discard changes" restores the values as they were
# when the window opened; "Reset all" shows the defaults again.
procedure advancedDialog
    .p = profileChoice
    .problem$ = ""
    # The values when the window opened, for "Discard changes".
    .was_pitchFloorOverride = pitchFloorOverride
    .was_pitchCeilingOverride = pitchCeilingOverride
    .was_formantCeilingOverride = formantCeilingOverride
    .was_setFormantCount = setFormantCount
    .was_setVowelWindowSec = setVowelWindowSec
    .was_setVowelShortFraction = setVowelShortFraction
    .was_setFormantWindow$ = setFormantWindow$
    .was_setCppsMethod$ = setCppsMethod$
    .was_setCppsSpeechVoicedOnly$ = setCppsSpeechVoicedOnly$
    .was_setIntensitySpeechVoicedOnly$ = setIntensitySpeechVoicedOnly$
    .was_setIntensityAveraging$ = setIntensityAveraging$
    .was_setHnrMethod$ = setHnrMethod$
    .was_setPeriodRangeMode$ = setPeriodRangeMode$
    .was_setJitterMeasures$ = setJitterMeasures$
    .was_setShimmerMeasures$ = setShimmerMeasures$
    .was_setChannelHandling$ = setChannelHandling$
    .page = 1
    .done = 0
    while not .done
        # .reset = 1 when "Reset all" was clicked on the current page.
        .reset = 0
        if .page = 1
            @choiceIndex: "whole_trimmed|midpoint", setFormantWindow$
            .iFormantWindow = choiceIndex.result
            beginPause: "Advanced settings (page 1 of 2)"
                if .problem$ <> ""
                    @wrapComment: "PLEASE FIX: " + .problem$
                endif
                comment: "Most people do not need to change these. All values used are saved."
                @wrapComment: "PITCH AND FORMANTS. Leave at 0 to use the speaker profile (" + profile$[.p] + "): pitch floor " + string$ (profFloor[.p]) + " Hz, pitch ceiling " + string$ (profCeiling[.p]) + " Hz, formant ceiling " + string$ (profFormant[.p]) + " Hz."
                real: "Pitch floor (Hz)", pitchFloorOverride
                real: "Pitch ceiling (Hz)", pitchCeilingOverride
                real: "Formant ceiling (Hz)", formantCeilingOverride
                real: "Number of formants", setFormantCount
                optionMenu: "Formant window", .iFormantWindow
                    option: "whole_trimmed (mean, median and SD over the analyzed part)"
                    option: "midpoint (one value at the middle)"
                @wrapComment: "VOWELS. The middle part of the voiced vowel that is analyzed; if the voiced vowel is shorter than the window, this fraction of its middle (0.5 = middle 50%)."
                real: "Vowel window (s)", setVowelWindowSec
                real: "Short vowel fraction", setVowelShortFraction
            .c = endPause: "Discard changes", "Reset all", "Next >", 3, 1
            .problem$ = ""
            .reset = (.c = 2)
            if .c = 3
                # Keep what was typed, also if there is a problem.
                pitchFloorOverride = pitch_floor
                pitchCeilingOverride = pitch_ceiling
                formantCeilingOverride = formant_ceiling
                setFormantCount = number_of_formants
                setVowelWindowSec = vowel_window
                setVowelShortFraction = short_vowel_fraction
                @firstWord: formant_window$
                setFormantWindow$ = firstWord.result$
                @checkAdvancedPage1
                .problem$ = checkAdvancedPage1.problem$
                if .problem$ = ""
                    .page = 2
                endif
            endif
        else
            @choiceIndex: "praat_default|maryn_weenink_2015", setCppsMethod$
            .iCpps = choiceIndex.result
            @choiceIndex: "energy|dB", setIntensityAveraging$
            .iIntensity = choiceIndex.result
            @choiceIndex: "cc|ac", setHnrMethod$
            .iHnr = choiceIndex.result
            @choiceIndex: "derived|fixed", setPeriodRangeMode$
            .iPeriod = choiceIndex.result
            @choiceIndex: "average|left", setChannelHandling$
            .iChannel = choiceIndex.result
            beginPause: "Advanced settings (page 2 of 2)"
                if .problem$ <> ""
                    @wrapComment: "PLEASE FIX: " + .problem$
                endif
                comment: "CPPS AND INTENSITY"
                optionMenu: "Preset for CPPS", .iCpps
                    option: "praat_default (Get CPPS defaults of Praat 7.0.02)"
                    option: "maryn_weenink_2015 (AVQI v02.02 settings)"
                boolean: "Voiced parts only for speech CPPS", (setCppsSpeechVoicedOnly$ = "yes")
                boolean: "Voiced parts only for speech intensity", (setIntensitySpeechVoicedOnly$ = "yes")
                optionMenu: "Intensity averaging", .iIntensity
                    option: "energy (mean of the energy)"
                    option: "dB (mean of the dB values)"
                comment: "HNR, JITTER AND SHIMMER (vowels)"
                optionMenu: "Harmonicity method", .iHnr
                    option: "cc (cross-correlation)"
                    option: "ac (autocorrelation)"
                optionMenu: "Period range", .iPeriod
                    option: "derived (0.8 / pitch ceiling to 1.25 / pitch floor)"
                    option: "fixed (0.1 to 20 ms, as in AVQI)"
                @wrapComment: "Comma-separated. Jitter: local, local_absolute, rap, ppq5, ddp. Shimmer: local, local_db, apq3, apq5, apq11, dda."
                sentence: "Jitter measures", setJitterMeasures$
                sentence: "Shimmer measures", setShimmerMeasures$
                optionMenu: "Stereo channels", .iChannel
                    option: "average (of the two channels)"
                    option: "left (channel only)"
            .c = endPause: "Discard changes", "< Previous", "Reset all", "OK", 4, 1
            .problem$ = ""
            .reset = (.c = 3)
            if .c = 2 or .c = 4
                # Keep what was typed, also when going back to page 1.
                @firstWord: preset_for_CPPS$
                setCppsMethod$ = firstWord.result$
                setCppsSpeechVoicedOnly$ = if voiced_parts_only_for_speech_CPPS then "yes" else "no" fi
                setIntensitySpeechVoicedOnly$ = if voiced_parts_only_for_speech_intensity then "yes" else "no" fi
                @firstWord: intensity_averaging$
                setIntensityAveraging$ = firstWord.result$
                @firstWord: harmonicity_method$
                setHnrMethod$ = firstWord.result$
                @firstWord: period_range$
                setPeriodRangeMode$ = firstWord.result$
                @firstWord: stereo_channels$
                setChannelHandling$ = firstWord.result$
                setJitterMeasures$ = jitter_measures$
                setShimmerMeasures$ = shimmer_measures$
            endif
            if .c = 2
                .page = 1
            elsif .c = 4
                @cleanList: setJitterMeasures$, "local|local_absolute|rap|ppq5|ddp"
                .jitter$ = cleanList.result$
                .badJitter$ = cleanList.bad$
                @cleanList: setShimmerMeasures$, "local|local_db|apq3|apq5|apq11|dda"
                .shimmer$ = cleanList.result$
                .badShimmer$ = cleanList.bad$
                if .badJitter$ <> ""
                    .problem$ = "the jitter measure """ + .badJitter$ + """ is not one of: local, local_absolute, rap, ppq5, ddp."
                elsif .badShimmer$ <> ""
                    .problem$ = "the shimmer measure """ + .badShimmer$ + """ is not one of: local, local_db, apq3, apq5, apq11, dda."
                else
                    setJitterMeasures$ = .jitter$
                    setShimmerMeasures$ = .shimmer$
                    # Page 1 was checked when leaving it.
                    .done = 1
                endif
            endif
        endif
        if .c = 1
            pitchFloorOverride = .was_pitchFloorOverride
            pitchCeilingOverride = .was_pitchCeilingOverride
            formantCeilingOverride = .was_formantCeilingOverride
            setFormantCount = .was_setFormantCount
            setVowelWindowSec = .was_setVowelWindowSec
            setVowelShortFraction = .was_setVowelShortFraction
            setFormantWindow$ = .was_setFormantWindow$
            setCppsMethod$ = .was_setCppsMethod$
            setCppsSpeechVoicedOnly$ = .was_setCppsSpeechVoicedOnly$
            setIntensitySpeechVoicedOnly$ = .was_setIntensitySpeechVoicedOnly$
            setIntensityAveraging$ = .was_setIntensityAveraging$
            setHnrMethod$ = .was_setHnrMethod$
            setPeriodRangeMode$ = .was_setPeriodRangeMode$
            setJitterMeasures$ = .was_setJitterMeasures$
            setShimmerMeasures$ = .was_setShimmerMeasures$
            setChannelHandling$ = .was_setChannelHandling$
            .done = 1
        elsif .reset
            pitchFloorOverride = 0
            pitchCeilingOverride = 0
            formantCeilingOverride = 0
            @resetAnalysisSettings
        endif
    endwhile
endproc

# The checks of page 1 of the Advanced settings ("" if all is well).
procedure checkAdvancedPage1
    .problem$ = ""
    if setFormantCount < 3
        .problem$ = "the number of formants must be at least 3 (F1 to F3 are reported)."
    elsif setVowelWindowSec <= 0
        .problem$ = "the vowel window must be above 0 s."
    elsif setVowelShortFraction <= 0 or setVowelShortFraction > 1
        .problem$ = "the short vowel fraction must be above 0 and at most 1."
    endif
endproc

# ======================================================================
# SEPARATE FILES PROCEDURES
# ======================================================================

# The sound files in recFolder$ (sorted), as folderFile$[1..nFolderFiles].
# Files whose names look like a task are filled in as guesses.
procedure listFolder
    nFolderFiles = 0
    nPrefilled = 0
    for .s to nSlots
        slotPath$[.s] = ""
    endfor
    .list = Create Strings as file list: "files", recFolder$ + "/*"
    Sort
    .n = Get number of strings
    for .i to .n
        selectObject: .list
        .name$ = Get string: .i
        @toLower: .name$
        .lower$ = toLower.result$
        .dot = rindex (.lower$, ".")
        if .dot > 1
            .ext$ = mid$ (.lower$, .dot + 1, length (.lower$) - .dot)
            if index (soundExtensions$, "|" + .ext$ + "|") > 0
                nFolderFiles = nFolderFiles + 1
                folderFile$[nFolderFiles] = .name$
                @classifyName: left$ (.lower$, .dot - 1)
                if classifyName.task$ <> ""
                    @placeInSlot: classifyName.task$, classifyName.take, recFolder$ + "/" + .name$
                endif
            endif
        endif
    endfor
    removeObject: .list
endproc

# Choose the folder (if not chosen yet), then one dialog with a list of the
# folder's sound files for every task. Sets oneByOne = 1 if the person
# would rather choose the files one by one.
procedure fileDialog
    .done = 0
    while not .done
        if recFolder$ = ""
            .f$ = chooseFolder$: "Choose the folder that contains the recordings"
            if .f$ = ""
                beginPause: "No folder chosen"
                    comment: "Please choose the folder that contains the recordings,"
                    comment: "or choose the files one by one (if they are in different folders)."
                .c = endPause: "Cancel", "One by one...", "Choose folder...", 3, 1
                if .c = 1
                    @cancelRun
                elsif .c = 2
                    oneByOne = 1
                    .done = 1
                endif
            else
                recFolder$ = .f$
                @listFolder
            endif
        elsif nFolderFiles = 0
            beginPause: "No recordings found"
                comment: "There are no sound files in this folder:"
                @wrapComment: recFolder$
            .c = endPause: "Cancel", "One by one...", "Other folder...", 3, 1
            if .c = 1
                @cancelRun
            elsif .c = 2
                oneByOne = 1
                .done = 1
            else
                recFolder$ = ""
            endif
        else
            # The list position of each task's current file (1 = none).
            for .s to nSlots
                .def[.s] = 1
                for .i to nFolderFiles
                    if slotPath$[.s] = recFolder$ + "/" + folderFile$[.i]
                        .def[.s] = .i + 1
                    endif
                endfor
            endfor
            beginPause: "Which file is which task?"
                @baseName: recFolder$
                @wrapComment: "Folder:  " + baseName.result$ + "   (" + string$ (nFolderFiles) + " sound files)"
                comment: "For each task, choose its file, or ""(none)"" if it was not recorded."
                if nPrefilled > 0
                    comment: string$ (nPrefilled) + " file(s) were filled in from their names. Please check them."
                endif
                # The text in parentheses is not part of the field's name.
                @fileMenu: "Vowel 1 (sustained /a/)", .def[1]
                @fileMenu: "Vowel 2 (optional extra take)", .def[2]
                @fileMenu: "Vowel 3 (optional extra take)", .def[3]
                @fileMenu: "Sentence 1", .def[4]
                @fileMenu: "Sentence 2", .def[5]
                @fileMenu: "Sentence 3", .def[6]
                @fileMenu: "Sentence 4", .def[7]
                @fileMenu: "Sentence 5", .def[8]
                @fileMenu: "Sentence 6", .def[9]
                @fileMenu: "Conversation 1 (conversational speech)", .def[10]
                @fileMenu: "Conversation 2 (optional second sample)", .def[11]
            .c = endPause: "Cancel", "One by one...", "Other folder...", "OK", 4, 1
            if .c = 1
                @cancelRun
            elsif .c = 2
                oneByOne = 1
                .done = 1
            elsif .c = 3
                recFolder$ = ""
            else
                .pick[1] = vowel_1
                .pick[2] = vowel_2
                .pick[3] = vowel_3
                .pick[4] = sentence_1
                .pick[5] = sentence_2
                .pick[6] = sentence_3
                .pick[7] = sentence_4
                .pick[8] = sentence_5
                .pick[9] = sentence_6
                .pick[10] = conversation_1
                .pick[11] = conversation_2
                for .s to nSlots
                    if .pick[.s] > 1
                        slotPath$[.s] = recFolder$ + "/" + folderFile$[.pick[.s] - 1]
                    else
                        slotPath$[.s] = ""
                    endif
                endfor
                .done = 1
            endif
        endif
    endwhile
endproc

# One drop-down list: "(none)", then the folder's sound files. Long file
# names are shortened in the middle (the choice is read by position).
procedure fileMenu: .label$, .default
    optionMenu: .label$, .default
        option: "(none)"
        for .i to nFolderFiles
            .name$ = folderFile$[.i]
            if length (.name$) > maxMenuChars
                .name$ = left$ (.name$, 15) + "..." + right$ (.name$, maxMenuChars - 18)
            endif
            option: .name$
        endfor
endproc

# Guess the task from a lowercase file name without its extension, for
# example P001_vowel_a, P001_sentence_1_t2, ah, sentence3, conversation.
# Sets .task$ ("" = no guess) and .take (0 = not given).
procedure classifyName: .base$
    .task$ = ""
    .take = 0
    .n$ = "_" + replace_regex$ (.base$, "[^a-z0-9]+", "_", 0) + "_"
    # A take marker at the end: _t2, _take2, _take_2
    if index_regex (.n$, "_t(ake)?_?[0-9]+_$") > 0
        .take = number (replace_regex$ (.n$, "^.*_t(ake)?_?([0-9]+)_$", "\2", 1))
        .n$ = replace_regex$ (.n$, "_t(ake)?_?[0-9]+_$", "_", 1)
    endif
    if index_regex (.n$, "vowel_?i_|_ee_|_i_") > 0
        # /i/ is not one of the tasks: no guess.
        .task$ = ""
    elsif index_regex (.n$, "sent(ence)?_?[1-6]_") > 0
        .task$ = "sentence_" + replace_regex$ (.n$, "^.*sent(ence)?_?([1-6])_.*$", "\2", 1)
    elsif index_regex (.n$, "conv|extemp|spont|monolog|narrat|sandwich|pbj|family") > 0
        .task$ = "extemporaneous"
    elsif index_regex (.n$, "vowel|sustain|_a+h*[0-9]?_") > 0
        .task$ = "vowel_a"
    endif
endproc

# Put a guessed recording into a free slot of its task: the slot of the
# given take if that is free, otherwise the first free one. Extra files are
# left out (the user can still choose them by hand).
procedure placeInSlot: .task$, .take, .path$
    .placed = 0
    if .take > 0
        for .s to nSlots
            if not .placed and slotTask$[.s] = .task$ and slotTake[.s] = .take and slotPath$[.s] = ""
                slotPath$[.s] = .path$
                .placed = 1
            endif
        endfor
    endif
    for .s to nSlots
        if not .placed and slotTask$[.s] = .task$ and slotPath$[.s] = ""
            slotPath$[.s] = .path$
            .placed = 1
        endif
    endfor
    if .placed
        nPrefilled = nPrefilled + 1
    endif
endproc
