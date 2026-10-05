globals [
  weather                 ; common state of nature, 1..5; 0 before the first round
  number-of-strategies
]

patches-own [
  selected-row-number     ; fixed row, 1..7, from left to right
  income-1-round          ; payoff in the latest completed round
  payoff-history          ; most recent 15 payoffs, oldest to newest
  property-payoffs        ; payoffs included in the current rolling window
  average-property       ; arithmetic mean of property-payoffs
]

;; Seven patches, each permanently assigned to one matrix row.
to setup
  clear-all
  resize-world 0 6 0 0
  set-patch-size 100
  set number-of-strategies 7
  set weather 0

  ask patches [
    set selected-row-number pxcor + 1
    set income-1-round 0
    set payoff-history []
    set property-payoffs []
    set average-property 0
  ]

  update-patch-colours
  reset-ticks
end

;; One state of nature is drawn for all seven crops in each round.
to go
  if number-of-strategies != 7 [ setup ]
  if ticks >= 100 [ stop ]
  set weather draw-from-vector prob-vector
  update-property
  tick
end

;; Store each realised payoff once. Retain 15 observations so increasing
;; the slider during a run can use all available observations in that window.
;; The slider is read on every completed round, including after a live change.
to update-property
  let payoffs payoff-matrix
  ask patches [
    let row item (selected-row-number - 1) payoffs
    set income-1-round item (weather - 1) row
    set payoff-history lput income-1-round payoff-history
    if length payoff-history > 15 [
      set payoff-history but-first payoff-history
    ]

    let periods min (list rolling-window length payoff-history)
    set property-payoffs sublist payoff-history
      (length payoff-history - periods) (length payoff-history)
    set average-property mean property-payoffs
  ]
  update-patch-colours
end

;; Fixed terrain scale: blue below zero, deep green at zero,
;; brown at 40, and red at 80. Values are averages on the payoff scale.
to update-patch-colours
  ask patches [
    set pcolor property-colour average-property
    set plabel-color white
    set plabel (word (item (selected-row-number - 1) crop-names)
      ": " (precision average-property 2))
  ]
end

to-report property-colour [value]
  if value < 0 [
    let depth min (list 1 ((0 - value) / 20))
    report blend-colours [65 140 220] [10 40 135] depth
  ]
  if value <= 40 [
    report blend-colours [0 80 35] [145 85 40] (value / 40)
  ]
  let height min (list 1 ((value - 40) / 40))
  report blend-colours [145 85 40] [205 30 25] height
end

to-report blend-colours [start-colour end-colour fraction]
  report (map [[a b] -> round (a + fraction * (b - a))]
    start-colour end-colour)
end

;; The probabilities are fixed and sum to one.
to-report prob-vector
  report [0.10 0.20 0.25 0.15 0.30]
end

;; Fixed 7 x 5 payoff matrix, transcribed from the supplied image.
;; Rows: crops A..G. Columns: states of nature 1..5.
to-report payoff-matrix
  report [
    [ 10 -10 20 25  60 ]
    [ 11  -1 11 11  11 ]
    [ 55  -5 30 10  35 ]
    [ 80 -20 11 11  11 ]
    [ 75  15 15 -10 15 ]
    [ 65  15 30 30 -10 ]
    [-15   0  5  5   5 ]
  ]
end

to-report crop-names
  report ["A" "B" "C" "D" "E" "F" "G"]
end

to-report draw-from-vector [probabilities]
  let draw random-float 1
  let cumulative 0
  foreach (range length probabilities) [ index ->
    set cumulative cumulative + item index probabilities
    if draw < cumulative [ report index + 1 ]
  ]
  report length probabilities
end
@#$#@#$#@
GRAPHICS-WINDOW
20
170
728
279
-1
-1
100.0
1
14
1
1
1
0
0
0
1
0
6
0
0
0
0
1
Rounds
10.0

TEXTBOX
20
10
840
38
Game against nature: seven fixed crops
20
0.0
1

