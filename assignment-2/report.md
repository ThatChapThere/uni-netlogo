## 1. Introduction (300)

In this report I lay out the approaches considered, attempted, and implemented in order to create an AI for the pacman and ghosts in a game of pacman.

First of all the realisation that the limited number of interactions between different type of entities effectively makes the game two simultaneous games of "regular" pacman allowed me to simplify the problem.

I considered creating an adversarial search algorithm and then using a genetic algorithm to fine tune the evaluation of search nodes, but ultimately adversarial search proved an impractical solution (completely crashed my computer). Implementing a genetic algorithm proved too complex to even attempt in the available time.

The actual AI created uses a set of heuristics to choose a move for a ghost or a pacman. Both types of entity use the same heuristic, but pacmans try to maximise it while ghosts try to minimise it. The factors considered are: amount of food collected, amount of food held by pacman, distance from pacman to nearest ghost, distance from pacman to nearnest food pellet, distance from pacman to home (with the homing instinct increased by held food).
All of the distances listed are found using A* search. The A* heuristic is euclidean distance in all cases except for homing distance, which simply uses the X coordinate.

Because ghosts don't always know where the pacman they are chasing is, they actually store the set of possible pacman locations based on its last known location, expanding on every tick. This list of possible locations is capped at 1000 items to prevent exponential growth. Then, using a Monte-Carlo technique, some set number of these possible pacman positions are chosen in order to guess the best way to chase it.

## 2. Justification (300)

My initial thoughts were that the simplest AI to implement would be to have the pacman find the shortest path to any
uneaten food, and then the shortest path to a home square, and to have the ghosts find the shortest path to the pacman.
This is fairly simple and would only require finding shortest paths, probably using the A\* algorith.

My second thought was to have the pacmans and ghosts try to predict each others behaviour by taking into account each
other's AI. However, if the pacman code calls the ghost code and vice versa to simulate each other, this could lead
to an infinite regression. Thus what we need here is some form of adverserial search.

Since ghosts don't interact with each other, pacmans don't interact with each other, and pacmans don't interact with
the ghost on their team, the game is essentially two simultaneous independent ghost vs pacman competitions, which
means we can simplify the scenarion by thinking about what a pacman vs ghost competition looks like

Adversarial search should ideally use minimax with alpha-beta pruning in order to search as many nodes as possible.

I then considered using some forms of heuristics to evaluate nodes. This is required for adverserial search to work in
this case, since the set of all possible games is undoubtedly astronomical, so finding theoretically perfect behavior
is impossible and a search tree needs to exist without finding terminal nodes (ones where all food is eaten).

This means that we have to come up with some sort of heuristic. The factors that can be taken into account are:

* Number of collected foods
* Number of eaten foods
* proximity of pacman to closest food (found using A\*)
* proximity of ghosts to pacman (found using A\*)

The relative values of these factors is unclear, giving us the opportunity to use a genetic algorithm.

Up until this point I had missed the fact that this is not a perfect information game. The ghosts don't actually know
where the pacman is until they can see it in direct line of sight. The ghosts also know the exact location of the
pacman at the exact moment that it eats a food. This also means that ghosts know the set of possible positions of the
pacman, which is an increasing large blob eminating from the last eaten food.

For the sake of simplicity we can allow the pacman (which has perfect information) to (incorrectly) assume that ghosts
do too. This doesn't violate the specification since no real ghosts have perfect information, only the ones in the
pacman's "imagination". This simplification allows the pacman to implement a simple minimax algorithm. This won't be
optimal since the pacman could try to "sneak" past ghosts, but it will be safe since it essentially assumes worst case.

Now we have to consider what information the ghosts have, which is the following and only the following:

