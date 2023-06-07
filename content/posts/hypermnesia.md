---
title: "Hypermnesia: Eventual Consistency in Mnesia"
date: 2023-06-06T19:26:33+01:00
description: "Extending Mnesia with automatic reconciliation"
draft: true
tags: ["Eventual consistency", "CRDTs", "Mnesia", "Erlang"]
---


## Motivation

Mnesia is a soft real-time embedded Database Management System written for Erlang,
a programming language that powers the infrastructures of various organisations
such as Cisco, Ericsson and the NHS. Due to Mnesia’s tight integration with Erlang,
it is also impactful in open source projects such as RabbitMQ and ejabberd.

However, the development of Mnesia has remained stagnant for years, resulting
in the lack of features such as automatic conflict resolution: Mnesia leaves
the handling of conflicts after network partitions entirely to the developer.
Moreover, as a distributed database, Mnesia only provides two extreme forms of
consistency guarantee: transactions and weak consistency. Existing solutions to
this problem are either external libraries or commercial standalone products,
none of which is integrated into Mnesia natively. This means Erlang developers
often have to introduce new dependencies into their codebase or resort to less
ideal alternative databases.

The question we want to ask is whether it would be possible to introduce automatic
conflict resolution into Mnesia, so that developers do not need to resolve this
conflict each time there is a network partition. To understand how we can achieve
this, we first need to understand how Mnesia works.

{{< figure src="/image/hypermnesia/mesh.svg" caption="Mnesia cluster connection" >}}

## Mnesia

### Architecture

Mnesia is built on top of Erlang’s built-in memory and disk term storage `ets` and `dets`.
These term storage can be thought of as primitive storage engines that provide
constant (or logarithmic) access time for large amounts of data [28]. They support
different data structures for storing data, such as set, bag, etc. Internally,
these are implemented as hash tables or balanced binary trees. Mnesia also provides
additional functionalities such as transactions and distribution on top of
`ets` and `dets`.

A Mnesia cluster generally has a leaderless architecture where every replica can
handle client requests. A cluster of Mnesia nodes are connected via the Erlang
distribution protocol, which uses TCP/IP as its carrier by default, providing
reliable in-order delivery. Moreover, the connection is transitive, which means
the nodes form a cluster of fully connected nodes (or a mesh).


### Access contexts and consistency models

A central API provided by Mnesia for table manipulation is given below.
A user calls the activity function which takes in an access context, a function
to be executed, and a list of arguments. Currently supported access contexts
include transactions and dirty operations.

An example of access to Mnesia using transactions is given below.

```erlang
mnesia:transaction(fun () ->
  mnesia:write({tab_name, k, v}),
  mnesia:read({tab_name, k})
end).
```

Or using (asynchronous) dirty operations:

```erlang
mnesia:async_dirty(fun () ->
  mnesia:write({tab_name, k, v}),
  mnesia:read({tab_name, k})
end).
```




## Eventual consistency


## CRDTs


## Benchmarks



## Conclusion


