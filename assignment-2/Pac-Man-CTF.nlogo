; Pac-Man Capture the Flag (CTF) created for CMP2020 assessment item 2.
; This model is an adpation of the Pac-Model by Wilensky (2001).
; Wilensky, U. (2001). NetLogo Pac-Man model. http://ccl.northwestern.edu/netlogo/models/Pac-Man. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;

globals [
  game-over?  ;; true when a game has ended
  free-colors ;; the colors the agents can navigate on (i.e., non-wall colors)
  ;;;;;;;;;;;;;;
  level tool  ;; Unused! : these variables are included within the model for creating the map, and so must be either deleted from the map or included here.

  max-stored-pacman-locations-per-ghost

  ;; search depths
  ghost-max-search-depth
  pacman-max-search-depth
]

turtles-own [ home-pos team  ]
patches-own [ pellet-grid? ]  ;; true/false: is a pellet here initially?

breed [ pellets pellet ] ;; the food items are called pellets
breed [ pacmans pacman ]
breed [ ghosts ghost ]

breed [ search-nodes search-node ] ;; these aren't actually turtles, it's just that agents are the closest thing netlogo has to structs
breed [ search-pellets search-pellet ]
breed [ search-pacmans search-pacman ]
breed [ search-ghosts search-ghost ]

breed [ a-star-search-nodes a-star-search-node ]

pacmans-own [
  dead?           ;; pacman has been eaten by a ghost
  score           ;; the score of this pacman's team
  pellets-holding ;; patches of the pellets the pacman has collected (but has not yet deposited)
  home-color      ;; when the pacman is on a patch of this color the pellets are deposited (and the score is increased)
]

ghosts-own [
  eaten? ;; after eating pacman, the ghost must visit its home/initial location to be reactivated

  possible-pacman-locations
]

;; because both sides of the game are orthagonal, we only need to store coordinated in a search tree, not entire game
;; states
;; ie. the search tree for blue ghosts and the red pacman is separate from the search tree for red ghosts and the blue
;; pacman
search-nodes-own [
  parent
  children
  evaluation
  evaluating?
  depth

  pacman-to-move?
]

search-pellets-own [
  node
]

search-pacmans-own [
  dead?           ;; pacman has been eaten by a ghost
  score           ;; the score of this pacman's team
  pellets-holding ;; patches of the pellets the pacman has collected (but has not yet deposited)
  home-color      ;; when the pacman is on a patch of this color the pellets are deposited (and the score is increased)

  node
]

search-ghosts-own [
  eaten? ;; after eating pacman, the ghost must visit its home/initial location to be reactivated

  node
]

