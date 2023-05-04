# Classical Planning

Classical planning is about finding a sequence of actions in a

* discrete
* deterministic
* static
* fully observable

environment. Any other type of environment is said to use **non-classical** planning.

## PDDL (Planning Domain Definition Language)

Seems very lisp based.

```pddl
(on x y)
(ontable x)
```

and so on.

PDDL uses something called the **closed world assumption**, that is to say that anything not stated is assumed to be false.

### Problem File

an example of PDDL problem file looks like this:

```pddl
(define (problem blocks-world-p0)
    (:domain blocks-world)
    (:objects A B C )
    (:init
        (on C A) (ontable A) (ontable B)
        (clear B) (clear C) (handempty)
    )
    (:goal
        (and (on A B) (on B C) (ontable C) )
    )
)
```

We can see that colons are used for each main section. We define

* a set of objects
* the initial conditions
* the goal conditions

in a PDDL file.

### Action Definition

Every action has

* a name
* parameters
* conditions
* effects
    * things it makes true
    * things it makes false

An example

```pddl
(:action stack
:parameters (?x ?y)
:precondition (and
(holding ?x)
(clear ?y)
)
:effect (and
(not (holding ?x))
(not (clear ?y))
(clear ?x)
(handempty)
(on ?x ?y)
)
)
```

Action files define specific actions. Every problem will of course have several of these.

### Domain File

```
(define (domain blocks-world)
	(:requirements :strips)
	(:predicates
		(on ?x ?y)
		(ontable ?x)
		(clear ?x)
		(handempty)
		(holding ?x)
	)

	(:action stack ...)
	(:action unstack ...)
	(:action put-down ...)
	(:action pick-up ...)
)
```

The domain file contains all of the action definitions at the bottom. It also defines the predicates. Predicates are the abstract definitions of things about objects that may or may not be true. `(on ?x ?y)` is a predicate.

### Recap

The domain file contains abstract things - predicates and actions.

The problem file contains concrete things - a list of objects that actually exist, and the state they are in.

The problem file also contains the desired state. This makes sense since it is another concrete thing, and is also consistent with the name "problem file" since it states the problem that needs solving.

### A Plan

A plan is a list of actions that take us from initial state to goal.

eg.

```pddl
(unstack C A)
(put-down C)
(pick-up B)
(stack B C)
(pick-up A)
(stack A B)
```

You can see it follows a lisp style syntax.

## Forward Chaining

This is more or less a fancy way of saying "search". An action *a* can be executed in state *s* if *s* entails the precondition pre(a), written as *s* |= pre(*a*).

A state entails a precondition iff it makes every part of it true.

Don't be confused by the iff here, entailing doesn't mean equivalence. The above statement is a bidirectional implication *about* a monodirectioan implication. That is *s* |= pre(*a*) <=> *s* => pre(*a*).

## Backward Chaining

This is basically a search from the goal to the initial state. Also known as **relevant-states search**.

This allows you to search for a specific type of action. Since actions don't typically affect all predicates, we just need to look for any action that makes some part of the goal true and doesn't make any part of the goal false. This of course is then a plausible final action. It can be an action that doesn't affect all of the goal, in fact in most cases it will be.

The new state now of course becomes the new "goal" for the purposes of the search algorithm.

To generate this new goal, we remove the effects of the action and add its preconditions. This exactly creates what the world would look like before the action is performed.

One thing I'm curious about here is the case where an action does something that was already done. This isn't possible in the block stacking example, but certainly is possible in theory. Here, it doesn't seem obvious to me that some problems won't have solutions missed because an action can be used to get between two states where one of the action's effects is true in both. Perhaps this doesn't matter mathematically, but it's interesting.
