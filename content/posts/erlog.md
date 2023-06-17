---
author: "Shuntian Liu"
title: "Erlog: A Distributed Datalog Engine"
description: "Showcasing a project on building a distributed Datalog engine in
Erlang"
date: 2023-04-16T19:53:43Z
draft: false
tags: ["datalog", "computer science", "distributed systems", "fixpoint",
 "MapReduce"]
---


## Introduction

In this blogpost we build a distributed datalog engine that can process datalog
queries such as the one below in a distributed fashion. The key idea mimics
the usual 
[dataflow programming](https://www.sigops.org/2020/the-remarkable-utility-of-dataflow-computing/) 
idea such as MapReduce where we shard our data
and create a dataflow-graph to specify the computation we want.

```erlang
link("a","b").
link("b","c").
link("c","c").
link("c","d").
link("d","e").
link("e","f").

reachable(X, Y) :- link(X, Y).
reachable(X, Y) :- link(X, Z), reachable(Z, Y).
```

We will build our engine from first principle by looking at how we perform single
node evaluation of datalog queries, and then extend it to multiple nodes.

## Datalog

Datalog is a declarative logic programming language. It is rooted in the database systems community and was first developed in the eighties and early nineties.

### Syntax

A datalog program is a collection of datalog rules, and each rule has the form:

```text
A :- B1, B2, ..., Bn.
```

where `A` is called the *head* of the rule, and `B`'s constitutes the *body*
of the rule.  `A` and `B` are called atoms in datalog (notice this is a different use of the term atom from Prolog, where atoms are just constants), and each atom has the form `pred_sym(term, term, ...)`, where `pred_sym` is the predicate symbol, or the name of the atom, and terms are the arguments. Each term can either be a constant, which starts with a lower case letter, or a variable, which starts with a capital letter. For example, `reachable(X, Y)` is an atom, with the predicate symbol reachable and two arguments, `X` and `Y`, both of which are variables.



## Single node


Before we carry out distributed evaluation, we first need to understand how a
single-node datalog engine works. Briefly, each datalog query can be compiled
into a relational algebra (RA) statement, and we apply these RA queries with a
bottom-up fashion until we reach the fix point.


### Database & Relational algebra

It turns out that each datalog query can be mapped to a corresponding relational
algebra operator. For example:

```erlang
reachable(X, Y) :- reachable3(X, Z, Y).
```

can be mapped to

\\[
  \mathrm{reachable}(X, Y) = \pi_{X,Z}(\mathrm{reachable3}(X, Z, Y))
\\]

And rules like

```erlang
reachable(X, Y) :- reachable3(X, Z, Y).
```

can be mapped to

\\[
   \mathrm{reachable} = \pi_{X,Z}(\mathrm{link}\bowtie_{2=1}\mathrm{reachable})
\\]

### Bottom-up evaluation

Bottom-up evaluation[^2] starts from, as its name suggests, the ``bottom``, or the
initial input data, and repeatedly work towards a fixpoint, which is the final
results we are looking for.

Let's consider an example where we want to find out all connected edges in a
graph (a.k.a. transitive closure), given some initial connections between nodes,
for example:

```goat
    .-.         .-.        .-.        .-.            
   | a +<----->| b +<---->| c |<---->+ d |
    '-'         '-'        '+'        '-'       
```

```erlang
link(a, b).
link(b, c).
link(c, d).

reachable(X, Y) :- link(X, Y).
reachable(X, Y) :- link(X, Z), reachable(Z, Y).
```

Applying the rule in iteration one would give us two extra edges, i.e.

```erlang
link(a, c).
link(b, d).
```

And applying the rule again gives us

```erlang
link(a, d).
```

And we have computed all edges of the graph (i.e. the transitive closure) in two
iterations. The termination condition is that we no longer get new edges after
applying these rules.

There is a indeed an algorithm for doing such bottom up evaluation called semi-naive
evaluation[^3]. Intuitively, this algorithm takes the initial input and apply the
RA operators derived from the input datalog rules on them to obtain new data,
or deltas. These deltas are then used as the new input in the next iteration
to obtain deltas for iteration two. We carry on this process until we reach a fixpoint,
i.e. we longer get new data when applying rules on the data.


## Distributed evaluation

We have seen how Datalog can be evaluated on a single node. It is time to evaluate
it in a distributed environment.

### Why & How

Now before diving into the details of how to do distributed evaluation of datalog
queries, one might ask what good it brings to us if we do this, and why is
distributed evaluation a good way to do this. The benefits of distributed computing
is to offload the computation from one node to many others. This sounds attractive
since we can now offload the computation from one node to many others. But it also
brings numerous other problems including how to coordinate multiple nodes so that
the final result is consistent with single node computation.

The parallelism we want to extract here is data-level parallelism, i.e. we wish
to partition the input data into multiple copies and (ideally) ask workers to
perform computation on each copy independently. As we have seen above that datalog
queries can be compiled into relational algebra operators like projection and
join, the remaining question is how we can do these RA operators in a distributed
way. As you might have guessed, operators like projections can be mapped nicely
to a subset of data, i.e. 
\\[\pi_X(R_1 \cup R_2 \cup \ldots \cup R_n) = \pi_X(R_1)\cup \pi_X(R_2)\cup \ldots \cup \pi_X(R_n)\\]

The tricky case is actually join, if we are not careful with how we partition the
data, two tuples that might have been able to generate a new tuple could be
partitioned into different parts and hence cannot be joined. To this end we deploy
a distributed hash join technique, often used in the distributed database query
evaluation.

### Distributed join

Joins are tricker as we cannot just partition input arbitrarily since this might
result in tuples that could have been joined together, such as `link(a, b)` and
`link(b, c)` ending up at different nodes and therefore cannot be joined together.

We use a technique called *simple distributed (hash) join* to resolve this issue. This
algorithm originates from the database community. In short, it performs hash
on the attributes to be joined and splits tuples according to such hash. In such
way, the tuples above (`link(a,b)` and `link(b,c)`) will be hashed into the same
partition and therefore can be joined together, and similarly for other tuples.
In this way, we can now distribute our join across multiple nodes and each of
them can perform the join independently. We have achieved data parallelism
through this combination of distributed join and other relational embarrassingly
parallel relational algebra operators.


### Architecture

The Erlog itself follows a popular master-worker approach, a bit like [Apache
Flink](https://nightlies.apache.org/flink/flink-docs-master/fig/processes.svg).
The master is responsible for coordinating the process of distributing work and
supervising the progress of workers, while the worker performs their work
independently and report back to the coordinator when finished.

One common problem in such a MapReduce-like system is stragglers. While computing
a Datalog query, there are often tasks that have to be completed before other
tasks can start. One straggler can sometimes slow down the entire pipeline of
computations. To this end, we adopt a LATE scheduler that can estimate the
progress of a task and then detect slow workers. Based on this estimation,
it can launch tasks speculatively to reduce the impact of slow workers.


### Limitations

During my experience of implementing Erlog, I observed several limitations of
performing distributed computation using a MapReduce framework:

1. Shuffle phase is heavy weight, and there are a lot of data to be moved around
with a workload like this.
2. Repeated storeage of intermediate results on each node wastes a lot of memory,
and also lots of memory bandwidth. To solve this issue, a shared memory system
like [Spark](https://spark.apache.org) can be useful.


## Conclusion

In this post we demonstrated a way of evaluating datalog queries in a distributed
environment. Starting from how to evaluate a datalog query to extending it to
distributed evaluation. There are actually many connections between datalog and
the database query community, therefore lots of chances for research and optimisation
to this existing approach. Hope you find this post interesting and perhaps try
playing with Datalog yourself[^1]. There are also production-ready single-node
Datalog engines such as [Soufflé](https://souffle-lang.github.io) which is 
also blazingly fast.

## Appendix

Feel free to checkout the [full dissertation](/writeup/erlog.pdf) for a more formal
and complete description of the project and the code
[repo](https://github.com/Vincent-lau/erlog).

[^1]: [This post](https://dodisturb.me/posts/2018-12-25-The-Essence-of-Datalog.html)
from my project supervisor is a more tutorial style guide on how to build a datalog
engine. Check it out!

[^2]: As opposed to top-down evaluation strategy, which starts from the goal and
gradually work towards the given condition.

[^3]: There is also a naive evaluation which uses the full data rather than
deltas.
