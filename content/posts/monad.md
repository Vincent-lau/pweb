---
title: "Monad in programming and category theory"
date: 2023-10-24T23:48:44+01:00
description: "A monoid in the category of monad tutorials"
tags: ["category theory", "functional programming", "computer science", "maths"]
draft: false
---

This article is very much my attempt to understand monad as a _design pattern_
in programming languages and why on earth it is useful. There are tons of monad
tutorials [online](https://wiki.haskell.org/Monad_tutorials_timeline), but I
found relatively few ones argue for the usefulness of a monad by having side
by side code examples that achieve similar functionalties. If you found one,
please do [let me know](/)!

I try to draw connections
between monads' original mathematical definition and its actual usage so that
this mysterious concept does not come out of the blue.

## Programming

Let's start with programming, since I like to understand abstract concepts from
concrete examples and then look at the abstract definition.

### Intuition

We tend to think of
Monads as wrapping some value up in a box, and each time we perform computation
on the monad, we take it out, perform computation, and always put it back in the
box. This is a bit like a pipeline where we've got a chain of workers ready to
assemble a car. Each worker takes out the component of a car from the box first, carries out their amazing work, and put the (half-)assembled component back 
into the box before handing it to the next worker.

Now we might wonder what is the point of a box? Why not
just hand the item to the next worker which is much faster than unboxing and boxing?
And indeed, handing the item to the next worker directly would be faster if
the work performed is _pure_ or guaranteed to return a valid result. If this is
not the case, for example, a worker might get tired while assembling and decides
to go back home for a nap, or he/she might get a defective component and not
know what to do with it. In these cases, the worker would still try to send a
special box (perhaps an box with an empty label on it). The pipeline at this
stage would take care of this and by receiving the special box, it will tell
the worker downstream that this car can no longer be assembled, everyone go home.

I think this is what is usually meant by "monads can make the code structured
in a controlled manner", since workers in the pipeline won't go into some random
state where people are just panicing that they are not getting the component
from their upstream worker, or maybe fighting against each other as they are
don't know what to do with the defective component. Instead, the monadic structure
or the pipeline is controlled in a way that when an error happens, it goes straight
to the workers and they know what to do with it.

In other words, monads, as a design pattern, encapsulates the error handling
logic in a controlled manner. And we shall we in actual code it makes it easy
to write clear code as well without repeatedly writing error handling code such
as if statements or try-catch blocks. Eric Kow [^1] puts it in a nice way like this:

> "do X and then do Y, where Y may be affected by X"

Yet another good place to use a monad is in asynchronous/event-driven programming.
In this case, a monad encapsulates the results of the computation, which may
be nothing (i.e. the computation is not done yet), or some result (i.e.
the computaiton is finished and the result is returned). This way of representing
futures/promises are nice because they allow us to chain computations together
easier, whereas the normal approach would be to use a callback function, which
can get quite cumbersome sometimes.

[^1]: There is a [link](https://wiki.haskell.org/Monad_tutorials_timeline) 
to all the monad tutorials online. This is where I found
Eric's notes. I hope this blog can be posted onto this list one day 😊.

### Definition

Here I will be using OCaml for examples.

The defining feature of a monad is a return and a bind operation:

```ocaml
type 'a monad = None | Some of 'a

val return: 'a -> 'a monad
val (>>=): 'a monad -> ('a -> 'b monad) -> 'b monad

```

The first one constructs a monad from a value, i.e. puts a box outside the plain
value, the second one allows us to chain computations on monads together, by
taking a monad and an operation on the value inside the monad, giving back
a new monad.

### Use cases


#### Maybe monad

The option type in OCaml is a monad:

```ocaml
let return x = Some x
let (>>=) m f = match m with
  | None -> None
  | Some x -> f x
```

And a good use of this is to handle exceptions, such as division by zero:

```ocaml
let mdiv x y = if y = 0 then None else Some (x / y)

let x = 3 
and y = 0 
in Some x 
>>= fun w -> mdiv w y
>>= fun y -> print_endline "I am y"; return (y + 1) 
>>= fun z -> print_endline "I am z"; return (z * 2)

```

In this example, we would get a maybe monad with value None, without any printed
values. In a normal case, we would need write code that looks like:

```ocaml
let x = 3 
and y = 0
in
x 
|> fun x -> x / y 
|> fun y -> print_endline "I am y"; y + 1 
|> fun z -> print_endline "I am z"; z * 2
```

which, in my opinion, is similar enough to the monad version, except this new one
would have an exception thrown. And most people dislike exceptions because they
alter the control flow abruptly, which might cause all sorts of issues like resource
leak, etc. If, however, we do want to handle the exception properly, we might
need to do something like:

```ocaml
let x = 3 
and y = 0
in
x 
|> fun x -> 
  try 
    x / y 
  with 
    Division_by_zero -> None
|> function
  | None -> None
  | Some y ->
    print_endline "I am y"; 
      y + 1 
|> function
  | None -> None
  | Some z ->
    print_endline "I am z"; 
    z * 2
```

You see how this becomes cumbersome quite quickly. Sure, you can abstract the
`match | None | Some` part into a new function and call this function instead of writing
it out every time. But in doing so, you are essentially reinventing a monad's
bind operator.  On the other hand, Monad
abstracts all the error handling in the powerful `>>=` operator, and allows
us programmers to stream our main processing logic in a succint way, with the
additional benefit of no suprise exceptions.

#### Haskell IO monad

In the world of Haskell, they try to separate the pure and impure world as much
as possible, using a technique called _tainting_. This essentially means that they
taint anything that has an side effect, such as IO with some special type constructor,
(for example, a `string` becomes a `IO string`, where `IO` acts like a type constructor).
This is exactly the `return` function mentioned above. To get a monad, we lift
up/wrap up/taint (or whatever you want to call it) the value so that it is now
contained in a box, and this box cannot interact with other pure values. For
example, you can't contantenate a `string` with a `IO string` without first
explicitly taking the value out of the box. This encourages programmers to
do these two things (pure and impure) separately, and only cross use them when
necessary. It's also useful for compiler optimisation purposes since the compiler
can know which part of the code is pure and perform certain optimisations.

#### Asynchronous programming

Monads are a common technique used in asynchronous programming as well, for
example, OCaml's `Lwt` and `Async` library relies heavily on monads, as is
Rust's Tokio library. Monads are useful as they allow chaining of operations
that would otherwise be defined as many callbacks and passed as arguments to
asynchronous functions. Another nice feature of monad is their boxy nature,
since in asynchronous programming, we frequently needed to maintain the state
of a promise/future without the help of having multiple threads each having their
own stacks/registers. The scheduler/worker thread knows nothing about the state,
and it only goes around each future/promise and executes them when they are ready
to be executed. In this case Monads as a container with all the necessary state
information encapsulated ready for the thread to actually carry out the computation.

It is also worth mentioning that monads simplifies error handling with asynchronous
programming, similar to what we have seen above, where we would guarantee to get
a None in the end without any random control flow changes. Moreover, in asynchronous
programming, the usual `try/catch` method might not work as expected, since it
might only catch the exception by the code executed synchronously within it.


#### Continuation-parsing style

Continuation parsing style (CPS) is a technique used in compilers so that the generated
program can have certain properties, such as tail-call, explicit evaluation order,
etc. In fact, we can indeed model CPS with monads, with the following definition:

```ocaml
module type Res = sig
  type t
end

module Cps_mon (M: Res) = struct
  type result = M.t

  type 'a cnt = 'a -> result
  type 'a cps_mon = 'a cnt -> result


  let return (x: 'a): 'a cps_mon = fun (k: 'a cnt) -> k x

  let (>>=) (cps: 'a cps_mon) (f: 'a -> 'b cps_mon) = 
    fun (k: 'b cnt) -> cps (fun (x: 'a) -> f x k)
end
```

This gives an example of a monad that is different from many of the monads 
we will see in a monad introductory tutorial, in that
it is not a sum type (i.e. `Some` or `None`), but a function type (or an
exponential object in a category). Note the bind operator for this CPS monad first
abstracts the application of `f` into a new continuation, and then apply the
old cps onto it before abstracting all of these into another cps, which is
exactly the style of CPS that allows us to chain things together.

As an example usage, we can turn the following example[^4] of a cps style fib 
function:

[^4]: Example take from [Compiler Construction course](https://www.cl.cam.ac.uk/teaching/current/CompConstr/materials.html).

```ocaml
let rec fib m =
  if m = 0 then 1
  else if m = 1 then 1
  else fib (m-1) + fib (m-2)

let rec fib_cps m k =
  if m = 0 then k 1
  else if m = 1 then k 1
  else fib_cps (m - 1) (fun a ->
  fib_cps (m - 2) (fun b ->
  k (a + b)))
```

into something that looks like this:

```ocaml
let open (module Fib_cps = Cps_mon(Int)) in
let rec fib_cps (m: 'a cps_mon): ('a cps_mon) =
  m >>= function
  | x when x = 1 || x = 0 -> return 1
  | x -> 
    fib_cps (return (x - 1)) 
    >>= fun y -> fib_cps (return (x - 2))
    >>= fun z -> return (z + y)

```

In this example it might not be that obvious how monads are useful in simplifying
our program, but we can see how the chaining helps us streamline our programs
rather than trying to nesting functions.

## Category theory 


A monad[^2] is defined to be "a monoid in the category of endofunctors". Endofunctors
refer to functors that map from a category \\(C\\) to the same category \\(C\\).
A monoid in such a category is an object \\(M\\) with two morphisms 
\\(\mu: M \times M \rightarrow M\\) and \\(\eta: I \rightarrow M\\) that satisfy
certain properties. To me, a more straightforward way of defining a monad on a
category \\(C\\) would be an endofunctor \\(T: C \rightarrow C\\) with two natural
transformations \\(\eta: \mathrm{id}\rightarrow T\\) and \\(\mu: T\circ T\to T\\) 
such that the following two diagrams commute:

[^2]: Many of the notations and concepts are based on the 
[Category Theory](https://www.cl.cam.ac.uk/teaching/current/L108/)
course and notes by Andrew Pitts.

{{< quiver >}}
<!-- https://q.uiver.app/#q=WzAsNCxbMCwwLCJUIl0sWzEsMCwiVFxcY2lyYyBUIl0sWzIsMCwidCJdLFsxLDEsInQiXSxbMCwxLCJUX1xcZXRhIl0sWzIsMSwiXFxldGFfVCIsMl0sWzAsMywiXFxtYXRocm17aWR9X1QiLDJdLFsyLDMsIlxcbWF0aHJte2lkfV9UIl0sWzEsMywiXFxtdSIsMV1d -->
<iframe class="quiver-embed" src="https://q.uiver.app/#q=WzAsNCxbMCwwLCJUIl0sWzEsMCwiVFxcY2lyYyBUIl0sWzIsMCwidCJdLFsxLDEsInQiXSxbMCwxLCJUX1xcZXRhIl0sWzIsMSwiXFxldGFfVCIsMl0sWzAsMywiXFxtYXRocm17aWR9X1QiLDJdLFsyLDMsIlxcbWF0aHJte2lkfV9UIl0sWzEsMywiXFxtdSIsMV1d&embed" width="443" height="304" style="border-radius: 8px; border: none;"></iframe>
{{< /quiver >}}

{{< quiver >}}
<!-- https://q.uiver.app/#q=WzAsNCxbMCwwLCJUXFxjaXJjIFRcXGNpcmMgVCJdLFsxLDAsIlRcXGNpcmMgVCJdLFsxLDEsIlQiXSxbMCwxLCJUXFxjaXJjIFQiXSxbMCwxLCJcXG11IFQiXSxbMSwyLCJcXG11Il0sWzAsMywiVFxcbXUiLDJdLFszLDIsIlxcbXUiLDJdXQ== -->
<iframe class="quiver-embed" src="https://q.uiver.app/#q=WzAsNCxbMCwwLCJUXFxjaXJjIFRcXGNpcmMgVCJdLFsxLDAsIlRcXGNpcmMgVCJdLFsxLDEsIlQiXSxbMCwxLCJUXFxjaXJjIFQiXSxbMCwxLCJcXG11IFQiXSxbMSwyLCJcXG11Il0sWzAsMywiVFxcbXUiLDJdLFszLDIsIlxcbXUiLDJdXQ==&embed" width="379" height="304" style="border-radius: 8px; border: none;"></iframe>
{{< /quiver>}}


(Notation: \\(T \eta\\) is a natural transformation, whose component at \\(x\\):
\\((T \eta)_x \triangleq T(\eta_x)\\), where \\(\eta_x\\) is the component
of the natural transformation \\(\eta\\) at object \\(x\\), i.e. a morphism.
\\(\eta_T\\) is the natural transformation \\((\eta T)_x \triangleq \eta _{T(x)}) \\)

The first diagram is saying that \\(\eta\\) is the left and right identity of
\\(T\\), and the second diagram is saying that \\(\mu\\) is associative.[^3]

[^3]: Indeed this is exactly the law that monad needs to satisfy, as stated
[here](https://cs3110.github.io/textbook/chapters/ds/monads.html#monad-laws).

So how does this relate to the monad we have been looking at in programming languages?
\\(T\\) is the "box" we use to model the computation/contain effectual code,
it is a functor because \\(T(X)\\) allows us to contain map/contain an element
\\(X\\) inside it, or the actual value inside the box. We can even map morphisms
with \\(T\\) as well, just as functions in a programming language is now encapsulated
by the monad. \\(\eta\\) is the natural transformation that lifts up a value
\\(X\\) into the box \\(T(X)\\), a mechanism going from a pure value to a tainted
value. Finally \\(\mu\\) allows us to sequence computations on monads, since
originally we have two boxes \\(T(T(X))\\), which are then combined into a single
one.

We can see there is indeed a correspondence here, where \\(T\\) is corresponds
to the box itself, and \\(\eta\\) and \\(\mu\\) enable the return and bind operations
by lifting a vanilla value onto a box and combining multiple boxes into one.


## Conclusion

In summary, Monads are not magic that enable new features like async programming.
One could pretty much do them without using Monad, but it would either be awkward,
or the programmer might just invent something that is very similar to monad itself.
It is worth stressing again that they are merely _design patterns_ that make 
our life easier when writing code that deal with side effects/states.
