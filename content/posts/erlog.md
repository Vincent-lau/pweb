---
title: "Erlog"
date: 2023-01-08T19:53:43Z
draft: false
tags: ["datalog", "computer science", "distributed systems", "fixpoint"]
---


*[This work in currently in progress, therefore still kind of reliant on a long
and verbose [dissertation](/writeup/diss.pdf), but I plan to shorten it into a self-contained 
blogpost when I have more time]*


## Introduction

In this blogpost we build a distributed datalog engine that can process datalog
queries such as the one below in a distributed fashion. The key idea mimics
the usual 
[dataflow programming](https://www.sigops.org/2020/the-remarkable-utility-of-dataflow-computing/) 
idea such as MapReduce where we shard our data
and create a dataflow-graph to specify the computation we want.

```
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



## Single node

### Bottom-up evaluation


### Database & Relational algebra

It turns out that each datalog query can be mapped to a corresponding relational
algebra operator. For example:

```text
reachable(X, Y) :- reachable3(X, Z, Y).
```

can be mapped to

\\[
  \mathrm{reachable}(X, Y) = \pi_{X,Z}(\mathrm{reachable3}(X, Z, Y))
\\]

And rules like

```text
reachable(X, Y) :- reachable3(X, Z, Y).
```

can be mapped to

\\[
   \mathrm{reachable} = \pi_{X,Z}(\mathrm{link}\bowtie_{2=1}\mathrm{reachable})
\\]


## Distributed evaluation

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



### Performance

### Fault tolerance & Stragglers


### Limitations

## Conclusion

In this post we demonstrated a way of evaluating datalog queries in a distributed
environment. Starting from how to evaluate a datalog query to extending it to
distributed evaluation. There are actually many connections between datalog and
the database query community, therefore lots of chances for research and optimisation
to this existing approach. Hope you find this post interesting and perhaps try
playing with datalog yourself[^1].

## Appendix

Feel free to checkout the [full dissertation](/writeup/diss.pdf) and the code
[repo](https://github.com/Vincent-lau/erlog).

[^1]: [This post](https://dodisturb.me/posts/2018-12-25-The-Essence-of-Datalog.html)
from my project supervisor is a more tutorial style guide on how to build a datalog
engine. Check it out!
