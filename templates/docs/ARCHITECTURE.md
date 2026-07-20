# Architecture

This document provides a high-level overview of how this project is wired and organized.

## System Overview

<!-- High-level description of the system's purpose and boundaries -->

## Component Diagram

<!--
  Add a Mermaid diagram (default choice: plain text, diffable, renders
  natively on GitHub/GitLab) showing major components and how they connect.
  Only a linked image if Mermaid genuinely cannot express it. Example:

  ```mermaid
  flowchart LR
      Client --> API[API Service]
      API --> DB[(Database)]
      API --> Queue[Message Queue]
  ```
-->

## Data Flow

<!-- Describe how data moves through the system -->

## Key Technologies

- **Frontend**: <!-- e.g., React, Tailwind -->
- **Backend**: <!-- e.g., FastAPI, PostgreSQL -->
- **Infrastructure**: <!-- e.g., AWS, Docker -->

## Repository Structure

- `src/`: Core logic.
- `tests/`: Automated tests.
- `docs/`: Supplemental documentation.
- `constitution/`: Universal engineering rules.

## Layer Boundaries

<!--
Declare this project's layers to turn on Dependency Rule enforcement
(`constitution/scripts/check_architecture.sh`). Until the table below is
uncommented and filled in, layer enforcement is skipped and only advisory
structural signals are reported.

List layers inner-first. "May Depend On" names the layers each one may import;
use an em dash for none. A layer may always import itself, and imports that do
not resolve to a declared layer (third-party and standard-library packages) are
ignored.

Delete the layers that do not apply and rename the paths to match this project.

| Layer          | Path               | May Depend On       |
| -------------- | ------------------ | ------------------- |
| domain         | src/domain         | --                  |
| application    | src/application    | domain              |
| infrastructure | src/infrastructure | domain, application |
-->

<!-- Once this table is real, tighten the constitution-architecture workflow to `--strict`. -->
