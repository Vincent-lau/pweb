---
title: "Proof System Case Study"
date: 2024-03-30T23:50:10Z
description: "A brief study of formally verified systems"
tags: ["formal verification", "survey", "computer systems"]
draft: false
---

This blogpost is the second part of a trilogy of formal verification on computer
systems. Here we will take a quick tour of what formal verification means, with
a particular focus on verifying systems software and examples of verifying some
file system. If you have not read the previous post on
[system verification]({{< ref "/posts/system-proof-101.md" >}}), feel free to jump
there first for an introduction!


## Case studies

### CompCert

CompCert[^1] is probably one of the first and most famous verified compilers (and
perhaps also computer systems). It is itself a significant piece of work which
took around 15 years. It is a rather important corner stone, however, that is achieved
by the verification community, with tools/frameworks available in 2009, it is already
possible to formally verify a complex system such as a compiler.

The verification is done through the notion of semantic preservation, which is
amenable to compiler passes. A compiler will run a number of passes on the code,
transforming the code into structures that is desirable for a particular target
(often the binary executable, but could be something else). The paper formally
defines the semantic preservation as

$$
S\ \mathrm{safe} \implies (\forall B, C \Downarrow B \implies S \Downarrow B)
$$

where a safe source (S) excludes non-determinism from the source such as undefined
behaviours where the compiler can do whatever it wants to. This is saying: given
that the source input program is good, the produced code C should only contain
behaviours that is allowed by the S.

A verified compiler is then defined as:

$$
\forall S, C, \mathit{Comp}(S)=\mathtt{OK}(C)\implies S\approx C
$$

which says that our verified program can produce nothing, but it never produces
something that is incorrect.

