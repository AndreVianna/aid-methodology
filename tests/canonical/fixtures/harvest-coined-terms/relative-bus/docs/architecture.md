# Architecture

The Relative Bus is the core routing mechanism for this project.
Relative Bus connects domain services without tight coupling.
RelativeBus provides asynchronous message passing between subsystems.

## Design Rationale

The Relative Bus concept emerged from the need to decouple domain logic.
Relative Bus routes messages based on priority and destination domain.
