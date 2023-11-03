---
title: "Making sense of adjunctions"
date: 2023-11-03T19:53:38Z
draft: false
tags: ["category theory", "computer science", "maths"]
---

When I first encountered the concept of an adjunction, I got quite confused as
to what it is, and why it is useful: Just how on earth is a left adjoint of a functor?
What's the matter of a free and forgetful functor, why is free left to forgetful
but not the other way round. That's where this blog comes from. I hope this blogpost
can help demystify adjunction for you a little bit.

*Disclaimer: I am still not very certain that I understand this concept very
well so there might be mistakes/misunderstandings in this post. This is merely
an attempt to understand adjunction more intuitively through many examples.
Please read it with a grain of salt, and, as always, let me know if you spot a mistake.*

## Definition

Let's first define what an adjunction is. It turns out there are many equivalent
definitions, I will be using this one[^1]:

An adjunction between two categories \\(C\\) and \\(D\\) is specified by:

- functors \\(F\\) and \\(G\\)

{{< quiver >}}
<!-- https://q.uiver.app/#q=WzAsMixbMCwwLCJDIl0sWzIsMCwiRCJdLFswLDEsIkYiLDAseyJjdXJ2ZSI6LTJ9XSxbMSwwLCJHIiwwLHsiY3VydmUiOi0yfV0sWzIsMywiIiwwLHsibGV2ZWwiOjEsInN0eWxlIjp7Im5hbWUiOiJhZGp1bmN0aW9uIn19XV0= -->
<iframe class="quiver-embed" src="https://q.uiver.app/#q=WzAsMixbMCwwLCJDIl0sWzIsMCwiRCJdLFswLDEsIkYiLDAseyJjdXJ2ZSI6LTJ9XSxbMSwwLCJHIiwwLHsiY3VydmUiOi0yfV0sWzIsMywiIiwwLHsibGV2ZWwiOjEsInN0eWxlIjp7Im5hbWUiOiJhZGp1bmN0aW9uIn19XV0=&embed" width="432" height="176" style="border-radius: 8px; border: none;"></iframe>

{{< /quiver >}}

- For each \\(X\in C\\) and \\(Y \in D\\) a bijection \\(\theta_{X,Y} \\):
\\(D(F X, Y) \cong C(X,G Y) \\) which is natural in \\(X\\) and \\(Y\\).

[^1]: Thanks to Andrew Pitts for his course on [Category theory](), which provides
the foundation for this blog post.

Roughly speaking, this means if \\(F \dashv G\\) there is a morphism in \\(D: F X \to Y\\), then
we can find a morphism in \\(C: X\to G Y\\). 

## Examples of adjunctions

We list a few examples of adjunctions:

### Free and forgetful

The free functor is left adjoint to the forgetful functor \\(F \dashv U\\).
In this case the free functor takes a set and converts it into a list
monoid whose list elements come from the set, and with the list concatenation
and empty list as the monoid operation and identity element.


$$
  \begin{prooftree}
  \AxiomC{\\(\Sigma \to U(M,\cdot, e)\\)}
  \UnaryInfC{\\(F\ \Sigma \to (M,\cdot, e)\\)} 
  \end{prooftree}
$$

Due to the universal properties that when we can go from a set to (the set component
of) a monoid, we can always apply that function to every element in the list
and hence go from the list monoid to the monoid.

{{< quiver >}}
<!-- https://q.uiver.app/#q=WzAsMyxbMCwwLCJcXFNpZ21hIl0sWzIsMCwiXFxtYXRocm17TGlzdH1cXCBcXFNpZ21hIl0sWzIsMiwiTSJdLFswLDEsIlxcZXRhX3tcXFNpZ21hfSJdLFsxLDIsIlxcb3ZlcmxpbmUge2Z9Il0sWzAsMiwiZiIsMl1d -->
<iframe class="quiver-embed" src="https://q.uiver.app/#q=WzAsMyxbMCwwLCJcXFNpZ21hIl0sWzIsMCwiXFxtYXRocm17TGlzdH1cXCBcXFNpZ21hIl0sWzIsMiwiTSJdLFswLDEsIlxcZXRhX3tcXFNpZ21hfSJdLFsxLDIsIlxcb3ZlcmxpbmUge2Z9Il0sWzAsMiwiZiIsMl1d&embed" width="452" height="432" style="border-radius: 8px; border: none;"></iframe>
{{< /quiver >}}

### Diagonal and product and coproduct

The diagonal functor is left adjoint to the product functor \\(\Delta \dashv \times\\)

$$
  \begin{prooftree}
  \AxiomC{\\(\Delta C=(C,C) \to (X,Y)\\)}
  \UnaryInfC{\\(C \to \times(X, Y)=X\times Y\\)} 
  \end{prooftree}
$$

This is due to the terminal nature of a binary product in a category. We see that
we have a morphism to go from \\(C\\) to \\(X\times Y\\), then this implies we
can go from \\(C\\) to \\(X\\) and \\(Y\\), which means there is indeed a unique
morphism from \\(C\\) to the binary product (by the UP of binary product).

{{< quiver >}}

