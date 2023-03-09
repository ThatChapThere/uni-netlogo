# Adversarial Search

This type of search is applicable to games that are:

* Two person
* Perfect information
* Zero sum

like chess, draughts, go, othello connect 4 etc.

These games can be represented via a **state space**. They can also have an **iconic representation**. That as far as I can tell just means a graphical representation, but with icons being reused. Eg. a chessboard with the white pawn image drawn 8 times.

## Zero Sum Games

Constant sum games can easily made zero sum by making a linear transformation of the utility function.

## Minimax

Pretty straightforward. Assumes best play by opponent.

## Alpha-Beta Pruning

Mathematically equivalent to minimax. This is possible because it's depth first and specifies a depth.

Since there is a given depth, terminal nodes are the only nodes to be evaluated (except for performace related node sorting purposes) and their evalutations are assumed to be infallible.

The simplest case is a 2-ply search. There is no pruning for a 1 ply search.

At least one depth-1 node must have all of its children evaluated. Then we have a depth-1 node with a fully know evaluation. Since we're working with minimax, we can now look at the other depth-1 nodes. All it takes is one depth-2 child to be worse than the fully known depth-1 node, and the new depth-1 node cannot possibly be better than the first one. We also obviously modify our knowlodge of the best case should this new depth-1 node be better.

Then it's as simple as replacing the evaluation function with a recursive call to the alpha-beta function and treating it as a black box, and conceptually that's it.

Programatically this just means returning an evalutation prematurely once we have a bad child node.
