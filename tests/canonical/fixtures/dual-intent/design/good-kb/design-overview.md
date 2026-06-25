---
spine-dimension: C9
owner: aid-researcher-architecture
---
# Design Overview

## Button

Interactive trigger for user actions. Variants: primary, secondary, destructive, ghost.
Props: `label` (string, required), `variant` (enum, default: primary), `disabled` (bool).
Consumes: color-primary-500, color-danger-500, space-2.

## Input Field

Text entry component. Variants: default, error, disabled.
Props: `label` (string, required), `placeholder` (string), `error` (string|null).
Consumes: color-neutral-50, color-danger-500, font-size-md.

## Card

Content container. Variants: flat, elevated.
Props: `title` (string), `children` (ReactNode).
Consumes: space-4, color-neutral-50.