BUTTON
20
44
108
78
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
118
44
206
78
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
216
44
304
78
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
330
40
455
89
State of nature
ifelse-value (weather = 0) [\"--\"] [weather]
0
1
12

MONITOR
470
40
585
89
Round / 100
ticks
0
1
12

MONITOR
600
40
745
89
Periods averaged
ifelse-value (number-of-strategies = 7) [length [property-payoffs] of patch 0 0] [0]
0
1
12

SLIDER
20
97
310
130
rolling-window
rolling-window
1
15
11.0
1
1
NIL
HORIZONTAL

TEXTBOX
330
98
850
136
Rolling window: 1-15 rounds; changes apply on the next round.\nBefore the window fills, average all available payoffs.
12
0.0
1

TEXTBOX
33
145
128
167
1: Crop A
13
0.0
1

TEXTBOX
133
145
228
167
2: Crop B
13
0.0
1

TEXTBOX
233
145
328
167
3: Crop C
13
0.0
1

TEXTBOX
333
145
428
167
4: Crop D
13
0.0
1

TEXTBOX
433
145
528
167
5: Crop E
13
0.0
1

TEXTBOX
533
145
628
167
6: Crop F
13
0.0
1

TEXTBOX
633
145
728
167
7: Crop G
13
0.0
1

TEXTBOX
20
289
850
311
Patch label = crop and average property in the selected rolling window.
13
0.0
1

TEXTBOX
20
319
195
342
Blue: negative
13
105.0
1

TEXTBOX
205
319
390
342
Deep green: near 0
13
52.0
1

TEXTBOX
400
319
580
342
Brown: high (40)
13
33.0
1

TEXTBOX
590
319
820
342
Red: very high (80)
13
15.0
1

TEXTBOX
20
358
840
385
Fixed payoff matrix, probabilities and winning strategies
17
0.0
1

TEXTBOX
123
396
198
418
Nature 1
12
0.0
1

TEXTBOX
198
396
273
418
Nature 2
12
0.0
1

TEXTBOX
273
396
348
418
Nature 3
12
0.0
1

TEXTBOX
348
396
423
418
Nature 4
12
0.0
1

TEXTBOX
423
396
498
418
Nature 5
12
0.0
1

TEXTBOX
515
396
855
418
Unique winning strategy
13
0.0
1

TEXTBOX
30
430
120
454
1: Crop A
14
0.0
1

TEXTBOX
135
430
195
454
10
14
0.0
1

TEXTBOX
210
430
270
454
-10
14
0.0
1

TEXTBOX
285
430
345
454
20
14
0.0
1

TEXTBOX
360
430
420
454
25
14
0.0
1

TEXTBOX
435
430
495
454
60
14
0.0
1

TEXTBOX
515
430
855
455
Max Expected Value
14
0.0
1

TEXTBOX
30
462
120
486
2: Crop B
14
0.0
1

TEXTBOX
135
462
195
486
11
14
0.0
1

TEXTBOX
210
462
270
486
-1
14
0.0
1

TEXTBOX
285
462
345
486
11
14
0.0
1

TEXTBOX
360
462
420
486
11
14
0.0
1

TEXTBOX
435
462
495
486
11
14
0.0
1

TEXTBOX
515
462
855
487
Maximin
14
0.0
1

TEXTBOX
30
494
120
518
3: Crop C
14
0.0
1

TEXTBOX
135
494
195
518
55
14
0.0
1

TEXTBOX
210
494
270
518
-5
14
0.0
1

TEXTBOX
285
494
345
518
30
14
0.0
1

TEXTBOX
360
494
420
518
10
14
0.0
1

TEXTBOX
435
494
495
518
35
14
0.0
1

TEXTBOX
515
494
855
519
Min Regret
14
0.0
1

TEXTBOX
30
526
120
550
4: Crop D
14
0.0
1

TEXTBOX
135
526
195
550
80
14
0.0
1

TEXTBOX
210
526
270
550
-20
14
0.0
1

TEXTBOX
285
526
345
550
11
14
0.0
1

TEXTBOX
360
526
420
550
11
14
0.0
1

TEXTBOX
435
526
495
550
11
14
0.0
1

TEXTBOX
515
526
855
551
Maximax
14
0.0
1

TEXTBOX
30
558
120
582
5: Crop E
14
0.0
1

TEXTBOX
135
558
195
582
75
14
0.0
1

TEXTBOX
210
558
270
582
15
14
0.0
1

TEXTBOX
285
558
345
582
15
14
0.0
1

TEXTBOX
360
558
420
582
-10
14
0.0
1

TEXTBOX
435
558
495
582
15
14
0.0
1

TEXTBOX
515
558
855
583
Hurwicz (alpha=0.5)
14
0.0
1

TEXTBOX
30
590
120
614
6: Crop F
14
0.0
1

TEXTBOX
135
590
195
614
65
14
0.0
1

TEXTBOX
210
590
270
614
15
14
0.0
1

TEXTBOX
285
590
345
614
30
14
0.0
1

TEXTBOX
360
590
420
614
30
14
0.0
1

TEXTBOX
435
590
495
614
-10
14
0.0
1

TEXTBOX
515
590
855
615
Laplace
14
0.0
1

TEXTBOX
30
622
120
646
7: Crop G
14
0.0
1

TEXTBOX
135
622
195
646
-15
14
0.0
1

TEXTBOX
210
622
270
646
0
14
0.0
1

TEXTBOX
285
622
345
646
5
14
0.0
1

TEXTBOX
360
622
420
646
5
14
0.0
1

TEXTBOX
435
622
495
646
5
14
0.0
1

TEXTBOX
515
622
855
647
Target attainment (payoff >= 0)
14
0.0
1

TEXTBOX
30
670
130
694
Probability
14
0.0
1

TEXTBOX
135
670
195
694
10%
14
0.0
1

TEXTBOX
210
670
270
694
20%
14
0.0
1

TEXTBOX
285
670
345
694
25%
14
0.0
1

TEXTBOX
360
670
420
694
15%
14
0.0
1

TEXTBOX
435
670
495
694
30%
14
0.0
1

TEXTBOX
515
661
855
705
Min Regret = minimax regret.\nTarget attainment uses the given probabilities.
12
0.0
1

TEXTBOX
20
721
855
781
Every crop keeps its row and faces the same state of nature.\nThe run stops at round 100. Setup clears the history and plots.\nColours use fixed property values, so they remain comparable across rounds.
12
0.0
1

TEXTBOX
890
10
1590
38
Average property by strategy
17
0.0
1

TEXTBOX
890
40
1590
64
Common axes: rounds 0-100; average property -20 to 80. Grey line = zero.
12
0.0
1

PLOT
890
74
1230
274
1 / A: Max Expected Value
Round
Average property
0.0
100.0
-20.0
80.0
false
false
"" ""
PENS
"Zero" 1.0 0 -7500403 true "" "plotxy ticks 0"
"Average property" 1.0 0 -13345367 true "" "plotxy ticks [average-property] of patch 0 0"

PLOT
1245
74
1585
274
2 / B: Maximin
Round
Average property
0.0
100.0
-20.0
80.0
false
false
"" ""
PENS
"Zero" 1.0 0 -7500403 true "" "plotxy ticks 0"
"Average property" 1.0 0 -13345367 true "" "plotxy ticks [average-property] of patch 1 0"

PLOT
890
289
1230
489
3 / C: Min Regret
Round
Average property
0.0
100.0
-20.0
80.0
false
false
"" ""
PENS
"Zero" 1.0 0 -7500403 true "" "plotxy ticks 0"
"Average property" 1.0 0 -13345367 true "" "plotxy ticks [average-property] of patch 2 0"

PLOT
1245
289
1585
489
4 / D: Maximax
Round
Average property
0.0
100.0
-20.0
80.0
false
false
"" ""
PENS
"Zero" 1.0 0 -7500403 true "" "plotxy ticks 0"
"Average property" 1.0 0 -13345367 true "" "plotxy ticks [average-property] of patch 3 0"

PLOT
890
504
1230
704
5 / E: Hurwicz (alpha=0.5)
Round
Average property
0.0
100.0
-20.0
80.0
false
false
"" ""
PENS
"Zero" 1.0 0 -7500403 true "" "plotxy ticks 0"
"Average property" 1.0 0 -13345367 true "" "plotxy ticks [average-property] of patch 4 0"

PLOT
1245
504
1585
704
6 / F: Laplace
Round
Average property
0.0
100.0
-20.0
80.0
false
false
"" ""
PENS
"Zero" 1.0 0 -7500403 true "" "plotxy ticks 0"
"Average property" 1.0 0 -13345367 true "" "plotxy ticks [average-property] of patch 5 0"

PLOT
890
719
1230
919
7 / G: Target attainment (>= 0)
Round
Average property
0.0
100.0
-20.0
80.0
false
false
"" ""
PENS
"Zero" 1.0 0 -7500403 true "" "plotxy ticks 0"
"Average property" 1.0 0 -13345367 true "" "plotxy ticks [average-property] of patch 6 0"

@#$#@#$#@
## WHAT IS IT?

Seven fixed crop choices in a game against nature. The world contains exactly
seven patches in one horizontal row. From left to right, patches represent
rows 1 to 7 (crops A to G) of the payoff matrix. A patch never changes its row.

## HOW IT WORKS

Each round draws one common state of nature for all seven patches, with fixed
probabilities [0.10 0.20 0.25 0.15 0.30]. The realised payoff is the entry at
the patch's fixed row and the drawn column.

The **rolling-window** slider takes integer values
from 1 to 15 and defaults to 5. Property, stored as `average-property`, is the
arithmetic mean of the payoffs in the selected rolling window. At round t,
the number of included observations is k = min(rolling-window, t), and the
property is the sum of those k latest realised payoffs divided by k.

Before any round, property is displayed as zero. During the first rounds,
the denominator is the number of available observations, not the full slider
value. Negative payoffs and negative averages are retained. Labels round the
displayed mean to two decimal places; the calculation and plots retain full
precision. With a window of one, property equals the current round's payoff.

`payoff-history` retains the last 15 observations, while `property-payoffs`
contains only the observations used in the current mean. Increasing the
window can therefore recover earlier observations even if a smaller window
was used previously. Slider changes take effect on the next completed round.
The **Periods averaged** monitor shows the number actually used in the latest
calculation. Earlier plot points retain the window used when they were drawn.
For a single constant window throughout a run, set the slider before Setup.

Each payoff is used once in each applicable average. There is no discounting,
decay, reinforcement learning, experimentation, or strategy switching.

## PATCH COLOURS

The terrain uses a fixed scale in payoff units, independent of the window
length and of the other patches' property:

* Every negative average is blue; larger losses have a deeper blue shade.
* Zero is deep green. Small non-negative averages remain near deep green.
* Positive values gradually move towards brown at 40.
* Values above 40 progress from brown towards red at 80.

The payoff matrix bounds all possible rolling averages between -20 and 80.
Equal averages always have equal colours, across strategies and across rounds.
The scale does not rescale to the current minimum and maximum across patches.

## FIXED DATA

The matrix and probabilities are stored as constants in `payoff-matrix` and
`prob-vector`. The Interface shows them as static text, without input boxes,
probability sliders, or probability-normalisation controls. Only the rolling
window length is adjustable through a slider.

| Crop / row | Nature 1 | Nature 2 | Nature 3 | Nature 4 | Nature 5 |
|------------|----------|----------|----------|----------|----------|
| A / 1 | 10 | -10 | 20 | 25 | 60 |
| B / 2 | 11 | -1 | 11 | 11 | 11 |
| C / 3 | 55 | -5 | 30 | 10 | 35 |
| D / 4 | 80 | -20 | 11 | 11 | 11 |
| E / 5 | 75 | 15 | 15 | -10 | 15 |
| F / 6 | 65 | 15 | 30 | 30 | -10 |
| G / 7 | -15 | 0 | 5 | 5 | 5 |
| Probability | 10% | 20% | 25% | 15% | 30% |

## UNIQUE WINNING STRATEGIES

The labels to the right of the matrix identify the unique row selected by
each decision criterion for the fixed matrix and probabilities.

| Row / crop | Criterion | Winning criterion value |
|------------|-----------|-------------------------|
| 1 / A | Max Expected Value | 25.75 |
| 2 / B | Maximin | -1 (minimum payoff) |
| 3 / C | Min Regret (minimax regret) | 25 (maximum regret) |
| 4 / D | Maximax | 80 (maximum payoff) |
| 5 / E | Hurwicz (alpha=0.5) | 32.5 |
| 6 / F | Laplace | 26 |
| 7 / G | Target attainment (payoff >= 0) | 0.90 |

Expected value weights each payoff by its state probability. Maximin
maximises the row minimum; maximax maximises the row maximum. Minimax regret
minimises the largest difference between the column maximum and the row's
payoff. Hurwicz uses 0.5 times the row maximum plus 0.5 times its minimum.
Laplace averages the five payoffs with equal weights, irrespective of the
given probabilities. Target attainment maximises the probability of a
non-negative payoff, using the given probabilities.

Crop C is the unique minimax-regret choice, and crop D the unique maximax
choice. The criteria identify fixed rows; the simulation does not reselect
strategies or optimise the realised rolling average property during a run.

## HOW TO USE IT

1. Choose a window length from 1 to 15 using the slider.
2. Click **Setup** to reset the model; the selected slider value is preserved.
3. Click **Step** for one round or **Go** to run continuously.
4. Observe average property in the patch labels, terrain colours and plots.
5. Adjust the slider during the run if desired; the next round uses its new value.

The run stops at exactly 100 completed rounds. Further Step or Go calls do
not advance it. Click Setup to begin another run and clear history and plots.
A slider change after the completed run requires a new run to take effect.

Seven separate plots are arranged in two columns to the right of the World
and matrix. Each shows one strategy's rolling average property against rounds.
The initial point is (0,0); a point is added after each round through round 100.
All plots use the same fixed axes: rounds 0 to 100 and average property -20 to
80. The grey reference line is zero.

## IMPLEMENTATION

Prepared for NetLogo 6.4.0, using built-in primitives only. No extensions or
external data files are required. The matrix and probability values remain
those supplied with the original requested revision of ProtiPrirode.nlogo.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
setup
repeat 5 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
