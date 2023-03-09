breed [vacuums vacuum] ; We need to create a path for the vacuum agent...
breed [dirts dirt]     ;  so that it can reach the dirt agent.

patches-own [
  visited ; Once the patch has been visited by the search method, usually, we do not want to re-visit it. In the setup, this variable is initialised to false.
  parent  ; We use parent for recovering the path once the goal has been found (and for calculating g (i.e. the cost of reaching the node/patch from the start location))
  path-cost ; When you implement greedy and a*, if you do not want to re-calculate g (the cost of reaching the node/patch from the start location), they you could use a path-cost variable.
]

globals [ clear_color ; A constant. We use the color 68 for empty squares. You might want to use this constant rather than using 68 (in case you decide to change the background color).
          wall_color  ; A constant.
          planned_path ; The path the vacuum agent should follow to reach the dirt turtle.
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Setup methods for the various types of agents ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
;; Called from the setup-world button.
;; - Adds walls and clear/empty space
;; - Adds a dirt turtle and a vacuum turtle
to standard-setup
  clear-all
  set clear_color 68
  set wall_color 0
  ask patches [set pcolor clear_color]
  add-walls

  ; Setup turtles:
  create-dirts 1 [
    let p one-of patches with [pcolor = clear_color] ; add 1 dirt to a random clear/empty patch
    setxy [pxcor] of p [pycor] of  p
    ;setxy 18 -9
    set shape "tile stones"
    set color 34
  ]
  create-vacuums 1 [  ; add 1 vacuum to a random clear/empty patch
    let p one-of patches with [pcolor = clear_color]
    setxy [pxcor] of p [pycor] of  p
    ;setxy -5 19
    set shape "turtle"
  ]

  reset-patches
  reset-ticks
end


to add-walls
  ask patches with [pxcor = max-pxcor or pycor = max-pycor or pxcor = min-pxcor or pycor = min-pycor] [set pcolor wall_color]
  ask patches with [pxcor = 3 or pxcor = -3 ] [set pcolor wall_color]

  ask patches with [pycor = 10 and (pxcor > 3 or pxcor < -3 )] [set pcolor wall_color]
  ask patches with [pycor = 14 or pycor = 15 or pycor = 16 and (pxcor = 3 or pxcor = -3 )] [set pcolor clear_color]

  ask patches with [pycor = 0 and (pxcor > 3 or pxcor < -3 )] [set pcolor wall_color]
  ask patches with [pycor = 4 or pycor = 5 or pycor = 6 and (pxcor = 3 or pxcor = -3 )] [set pcolor clear_color]

  ask patches with [pycor = -10 and (pxcor > 3 or pxcor < -3 )] [set pcolor wall_color]
  ask patches with [pycor = -4 or pycor = -5 or pycor = -6 and (pxcor = 3 or pxcor = -3 )] [set pcolor clear_color]

  ask patches with [pycor = -14 or pycor = -15 or pycor = -16 and (pxcor = 3 or pxcor = -3 )] [set pcolor clear_color]
end


to reset-patches
  ask patches [ ;set path-cost -1 ; if you use a path-cost varable you might want to reset it here.
               set visited false
               set parent nobody ]
end

;-----------------------------------------


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; depth-first search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;
;; Executed when the plan-depth-first button is pressed.
;;  - Calls depth-first-search and sets planned_path to the result.
;;  - Changes the color of all patches in the planned_path to red.
to plan-depth-first
  set planned_path depth-first-search
  show planned_path
  foreach planned_path [path_patch -> ask path_patch [ set pcolor 18 ] ]
  stop
end

;;;;;;;;;;;;;;;;;;
;; Performs depth-first-search to find a path from the vacuum agent to the dirt.
to-report depth-first-search
  let start_location [patch-here] of one-of vacuums ;; get the start patch
  let goal_location [patch-here] of one-of dirts    ;; get the goal patch

  if start_location = goal_location [ report recover-plan goal_location  ] ;; perform goal test. If the goal has been reached, we need to recover the patches/nodes that were visited on the way to the goal.
  let frontiers (list start_location) ;; initialise frontiers LIFO (Last in, First out) stack. Note: we are just treating patches as nodes (we do not create a seperate Node object).
                                      ;; We add to the back and remove from the back of our LIFO stack.
  loop [
    if empty? frontiers [ ;; frontiers is empty; no path has been found.
      show "Failed to find a valid path."
      report (list )
    ]
    let node last frontiers   ; get the last node from frontiers
    set frontiers remove-item (length frontiers - 1) frontiers   ; remove the last node from frontiers
    ask node [set visited true] ;; Node has been explored/visited.
    ask node [set pcolor 108]   ;; Sets color of the patch/node. All visited nodes/patches have a pcolor of 108.
    ;show node
    ;; valid-next-patches is a function (found towards the end of this file) that returns all the patches the agent can reach from node.
    ;; In python the line below would be: for valid_next_patch in node.valid-next-patches():
    foreach [valid-next-patches] of node [ valid_next_patch ->
      ;; if we have not visited valid_next_patch and valid_next_patch is not in frontiers:
      if (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [
        ask valid_next_patch [set parent node] ;; set node to be the parent of valid_next_patch (so we can recover the plan).
        if valid_next_patch = goal_location [report recover-plan goal_location ]  ;; Perform goal test
        set frontiers lput valid_next_patch frontiers  ;; insert valid_next_patch into frontiers
        ask valid_next_patch [set pcolor 78]   ;; all the patches in our frontiers stack have a pcolor of 78
      ]
    ]
    tick
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; breadth-first search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plan-breadth-first
  set planned_path breadth-first-search
  show planned_path
  foreach planned_path [path_patch -> ask path_patch [ set pcolor 18 ] ]
  stop
end

;;;;;;;;;;;;;;;;;;
;; Performs breadth-first-search to find a path from the vacuum agent to the dirt.
to-report breadth-first-search
  let start_location [patch-here] of one-of vacuums ;; get the start patch
  let goal_location [patch-here] of one-of dirts    ;; get the goal patch

  if start_location = goal_location [ report recover-plan goal_location  ] ;; perform goal test. If the goal has been reached, we need to recover the patches/nodes that were visited on the way to the goal.
  let frontiers (list start_location) ;; initialise frontiers FIFO (Last in, First out) queue.
                                      ;; We add to the back and remove from the front of our FIFO queue.
  loop [
    if empty? frontiers [ ;; frontiers is empty; no path has been found.
      show "Failed to find a valid path."
      report (list )
    ]
    let node first frontiers   ; get the first node from frontiers
    set frontiers remove-item 0 frontiers   ; remove the first node from frontiers
    ask node [set visited true] ;; Node has been explored/visited.
    ask node [set pcolor 108]   ;; Sets color of the patch/node. All visited nodes/patches have a pcolor of 108.
    ;show node
    ;; valid-next-patches is a function (found towards the end of this file) that returns all the patches the agent can reach from node.
    ;; In python the line below would be: for valid_next_patch in node.valid-next-patches():
    foreach [valid-next-patches] of node [ valid_next_patch ->
      ;; if we have not visited valid_next_patch and valid_next_patch is not in frontiers:
      if (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [
        ask valid_next_patch [set parent node] ;; set node to be the parent of valid_next_patch (so we can recover the plan).
        if valid_next_patch = goal_location [report recover-plan goal_location ]  ;; Perform goal test
        set frontiers lput valid_next_patch frontiers  ;; insert valid_next_patch into frontiers
        ask valid_next_patch [set pcolor 78]   ;; all the patches in our frontiers stack have a pcolor of 78
      ]
    ]
    tick
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; greedy best-first search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plan-greedy-best-first
  set planned_path greedy-best-first-search
  show planned_path
  foreach planned_path [path_patch -> ask path_patch [ set pcolor 18 ] ]
  stop
end

to-report greedy-best-first-search
  let start_location [patch-here] of one-of vacuums ;; get the start patch
  let goal_location [patch-here] of one-of dirts    ;; get the goal patch

  if start_location = goal_location [ report recover-plan goal_location  ] ;; perform goal test. If the goal has been reached, we need to recover the patches/nodes that were visited on the way to the goal.
  let frontiers (list start_location) ;; initialise frontiers priority queue, ordered by path cost
  loop [
    if empty? frontiers [ ;; frontiers is empty; no path has been found.
      show "Failed to find a valid path."
      report (list )
    ]
    set frontiers sort-by [ [f1 f2] ->
      [distance goal_location] of f1 <
      [distance goal_location] of f2 ]
        frontiers; sort the frontiers
    let node first frontiers   ; get the first node from frontiers
    let cost [path-cost] of node
    set frontiers remove-item 0 frontiers   ; remove the first node from frontiers
    if node = goal_location [report recover-plan node ]  ;; Perform goal test
    ask node [set visited true] ;; Node has been explored/visited.
    ask node [set pcolor 108]   ;; Sets color of the patch/node. All visited nodes/patches have a pcolor of 108.
    ;show node
    ;; valid-next-patches is a function (found towards the end of this file) that returns all the patches the agent can reach from node.
    ;; In python the line below would be: for valid_next_patch in node.valid-next-patches():
    foreach [valid-next-patches] of node [ valid_next_patch ->
      ;; if we have not visited valid_next_patch and valid_next_patch is not in frontiers:
      ifelse (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [
        ask valid_next_patch [
          set parent node
          set path-cost cost + 1
        ] ;; set node to be the parent of valid_next_patch (so we can recover the plan).
        set frontiers lput valid_next_patch frontiers  ;; insert valid_next_patch into frontiers
        ask valid_next_patch [set pcolor 78]   ;; all the patches in our frontiers stack have a pcolor of 78
      ][
        if (member? valid_next_patch frontiers) and ([path-cost] of valid_next_patch < cost + 1) [
          ask valid_next_patch [
            set parent node
            set path-cost cost + 1
          ] ;; set node to be the new parent of valid_next_patch.
        ]
      ]
    ]
    tick
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; uniform-cost search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plan-uniform-cost
  set planned_path uniform-cost-search
  show planned_path
  foreach planned_path [path_patch -> ask path_patch [ set pcolor 18 ] ]
  stop
end

to-report uniform-cost-search
  let start_location [patch-here] of one-of vacuums ;; get the start patch
  let goal_location [patch-here] of one-of dirts    ;; get the goal patch

  if start_location = goal_location [ report recover-plan goal_location  ] ;; perform goal test. If the goal has been reached, we need to recover the patches/nodes that were visited on the way to the goal.
  let frontiers (list start_location) ;; initialise frontiers priority queue, ordered by path cost
  loop [
    if empty? frontiers [ ;; frontiers is empty; no path has been found.
      show "Failed to find a valid path."
      report (list )
    ]
    set frontiers sort-by [ [f1 f2] -> [path-cost] of f1 < [path-cost] of f2] frontiers; sort the frontiers
    let node first frontiers   ; get the first node from frontiers
    let cost [path-cost] of node
    set frontiers remove-item 0 frontiers   ; remove the first node from frontiers
    if node = goal_location [report recover-plan node ]  ;; Perform goal test
    ask node [set visited true] ;; Node has been explored/visited.
    ask node [set pcolor 108]   ;; Sets color of the patch/node. All visited nodes/patches have a pcolor of 108.
    ;show node
    ;; valid-next-patches is a function (found towards the end of this file) that returns all the patches the agent can reach from node.
    ;; In python the line below would be: for valid_next_patch in node.valid-next-patches():
    foreach [valid-next-patches] of node [ valid_next_patch ->
      ;; if we have not visited valid_next_patch and valid_next_patch is not in frontiers:
      ifelse (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [
        ask valid_next_patch [
          set parent node
          set path-cost cost + 1
        ] ;; set node to be the parent of valid_next_patch (so we can recover the plan).
        set frontiers lput valid_next_patch frontiers  ;; insert valid_next_patch into frontiers
        ask valid_next_patch [set pcolor 78]   ;; all the patches in our frontiers stack have a pcolor of 78
      ][
        if (member? valid_next_patch frontiers) and ([path-cost] of valid_next_patch < cost + 1) [
          ask valid_next_patch [
            set parent node
            set path-cost cost + 1
          ] ;; set node to be the new parent of valid_next_patch.
        ]
      ]
    ]
    tick
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; a-star search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plan-a-star
  set planned_path a-star-search
  show planned_path
  foreach planned_path [path_patch -> ask path_patch [ set pcolor 18 ] ]
  stop
end

to-report a-star-search
  let start_location [patch-here] of one-of vacuums ;; get the start patch
  let goal_location [patch-here] of one-of dirts    ;; get the goal patch

  if start_location = goal_location [ report recover-plan goal_location  ] ;; perform goal test. If the goal has been reached, we need to recover the patches/nodes that were visited on the way to the goal.
  let frontiers (list start_location) ;; initialise frontiers priority queue, ordered by path cost
  loop [
    if empty? frontiers [ ;; frontiers is empty; no path has been found.
      show "Failed to find a valid path."
      report (list )
    ]
    set frontiers sort-by [ [f1 f2] ->
      [distance goal_location + path-cost] of f1 <
      [distance goal_location + path-cost] of f2 ]
        frontiers; sort the frontiers
    let node first frontiers   ; get the first node from frontiers
    if node = goal_location [report recover-plan node ]  ;; Perform goal test
    let cost [path-cost] of node
    set frontiers remove-item 0 frontiers   ; remove the first node from frontiers
    ask node [set visited true] ;; Node has been explored/visited.
    ask node [set pcolor 108]   ;; Sets color of the patch/node. All visited nodes/patches have a pcolor of 108.
    ;show node
    ;; valid-next-patches is a function (found towards the end of this file) that returns all the patches the agent can reach from node.
    ;; In python the line below would be: for valid_next_patch in node.valid-next-patches():
    foreach [valid-next-patches] of node [ valid_next_patch ->
      ;; if we have not visited valid_next_patch and valid_next_patch is not in frontiers:
      ifelse (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [
        ask valid_next_patch [
          set parent node
          set path-cost cost + 1
        ] ;; set node to be the parent of valid_next_patch (so we can recover the plan).
        set frontiers lput valid_next_patch frontiers  ;; insert valid_next_patch into frontiers
        ask valid_next_patch [set pcolor 78]   ;; all the patches in our frontiers stack have a pcolor of 78
      ][
        if (member? valid_next_patch frontiers) and ([path-cost] of valid_next_patch < cost + 1) [
          ask valid_next_patch [
            set parent node
            set path-cost cost + 1
          ] ;; set node to be the new parent of valid_next_patch.
          ; this only exists in the pseudocode to handle cases where a heuristic is admissable but not consistent
          ; for this example, which is consistent, this code is unnecessary
        ]
      ]
    ]
    tick
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Common methods
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;
;; Returns a list of patches than can be reached from the patch that calls this function.
;; Usage: set myVar [valid-next-patches] of myPatch
to-report valid-next-patches ;; patch procedure
  let dirs []
  if [pcolor] of patch-at 0 1 = clear_color
  [ set dirs lput patch-at 0 1 dirs ]
  if [pcolor] of patch-at 1 0 = clear_color
  [ set dirs lput patch-at 1 0 dirs ]
  if [pcolor] of patch-at 0 -1 = clear_color
  [ set dirs lput patch-at 0 -1 dirs ]
  if [pcolor] of patch-at -1 0 = clear_color
  [ set dirs lput patch-at -1 0 dirs ]
  report dirs
end

;;-----------------

;;;;;;;
;; returns a list contain the root (i.e, the start location)... node's parent's parent, node's parent, node
to-report recover-plan [node ]
  let plan (list )
  if [parent] of node = nobody [report (list node)]
  report recover-plan-recursive [parent] of node plan
end
;;;;;;
;; Don't call this (instead call recover-plan)
to-report recover-plan-recursive [node plan]
  set plan fput node plan
  if [parent] of node = nobody [report plan]
  report recover-plan-recursive [parent] of node plan
end
;;-----------------



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Execute plan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;
;; moves the vacuum along the planned path.
to execute-plan
  if empty? planned_path [ stop ]
  let next-patch first planned_path
  set planned_path remove-item 0 planned_path
  ask vacuums [setxy [pxcor] of next-patch [pycor] of next-patch]
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; END OF FILE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
228
10
851
634
-1
-1
15.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
65
65
211
98
setup-world
standard-setup
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
44
149
212
182
NIL
plan-depth-first
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
45
190
213
223
NIL
plan-breadth-first
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
47
229
213
262
NIL
plan-uniform-cost
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
48
269
214
302
NIL
plan-greedy-best-first
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
48
312
214
345
NIL
plan-a-star
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
85
398
210
431
NIL
execute-plan
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

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
NetLogo 6.3.0
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