<!-- https://q.uiver.app/#q=WzAsNSxbMCwxLCJDIl0sWzIsMSwiXFx0aW1lcyBcXERlbHRhIEM9Q1xcdGltZXMgQyJdLFsyLDMsIlhcXHRpbWVzIFkiXSxbMCwwLCIoQyxDKSJdLFsyLDAsIihYLFkpIl0sWzAsMSwiXFxldGFfe0N9Il0sWzEsMiwiXFxEZWx0YVxcb3ZlcmxpbmUge2Z9Il0sWzAsMiwiZiIsMl0sWzMsNCwiXFxvdmVybGluZSBmIl1d -->
<iframe class="quiver-embed" src="https://q.uiver.app/#q=WzAsNSxbMCwxLCJDIl0sWzIsMSwiXFx0aW1lcyBcXERlbHRhIEM9Q1xcdGltZXMgQyJdLFsyLDMsIlhcXHRpbWVzIFkiXSxbMCwwLCIoQyxDKSJdLFsyLDAsIihYLFkpIl0sWzAsMSwiXFxldGFfe0N9Il0sWzEsMiwiXFxEZWx0YVxcb3ZlcmxpbmUge2Z9Il0sWzAsMiwiZiIsMl0sWzMsNCwiXFxvdmVybGluZSBmIl1d&embed" width="597" height="560" style="border-radius: 8px; border: none;"></iframe>

{{< /quiver >}}

Similarly, the coproduct is actually left adjoint to the diagonal functor
\\(+ \dashv \Delta \dashv \times \\).

### Initial and terminal object

Suppose \\(\!: \mathbf C\to \mathbf 1\\) is a functor that maps an arbitrary category
to the terminal category, then it is left adjoint to the functor that maps the
unique object in the terminal category the terminal object to any other category
\\(C\\).

$$
  \begin{prooftree}
  \AxiomC{\\(\! C\to \*\\)}
  \UnaryInfC{\\(C \to U(\*)\\)} 
  \end{prooftree}
$$

Why is that the case? Looking at the required property: for each \\(\overline f\\),
we need to have a unique \\(f\\) that maps from any object \\(C\\) to the object
\\(U(\*)\\). \\(f\\) always exists since there is only one object in the terminal
category, hence we need to have an always-existing \\(\overline f\\) as well,
which forces the \\(U(\*)\\) to be terminal.

Similarly \\(F\dashv\ \! \dashv U\\) where \\(F\\) maps an object \\(\*\\) to the
initial object.


{{< quiver >}}

<!-- https://q.uiver.app/#q=WzAsNSxbMCwxLCJDIl0sWzIsMSwiVSghQyk9VSgqKSJdLFsyLDMsIlUoKikiXSxbMCwwLCIhQyJdLFsyLDAsIioiXSxbMCwxLCJcXGV0YSJdLFsxLDIsIlVcXG92ZXJsaW5lIHtmfSJdLFswLDIsImYiLDJdLFszLDQsIlxcb3ZlcmxpbmUgZiJdXQ== -->
<iframe class="quiver-embed" src="https://q.uiver.app/#q=WzAsNSxbMCwxLCJDIl0sWzIsMSwiVSghQyk9VSgqKSJdLFsyLDMsIlUoKikiXSxbMCwwLCIhQyJdLFsyLDAsIioiXSxbMCwxLCJcXGV0YSJdLFsxLDIsIlVcXG92ZXJsaW5lIHtmfSJdLFswLDIsImYiLDJdLFszLDQsIlxcb3ZlcmxpbmUgZiJdXQ==&embed" width="558" height="560" style="border-radius: 8px; border: none;"></iframe>

{{< /quiver >}}

### Thoughts

So what is the pattern here? The more left a functor is, the more initial it will 
be and dually, the more right a functor is, the more terminal its destination
object would be.

Looking at the diagram, we note that for each \\(f\\), there is a unique \\(\overline f\\)
such that the triangle commutes, and vice versa. If we were to fix \\(R\\) and
try to find \\(L\\), then we would want \\(L X\\) to be as "initial" as possible,
since an initial object, by definition, has a unique morphism to any other object
in the category. Dually, if we fix \\(L\\) and want to find \\(R\\), then we
would want \\(R X\\) to be as terminal as possible, since we want to go from
\\(X\\) to \\(R Y\\).

{{< quiver >}}

<!-- https://q.uiver.app/#q=WzAsNSxbMCwzLCJYIl0sWzAsMSwiUkxYIl0sWzIsMSwiUiBZIl0sWzAsMCwiTFgiXSxbMiwwLCJZIl0sWzAsMiwiZiIsMl0sWzEsMiwiUmc9Ulxcb3ZlcmxpbmV7Zn0iLDJdLFswLDEsIlxcZXRhIl0sWzMsNCwiZz1cXG92ZXJsaW5le2Z9IiwyLHsic3R5bGUiOnsiYm9keSI6eyJuYW1lIjoiZGFzaGVkIn19fV1d -->
<iframe class="quiver-embed" src="https://q.uiver.app/#q=WzAsNSxbMCwzLCJYIl0sWzAsMSwiUkxYIl0sWzIsMSwiUiBZIl0sWzAsMCwiTFgiXSxbMiwwLCJZIl0sWzAsMiwiZiIsMl0sWzEsMiwiUmc9Ulxcb3ZlcmxpbmV7Zn0iLDJdLFswLDEsIlxcZXRhIl0sWzMsNCwiZz1cXG92ZXJsaW5le2Z9IiwyLHsic3R5bGUiOnsiYm9keSI6eyJuYW1lIjoiZGFzaGVkIn19fV1d&embed" width="442" height="560" style="border-radius: 8px; border: none;"></iframe>

{{< /quiver >}}


## References

Awodey, S. (2010). Category theory. Oxford University Press (2nd ed.).