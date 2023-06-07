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

{{< figure src="/image/hypermnesia/mesh.svg" caption="Example Mnesia cluster of five nodes. Note they always form a fully connected network." >}}

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

The above two examples showcase the two consistency models provided by Mnesia:
transactional ACID guarantee and weak consistency. The former is almost the
strongest consistency guarantee in a distributed system, while the latter is the weakest.
We start to see that there is something "intermediate" missing: perhaps an intermediate
consistency model between these two extremes.


## Eventual consistency

Eventual consistency is defined as follows: ``If no new updates are made to the object,
eventually all accesses will return the last updated value''. This is a much
weaker guarantee than transactions, but is still better than weak consistency.

When designing an API for Mnesia with eventual consistency, an natural extension
would be to add a new access context. For example:

```erlang
mnesia:async_ec(fun () ->
  mnesia:write({tab_name, k, v}),
  mnesia:read({tab_name, k})
end).
```

This would allow developers to use this without too much refactoring, or how the
API works underneath, so that we are free to choose the exact implementation
strategy for eventual consistency. There are indeed many ways to achieve eventual
consistency, but they typically involve several steps:

1. Decide the replication protocol, e.g. master-worker, leaderless, etc
2. Decide the anti-entropy protocol, e.g. gossip, read-repair, broadcasting.
3. Choose a conflict resolution protocol, e.g. CRDTs, LWW, etc.

The first two factors are very much determined by Mnesia design already, so we
will focus on the last one, which Mnesia does not address. We will focus on
CRDTs in this blog post since it is quite a popular choice for conflict resolution.

## CRDTs

Conflict-free Replicated Data Types (CRDTs) are a family of replicated
data types with a common set of properties that enable operations to be performed
locally on each node while always converging to a final state among replicas if
they receive the same set of updates. There are two types of CRDTs: state-based
and operation-based (op-based).

Intuitively, state-based CRDTs propagate their states during the communication
(or the anti-entropy protocol) between replicas, while op-based CRDTs send the
operations. For example, a state-based Set CRDT would send elements in the set
as its state, while op-based Set sends the operation such as `add` and `remove`.
These CRDTs have their own pros and cons. In short, state-based CRDTs put less
constraint on the channel but have larger communication overhead. Op-based CRDTs
often require causal broadcast but have lower communication cost since they
are only sending the operations rather than the entire state.

Mnesia's dirty operation has an immediate synchronisation model, i.e. when a client
sends an operation to a replica, it is immediately sent to all the replicas in the
cluster. Moreover, this process does not involve any inspection of the current
state of the database, which is needed for most state-based CRDTs (and some op-based
CRDTs as well). For these two reasons, op-based CRDTs are a bit more suitable
for our purpose of extending Mnesia to support automatic conflict resolution,
or in particular, pure op-based CRDTs. These CRDTs are designed to not inspect
the current state of the database and only broadcast the operations (and the associated
payload). We are going to use a pure add-wins set, which has the following requirements:

1. Operations must be delivered reliably.
2. Operations need to be delivered in causal order[^1].
3. When there are causally concurrent addition and deletion, then add-wins semantics
specifies that addition takes precedence over deletion.

[^1]: For those who are not familiar with causal delivery, intuitively, this is
just saying that a message cannot possibly be delivered if its causal predecessor
has not been delivered. For example, if my message of this dish is so delicious
depends on the fact that I previously received an image of the dish, then the
other people must see the image before seeing my praise.


With these requirements, we can now enjoy the nice property provided by the op-based
CRDTs:

*Any two replicas of an op-based CRDT eventually converge under reliable
broadcast channels that deliver operations in delivery order \\(<_d\\).*

### Example




## Benchmarks



## Conclusion


