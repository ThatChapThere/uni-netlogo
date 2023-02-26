# Search

Agents that are more complex than simple reflex agents have some form of state. More complex agents have a sense of goals as well.

Agents can be give a specific thing to try to do, and ideally will adapt to do so.

## Goals

Goals actually provide two things to an agent:

1. Focus - only goal relate actions are considered in the first place
2. Filter - actions that lead too far away from goals can be ignored

Both of these things help to reduce computational load. An example of a filter would be alpa-beta pruning. It's not really clear what the difference between focus and filter is, since they seem synonymous. I suppose it's the difference between not creating vs creating but then deleting seach nodes.

## Problems

Problems have 5 components:
1. Initial state
2. Actions
3. Transition model
4. Goal test
5. Path cost

**Transition models** are functions that determine what actions will actually do. States have **successor states**, and if the model is non-deteministic there will obviously be more than one of these per action.

A **plan** is path through state space via a series of actions.

Goal tests are more or less just functions that return a boolean, at least for simple examples that aren't more about optimisation. Athough even for minimax board games, testing for a win state could be considered a goal test.

**Path cost** is used to determine the optimal solution - the one with the cheapest path. **Step cost** is the cost of a specific step in the path and is written as `c(s, a, a')`.

A **solution** is any path from the curernt state the the goal. The optimal solution is of course the solution with the lowest path cost.

## Search Types

### Graph Search

One way of finding solutions with a graph is to simply store a list of already reached nodes on the search tree and not seach after them. This isn't mentioned in the powerpoint, but presumably once you have this information you can use something like Dijkstra's.

### Breadth First Search

Pretty self explanatory as a concept, this uses brute force and is usually fairly inefficient.

### Uniform Cost Search

It's not really mentioned in the powerpoint, but this is a graph exclusive algorithm. Instead of searching the cheapest step of each child first, it orders nodes by their total distance from the first node and searches the closest. It's better than Dijkstra's when you only need the shortest path between two given nodes, rather than the shortest path between a given node and all other nodes. It's especially useful for implicit graphs, where node distances have to be calculated and aren't already stored.

### Depth First Search

Again, self explainatory. This can be much faster if you want to find any solution as fast as possible since you can order nodes. This has a massive memory advantage, as there's no need to store the entire tree at once like with breadth first. This algorithm isn't **complete**. This is because, and only becuase, you can end up going around in circles forever.

## Final Notes

This stuff is used by Google maps (obviously).
