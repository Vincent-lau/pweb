---
title: "System Proof 101"
date: 2024-03-23T17:48:35Z
description: "A introductory blog on formal verification of systems"
tags: ["formal verification", "coq", "computer systems"]
draft: false
---

This blogpost is the first part of a trilogy of formal verification on computer
systems. Here we will take a quick tour of what formal verification means, with
a particular focus on verifying systems software and examples of verifying some
file system. 

## What do you mean by formally verified systems?

Sometimes we hear people say we have built this formally verified system that is
provably correct, and does all sorts of amazing things without bugs. But what
we mean by having a system formally verified? At a high level, a formally verified
system often has a formal specification which mathematically stipulates what the
system ought (and ought not) to do, followed by a proof that such a concrete
realisation of the system meets such a spec.

One question that has I think this comes down to which layer of the abstraction is verified. Modern systems will inevitably
consist of many layers of abstractions, from the application itself down to the
implementation and even to the hardware. There is not much work (as far as I am
aware) that can do full stack verification, from the application to the hardware,
for example. One could develop a system and by having a verified protocol: say I
want to develop (yet another) system that can provide distributed consensus,
and I grab an off-the-shelf verified protocol (like Paxos) and implement it, and
claim that I have got a formally verified system. Well the Paxos protocol might
be formally verified, but that is far from saying that your consensus system is
verified: Who knows if you are actually implementing the Paxos protocol, maybe
you are writing Raft? And how do I know there is no bug in your system? Why should
I believe that the runtime of whatever language you are writing in is correct,
how do I know if the OS is correct, how about the hardware? The latter components,
such as OS and hardware, are certainly not the weak parts of the chain, but still,
there is proof that they have been formally proved to be correct. What I am trying
to reach here is that computer systems are complex and what verification can often
(and realistically) do is to verify one (small) part of the stack (often the protocol
and implementation layer).

{{< figure class="svg" align="center" src="/image/system-proof/sys_stack.svg" >}}

## Specification

So far we have been talking quite abstractly about how we wish to prove the correctness
of a system. In the next two sections I will be using a couple of concrete examples[^1]
to illustrate the proof process.

