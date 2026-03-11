; =====================================================
; COMMON POOL RESOURCE GAME
; 4 agents with Roth–Erev learning
; Agents fixed in the four corners
;
; Payoff function:
; pi_i = 6 + x_i (10 - X)
; X = total effort of the 4 players
; Effort choices = {0 1 2 3}
; =====================================================

globals [
  total-effort
  total-payoff
  average-effort
  average-payoff
  effort-options
  gini-index
  mean-prob-divergence
  mean-prob-entropy
  ema-effort ; exponential moving averages
  ema-payoff
  ema-entropy
  ema-divergence
  payoff-range
  ema-payoff-range
  total-tax-revenue
]

turtles-own [
  propensities
  chosen-effort
  payoff
  cumulative-payoff
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set effort-options [0 1 2 3]

  create-turtles 4 [
    set shape "person"
    set size 4
    set color blue

    set propensities (list initial-propensity initial-propensity initial-propensity initial-propensity)
    set chosen-effort 0
    set payoff 0
    set cumulative-payoff 0
  ]

  ; place turtles in corners
  ask turtle 0 [ setxy ( min-pxcor + 2 ) ( max-pycor - 2 ) ]
  ask turtle 1 [ setxy ( max-pxcor - 2 ) ( max-pycor - 2 ) ]
  ask turtle 2 [ setxy ( min-pxcor + 2 ) ( min-pycor + 2 ) ]
  ask turtle 3 [ setxy ( max-pxcor - 2 ) ( min-pycor + 2 ) ]
  set-current-plot "Effort Convergence"
  clear-plot
  set-current-plot "Mean probabilities"
  clear-plot
  set-current-plot "Wealth Inequality"
  clear-plot
  set-current-plot "Payoff Range"
  clear-plot

  set ema-effort 0
  set ema-payoff 0
  set ema-entropy 0
  set ema-divergence 0
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MAIN LOOP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go

  ; choose effort
  ask turtles [
    choose-effort
  ]

  ; compute total effort
  set total-effort sum [chosen-effort] of turtles

  ; compute payoffs
  ask turtles [
    set payoff (6 + chosen-effort * (10 - total-effort) - tax * chosen-effort)
    if payoff < 0 [ set payoff 0 ]
    set cumulative-payoff cumulative-payoff + payoff
  ]
  compute-gini

  ; learning update
  ask turtles [
    update-propensities
  ]

    ; statistics
  set total-tax-revenue sum [tax * chosen-effort] of turtles
  set total-payoff sum [payoff] of turtles
  set average-effort mean [chosen-effort] of turtles
  set average-payoff mean [payoff] of turtles
  set payoff-range (max [payoff] of turtles) - (min [payoff] of turtles)

  ; smoothed averages
  let λ ema-recency

  set ema-effort λ * ema-effort + (1 - λ) * average-effort
  set ema-payoff λ * ema-payoff + (1 - λ) * average-payoff
  set ema-entropy λ * ema-entropy + (1 - λ) * mean-prob-entropy
  set ema-divergence λ * ema-divergence + (1 - λ) * mean-prob-divergence
  set ema-payoff-range λ * ema-payoff-range + (1 - λ) * payoff-range

  ; plot average effort with benchmarks
  set-current-plot "Effort Convergence"
  set-current-plot-pen "Average effort"
  plot average-effort
  set-current-plot-pen "Nash"
  plot 2
  set-current-plot-pen "Social optimum"
  plot 1.25
  set-current-plot-pen "MAeffort"
  plot ema-effort


  ; Plot mean probabilities of choosing each effort

  set-current-plot "Mean probabilities"

  set-current-plot-pen "p0"
  plot mean [ item 0 normalize propensities ] of turtles

  set-current-plot-pen "p1"
  plot mean [ item 1 normalize propensities ] of turtles

  set-current-plot-pen "p2"
  plot mean [ item 2 normalize propensities ] of turtles

  set-current-plot-pen "p3"
  plot mean [ item 3 normalize propensities ] of turtles
    ; changing the seizes of the turtles based on their relative cummulative payoffs

; plot gini

  set-current-plot "Wealth Inequality"
  set-current-plot-pen "gini"
  plot gini-index

;  plot payoff range

  set-current-plot "Payoff Range"
  set-current-plot-pen "range"
  plot payoff-range
  set-current-plot-pen "MArange"
  plot ema-payoff-range


  compute-probability-divergence
  set-current-plot "Probability Divergence"
  set-current-plot-pen "divergence"
  plot mean-prob-divergence
  set-current-plot-pen "MAdivergence"
  plot ema-divergence

  compute-probability-entropy

  set-current-plot "Mean Probability Entropy"
  set-current-plot-pen "entropy"
  plot mean-prob-entropy
  set-current-plot-pen "MAentropy"
  plot ema-entropy

  update-turtle-sizes

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CHOICE OF EFFORT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to choose-effort

  let probs normalize propensities
  let r random-float 1
  let cumulative 0
  let index 0

  while [index < length probs] [
    set cumulative cumulative + item index probs
    if r <= cumulative [
      set chosen-effort item index effort-options
      set index length probs
    ]
    if index < length probs [ set index index + 1 ]
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ROTH-EREV LEARNING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-propensities

  let m length effort-options
  let action-index position chosen-effort effort-options
  let new-q []

  let i 0
  while [i < m]

  [
    let old-q item i propensities
    let base (1 - phi) * old-q

    let reinforcement 0

    if i = action-index [
      set reinforcement (1 - epsilon) * payoff
    ]

    if i != action-index [
      set reinforcement (epsilon * payoff) / (m - 1)
    ]

    let updated base + reinforcement

    if updated < 0.0001 [ set updated 0.0001 ]

    set new-q lput updated new-q

    set i i + 1
  ]

  set propensities new-q

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report normalize [lst]
  let s sum lst
  if s <= 0 [
    report n-values (length lst) [1 / (length lst)]
  ]
  report map [ x -> x / s ] lst
end

  to update-turtle-sizes

    let max-payoff max [cumulative-payoff] of turtles

    ask turtles [

      if max-payoff > 0 [
        let relative cumulative-payoff / max-payoff
        set size 1 + 4 * relative
      ]

    ]

  end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  wealth inequality
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to compute-gini

  let wealths sort [cumulative-payoff] of turtles
  let n length wealths
  let total sum wealths

  if total = 0 [
    set gini-index 0
    stop
  ]

  let cumulative 0
  let weighted-sum 0
  let i 1

  foreach wealths [ w ->
    set cumulative cumulative + w
    set weighted-sum weighted-sum + i * w
    set i i + 1
  ]

  set gini-index ((2 * weighted-sum) / (n * total)) - ((n + 1) / n)

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   compute probability divergences
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to compute-probability-divergence

  let probs [ normalize propensities ] of turtles
  let n length probs
  let distances []

  let i 0
  while [i < n] [
    let j (i + 1)
    while [j < n] [
      let p_i item i probs
      let p_j item j probs
      set distances lput (euclidean-distance p_i p_j) distances
      set j j + 1
    ]
    set i i + 1
  ]

ifelse empty? distances
[ set mean-prob-divergence 0 ]
[ set mean-prob-divergence mean distances ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  to compute euclidean distances
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report euclidean-distance [v1 v2]
  let s 0
  let i 0
  while [i < length v1] [
    let diff ((item i v1) - (item i v2))
    set s s + diff * diff
    set i i + 1
  ]
  report sqrt s
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Entropy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to compute-probability-entropy
  let probs [ normalize propensities ] of turtles
  let entropies map [ p -> vector-entropy p ] probs
  ifelse empty? entropies
  [ set mean-prob-entropy 0 ]
  [ set mean-prob-entropy mean entropies ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    normalization of the entropy on the interval [0,1]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report vector-entropy [p]
  let h 0
  let i 0
  while [i < length p] [
    let pk item i p
    if pk > 0 [
      set h h - pk * ln pk
    ]
    set i i + 1
  ]
  report h / ln(length p)
end
@#$#@#$#@
GRAPHICS-WINDOW
233
24
670
462
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
5
20
72
53
setup
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
86
21
149
54
go
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

SLIDER
25
70
197
103
initial-propensity
initial-propensity
0.1
20
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
24
127
196
160
phi
phi
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
24
182
196
215
epsilon
epsilon
0
1
0.05
0.01
1
NIL
HORIZONTAL

MONITOR
165
466
271
511
round-number
ticks
0
1
11

MONITOR
296
465
376
510
total-effort
total-effort
1
1
11

MONITOR
404
465
489
510
total-payoff
total-payoff
17
1
11

MONITOR
515
465
616
510
average-effort
average-effort
2
1
11

MONITOR
636
464
741
509
average-payoff
average-payoff
2
1
11

PLOT
765
175
1535
325
Average Payoff
NIL
NIL
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Average payoff" 1.0 0 -987046 true "" "plot average-payoff"
"MApayoff" 1.0 0 -5987164 true "" "plot ema-payoff"
"Social optimum" 1.0 0 -13840069 true "" "plot 12.25"
"Nash" 1.0 0 -2674135 true "" "plot 10"

PLOT
765
342
1536
492
Mean probabilities
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"p0" 1.0 0 -7500403 true "" ""
"p1" 1.0 0 -2674135 true "" ""
"p2" 1.0 0 -955883 true "" ""
"p3" 1.0 0 -6459832 true "" ""

PLOT
765
10
1533
160
Effort Convergence
Round
Effort
0.0
100.0
0.0
3.0
true
true
"" ""
PENS
"Average effort" 1.0 0 -987046 true "" ""
"Nash" 1.0 0 -2674135 true "" ""
"Social optimum" 1.0 0 -11085214 true "" ""
"MAeffort" 1.0 0 -7500403 true "" ""

TEXTBOX
12
347
162
449
Gini coefficient\n0.00 → perfectly equal\n0.10 → very equal\n0.30 → moderate inequality\n0.50 → strong inequality
12
0.0
1

MONITOR
147
398
221
443
NIL
gini-index
17
1
11

PLOT
22
517
733
667
Wealth Inequality
NIL
NIL
0.0
10.0
0.0
0.25
true
false
"" ""
PENS
"gini" 1.0 0 -2674135 true "" ""

PLOT
767
668
1539
818
Probability Divergence
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"divergence" 1.0 0 -987046 true "" ""
"MAdivergence" 1.0 0 -7500403 true "" ""

PLOT
765
509
1539
659
Mean Probability Entropy
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"entropy" 1.0 0 -987046 true "" ""
"MAentropy" 1.0 0 -7500403 true "" ""

SLIDER
24
284
196
317
ema-recency
ema-recency
0.5
0.995
0.98
0.005
1
NIL
HORIZONTAL

BUTTON
160
21
223
54
go
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

PLOT
22
670
732
820
Payoff Range
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"range" 1.0 0 -2674135 true "" ""
"MArange" 1.0 0 -7500403 true "" ""

SLIDER
23
232
195
265
tax
tax
0
5
0.0
0.1
1
NIL
HORIZONTAL

MONITOR
40
465
158
510
total-tax-revenue
total-tax-revenue
17
1
11

@#$#@#$#@
Common Pool Resource Model with Reinforcement Learning
## WHAT IS IT

This model simulates the Tragedy of the Commons in a Common Pool Resource (CPR) environment.

Four agents exploit a shared resource by choosing an effort level in each round. The total extraction reduces the productivity of the resource. If agents extract too much, the collective outcome becomes inefficient.

Agents do not compute the optimal strategy analytically. Instead, they learn using a Roth–Erev reinforcement learning algorithm, adjusting their probabilities of choosing different effort levels according to past payoffs.

The model demonstrates how decentralized learning can lead to outcomes close to the Nash equilibrium, which typically involves excessive extraction compared with the social optimum.

## HOW IT WORKS

Each round of the simulation proceeds as follows.

Each agent chooses an effort level from the discrete set

0, 1, 2, 3

based on a probability distribution derived from its propensities.

Total effort is computed

X = sum of all agents' efforts.

Each agent receives a payoff

π_i = c(E − x_i) + x_i(a − bX) − t x_i

where

x_i = effort of agent i
X = total effort
E = effort endowment
c = opportunity cost parameter
a,b = resource productivity parameters
t = tax per unit of effort

Propensities are updated using the Roth–Erev learning rule.

Chosen actions receive reinforcement proportional to their payoff, while unchosen actions may receive small reinforcement through exploration.

Probabilities are obtained by normalizing propensities.

The process repeats over many rounds.

## MATHEMATICAL BACKGROUND

The shared resource follows the quadratic production function

B(X) = aX − bX²

so the average return to effort is

a − bX.

The individual payoff is

π_i = c(E − x_i) + x_i(a − bX).

Social Optimum

A social planner maximizes

B(X) − cX.

The first-order condition gives

X* = (a − c) / (2b).

Nash Equilibrium

In a symmetric Nash equilibrium with N users,

x_i^NE = (a − c) / ((N + 1)b)

and total effort becomes

X^NE = N x_i^NE.

As the number of users increases, total extraction approaches

2X*,

illustrating the tragedy of the commons.

## MODEL PARAMETERS

Default classroom parameters:

a = 12
b = 1
c = 2
E = 3
N = 4

Under these parameters:

Social optimum total effort:

X* = 5

Nash equilibrium individual effort:

x_i^NE = 2

Total Nash effort:

X^NE = 8

Thus the Nash equilibrium leads to excessive extraction relative to the efficient level.

## INTERFACE ELEMENTS
Buttons

setup
initializes agents and learning parameters.

go
runs the simulation.

Sliders

initial-propensity
initial value of propensities for each action.

phi
learning rate in the Roth–Erev reinforcement rule.

epsilon
exploration parameter controlling experimentation.

tax
per-unit tax on effort.

ema-recency
recency parameter for exponential moving averages used in plots.

MONITORS

The interface displays several indicators:

round-number
current simulation round.

total-effort
sum of all agents' efforts.

total-payoff
sum of all agents' payoffs.

average-effort
mean effort per agent.

average-payoff
mean payoff per agent.

gini-index
inequality of cumulative payoffs.

total-tax-revenue
tax revenue collected from agents.

PLOTS

Effort Convergence
Shows the evolution of average effort together with the theoretical Nash equilibrium and social optimum.

Average Payoff
Shows the average payoff across agents.

Mean Probabilities
Shows the average probability of choosing each effort level.

Mean Probability Entropy
Measures the uncertainty of agents' strategies.
Higher entropy means more exploration.

Probability Divergence
Measures differences between agents’ probability distributions.

Wealth Inequality
Displays the Gini coefficient of cumulative payoffs.

Payoff Range
Shows the difference between the highest and lowest payoff in each round.

## THINGS TO TRY

Run the model with tax = 0 and observe convergence toward the Nash equilibrium.

Increase the tax parameter and observe how extraction decreases.

Increase epsilon to introduce more exploration and observe slower convergence.

Observe how inequality evolves using the Gini coefficient.

Compare outcomes under different learning parameters.

## EXTENDING THE MODEL

Possible extensions include:

introducing quotas instead of taxes

allowing communication between agents

varying the number of agents

introducing heterogeneous learning parameters

adding spatial commons

comparing different learning algorithms.

##RELATED MODELS

This model relates to the classic theory of the Tragedy of the Commons and to experimental research on Common Pool Resource games.

## REFERENCES

Hardin, G. (1968). The Tragedy of the Commons. Science, 162, 1243–1248.

Walker, J., Gardner, R., and Ostrom, E. (1990). Rent Dissipation in a Limited-Access Common-Pool Resource. Journal of Environmental Economics and Management.

Holt, C. (2007). Markets, Games, and Strategic Behavior. Pearson.

Roth, A. and Erev, I. (1995). Learning in Extensive-Form Games. Games and Economic Behavior.

## CREDITS

Model developed for teaching microeconomics, experimental economics, and agent-based modeling at the Faculty of Management, Comenius University in Bratislava.

The model combines:

Common Pool Resource theory
Roth–Erev reinforcement learning
visualization of learning dynamics, inequality, and strategy diversity.
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
