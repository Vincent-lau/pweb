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

{{< figure align="center" src="/image/hypermnesia/mesh.png" width=200 >}}

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



### Example 1 Buffering operations

The first example is a simple case where there are no conflicting operations.
In the following diagram, initially three replicated nodes are holding the element
`x` in a set-like data structure. Now when there is a partition happening
between node A and node B, as well as node A and node C (indicated by dashed lines),
the insertion operation of `y` at node B cannot be propagated to node A. Now the
replicated database is in an inconsistent state since node A is holding different elements
from node B and node C. When the partition heals, Mnesia reports an error message
to the developer and asks them to resolve the conflict manually.

{{< figure align="center" src="/image/hypermnesia/mnesia_comm_failure.png" >}}

Hypermnesia solves this issue by buffering the operations during the partition.
In the second diagram below, node A and node B are buffering the addition of
`y` and `z` respectively. When the partition heals, the buffered operations are
propagated to the other nodes. By the property of op-based CRDTs, as long as replicas
receive the same set of operations, they are guaranteed to be in the same state.
This nice property helps us resolve conflicts automatically and achieve eventual
consistency.

{{< figure align="center" src="/image/hypermnesia/hypermnesia_buffer.png" >}}

Now buffering alone is not enough to achieve automatic conflict resolution
as there are more complex cases with, say, concurrent additions and deletions.
And this is where we need the power of a CRDT. Let's look at the next example.

### Example 2 Concurrent addition and deletion

When a network failure happens, communication between nodes temporarily
stops but is not long enough for the failure detector to act. Transactions
will completely stall during this period. Although dirty operations can carry
on, replicas might end up in different states due to out-of-order message delivery.
For example, in the following diagram, there might be a
network failure between node B to A, resulting in B's `add a` being delayed.
If messages are delivered as they arrive, then node A and node C will end up in
an inconsistent state. This is because addition and deletion in a set
do not commute, and the two purple operations (add and delete) are concurrent, and
they are applied in a different order on node A and node C, resulting in different final states.

{{< figure align="center" src="/image/hypermnesia/cc_set1.png" width="400">}}

In order to achieve convergence, and hence eventual consistency, concurrent
operations need to commute.
The exact semantics of whether addition or deletion wins depends on the actual
application, and to achieve convergence, it is sufficient to
define consistent semantics across replicas. Add-wins semantics is presented here
but the remove-wins semantics is similar. To achieve
add-wins semantics with a pure op-based Set CRDT, we require deletions
to only remove elements that causally precede it.
In the following diagram,
the deletion with timestamp [2,0,0] removes the element (a,[1,0,0])
which is causally lower, but not (a,[0,1,0]) which is causally concurrent.

{{< figure align="center" src="/image/hypermnesia/cc_set2.png" width="500">}}

## Benchmarks

So how does Hypermnesia actually perform when compared to transactions and
dirty operations. We can see this by running benchmarks. This benchmark is a
modified version of Mnesia's built-in benchmark, extended in order to support
the new access context.

We compare the throughput and latency of three operations: dirty, transactions
and ec (the new eventually consistent access context introduced by Hypermnesia).
Two diagrams shown below represent the throughput and latency against the number
of generators/clients per node, both of them are in log scale (because the
difference between dirty and transactions is often too large). For throughput
we see that if we add more clients to the system, the database scales with the
increased clients and the throughput increases as well. For latency, there is
increase in all three operations, due to the inevitable overhead of more clients,
but this affects mostly the dirty operation since its original latency is already
quite low, and small increases in overhead can give a large overall increase.
EC operations generally stay stable as we add more clients, which is a desirable
property.

{{< figure align="center" src="/image/hypermnesia/hypermnesia_bench.png" width="700">}}


## Conclusion

In conclusion, Mnesia is a distributed embedded database built in and for Erlang/OTP.
Its tight integration gives its outstanding performance, but its lack of automatic
reconciliation after partition is a major drawback. Here we introduced Hypermnesia,
a native extension of Mnesia with a new `async_ec` API that provides eventual
consistency and hence automatic conflict resolution, exploiting the power of
CRDTs.

## Appendix

There are plenty more I did not cover in this post, feel free to check out my
full [dissertation](), the [code [repo](https://github.com/Vincent-lau/otp) and 
the two videos below.

### Presentation

{{< youtube id="pisH9HgEZjw" title="hypermnesia demo" >}}

### Demo

{{< youtube id="qfVU4IQBrQI" title="hypermnesia presentation" >}}