Suppose we wish to specify a replicated disk protocol, and provide an implementation
that meets such a protocol. A replicated disk protocol is commonly used for fault
tolerance purposes, sometimes referred to as [RAID](https://en.wikipedia.org/wiki/RAID),
where multiple physical disks are connected to provide one logical disk. Under the
hood, when one of the disk fails, it can then transparently switch to other failover
disks to continuously provide the disk service. The user does not need to worry
about this failover/switching process, all user gets to see is that their disk
is continuously working, despite the actual failure that has happened.

Let's try to specify what we expect a normal disk would do (no fancy failover whatsoever).
One might imagine it provides two basic functionalities:

```coq
Axiom read: addr -> proc block
Axiom write: addr -> block -> proc unit
```

The `proc` type above is just some kind of monad constructor that lifts the return
value to the monadic world.

The next step would be to specify what these operations are expected to do. We
can do that in a (crash) Hoare style logic, referring to the pre/post-condition
of our read operation. For example:

```coq
Definition read_spec (a: addr) :=
  fun (_: unit) state => {|
    pre := True;
    post := fun r state' =>
      state' = state /\
      diskGet state a =?= r;
    recovered := ...
  |}.

Definition write_spec (a : addr) (v : block) :=
  fun (_ : unit) state => {|
    pre := True;
    post := fun r state' =>
      r = tt /\ state' = diskUpd state a v;
    recovered := fun _ state' => ...
  |}.
```

There are lots of details here to be explained (I will omit the recovered condition
for this post, to simplify the explanation), but we can focus on the important
part, which is the pre and post conditions of these specs. For read, it says,
whatever it is initially, after the read, the state (that is, the disk blocks)
stays the same, and the return value `r` is equal to the actual value stored in
the disk state `state` at addr `a`. Contrast this with the simplest Hoare logic
triples:

```text
{X = 1}
{X + 1 = 2}
X := X + 1
{X = 2}
```

the `state` variable above refers to the stack in the usual Hoare logic, and the
`disk*` operations are just helper functions defined on the state to talk about
certain properties of the state.

Now we have specified what it means for a disk to function correctly in terms
of read and write, we can start specifying our replicated disk. We assume there is
a two disk library that has already been specified and verified for us, on top of
which we will specify the replicated disk. The spec might look something like this:

```coq
Theorem read_int_ok : forall a,
    proc_spec
      (fun d state =>
          {|
            pre := two_disks_are state (eq d) (eq d);
            post :=
              fun r state' =>
                two_disks_are state' (eq d) (eq d) /\
                diskGet d a =?= r;
            recovered := ...
          |})
      (read a)
      td.recover
      td.abstr.

Theorem write_int_ok : forall a b,
    proc_spec
      (fun d state =>
          {|
            pre := two_disks_are state (eq d) (eq d);
            post :=
              fun r state' =>
                r = tt /\
                two_disks_are state' (eq (diskUpd d a b)) (eq (diskUpd d a b));
            recovered := ...
          |})
      (write a b)
      td.recover
      td.abstr.
Proof.
```

where now the state becomes a pair of disks, which comes from the two disk library.
And our pre/post conditions refer to both of these disks, which the `two_disks_are`
function helps us to express. In particular, note that the `write` spec says that
after a (successful) write operation, the state of both disks would be the same,
i.e. both updated.

So far I believe the specs are all pretty straightforward and how one would expect
a duplicated disk would behave. The important thing to highlight (and will be mentioned
later on in the [Abstraction](#abstractions) section as well) is that there are
different layers: there is the top level single disk spec, the intermediate 
two disk disk spec, and the replicated disk spec which sits above the two disk
spec and below the single disk spec, connecting these two together by implementing
the two sing disk API, using the two disk API. This is indeed the power of abstraction,
which prevails many aspects of software development, and naturally manifests in
formal verification as well.

{{< figure class="svg" align="center" src="/image/system-proof/disks.svg" >}}


## Implementation

The actual implementation of a replicated disk should be quite familiar to many
of the software engineers/computer scientists. The general strategy is to do the
operation on both disks, and return the appropriate value. I will include the code
here for completeness, but the code itself should be quite straightforward.


```coq
Definition read (a:addr) : proc block :=
  mblk <- td.read d0 a;
  match mblk with
    | Working blk => Ret blk
    | Failed =>
      mblk <- td.read d1 a;
      match mblk with
        | Working blk => Ret blk
        | Failed => Ret block0
      end
  end.

Definition write (a:addr) (b:block) : proc unit :=
  _ <- td.write d0 a b;
  _ <- td.write d1 a b;
  Ret tt.
```


## Abstractions

In this section we take a quick detour on the actual example and talk about abstraction
abstractly :) before we return to our replicated disk example.

### Abstractions, abstractly

Abstraction is at the core of many areas of Computer Science. Whether we are building
software or hardware systems, we rely on layers of abstractions to help us produce
good design and focus on the property we care about with the right level of detail.
This is no different to formal verification. In fact, a specification itself can
be thought of as an abstraction of the underlying system. We specify in precise,
rigorous mathematical language how we want our system to behave and then we prove
that our actual design/implementation meets such a specification.

The diagram[^1] below summarises this in a very concise manner

{{< figure align="center" class="svg" src="/image/system-proof/abstr.svg" >}}

We write down our spec in a mathematical language, examples would be in a Hoare
logic style, and then as we execute our code step by step, the state of our world
gets changed (think about the state of an abstract state machine, Turing machine,
register machine, etc). If initially we are in state \\(w\\), and as we execute
our code, we transitioned to state \\(w'\\). Now if our abstraction relation holds
when we were in \\(w\\), then we need to show that there will be a new spec \\(s'\\) that
satisfies the abstraction relation in \\(w'\\) as well, _and_ this new spec is not
a random spec, but one where there is a valid transition from the old spec \\(s\\).
For example, if we are writing a our spec using Hoare logic, then the allowed transition
would be from the precondition to the postcondition. In a TLA-style model checking
spec, this would be encoded as part of the state transition relation.
In the diagram above, the solid lines indicate our assumptions, and dashed lines
are what we need to prove. Mathematically:

$$
  w \to w' \land \mathrm{abstr}(s, w) \implies 
  \exists s', \mathrm{abstr}(s', w') \land s \to s'
$$

If we do this for every _step_ of the program, and compose them together, we get
a proof that: if our program is in a initial state allowed by the spec, it will
be in a final state allowed by the spec, and we have proved that our program
satisfies/simulates/refines the spec! Intuitively, this means we have found a
concrete instantiation (i.e. the implementation) of our spec and proves it is
indeed a valid instantiation.

Note that not only can we compose this diagram horizontally to get a proof from
each instruction of the program, we can also stack it vertically to get a prove
about multiple layers of the system. This is indeed what IronFleet[^2] does, where
they used TLA-style state-machine refinement to verify that a Paxos-based consensus
protocol satisfies the high level spec (presumably reaches consensus), and then
use Floyd-Hoare-style logic to prove that their implementation of the system satisfies
consensus protocol. In the end, we get a system implementation (with actual binaries)
that meets the mathematical spec (they will reach consensus).

This idea of abstraction is reminiscent of the abstraction/encapsulation we see
in Object-oriented programming (and indeed in many other areas of Computer Science).
The similarity lies in that in OOP, programmers can just look at the interface
of a class and know how to use them, without worrying about how they are implemented.
And with formally specified code, we can check the spec of the code, and try to
see whether the spec is correct, which is usually much easier than looking at the
code and trying to find bugs. In other words, the spec is doing a similar thing
as the interface: to provide something that can be quickly inspected by the programmer,
knowing that the developer of the library/implementation has done the hard work
to make sure that the implementation has indeed satisfied the spec. The spec can
also be thought of as an enhancement of the documentation/type signature provided
by many of the libraries. Developers often need to read the doc/type signature
to understand how to use the API, the difference is that the documentation is
in natural language and provides no guarantee whatsoever that the implementation
does actually folllow the doc. Type signature, on the other hand, does provide
these guarantees by the compiler that at least the implementation takes the right
arguments and returns the value of the right type. Type systems, however, are often
not (yet) expressive enough to convey all the details in the doc though, and that
is why developers need to write prose to augment the type signature.
The spec is almost like a more expressive type system that allows one to express
the intention of the API in a mathematical language and have them machine-checked,
just like the type checking. In fact, the trend we see in programming language
type system design is that they are more and more expressive: from weak types to
strong types to borrow checker, dependent types, linear types, graded types, etc.
We shall discuss more on the this trend in 
the [real world applicability section](#how-applicable-are-these-systems).


### Abstractions in a replicated disk

(Un)fortunately the abstraction relation which connects the single disk state
and the replicated dual disk state is fairly straightforward:

```coq
Definition rd_abstraction (state: TwoDiskBaseAPI.State) (d:OneDiskAPI.State) : Prop :=
  two_disks_are state (eq d) (eq d).
```

which basically says that a single disk `d` and dual disk `(d1, d2)` is related
if `d = d1 /\ d = d2`, which is again, what one would expect from a replicated disk.

### Abstractions in a file system log disk

To illustrate the power of abstraction, here is another example where we are trying
to implement a write-ahead log. We will implement on top of the single disk api.
The basic strategy is to have one block in our disk to record the size of our
current log, and anything beyond the size stored in that block is considered invalid.
With the assumption that each individual disk write is atomic, we can achieve atomic
writes to the entire block with this implementation (by writing the actual data
first and does not commit until we atomically write to the first block).


```coq
Inductive log_abstraction (rd_disk: OneDiskAPI.State) (log_state: LogAPI.State) : Prop :=
  | LogAbstraction:
    forall
      (Hblock: forall b : block, diskGet rd_disk 0 =?= b ->
      (block_to_addr b) + 1 <= diskSize rd_disk /\
      diskGets rd_disk 1 (block_to_addr b) =??= log_state),
    log_abstraction rd_disk log_state.
```

This is Coq's inductive definition, which says that two states `OneDiskAPI.state`
and `LogAPI.state` is related if we can find a type constructor. And there is
only one type constructor, namely `LogAbstraction`, which says that for all the
hypothesis `Hblock`, the abstraction relation holds, i.e. if there is a hypothesis
that looks like `Hblock`, and it is proved to be true, we can conclude that
`log_abstraction` holds.

The hypothesis itself, in this case, just says, the first block is a valid block,
and the rest of the block up to the size stored in the first block, is the same
in the log and the one disk.

There are lots of details left out in the abstraction relation (and in the actual
proof, this is where the devil is in). But at least intuitvely, this abstraction
relation is, again, self-explanatory and as expected.

And this is it in terms of specifying, implementing and abstracing our replicated
disk protocol. Now the only thing left to do is (just?!) to prove that these things are
actually true, which I will not bore you with. At a high level, a user of this
replicated disk library would just need to check the spec of its api and ignore
the rest (such as implementations, abstractions, proofs) but still have the confidence
in the correctness of the system (as long as the author of this library is not doing
completely crazy things such as defining the abstraction relation to `True`).


## Reference


[^1]: Adapted from the [6.826 course](6.826.csail.mit.edu/2020), thanks to the course
staff for providing guidance and the proof infrastructure!

[^2]: Hawblitzel, C. et al. (2015) ‘IronFleet: proving practical distributed systems correct’, in Proceedings of the 25th Symposium on Operating Systems Principles. SOSP ’15: ACM SIGOPS 25th Symposium on Operating Systems Principles, Monterey California: ACM, pp. 1–17. Available at: https://doi.org/10.1145/2815400.2815428.
