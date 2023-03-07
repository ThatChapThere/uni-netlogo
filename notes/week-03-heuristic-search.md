# Heuristic Search

We need to be able to make algorithmic improvements to the basic search algorithms like breadth first and depth first.

We want better

* Memory efficiency
* Completeness

Time complexity is not so easily solved.

## Depth-Limited Search

Depth first search has some advantages, especially in terms of space complexity. But it does risk non-termination in cases where the wrong branch gets expanded.

The solution to this is to apply a depth limit. This *can* be a source of incompleteness. 

## Iterative Deepening

This is just DLS but done over and over again for each depth limit. This is done by chess engines in order to find moves in a reasonable amount of time but also to keep searching. Obviously infinite running is not the problem being solved in the case of games like chess since the seach space is functionally infinite anyway.

Iterative deepening does not, and cannot since it uses depth first seach, store previously searched positions. This is a bit counterintuitive but memory wise it's impossible to do otherwise for large search trees. There also isn't a way to somehow do depth first iteratively since depth first requires searching the entire tree to complete.

Also, since trees grow exponentially most searching is done at the deepest depth anyway.

The number of nodes for a breadth first search is the sum of the geometric series for (breadth)^(0 to depth) which is a proportional to b^d.

The number of nodes searched by iterative deepening is the sum of the sums of the geometric series in the worst case. This ends up approaching a ratio of (breadth)/(breadth - 1) for large depths, which is proportional to the number of nodes in the first place, so the extra cost is always reasonable, especilly considering the memory improvements.

## Heurtistic Search

we've solved the memory problem, but not the computation problem

The number of nodes is still exponential, so we need to turn to **informed search** in order to reduce the number of searched nodes. The simplest way of doing this is heuristics.

This heuristic can be an evaluation function, such as path cost.

Heuristics are **admissible** if they *never* overestimate the cost of the cheapest solution. That is to say, they are optimistic.

An example of this is taking distance as the crow flies when finding the shortest path between cities. This will obviously never be more than the road distance.

## Greedy Search

This is just expanding the cheapest nodes first. Greedy is **myopic**, since the current best isn't always the best overall (although this is true of any heuristic by definition).

Greedy search finds solutions quickly. I doesn't always find the best solution. It ignores the past nodes in a path. It can be subject to false starts early on.

## A* Search

The idea behind A* Search is to combine the uniform cost search and greedy search. It takes into account both the cost so far and a heuristic.

A* is actually guarunteed to eventually find the optimal path, as long as the heuristic is admissible. The heuristic just makes uniform cost search faster in most cases.

There are 3 conditions for this to work:

1. Each node has finitely many children
2. Each arc has a positive cost value > 0
3. h(n) <= the true cost

A search with a h() function that is consistently higher than another h() function while still being admissible is said to be more **informed**.

A* search is optimal because once an end node is found it's evaluation is its true distance. If the first end node found is not optimal, that means that its true distance is somehow less than the heuristic distance of the correct end node. Which in turn is less than the true distance of the correct node, which cannot be true by definition. This is a proof by contradiction.

Because

```
start -(found)-(found)- end [suboptimal]
    V
start -(found)-(estimated)- end [optimal]
```

is always true, the correct path will be looked at first.

Because unsearched paths are always too short, searched suboptimal paths will always be longer.

Optimal estimated < optimal optimal real < suboptimal real.

The truth will always lengthen fake paths before it's too late.

## Optimisation

Optimisation can be thought of as a search, but we just want to find the optimum. In this case the "path" is just whatever we happen to have already tried, and this isn't useful information. This means we need **local** algorithms that only store a small amount of state space at a given time.

For example with the travelling salesman problem, the "path" is not the path on the map, it's all of the routes we've tried thought of as nodes in the space of all possible routes. Of course, salesmen don't care about all of the routes they're not going to take.

## Iterative Improvment

### Travelling Salesman Problem

The travelling salesman problem is finding the shortest path that includes all cities.

You can take an iterative approach to the problem by swapping paths. This is actually quite effective for large numbers of cities and can get you within 1% of the optimum fairly quickly.

### N-Queens Problem

Iterative improvement is also useful for the n-queens problem.

## Hill Climbing / Gradient Ascent

This is a form of iterative improvement that works by finding the highest nearby point and moving to it. It's basically greedy search.

This will always end up on a local maximum.

### Random Restart Hill Climbing

This is trivially complete becuase you keep starting at random coordinates. This is not very efficient

### Random Lateral Moves

This solves issues with plateaus that have an uphill section on one side, but does not help with local maxima.

### Local Beam Search

Here we store k states instead of 1 state. We choose the top k successors of all of the states put together. For example if we choose k=10 and every state has 5 sucessors we choose the best 10 out of the 50 we have found to stay alive.

This has the problem of all states ending up on the same local maximum.

This is also quite similar to natural selection.

**Genetic Algorithms** are based on the idea of local beam search, but also generate successors from pairs of states, ie. use sexual reproduction to create new states.