a-star-search-nodes-own [
  cost-estimate
  path-cost
  frontier?
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup  ;; Observer setup button
  clear-all
  load-map
  set free-colors (list black 10 100) ; red pacman's home area has a pcolor of 10; the blue pacman’s home area has a pcolor of 100; all other free space has a pcolor of black (0).
  setup-teams
  setup-pellets
  set game-over? false

  ;set value-of-collected-food 400
  ;set value-of-eaten-food 200
  ;set value-of-food-distance -5
  ;set value-of-ghost-distance 4
  ;set value-of-homing-distance -2

  set ghost-max-search-depth 1
  set pacman-max-search-depth 1

  set max-stored-pacman-locations-per-ghost 100

  reset-ticks
end

;;;;;;;;;;
;; loads the selected pacman map.
;;   Make sure the maps directory is in the same directory as this netlogo file.
to load-map  ;; Observer Procedure
  let map_file_path (word "maps/" map_file ".csv")
  ifelse (file-exists? map_file_path) [
    import-world map_file_path
  ] [
    user-message "Cannot find map file. Please check the \"maps\" directory is in the same directory as this Netlogo model."
  ]

  ifelse map_file = "ctf-pacmap2" [ set-patch-size 14.5 ]
                                  [ set-patch-size 21 ]
end

;;;;;;;;
;; Add the pacman and ghost turtles
to setup-teams
  ; pacman is set to the first free square with y=0
  let pacmanx min-pxcor
  while [not member? [pcolor] of patch pacmanx 0 free-colors] [  set pacmanx pacmanx + 1  ]
  ; ghost x,y:
  let ghostx min-pxcor + 1
  let ghosty max-pycor - 1
  ; Add the pacmans an ghosts for both teams:
  setup-team blue "blue" abs pacmanx 0  abs ghostx ghosty 100 90
  setup-team red  "red"      pacmanx 0      ghostx ghosty 10  270

  setup-ghost-possible-pacman-locations
end

to setup-team [colour team_name pacmanx pacmany ghostx ghosty home-c initial-heading]
  ;; setup pacman
  create-pacmans 1[
    set team team_name
    set color colour + 9
    set shape "pacman"
    set dead? false
    setxy pacmanx pacmany
    set home-pos list pacmanx pacmany
    set pellets-holding (list)
    set home-color home-c
    set heading initial-heading
  ]
  ;; setup ghost
  repeat number_of_ghosts [
    while [not member? [pcolor] of patch ghostx ghosty free-colors] [  set ghosty ghosty - 1  ]
    if ghosty < min-pycor + 1 [  set ghosty max-pycor - 1
                                 while [not member? [pcolor] of patch ghostx ghosty free-colors] [  set ghosty ghosty - 1  ]]

    create-ghosts 1[
      set team team_name
      set color colour + 8
      set shape "ghost"
      setxy ghostx ghosty
      set eaten? false
      set home-pos list ghostx ghosty
    ]
    set ghosty ghosty - 1
  ]
end

to setup-ghost-possible-pacman-locations
  ask ghosts [
    let ghost_team team
    set possible-pacman-locations (list ([patch-here] of (one-of pacmans with [team != ghost_team])))
  ]
end

;; Create the food
to setup-pellets
  repeat number_of_pellets [
    ; select a random patch from one side of the environment
    let rand_patch one-of patches with [member? pcolor free-colors and pxcor < 0 and pycor < max-pycor and pycor > min-pycor and not any? turtles-here]
    ; create a pellet located on the randomly selected patch
    create-pellets 1[
      setxy [pxcor] of rand_patch [pycor] of rand_patch
      set color blue
      set shape "pellet"
      set team "blue"
    ]
    ; create a pellet at the same location on the opposite side of the map
    create-pellets 1[
      setxy abs [pxcor] of rand_patch [pycor] of rand_patch
      set color red
      set shape "pellet"
      set team "red"
    ]
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Runtime Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;
;; move the pacmans, check if the game is over, the move the ghosts.
to play  ;; Observer Forever Button

  update-pacman ;; redistributes pellets of dead pacmans, calls choose-heading-of-pacman and then moves the pacman

  if game-over? [
    let message-str "Game finished! Score: \n";; \n means start a new line
    ask pacmans [ set message-str (word message-str team " team score: " score "\n")]
    ask max-one-of pacmans [score] [set message-str (word message-str " Team " team " won!") ]
    user-message message-str
    stop ]

  update-ghosts ;; moves inactive games towards their home location, chooses the heading of the ghost, moves the ghost forward, then checks if the ghost has eaten a pacman
  display
end

;;;;;;;;;;;;;;
;; Since the pacmans are currently controlled by the human this method does very.
;;  Update the if statement to be able to select your approach.
to choose-heading-of-pacman  ;; Pacman Procedure <--- i.e. this procedure is ran from the pacman context and not from the observer context .
  ask pacmans with [team = "blue"][
    ifelse pacman_mode_blue = "human" [
      ; human has selected the direction, so we don't do anything here
    ] [
      ifelse pacman_mode_blue = "AI" [
        ; your AI should select the direction the pacman travels in (i.e. the heading of the pacman).
        choose-heading-of-pacman-ai-mode
      ] [
        choose-heading-of-pacman-random-mode
      ]
    ]
  ]
  ask pacmans with [team = "red"][
    ifelse pacman_mode_red = "human" [
      ; human has selected the direction, so we don't do anything here
    ] [
      ifelse pacman_mode_red = "AI" [
        ; your AI should select the direction the pacman travels in (i.e. the heading of the pacman).
        choose-heading-of-pacman-ai-mode
      ] [
        choose-heading-of-pacman-random-mode
      ]
    ]
  ]
end

;;;;;;;;;;;;;;
;; Controls the heading of the ghost using the provided methed.
;;  Update the if statement to be able to select your approach.
to choose-heading-of-ghost  ;; Ghosts Procedure
  if team = "blue"[
    ifelse ghost_mode_blue = "random" [
      choose-heading-of-ghosts-random-mode ;; our provided ghost moving method
    ] [
      ; call your ghost AI
      choose-heading-of-ghosts-ai-mode
    ]
  ]
  if team = "red"[
    ifelse ghost_mode_red = "random" [
      choose-heading-of-ghosts-random-mode ;; our provided ghost moving method
    ][
      ; call your ghost AI
      choose-heading-of-ghosts-ai-mode
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; update and move the pacmans

;;;;;;;;;;;;;
;; Updates the status of the pacman turtles
to update-pacman
  redistribute-pellets-of-dead-pacmans
  ask pacmans [
    ifelse dead?  [
      let c color
      let pacman-team team
      set pellets-holding (list)
      set shape "star"
      set dead? false
    ] [ ; else pacman is alive, so move pacman
      choose-heading-of-pacman
      move-pacman
    ]
  ]
end

;;;;;;;;
;; Loops through the pellets held by dead pacmans and re-creates them
to redistribute-pellets-of-dead-pacmans
  ; create a list of dead pacman
  let dead-pacman-lst (list)
  ask pacmans [ if dead? [set dead-pacman-lst lput self dead-pacman-lst]   ]

  ; for each pellet held by a dead pacman: re-create that pellet
  foreach dead-pacman-lst [this_pacman ->
    foreach  [pellets-holding] of this_pacman [ p ->
        create-pellets 1[
          setxy [pxcor] of p [pycor] of p
          set color [color] of this_pacman
          set team [team] of this_pacman
          set shape "pellet"
        ]
     ]
  ]
end

;;;;;;;;;
;; move pacman foward and consume a pellet.
to move-pacman  ;; Pacman Procedure
  let pacman_team team
  ;; move forward unless blocked by wall
  if member? [pcolor] of patch-ahead 1 free-colors  [ fd 1 ]
  ;; eat the pellet
  consume
  ;; Level ends when all pellets are eaten
  if not any? pellets with [pacman_team = team] and length pellets-holding = 0 [ set game-over? true ]
  ;; Animation
  ifelse shape = "pacman" [ set shape "pacman open" ]
                          [ set shape "pacman" ]
end

;;;;;;;;;;;
;; Pick-up pellets that are at the pacman's current location
;;  Consume/collect the pellets returned to the pacman's home side of the board.
;; Checks if a ghost is at the same location as the pacman.
to consume  ;; Pacman Procedure
  let pacman_team team
  let this-home-color home-color

  ;; Pick-up the Pellet
  if any? pellets-here with [team = pacman_team]
  [ set pellets-holding lput patch-here pellets-holding
    ask pellets-here [ die ] ]

  ;; After returning to the home side of the board, pellet is consumed/collected
  if (length pellets-holding) > 0 and [pcolor] of patch-here = home-color
  [ set score score + length pellets-holding
    set pellets-holding (list)
    set shape "face happy"

    ;; inform all ghosts of what happened
    let location patch-here
    ask ghosts with [team != pacman_team] [
      set possible-pacman-locations (list patch-here)
    ]
  ]

  ;; If there is an active ghost (on the opposite team) here, then it consumes the pacman
  if any? ghosts-here with [not eaten? and team != pacman_team][
    set dead? true
    set shape "star"
    ask ghosts-here with [not eaten? and team != pacman_team] [
      set eaten? true
      set shape "eyes"
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; update and move the ghost

;;;;;;;;;;
;; Moves the ghost turtles
to update-ghosts ;; Observer Procedure
  ask ghosts [
   ifelse eaten? [ ;; ghost has eaten, so needs to return home
     ;; if the ghost has reached its home location, return it to its active state:
     ifelse patch-here = patch item 0 home-pos item 1 home-pos [
       set eaten? false
       set shape "ghost"
      ][ ;; otherwise keep heading towards the home location
        return-home
      ]
    ][
      choose-heading-of-ghost
      fd 1
      ghost-eat-pacman
    ]
    let possible-pacman-position-count length possible-pacman-locations
    let new-possible-pacman-locations (list)
    foreach possible-pacman-locations [ possible-pacman-location ->
      foreach [clear-headings] of possible-pacman-location [ clear-heading ->
        set new-possible-pacman-locations lput [patch-at sin clear-heading cos clear-heading] of possible-pacman-location new-possible-pacman-locations
      ]
    ]
    set possible-pacman-locations up-to-n-of max-stored-pacman-locations-per-ghost new-possible-pacman-locations
  ]
end

;;;;;;;;;
;;
to ghost-eat-pacman ;; Ghost Procedure
  let ghost_team team
  if not eaten? and any? pacmans-here with [ team != ghost_team ][
    set eaten? true
    set shape "eyes"
    ask pacmans-here with [team != ghost_team] [
      set dead? true
      set shape "star"
    ]
  ]
end

;;;;;;;;;
;; Moves the ghost forwards its home location
to return-home  ;; Ghosts Procedure
  let dirs clear-headings
  let home-dir 0
  if patch-here != patch item 0 home-pos item 1 home-pos [
    set home-dir towardsxy item 0 home-pos item 1 home-pos
    let home-path 90 * round (home-dir / 90)
    set heading home-path
    fd 1
  ]
end

;;;;;;;;; ;; The random procedure for controlling the heading of the pacman.
to choose-heading-of-pacman-random-mode  ;; Pacman Procedure
  let dirs clear-headings
  let new-dirs remove opposite heading dirs

  ; if only one direction is clear: head in that direction
  ifelse length dirs = 1 [ set heading item 0 dirs ]
                         [ set heading one-of new-dirs ] ; otherwise pick a random direction to move in.
end

;;;;;;;;;
;; The AI procedure for controlling the heading of the pacman.
to choose-heading-of-pacman-ai-mode ;; pacman procedure
  ;; This uses non-recursive depth first search.
  ;; This means an algorithm that:
  ;; 1. Adds children to exactly one of the deepest nodes (cousins should not exist)
  ;; 2. Deletes a node immediately after all children are evaluated

  create-pacman-root-node
  ask one-of search-nodes [add-children] ;; Add children to root node

  let ideal-move list 0 0

  while [max [depth] of search-nodes > 0] [
    ;; ask a node at the bottom of the current tree to either expand or evaluate
    if  any?   search-nodes with [depth = max [depth] of search-nodes and not evaluating?] [
      ask one-of search-nodes with [depth = max [depth] of search-nodes and not evaluating?] [
        set evaluating? true
        ifelse depth = pacman-max-search-depth [evaluate-node] [add-children]
      ]
      if any? search-nodes with [evaluating? and empty? children] [
        ask     search-nodes with [evaluating? and empty? children] [
          ;; update parent evaluation if appropriate
          if (pacman-to-move? = evaluation < [evaluation] of parent) [
            let child_evaluation evaluation
            ask parent [ set evaluation child_evaluation ]
            if depth = 1 [
              let ideal_node self
              let ideal_pacman one-of search-pacmans with [node = ideal_node]
              set ideal-move [list pxcor pycor] of ideal_pacman
            ]
          ]
          ;; remove self as child and die
          let specific_child self
          ask parent [
            set evaluating? true
            set children remove specific_child children
          ]
          die
      ]]
  ]]

  facexy item 0 ideal-move item 1 ideal-move

  ;; Clear search tree
  ask search-nodes [die]
  ask search-pellets [die]
  ask search-pacmans [die]
  ask search-ghosts [die]
end

;;;;;;;;;
;; The AI procedure for controlling the heading of the ghost.
to choose-heading-of-ghosts-ai-mode  ;; Ghosts Procedure
  ;; This uses non-recursive depth first search.
  ;; This means an algorithm that:
  ;; 1. Adds children to exactly one of the deepest nodes (cousins should not exist)
  ;; 2. Deletes a node immediately after all children are evaluated

  let dirs clear-headings

  ; if only one direction is clear: head in that direction
  ifelse length dirs = 1 [ set heading item 0 dirs ]
  [
    let ghost_team team
    if look-for-pacman != -1 [
      ;; Found pacman
      set possible-pacman-locations (list [patch-here] of (one-of pacmans with [team != ghost_team]))
    ]
    let ideal-moves (list)

    repeat monte-carlo-pacman-positions-considered-by-ghost
    [
      create-ghost-root-node one-of possible-pacman-locations
      ask one-of search-nodes [add-children] ;; Add children to root node

      let ideal-move list 0 0

      while [max [depth] of search-nodes > 0] [
        ;; ask a node at the bottom of the current tree to either expand or evaluate
        if  any?   search-nodes with [depth = max [depth] of search-nodes and not evaluating?] [
          ask one-of search-nodes with [depth = max [depth] of search-nodes and not evaluating?] [
            set evaluating? true
            ifelse depth = pacman-max-search-depth [evaluate-node] [add-children]
          ]
          if any? search-nodes with [evaluating? and empty? children] [
            ask     search-nodes with [evaluating? and empty? children] [
              ;; update parent evaluation if appropriate
              if (pacman-to-move? = evaluation < [evaluation] of parent) [
                let child_evaluation evaluation
                ask parent [ set evaluation child_evaluation ]
                if depth = 1 [
                  let ideal_node self
                  let ideal_ghost one-of search-ghosts with [node = ideal_node]
                  set ideal-move [list pxcor pycor] of ideal_ghost
                ]
              ]
              ;; remove self as child and die
              let specific_child self
              ask parent [
                set evaluating? true
                set children remove specific_child children
              ]
              die
          ]]
      ]]
      set ideal-moves lput ideal-move ideal-moves

      ;; Clear search tree
      ask search-nodes [die]
      ask search-pellets [die]
      ask search-pacmans [die]
      ask search-ghosts [die]
    ]

    let ideal-move one-of modes ideal-moves
    facexy item 0 ideal-move item 1 ideal-move
    set heading one-of clear-headings
  ]
end

to create-pacman-root-node ;; pacman method
  ;; Clear search tree
  ask search-nodes [die]
  ask search-pellets [die]
  ask search-pacmans [die]
  ask search-ghosts [die]

  let pacman_team team
  hatch-search-nodes 1 [
    let current_node self
    ask pellets with [team = pacman_team]  [ hatch-search-pellets 1 [set node current_node] ]
    ask pacmans with [team = pacman_team]  [ hatch-search-pacmans 1 [set node current_node] ]
    ask ghosts  with [team != pacman_team] [ hatch-search-ghosts  1 [set node current_node] ]
    set parent self
    set children (list)
    set evaluation -10000
    set evaluating? false
    set depth 0
    set pacman-to-move? true
  ]
end

to create-ghost-root-node [pacman-location] ;; ghost method (creates search tree with singular ghost)
  ;; Clear search tree
  ask search-nodes [die]
  ask search-pellets [die]
  ask search-pacmans [die]
  ask search-ghosts [die]

  let ghost_team team
  let current_ghost self
  hatch-search-nodes 1 [
    let current_node self
    ask current_ghost                     [ hatch-search-ghosts  1 [set node current_node] ]
    ;;ask pacman-location                   [ sprout-search-pacmans 1 [set node current_node]]
    ask current_ghost                  [ hatch-search-pacmans 1 [set node current_node]]
    set parent self
    set children (list)
    set evaluation 10000
    set evaluating? false
    set depth 0
    set pacman-to-move? false
  ]
end

;;;;;;;;;
;; The provided procedure for controlling the heading of the ghost.
to choose-heading-of-ghosts-random-mode  ;; Ghosts Procedure
  let dirs clear-headings
  let new-dirs remove opposite heading dirs

  ; if only one direction is clear: head in that direction
  ifelse length dirs = 1 [ set heading item 0 dirs ]
  [ let pacman-dir look-for-pacman ; otherwise look for pacman
    ifelse pacman-dir != -1 [ set heading pacman-dir ] ; if your can see pacman head towards pacman.
      [ set heading one-of new-dirs ] ; otherwise pick a random direction to move in.
  ]
end

to-report clear-headings ;; turtle procedure
  let dirs []
  ;ycor < max-pycor and
  if member? [pcolor] of patch-at 0 1 free-colors
  [ set dirs lput 0 dirs ]
  if member? [pcolor] of patch-at 1 0 free-colors
  [ set dirs lput 90 dirs ]
  if member? [pcolor] of patch-at 0 -1 free-colors
  [ set dirs lput 180 dirs ]
  if member? [pcolor] of patch-at -1 0 free-colors
  [ set dirs lput 270 dirs ]
  report dirs
end

to-report look-for-pacman ;; ghosts procedure
  ;; Guard clause to fix crash - We don't want ghosts to be redirected by a pacman they are on top of since this sends it into a wall
  let ghost_team team
  if any? pacmans-here with [ team != ghost_team ] [ report -1 ]

  if see-pacman 0   [ report 0   ]
  if see-pacman 90  [ report 90  ]
  if see-pacman 180 [ report 180 ]
  if see-pacman 270 [ report 270 ]
  report -1
end

to-report opposite [dir]
  ifelse dir < 180
  [ report dir + 180 ]
  [ report dir - 180 ]
end

to-report see-pacman [dir] ;; ghosts procedure
  let ghost_team team
  let saw-pacman? false
  let p patch-here
  while [is-patch? p and member? [pcolor] of p free-colors]
  [ ask p
    [ if any? pacmans-here with [team != ghost_team]
      [ set saw-pacman? true ]
      set p patch-at sin dir cos dir ;; next patch in direction dir
    ]
    ;; stop looking if you loop around the whole world
    if p = patch-here [ report saw-pacman? ]
  ]
  report saw-pacman?
end

to evaluate-node ;; node procedure
  let current_node self
  let current_pacman one-of search-pacmans with [node = current_node]

  let pellet-distances (list)
  let ghost-distances  (list)

  ask up-to-n-of 10 search-pellets with [node = current_node] [
    let current_pellet self
    set pellet-distances lput [pacman-distance current_pellet] of current_node pellet-distances
  ]

  ask up-to-n-of 10 search-ghosts with [node = current_node and not eaten?] [
    let current_ghost self
    set ghost-distances lput [pacman-distance current_ghost] of current_node ghost-distances
  ]

  if pellet-distances = (list) [ set pellet-distances (list 0) ]
  if ghost-distances  = (list) [ set ghost-distances  (list 0) ]

  set evaluation
    value-of-collected-food  * [score] of current_pacman +
    value-of-eaten-food      * [length pellets-holding] of current_pacman +
    value-of-food-distance   * min pellet-distances +
    value-of-ghost-distance  * min ghost-distances +
    value-of-homing-distance * homing-distance * [length pellets-holding] of current_pacman
end

to-report homing-distance
  let current_node self
  let current_pacman one-of search-pacmans with [node = current_node]
  let path-distance 0
  let path-found? false

  ask current_pacman [
    hatch-a-star-search-nodes 1 [
      set cost-estimate [homing-heuristic] of current_pacman
      set path-cost 0
      set frontier? true
    ]
  ]

  loop [
    if not any? a-star-search-nodes with [frontier?] [
      ask a-star-search-nodes [die]
      report 10000
    ]
    ;; Expand the node with the best heuristic
    ask (min-one-of (a-star-search-nodes with [frontier?]) [cost-estimate]) [
      ;; If terminal
      ifelse pcolor = [home-color] of current_pacman [
        set path-distance path-cost
        set path-found? true
      ] [
        set frontier? false
        let current_path_cost path-cost

        let dirs clear-headings
        foreach dirs [ dir ->
          if not any? a-star-search-nodes-at sin dir cos dir [
            hatch-a-star-search-nodes 1 [
              set cost-estimate [homing-heuristic] of current_pacman + path-cost
              set path-cost current_path_cost + 1
              set frontier? true
              set heading dir
              fd 1
            ]
          ]
        ]
      ]
    ]
    if path-found? [
      ask a-star-search-nodes [die]
      report path-distance
    ]
  ]
end

to-report homing-heuristic ;; search-pacman procedure
  ifelse team = "blue" [report pxcor] [report (- pxcor)]
end

;; report the distance from pacman to a specific ghost
to-report pacman-distance [current_agent] ;; node procedure
  if nobody = current_agent [ report 0 ]
  let current_node self
  let current_pacman one-of search-pacmans with [node = current_node]
  let path-distance 0
  let path-found? false

  ask current_pacman [
    hatch-a-star-search-nodes 1 [
      set cost-estimate distance current_agent
      set path-cost 0
      set frontier? true
    ]
  ]

  loop [
    if not any? a-star-search-nodes with [frontier?] [
      ask a-star-search-nodes [die]
      report 10000
    ]
    ;; Expand the node with the best heuristic
    ask (min-one-of (a-star-search-nodes with [frontier?]) [cost-estimate]) [
      ;; If terminal
      ifelse pxcor = [pxcor] of current_agent and pycor = [pycor] of current_agent [
        set path-distance path-cost
        set path-found? true
      ] [
        set frontier? false
        let current_path_cost path-cost

        let dirs clear-headings
        foreach dirs [ dir ->
          if not any? a-star-search-nodes-at sin dir cos dir [
            hatch-a-star-search-nodes 1 [
              set cost-estimate distance current_agent + path-cost
              set path-cost current_path_cost + 1
              set frontier? true
              set heading dir
              fd 1
            ]
          ]
        ]
      ]
    ]
    if path-found? [
      ask a-star-search-nodes [die]
      report path-distance
    ]
  ]
end

to add-children ;; Node method
  let current_node self
  let current_pacman one-of search-pacmans with [node = current_node]
  let pacman_team [team] of current_pacman

  ifelse pacman-to-move? [
    ifelse [dead?] of one-of search-pacmans with [node = current_node] [
      hatch-search-nodes 1 [
        let child_node self
        ask pellets with [team = pacman_team]  [ hatch-search-pellets 1 [set node child_node] ]
        ask pacmans with [team = pacman_team]  [ hatch-search-pacmans 1 [set node child_node
          set dead? false
        ]]
        ask ghosts  with [team != pacman_team] [ hatch-search-ghosts  1 [set node child_node] ]
        set parent current_node
        set children (list)
        set evaluation -10000
        set evaluating? false
        set depth [depth] of current_node + 1
        ;set pacman-to-move? false

        ask parent [ set children lput child_node children ]
        node-interactions
      ]
    ] [
      let dirs [clear-headings] of current_pacman
      foreach dirs [ dir ->
        hatch-search-nodes 1 [
          let child_node self
          ask pellets with [team = pacman_team]  [ hatch-search-pellets 1 [set node child_node] ]
          ask pacmans with [team = pacman_team]  [ hatch-search-pacmans 1 [set node child_node
            set heading dir
            fd 1
          ]]
          ask ghosts  with [team != pacman_team] [ hatch-search-ghosts  1 [set node child_node] ]
          set parent current_node
          set children (list)
          set evaluation -10000
          set evaluating? false
          set depth [depth] of current_node + 1
          set pacman-to-move? false

          ask parent [ set children lput child_node children ]
          node-interactions
        ]
      ]
    ]
  ] [
    repeat monte-carlo-ghost-search-options [
      hatch-search-nodes 1 [
        let child_node self
        ask pellets with [team = pacman_team]  [ hatch-search-pellets 1 [set node child_node] ]
        ask pacmans with [team = pacman_team]  [ hatch-search-pacmans 1 [set node child_node] ]
        ask ghosts  with [team != pacman_team] [ hatch-search-ghosts  1 [set node child_node
          set heading one-of clear-headings
          fd 1
        ]]
        set parent current_node
        set children (list)
        set evaluation 10000
        set evaluating? false
        set depth [depth] of current_node + 1
        set pacman-to-move? true

        ask parent [ set children lput child_node children ]
        node-interactions
      ]
    ]
  ]
end

to node-interactions ;; Node procedure
  let current_node self
  let current_pacman one-of search-pacmans with [node = current_node]
  let pacman_team [team] of current_pacman
  let this-home-color [home-color] of current_pacman

  ;; Pick-up the Pellet
  if any? (pellets-on current_pacman) with [team = pacman_team] [
    ask current_pacman [ set pellets-holding lput patch-here pellets-holding ]
    ask (search-pellets-on current_pacman) with [team = pacman_team] [ die ]
  ]

  ask current_pacman[
    ;; After returning to the home side of the board, pellet is consumed/collected
    if (length pellets-holding) > 0 and [pcolor] of patch-here = home-color [
      set score score + length pellets-holding
      set pellets-holding (list)
    ]

    ;; If there is an active ghost (on the opposite team) here, then it consumes the pacman
    if any? search-ghosts-here with [not eaten? and node = current_node][
      set dead? true
      ask search-ghosts-here with [not eaten? and node = current_node] [
        set eaten? true
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Interface Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-up [this_team]
  ask pacmans with [team = this_team] [ set heading 0 ]
end

to move-right [this_team]
  ask pacmans with [team = this_team]  [ set heading 90 ]
end

to move-down [this_team]
  ask pacmans with [team = this_team]  [ set heading 180 ]
end

to move-left [this_team]
  ask pacmans with [team = this_team]  [ set heading 270 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
243
10
902
376
-1
-1
21.0
1
10
1
1
1
0
1
0
1
-15
15
-8
8
1
1
0
ticks
30.0

MONITOR
913
37
1034
82
Score
[score] of one-of pacmans with [team = \"blue\"]
0
1
11

BUTTON
577
386
687
419
Setup
setup
NIL
1
T
OBSERVER
NIL
N
NIL
NIL
1

BUTTON
688
386
798
419
Play
play
T
1
T
OBSERVER
NIL
P
NIL
NIL
0

BUTTON
970
106
1025
139
Up
move-up \"blue\"
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
0

BUTTON
1025
139
1080
172
Right
move-right \"blue\"
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
0

BUTTON
970
139
1025
172
Down
move-down \"blue\"
NIL
1
T
OBSERVER
NIL
K
NIL
NIL
0

BUTTON
915
139
970
172
Left
move-left \"blue\"
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
0

MONITOR
119
37
235
82
Score
[score] of one-of pacmans with [team = \"red\"]
17
1
11

BUTTON
114
106
177
139
Up
move-up \"red\"
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
114
139
177
172
Down
move-down \"red\"
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
51
139
114
172
Left
move-left \"red\"
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
176
139
236
172
Right
move-right \"red\"
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

TEXTBOX
911
10
1061
29
Blue Team
16
103.0
1

TEXTBOX
152
12
302
31
Red Team
16
13.0
1

CHOOSER
918
286
1085
331
pacman_mode_blue
pacman_mode_blue
"human" "random" "AI"
2

CHOOSER
918
335
1069
380
ghost_mode_blue
ghost_mode_blue
"random" "AI"
0

CHOOSER
63
282
224
327
pacman_mode_red
pacman_mode_red
"human" "random" "AI"
2

CHOOSER
81
334
225
379
ghost_mode_red
ghost_mode_red
"random" "AI"
0

SLIDER
380
433
559
466
number_of_pellets
number_of_pellets
1
200
9.0
1
1
NIL
HORIZONTAL

CHOOSER
379
384
526
429
map_file
map_file
"ctf-pacmap0" "ctf-pacmap1" "ctf-pacmap2" "ctf-pacmap3"
0

SLIDER
378
470
558
503
number_of_ghosts
number_of_ghosts
0
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
21
638
323
671
monte-carlo-ghost-search-options
monte-carlo-ghost-search-options
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
20
678
447
711
monte-carlo-pacman-positions-considered-by-ghost
monte-carlo-pacman-positions-considered-by-ghost
1
10
3.0
1
1
NIL
HORIZONTAL

TEXTBOX
24
597
174
627
Monte-Carlo attempt amounts
12
0.0
1

SLIDER
938
645
1158
678
value-of-collected-food
value-of-collected-food
10
1000
400.0
10
1
NIL
HORIZONTAL

SLIDER
962
691
1159
724
value-of-eaten-food
value-of-eaten-food
10
1000
200.0
10
1
NIL
HORIZONTAL

SLIDER
1181
644
1398
677
value-of-food-distance
value-of-food-distance
-20
-1
-5.0
1
1
NIL
HORIZONTAL

SLIDER
1182
689
1408
722
value-of-ghost-distance
value-of-ghost-distance
1
20
4.0
1
1
NIL
HORIZONTAL

SLIDER
1182
733
1420
766
value-of-homing-distance
value-of-homing-distance
-20
-1
-2.0
1
1
NIL
HORIZONTAL

TEXTBOX
1133
609
1283
627
Heuristics
12
0.0
1

@#$#@#$#@
## CMP2020 Assessment 2

; This model is an adpation of the Pac-Model by Wilensky (2001).
; Wilensky, U. (2001). NetLogo Pac-Man model. http://ccl.northwestern.edu/netlogo/models/Pac-Man. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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
Circle -7500403 true true 45 45 210

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

eyes
false
0
Circle -1 true false 62 75 57
Circle -1 true false 182 75 57
Circle -16777216 true false 79 93 20
Circle -16777216 true false 196 93 21

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

ghost
false
0
Circle -7500403 true true 61 30 179
Rectangle -7500403 true true 60 120 240 232
Polygon -7500403 true true 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -1 true false 81 78 56
Circle -16777216 true false 99 98 19
Circle -1 true false 155 80 56
Circle -16777216 true false 171 98 17

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

pacman
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 105 -15 150 150 195 -15

pacman open
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 270 -15 149 152 30 -15

pellet
true
0
Circle -7500403 true true 105 105 92

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

scared
false
0
Circle -13345367 true false 61 30 179
Rectangle -13345367 true false 60 120 240 232
Polygon -13345367 true false 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -16777216 true false 81 78 56
Circle -16777216 true false 155 80 56
Line -16777216 false 137 193 102 166
Line -16777216 false 103 166 75 194
Line -16777216 false 138 193 171 165
Line -16777216 false 172 166 198 192

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
new
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