* The initial state of the world (including the positions of all entities)
* The location of eaten food, past (I'm assuming) and present

This does not include:

* What other ghosts know
* Where other ghosts are (surprisingly!)

This is something other than the lack of perfect information that separates the scenario from other adversarial
situations - it's not a two player game.

Creating an AI for the ghosts is therefore a little tricky. Here we can employ a Monte-Carlo method by considering some
small subset of the possible positions of the pacman, and going in the direction that a plurality of these
hypotheticals suggest. This will be different than the minimax used by the pacman, since it will only considere one
ghost and not four.

Now we have to consider an issue with evaluation the usefulness of heuristics in the genetic algorithm. Longer game
times indicate ghost success, while shorter game times indicate pacman success. However, this is an arms race, and
better heurtistics should benefit both sides (since both sides use similar heuristics). This means that if we naively
change heuristics we don't actually have any metric to measure how good it was.

Therefore, we will run the genetic algoritm by alternating between ghosts and pacman, where one side gets a new
heuristic while the other gets the "parent" of that heuristic.

It then became obvious that the method laid out so far cannot accomodate large numbers of ghosts. The minimax used by
pacmans allows all possible ghost moves, which in the worst case is 4^g where g is the number of ghosts. This is
astronomical for large numbers of ghosts, so here we must again use a monte-carlo technique. This means restricting
the number of ghost movement possibilies considered by the pacmans.

Another scenario where we needed a monte-carlo method was the case where there are a large number of pellets and
ghosts. This is becuase finding distances to all of them massively slows the simuation. Thus when evaluating nodes I
opted to choose only some limited number of pellets and ghosts to consider.

After creating the ability to search, I set the search depth to 2. This caused NetLogo to crash and forced me to 
reboot my computer. Given that I used
a depth first search algorithm, this is unlikely to be a memory related issue unless NetLogo struggles with large
numbers of entities. Using turtles to create a search tree, while idiomatic, seems to be a poorly peforming approach.

As such I abandoned the idea of adverserial search, and set the depth to 1, essentially using a distance based
heuristic.

I also abandoned the idea of a genetic algorithm. Firstly because only certain heuristic values even work. The value of
collected pellets has to be much larger than the value of being close to a pellet, for example, otherwise the pacman
simply hovers near the pellet, preferring to have its cake rather than eat it. Secondly, personal time constraints
became an issue at this point. However, a genetic algorithm would still be a potential way of optimising the AI.

## 3. Critical Evaluation (400)

While we were informed that fixing the crashes is not neccesary for marks, I opted to do so anyway since I chose to
use a genetic algorithm which neccesitates numerous crash free iterations. This was as simple as not letting ghosts be
directed "towards" pacmans in the same location.

I tried my hardest to make the simulation used by the search algorithm mathematically equivalent to the actual
simulation, but I did not manage to convince myself of this with 100% certainty. This could potentially be solved with
smarter code reusage or by taking further care to understand precisely how the simualtion works including edge cases.

While I'm not sure if it's a NetLogo convention, I used kebab-case for most variables, and snake\_case for specific
instances of agents used by loopds or procedures.

Unfortunately I was unable to get an adverserial search approach to perform well enough to even not crash my computer.
This is a room for improvement though, since a POD (plain old data) approach to creating a search tree would likely
be more performant, even if harder to implment in netlogo. Ultimately there is a lot of space for performance improvements
that I didn't have time to implement.

While they will eventually eat all of the pellets, when there are a large number of pellets or ghosts the pacmans seem
to get confused and move around randomly. This seems to be a side effect of them only being allowed to see a fixed number
of randomly chosen ghosts. I tried to fix this by getting the agent to choose the 10 pellets with the smallest "who",
but this didn't fix the problem, likely becuase the ordering of search-pellets is somewhat random.

It's unfortunate that of the four AI concepts I wanted to implement - pathfinding, adverserial search, Monte-Carlo methods and genetic
algorithms - I was only able to implement two, A* search and some Monte-Carlo methods. Ultimately I underestimated the amount of time that it would take
to program these, and also failed to anticipate the performance issues with such a complex approach, learning two valuable
lessons.

Another improvement posibility would be to use time limited iterative deepening instead of the fixed depth approach used by the 
code, allowing
entities to get "smarter" once there are fewer pellets and if there are fewer ghosts.

## 4. References

## 5. Word Count

This report contains [n] words
