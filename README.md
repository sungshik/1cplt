# 1CPLT

## Introduction

Implementing distributed systems is hard. One of the complicated challenges is
to "prove"&mdash;broadly construed&mdash;the absence of communication
[deadlocks](https://en.wikipedia.org/wiki/Deadlock_(computer_science)) among
message-passing processes. A communication deadlock is a form of misbehavior
that arises when processes get stuck in cyclic communication dependencies. For
instance, Alice might await a message from Bob, while Bob might await a message
from Alice. As neither Alice nor Bob sends a message, they are stuck forever.

[**Choreographic
programming**](https://en.wikipedia.org/wiki/Choreographic_programming) (CP) is
a method that aims to make implementing distributed systems easier. The benefit
of the method is that choreographic programs, called "choreographies", are free
of communication deadlocks by construction: if a choreography is well-formed and
well-typed at compile-time, then the processes will not get stuck in cyclic
communication dependencies at execution-time. For instance, it is impossible in
CP to let Alice and Bob await messages from each other without sending any.

The **1CP Language and Tooling** (1CPLT) is an extension of [Visual Studio
Code](https://code.visualstudio.com) to apply **first-person choreographic
programming** (1CP) in practice. It is implemented in
[Rascal](https://www.rascal-mpl.org). This repository contains:
 1. [examples](1cplt-examples/);
 2. an [LSP server](1cplt-rascal/);
 3. the [extension](1cplt-vscode/).

## References

  - [**First-Person Choreographic Programming with Continuation-Passing
    Communications**](https://doi.org/10.1007/978-3-031-91121-7_3).<br/>
    Proceedings of ESOP'25 (34th European Symposium on Programming), LNCS 15695,
    62-90. 2025.<br/>
    ⭐ EAPLS Best Paper Award<br/>
    ⭐ ETAPS Distinguished Paper Award