And the rest of the steps would be to define formal semantics for S and C, and
define a simulation relation (as in the [abstraction relation](#abstractions))
to prove that a step in the higher level code is locked by a step in a level below.

CompCert does have some limitations, though: for example, some parts of it is not
verified (lexer, parser), and indeed there has been bugs found in the unverified
part of CompCert. But otherwise I think it is very impressive work, especially
considering that the performance of its generated code is competitive with `gcc`
with with optimisation turned on.


### FSCQ

FSCQ[^2] is a verified file system that incorporates crashes. The main novelty
in this paper is that the author extended the usual Hoare triple \\(\\{P\\}C\\{Q\\}\\)
with a new crash condition that describes the state of the system just _before_
the crash happens. This allows them to reason about the the behaviour of the
system when it crashes, which is arguably quite important for file systems, since
crash safety is one of the important features of a file system, and crash recovery
is implemented in tools such as `fsck`, therefore it is important to understand
the formal behaviour of such a system. A simple example from the paper illustrates
this well:

$$
  \begin{align}
    \mathrm{SPEC}:&\ \mathtt{disk\\_write}(a, v)  \newline
    \mathrm{PRE}:&\ \mathbf{disk}:a\to \langle v_0，vs\rangle * \mathit{other\\_blocks} 
  \end{align}
$$


To cope with repeated crashes i.e. crashes that happen while recovery, the spec
of the recovery procedure needs to be _idempotent_, which means that the crash
condition of the recover function implies its precondition, hence we can always
go from a crashed state of the recover procedure back to its starting state again.


### x86-TSO

The x86-TSO is also an interesting work which formalises the shared memory concurrency
model for the x86 architecture. The motivating example given in the paper is fairly
illuminating:

| Proc 0 | Proc 1|
|---------|------|
| Mov x <- 1 | Mov y <- 1|
| Mov Eax <- y | Mov Ebx <- x|
| Allowed final state: Proc 0: Eax=0 /\ Proc 1: Ebx = 0|

What this is saying is that processes are writing to the shared memory, but no
one is observing each other's write. Apparently this is allowed in the x86
(and also AArch) memory model, but developers often have to refer to the x86 manual
(perhaps thousands of pages) to find out if this is indeed allowed by design.

If we had a mathematically precise model for these ISAs, then it would be more
rigorous for developers and easier to verify whether something is allowed by
the model. This is where this paper developed x86-TSO model which formulates
this memory model in HOL4.

### Armada

Armada is a verification language/tool/framework that allows programmers to write
concurrent code with their choice of sync primitives and offers them the flexibility.
It then allows programmers to write a series of more abstract spec about their program,
and prove the refinement. Armada also has mechnically verified proof strategies,
making it more trustworthy.

The way I think about Armada is another layer built on top of Dafny to make verification
simpler. It uses several techniques such as movers to combine blocks, refinement,
explicitly tracking non-determinism through encapsulation, etc. These techniques
help make programmers' (who are trying to implement/verify a program) life easier.


### CertiKOS

This is about a proof of the security property of a system. The systems mentioned
above are usually about the functional correctness of a system, specifying security
of a system presents a different challenge. Firstly it is attractive to do so since
if security often consists of corner cases of code where an attack can be launched,
i.e. they are not in the normal good execution flow. It tends to be hard for developer
to manually rule out all such possible cases. Formal verification can be helpful
as it allows developer to do so-called "structured exploration"[^11], and systematically
rule out possible attacks, subject to the proof assumptions.

The key idea introduced in the CertiKOS[^12] paper is an observation function:
O(principal, state) defines the set of objects/observations that can be made by
the principal. Two states are then indistinguishable when their observations are
the same. If we can then prove inductively that the state indistinguishability
is preserved by the execution, non-interference can be proved, which means that
two traces are different _entirely_ based on the user input/observed data. The
opposite of that would be one process's execution result is interfered by another
one due to, for example, some shared resources being modified. The meltdown attack
can be approximately described as an interference: the (timing) result we get
by launching the meltdown attack is not based on the private data we have, but
some other kernel memory data, for example. This kind of interference by other
process (in this case the kernel, and the CPU) breaks down the isolation between
processes and can cause security problems.


### Industrial scale static analysis

I want conclude the case study with an example of a real-world deployment of static
analysers at scale in industry. We study two articles from Google [^3] and 
Facebook/Meta [^4], where static analysis tools are deployed in (part of) their large
codebase and made impact on their product.

Google developed several static analysers such as FindBugs [^5] for Java program analysis,
Tricoder and JavaFlume. Most of these tools perform intra-procedural analysis,
as Google argues that "Google does not have infrastructure support to run interprocedural
or whole-program analysis at Google scale". We see that in industry companies often
make tradeoffs between full-fledged product and pragmatism: what is the sweet spot
between these two that can be developed? This is often in contrast to academia
research where people wish to pursue a vision/develop a model that is as complete
as possible (arguably academia often makes tradeoffs as well, due to resource
constraints, but probably less so than industry). The 20/80 rule can often be
seen in many places there.

While Google focuses on getting the "effective false positives" (which they define
based on developer action) as low as possible, which often necessarily mean that
false negatives would increase as well. Facebook is coming from a different perspective,
where they do care about false negatives and hence has developed tools like Infer [^6]
to carry out inter-procedural analysis. Facebooks puts an emphasis on different
types of bugs as well: for example, a crash on a busy server is probably
more severe than a memory leak on a rarely hit code path, and they set different
tolerance level for false positives according to the nature of the bug. One extreme
of such would be security bugs, which they set a relatively high tolerance bar.

There are several common themes among the techniques used by these two companies
though:

1. Both of them focus on developer happiness in such tools, by using techniques
such as "diff time" analysis, which just means that potential issues reported
by the static analyser will be fired at code review time. Developers are often
reluctant to fix bugs identified in batch analysis, since these bugs are often
in code that is already in master, perhaps written a long time ago, and most
enginners are now working on a different problem. Dedicating time to fix these
bugs often mean that they had to context switch out of their current problem,
which tend to quite an expensive operation, and also mentally unpleasant.

2. The previous point also implies that these tools need to be intergated with
the developer workflow: from IDE to CI/CD, the earlier the analyser can issue
its finding, the cheaper it tends to be in terms of fixing it. Although here another
tradeoff would be that developer might not want to be bothered by static analyser
when they are delibrately taking a shortcut in their code to test a certain feature,
so review time analysis seems to be a sweet spot.

3. Companies like Google and Facebook has a enormous codebase, even building the
codebase itself can take a long time (see my [S-REPLS14]({{< ref "/posts/s-repls14.md" >}})
 article on build systems
developed by Meta), let along performing complex analysis. Google has taken the
approach to focus on simple yet effective analysis, while Facebook develops incremental
analysis and compositionality model to help speed up their analysis.


### Summary


|                 | system | abstraction level | theorem prover/tools | novelty  |
|-----------------|--------|-------------------|----------------------|----------|
| Static analysis |  code analysis  |   code structure |   FindBugs/Infer  | deployed in industry at scale  |
| CompCert        | compiler |   after parsing, before linking    |    Coq     |  One of the first to verify a complex system |
| FSCQ            |   file system     |    spec to impl. of the FS    |   Coq   |  Crash Hoare/Separation logic |
| x86-TSO         | x86 memory model       |    multicore CPU memory model |   HOL4           |  useful memory model for ISA |
| Armada          |  language for verification |  Impl + progressive abstr.                 |    Built with Dafny  | verification language with flexibility, automation and sound semantic extensibility  |
| IronFleet       | RSM and KV store |  Spec & Impl  |  TLA & Dafny   | breakthrough in distributed system verification  |
| CertiKOS | kernel security | e2e security | Coq | formalisation of security properties: non-interference |


## Does formally verified systems still have bugs?

A good empirical study in this area [^7] points out that most of the time verified
system themselves are quite stable but systems we use inevitably consist of many
layers and it is often the tooling, shim, frameworks around the these verified
systems can go wrong.

Referring to the diagram in my previous [post](/content/posts/system-proof.md),
I have added colour to indicate different levels of verification. Verifying the
whole system stack can often be too expensive to be done, therefore most systems
will focus on one part of the stack. Even in a system such as IronFleet, it is just
the protocol and implementation that have been verified. The rest of the system
is either partially verified or not verified. For example, the specification of
the system is often not verifiable (this is like asking if the type signature of
a function is correct, but it is up to the programmer to decide what type signature
they want a function to have), hence bugs such as incorrect assumptions about
the system (infinite stacks, UDP vs TCP etc) can often cause bugs in the system. The shim
layer that often acts as a wrapper around some of the OS functionalities (for example
some language thin libraries that wrap around OS system calls to ease the life of
developers) might do incorrect translations, handling of errors.

{{< figure class="svg" align="center" src="/image/system-proof/sys_stack_colour.svg" >}}

Although there are still bugs in these verified systems, the good news is that
those verified parts (green ones) are indeed bug-free, unlike many unverified systems.
This does tell us though that verification is not panacea, but merely an integral
part. Practically speaking, we still want to combine testing strategies (fuzzing,
property-based, integration, regression) _with_ formal verification to act, as if,
sanity checks for these formally verified systems.

## How applicable are these systems?

So far these verified systems often still live in their research areas and are
seldom deployed in production. Moreover, there are still quite a lot of beasts
that we need to overcome in order to make these techniques more usable in general
realm of software development. In this section I will be focusing on two major,
in my opinion, obstacles yet to be overcome for formal verification to be widely
used.

### Development

Perhaps what is fairly obvious is that specifying the system consists of certain
overhead, let alone proving them. Needless to say, this would depend on the actual
theorem prover being used. Coq, for example, can often require 10x[^8] proof to code
ratio due to its powerful proof system (which means relatively less automation).
Other tools might be better, anecdotally, Dafny has a much lower proof to code
ratio, which is around 1:10, thanks to its powerful automation. This comes with the
cost that Dafny is a much more complex system that depends on external libraries
and solvers to do the job for it. Bugs/crashes in these external tools might introduce
bugs in a formally verified system. There are lots of other theorem provers available
to choose from, I am planning to write a more detailed survey of these soon, so
stay tuned!

Another overhead in using these formal verifications is that they require extra
learning effort. Again, this would depend on the specific tools being used, but
my personal experience with Coq, even coming from a functional programming background,
is that it still takes quite some effort to get up to speed and do proofs efficiently,
let alone mastering it. Coq has lots of advanced automation features, such as its
`Ltac` tactical language that allows one to develop "higher order" tactics. This
indeed makes proofs more automatable and robust, can take some effort to learn.
The formal verification community is not quite as mature as the programming language
community so its documentation/tutorials might not be as approachable. Moreover,
learning Coq, as pointed out here [^9], is learning _specification_ and _proof_ at
the same time. The good news is that both of them are often interconnected, and
an incorrect specification leads to inability to prove and makes one think about
the spec again. The disadvantage is that learning two things at the same time is
not easy, oftentimes knowing how to write a spec will get you quite far in ensuring
the correctness of the system. That is why there are tools that tries to automate
the proof process and let developers focus on writing a good spec.


### Deployment

Formally verified systems are often not as fast as their unverified counterparts.
Lots of optimisations involving mutable data structures, impure code, which are
fairly tricky to prove. And many of the production systems is a combination of
years of optimisation and fine tuning, whereas formally verified systems are often
developed from scratch (it tends to be tricky to verify an existing codebase,
since their code is not written with verification in mind), and the main focus
is often not getting it as fast as possible. Is it worth using a formally verified
system to get those extra assurance in exchange of some performance downgrades?
Depending on your context, but for software (excluding safe-critical ones), 
maybe not. Since software are relatively easy to fix up, and most of them can be
solved by restarting the system anyway, as long as they are "good enough", users 
won't care if their software is formally verified.

Another question to ask is how maintainable are these formally verified systems?
Ideally we might want to say that our system is 100% correct so there is no need
to maintain (or at least fix bugs) in the first place! But in [reality](#does-formally-verified-systems-still-have-bugs), specs can go wrong, dependencies
might get updated, and there may be new feature requests. Note that updating the
source code of a formally verified system could require updating the proof as well.
One line of change might render the whole proof incorrect (this would depend on
the actual tool used, once again). So do companies want to pay that price for that
extra correctness?

Reflecting on [static analyser section](#industrial-scale-static-analysis), in
order to get more deployment of these systems, we should consider: 1. how can
these verification techniques be integrated into developer's day-to-day workflow;
2. how can we lower the bar of learning to use tools so that developers can get
started quickly; 3. how can we make sure that such systems scale well for large
corporations; 4. is the cost-benefit ration of developing/deploying these tools
striking the right balance for the company to invest in them. Addressing these
open questions is a key part of getting more wide spread usage of these tools.


## Conclusions

Recent years have seen lots of development in formal verifications, especially
in verifying a relatively large piece of software system. Although the real-world
deployment of these systems are still not prevalent, the community has been growing
larger and larger with more formally verified systems, as well as tools/frameworks
for doing such verification.

There are still steps need to be taken to get us towards wider deployment of these
techniques, including learning curves, proof overhead, etc. And to end on a positive
note, formal verification has found its usage in safety-critical systems [^10] and will
probably remain being used in such areas.

## References

[^1]: Xavier Leroy. 2009. Formal verification of a realistic compiler. Commun. ACM 52, 7 (July 2009), 107–115. https://doi.org/10.1145/1538788.1538814
[^2]: Haogang Chen, Daniel Ziegler, Tej Chajed, Adam Chlipala, M. Frans Kaashoek, and Nickolai Zeldovich. 2015. Using Crash Hoare logic for certifying the FSCQ file system. In Proceedings of the 25th Symposium on Operating Systems Principles (SOSP '15). Association for Computing Machinery, New York, NY, USA, 18–37. https://doi.org/10.1145/2815400.2815402
[^3]: Caitlin Sadowski, Edward Aftandilian, Alex Eagle, Liam Miller-Cushon, and Ciera Jaspan. 2018. Lessons from building static analysis tools at Google. Commun. ACM 61, 4 (April 2018), 58–66. https://doi.org/10.1145/3188720
[^4]: Dino Distefano, Manuel Fähndrich, Francesco Logozzo, and Peter W. O'Hearn. 2019. Scaling static analyses at Facebook. Commun. ACM 62, 8 (August 2019), 62–70. https://doi.org/10.1145/3338112
[^5]: https://github.com/findbugsproject/findbugs
[^6]: https://fbinfer.com/
[^7]: Pedro Fonseca, Kaiyuan Zhang, Xi Wang, and Arvind Krishnamurthy. 2017. An Empirical Study on the Correctness of Formally Verified Distributed Systems. In Proceedings of the Twelfth European Conference on Computer Systems (EuroSys '17). Association for Computing Machinery, New York, NY, USA, 328–343. https://doi.org/10.1145/3064176.3064183
[^8]: Upamanyu Sharma, Ralf Jung, Joseph Tassarotti, Frans Kaashoek, and Nickolai Zeldovich. 2023. Grove: a Separation-Logic Library for Verifying Distributed Systems. In Proceedings of the 29th Symposium on Operating Systems Principles (SOSP '23). Association for Computing Machinery, New York, NY, USA, 113–129. https://doi.org/10.1145/3600006.3613172
[^9]: https://news.ycombinator.com/item?id=15781508
[^10]: Cousot, P., Cousot, R., Feret, J., Mauborgne, L., Miné, A., Monniaux, D., and Rival, X. The ASTRÉE analyzer.
In Proceedings of the European Symposium on Programming (Edinburgh, Scotland, Apr. 2–10). Springer, Berlin, Heidelberg, 2005.
[^11]: T. Murray and P. van Oorschot, "BP: Formal Proofs, the Fine Print and Side Effects," 2018 IEEE Cybersecurity Development (SecDev), Cambridge, MA, USA, 2018, pp. 1-10, doi: 10.1109/SecDev.2018.00009.
keywords: {Security;Computational modeling;Cognition;Kernel;Arrays;Conferences;formal verification;computer security;software engineering},
[^12]: David Costanzo, Zhong Shao, and Ronghui Gu. 2016. End-to-end verification of information-flow security for C and assembly programs. SIGPLAN Not. 51, 6 (June 2016), 648–664. https://doi.org/10.1145/2980983.2908100
