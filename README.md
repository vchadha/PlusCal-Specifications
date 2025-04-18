# Specification Files

This repository contains Formal Specifications for various
algorithms/services.

## Getting started with TLA+

To learn more about TLA+ and find resources/tutorials, please see the [TLA+
Homepage](https://lamport.azurewebsites.net/tla/tla.html).

To use the specifications in this repo and develop your own, I recommend
installing the [TLA+
Toolbox](https://lamport.azurewebsites.net/tla/toolbox.html). There is also
a VSCode extension - I have not used this. Lastly, you can also use the cmd
line if you wish.

## Import and run an existing specification

1. Open the TLA+ Toolbox

2. Add a specification file to the workspace
```
File > Open Spec > Add New Spec...
```

Select a `.tla` file.
It will ask if you want to replace the file - choose yes.

3. Create a model to check the specification
```
TLC Model Checker > New Model...
```

Optionally give it a different name than the default `Model_1`.

4. Specify the values for any constants under `What is the model?`

Ex. Idempotency can have:
```
UniqueRequests <- 2
TotalRequests <- 3
```
Note: just put the numerical value in the box, nothing else.

5. Under `What to check?`, you can specify any invariants for the model.

Ex. For idempotency you can put:
```
DBSize
IndexOrder
IdUniqueness
FinalDBSize
```
Add the above one at a time by pressing the `Add` button.
These are defined at the bottom of the tla spec file.

Note: whenever you modify your spec file, make sure to translate it into
TLA+ by pressing `cmd+t`. If you try to run the model before doing this, it
will warn you.

## Creating a new specification

Create a new blank specification file:
```
File > Open Spec > Add New Spec...
```

Create a new file with your chosen name.

Typically you will write your spec as an algorithm in PlusCal. This is in a
comment at the top of the file that looks like:
```
(****************************************************************************

--algorithm Idempotency
{
    ...
}

****************************************************************************)
```

When you press the keyboard shortcut `cmd+t`, the TLA Toolbox will
translate your algorithm into TLA+.

Creating your own model and testing is the same as in the prior section.

## Other optional resources
* [graphviz](https://graphviz.org/) for `dot` (render the state machine
graph)
* [latex](https://www.latex-project.org/) for `pdflatex` (pretty print your
specifications)

Instructions on how to enable these can be found in the `Help` section of
the TLA+ Toolbox.
