---
title: "Equivalence of proof techniques in proving the fixpoint properties"
date: 2022-06-30T08:59:42+01:00
draft: false
tags: ["denotational semantics", "computer science", "maths"]
---


[Denotational Semantics](https://www.cl.cam.ac.uk/teaching/current/DenotSem/) is
a unique course offered by the Computer Lab at UoC. It can be intimidating at first
glance but at the same time bring you lots of fun and frustration at the same time.
In this blog post we will look at three proof techniques in domain theory and investigate the connections between them.


In this blog we look at three techniques that can be used to prove the fixpoint
of a function, namely, Tarski's fixpoint theorem, lfp1 + lfp2 and Scott induction.
We will show that they are equivalent to each other by working on an example.




## lfp1 + lfp2

lfp1 and lfp2 are two properties of the least pre-fixed point of a function \\(f: D\to D\\),
where \\(D\\) is a poset. We define a pre-fixed point of \\(f\\) to satisfy the
property that \\(f(d)\sqcup d\\). And we denote the least pre-fixed point of \\(f\\),
if it exists, to be \\(\mathit{fix}(f)\\) which is specified by two properties:

$$
  \begin{align}
    \mathrm{(lfp1)}\qquad & f(\mathit{fix}(f)) \sqsubseteq \mathit{fix}(f) \newline
    \mathrm{(lfp2)}\qquad & \forall d\in D. f(d)\sqsubseteq d\implies \mathit{fix}(f)\sqsubseteq d.
  \end{align}
$$

lfp1 is saying that \\(\mathit{fix}(f)\\) is a pre-fixed point of \\(f\\), while lfp2
says that it is least such. These two properties start from the definition of
the least pre-fixed point, i.e. it is 1. pre-fixed; 2. least.


## Tarski's fixpoint

Tarski's fixpoint theorem states that for a function \\(f:D\to D\\), where \\(D\\)
is a domain, then \\(f\\) has a least pre-fixed point, given by:

\\[
  \mathit{fix}(f) = \bigsqcup_n f^n(\bot)
\\]

Moreover, it is also a *fixpoint* of \\(f\\), which means that 
\\(f(\mathit{fix}(f)) = \mathit{fix}(f)\\), and because all fixpoints are also
pre-fixed point, this makes it a *least* fixpoint [^1].

Proving the Tarski's fixed point theorem involves two parts: firstly, to prove that
it is a pre-fixed point, i.e. lfp1, this involves induction on \\(f(\bot)\sqsubseteq \bot\\)
and using the monotonicity of \\(f\\). And to show it is a least one, we can show
that \\(\mathit{fix}(f)\\) is below any other pre-fixed point using the transitive
property of the poset and the property that 
\\(\sqcup_n f^n(\bot) = \sqcup_{n+1} f^{n+1}(\bot)\\). We can use the same property
to prove that \\(\mathit{fix}(f)\\) is indeed a fixpoint in addition to being
a pre-fixed point.

Intuitively, Tarski's theorem is saying that if we have a \\(\bot\\) element, and
if we have a continuous function \\(f\\), then we can always obtain the fixpoint
of this function by repeatedly applying it to \\(\bot\\) until we don't see changes.
We are guaranteed to arrive/terminate at the lub by the definition of a domain.


## Scott induction

Scott induction is a technique to prove that a fixpoint has a certain property.
It says that if \\(f: D\to D\\) is a continuous function on a domain \\(D\\).
Then for any admissible subset \\(S\subseteq D\\), then the following implication
holds:

$$
  \begin{prooftree}
  \AxiomC{\\(\forall d\in D.(d\in S \implies f(d)\in S)\\)} \RightLabel{ \\(S\\) admissible}
  \UnaryInfC{\\(\mathit{fix}(f)\in S\\)} 
  \end{prooftree}
$$

where admissibility is defined as every chain in \\(S\\) has a lub and \\(\bot\in S\\).

In other words, if we know that \\(f\\) preserves the property of \\(d\in S\\), 
then we know that \\(f\\) preserves it to the lub, hence the least pre-fixed point
\\(\mathit{fix}(f) = \sqcup_nf^n(\bot)\\) which is obtained by repeatedly applying \\(f\\) to the bottom
element (by Tarski's theorem) \\(\bot \in S\\) must also be in \\(S\\). The existence
of the bottom element is implied by the fact that \\(D\\) is a domain.



## Example question

To better understand these theorems, we apply them to a example question:

### Problem statement

Let \\(f, g:D\to D\\) be continuous functions on domain \\(D\\). Prove

$$
  \mathit{fix}(f\circ g) = f(\mathit{fix}(g\circ f))
$$

by showing 

1. \\(\mathit{fix}(f\circ g) \sqsubseteq f(\mathit{fix}(g\circ f))\\)
2. \\(f(\mathit{fix}(g\circ f)) \sqsubseteq \mathit{fix}(f\circ g) \\)

### Using lfp1 + lfp2

1. Here is the proof for the first part

$$
\begin{prooftree}
\AxiomC{}
\UnaryInfC{\\(f(\mathit{fix}(g\circ f)) \sqsubseteq f(\mathit{fix}(g\circ f))\\)} 
\RightLabel{ definition of \\(\mathit{fix}(g\circ f)\\)}
\UnaryInfC{\\(f\circ g(f(\mathit{fix}(g\circ f))) \sqsubseteq f(\mathit{fix}(g\circ f))\\)}
\RightLabel{ definition of \\(\mathit{fix}(f\circ g)\\)}
\UnaryInfC{\\(\mathit{fix}(f\circ g) \sqsubseteq f(\mathit{fix(g\circ f)}) \\)}
\end{prooftree}
$$

2. And the second part

$$
\begin{prooftree}
\AxiomC{}
\UnaryInfC{\\(g(\mathit{fix}(f\circ g)) \sqsubseteq g(\mathit{fix}(f\circ g))\\)}
\UnaryInfC{\\(g\circ f(g(\mathit{fix}(f\circ g))) \sqsubseteq g(\mathit{fix}(f\circ g))\\)}
\RightLabel{ lfp2 of \\(\mathit{fix}(g\circ f)\\)}
\UnaryInfC{\\(\mathit{fix}(g\circ f) \sqsubseteq g(\mathit{fix}(f\circ g))\\)}
\RightLabel{ \\(f\\) is monotine}
\UnaryInfC{\\(f(\mathit{fix}(g\circ f)) \sqsubseteq f\circ g(\mathit{fix}(f\circ g))\\)}
\RightLabel{ definition of \\(\mathit{fix}(f\circ g)\\)}
\UnaryInfC{\\(f(\mathit{fix}(g\circ f)) \sqsubseteq \mathit{fix}(f\circ g)\\)}
\end{prooftree}
$$

These proofs can be read either way, but it is better to read them "upwards"
to see how we go from a conclusion to an axiom, using different proof techniques 
along the way.

### Using Scott induction

The hard part of Scott induction is usually to identify the set that is admissible
and can be used to prove the property we want. For this question, the properties
we want to prove are the less than relation, so we use this as our \\(S\\)

1. Define \\(S = \\{e\ |\ e\sqsubseteq f(\mathit{fix}(g\circ f)) \\}\\) this is
admissible because it is a downset, i.e. \\(\downarrow f(\mathit{fix}(g\circ f))\\).
Now we can apply Scott induction to prove \\(\mathit{fix}(g\circ f)\in S\\):

$$
\begin{prooftree}
\AxiomC{\\(e\sqsubseteq f(\mathit{fix}(g\circ f)) \iff e\in S\\)}
\UnaryInfC{\\(g(e)\sqsubseteq g\circ f(\mathit{fix}(g\circ f)) \\)}
\UnaryInfC{\\(g(e)\sqsubseteq \mathit{fix}(g\circ f) \\)}
\UnaryInfC{\\(f\circ g(e)\sqsubseteq f(\mathit{fix}(g\circ f))\iff f\circ g(e)\in S \\)}
\end{prooftree}
$$

2. Define \\(S = \\{d\ |\ f(d)\sqsubseteq \mathit{fix}(f\circ g)\\}\\), this set
is the inverse image of the downset \\(\downarrow \mathit{fix}(f\circ g)\\) under \\(f\\),
denoted as \\(f^{-1}(\downarrow \mathit{fix}(f\circ g)) \\), since we know that
\\(\downarrow \mathit{fix}(f\circ g))\\) is admissible, then so is its inverse image.

$$
\begin{prooftree}
\AxiomC{\\(d\in S\iff f(d) \sqsubseteq \mathit{fix}(f\circ g)\\)}
\UnaryInfC{\\(f(g\circ f(d))) \sqsubseteq f\circ g( \mathit{fix}(f\circ g))\\)}
\UnaryInfC{\\(g\circ f(d)\in S\iff f(g\circ f(d))) \sqsubseteq \mathit{fix}(f\circ g)\\)}
\end{prooftree}
$$

