---
title: "Erlog"
date: 2023-01-08T19:53:43Z
draft: true
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


### Syntax

### Bottom-up evaluation


## Single node

## Distributed evaluation


### Distributed join



### Performance

### Fault tolerance


### Limitations

## Conclusion