# Specification Files

This repository contains Formal Specifications for various
algorithms/services.

## Getting started with TLA+

To learn more about TLA+ and find resources/tutorials, please see the [Getting Started Guide](./GettingStarted.md).

## Import and run an existing specification

1. Open VSCode with the TLA+ Extension installed

2. Open a specification file (*.tla)

3. Optionally create or use an existing model to check the specification (*.cfg)

Specify the values for any constants under `CONSTANT`

Ex. Idempotency can have:
```
UniqueRequests = 2
TotalRequests = 3
```

Under `INVARIANT`, you can specify any invariants for the model.

Ex. For optimistic locking you can put:
```
DBSize
IndexOrder
IdUniqueness
FinalDBSize
```
These are defined at the bottom of the tla spec file.

## Creating a new specification

Create a new blank specification file:
```
File > New File > {MySpec}.tla
```

Create a new file with your chosen name.

Typically you will write your spec as an algorithm in PlusCal. This is in a
comment at the top of the file that looks like:
```
(****************************************************************************

--algorithm MySpec
{
    ...
}

****************************************************************************)
```

When you press the keyboard shortcut or configure your editor to translate on save,
TLA tools jar will translate your algorithm into TLA+ for you.

Creating your own model and testing is the same as in the prior section.

## Other optional resources
* [graphviz](https://graphviz.org/) for `dot` (render the state machine
graph)
* [latex](https://www.latex-project.org/) for `pdflatex` (pretty print your
specifications)

Instructions on how to enable these can be found in the [Getting Started Guide](./GettingStarted.md).