### Using Tarski's theorem

The last method uses Tarski's representation of \\(\mathit{fix}(f)\\), and it is
actually similar for both subquestions so we focus on the first one:

$$
\begin{align}
f(\mathit{fix}(g\circ f)) &= f(\bigsqcup_n (g\circ f)^n(\bot)) \\\\
&= f(\underbrace{g\circ f\circ g\circ f\cdots g\circ f(\bot)}_{n}) \\\\
&= f\circ g\cdots\circ f\circ g(f(\bot)) \\\\
&= \bigsqcup_n(f\circ g)^n(f(\bot))
\end{align}
$$

And note that \\(\mathit{fix}(f\circ g)=\bigsqcup_n(f\circ g)^n(\bot))\sqsubseteq \bigsqcup_n(f\circ g)^n(f(\bot))) = f(\mathit{fix}(g\circ f))\\)
since the \\(\bot \sqsubseteq f(\bot)\\) and \\((f\circ g)^n\\) is a continuous function.

The second subquestion just requires some massage of the form and we should get a similar
form to the first one.

## Aside: applications of denotational semantics

I want to give a applications of an area that is as abstract as denotational semantics[^2],
in case you were thinking that this is just some useless abstract math:

- Give semantics to while loops without recursion. The denotational semantics of
a language PCF (programming computable function) is based the existence of fixpoint.
Otherwise the while loop cannot be defined without using some kind of recursive
definition. If we want to exclude recursion as a "built-in"/first-class element
of our semantics, then the fixpoint semantics becomes essential to us.

- Proving contextual equivalence. Contextual equivalence of two programs can be thought
of as two black boxes with pluggable holes in them. If they are contextually equivalent,
then we cannot distinguish them by plugging in different values into the hole and
observe the behaviour of the program (crucially, behaviour here includes both
output *non-terminating* behaviour, i.e. the program steps into something that
is not a value and cannot step further). One of the central results of this course
is that if two terms have the same denotation, then they are contextually equivalent,
i.e.

$$
  [\\![M]\\!] = [\\![N]\\!] \implies M \cong_{\mathrm{ctx}} N
$$

The converse is not true, though, due to the parallel or function.

- Compiler optimisation. Domain theory is also useful in compiler optimisation
where, for example, we want to apply some data flow analysis and want to show that
our algorithm terminates. Or if we want to do strictness analysis, an algorithm
that helps transfrom CBN to CBV, we need to use Tarski's construction to help
us solve some of the equations.

- CRDTs (conflict-free replicated data types). These are some special replicated 
data types that guarantees convergence.
Some of these data structures use something called a join semilattice, where every
two states in it has a lub, to resolve conflicts.

## Acknowledgements

This blog post is by no means my original idea, hence I want to acknowledge the
inspiration from the excellent courses
[denotational semantics](https://www.cl.cam.ac.uk/teaching/current/DenotSem/), 
[optimising compilers](https://www.cl.cam.ac.uk/teaching/current/OptComp/).
And also [this](https://www.cl.cam.ac.uk/teaching/exams/pastpapers/y2020p9q7.pdf) 
and [this](https://www.cl.cam.ac.uk/teaching/exams/pastpapers/y2003p9q14.pdf) 
exam question.


## Appendix

If you are a Mandarin speaker, then here are some jokes on denotational semantics
compiled for you, enjoy :)


### <span style="color:red"> 女生说话像 Denotational Semantics 的正确方式 </span>

|  话    | 换成 | Denotational semantics  |
|------------|------|------------------------------------------------------------------------|
| 你好笨     | 换成 | The question was elementary with many candidates achieving full marks. |
| 不想去     | 换成 | Proof of the Proposition on Slide 65 [NON-EXAMINABLE]                  |
| 不行       | 换成 | \\(M_1\cong_{\mathrm{ctx}} M_2 \implies [\\![M_1]\\!] = [\\![M_2]\\!] \\)     |
| 随便       | 换成 | \\(\bot\\)（gives no information whatsoever)                            |
| 你去忙吧   | 换成 | Why does \\(w = f_{[B],[C]}(w)\\) have a solution solution?  |
| 我不会     | 换成 | \\([\\![P]\\!] = \mathit{por}: \mathbb B_\bot \to \mathbb B_\bot \to \mathbb B_\bot\\) in PCF|
| 你好烦     | 换成 | We will not give the proof of this proposition here.                  |
| 要你管     | 换成 | Thesis: All computable functions are continuous                       |
| 滚（出去） | 换成 | \\(f(\bigsqcup_n d_n)  = \bigsqcup_n f(d_n)\\)                           |
| 帮我个忙   | 换成 | \\(\mathit{fix}(f) = f(\mathit{fix}(f))\\)|
| 你陪我     | 换成 |\\(x\in S \implies f(x)\in S\\)                                          |
| 气死我了   | 换成 | \\(\mathit{fix}(\mathbf{fn}\ x:\tau.\ x)\\)                               |

[^1]: It actually took me a while to realise this. To elaborate on this, it is like
0 is the smallest positive real number, and since 0 is an integer and all integers
are real numbers, 0 is also the smallest positive integer.

[^2]: There is actually something more abstract called Category theory :), which
is so-called abstract nonsense.
