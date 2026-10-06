# Acting on False Beliefs: Decision Failure, Observability and Revision


It provides a Python-driven implementation of an Answer Set Programming (ASP) framework (via **Clingo** and **Clyngor**) to model an agent that decides and acts on the basis of a possibly **false belief base**. Using a mountain-rescue scenario as a running case, the framework (i) detects when a decision is contradicted by the environment, (ii) diagnoses *why* it failed, (iii) computes the admissible **belief and decision revisions**, and (iv) evaluates the original decision in terms of **expected vs. real utility** and **observability**.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Code Structure](#code-structure)



## Features

- **ASP modeling with Clingo/Clyngor.** The core logic is encoded as ASP rules (`main.lp`); Python orchestrates solving and presentation (`main.py`).
- **Causal layer.** Actions, contexts and events (`hike → at_river`, `ford ∧ low_water ∧ at_river → across`, …) evaluated under both belief bases.
- **Decision layer.** Decision rules trigger goals (`gw, gh, gf, ge, gs`), each offering actions under cardinality bounds (`cmin`/`cmax`).
- **Decision-failure taxonomy.**
- **Temporal coherence.** An order over actions and events is derived from both theories, and incoherent theories are rejected.
- **Alerts and revision.** Observable discrepancies raise alerts, filtered so that only the earliest causes remain. Admissible revisions `Rev(B_a, D, Alert)` change beliefs and decisions while (a) satisfying the alerts and (b) preserving the past.
- **Ethical/legal evaluation.** Compares expected utility (`B_a`) and real utility (`B_env`), and classifies the decision as *excusable*, *revision required*, *culpable if kept* or *silent failure*.


## Installation


```bash
# With uv (recommended)
uv sync

# Or with pip
pip install clingo clyngor clyngor-with-clingo ipython
```

## Usage


```bash
uv run main.py       
```


## Code Structure

- **`main.lp`, `main2.lp`,`main3.lp`**: ASP program: vocabulary, causal and decision theories, scenario, failure diagnosis, temporal order, alerts, revision, evaluation.
- **`main.py`**: orchestration: solves the program with Clyngor, builds the three Markdown tables, writes `output.md`.
- **`output.md`**: auto-generated, do not edit by hand.
- **`pyproject.toml` / `uv.lock`**: locked dependencies managed via `uv`.

### Key Helpers (Python)
- `solve(files)`: concatenates the `.lp` files and returns the list of answer sets.
- `args(fact)`: normalizes the arguments of a Clyngor fact into a tuple.
- `get(facts, pred)` / `at(facts, pred, step, *rest)`: retrieve the arguments of a predicate, optionally filtered by step.
- `events`, `beliefs`, `decision`, `uti`, `flag`: accessors for the events, beliefs, decision, total utility and Boolean flags of a step.
- `fmt(items)`: formats a set (`{a, b}` or `∅`).
- `table_diagnosis(facts, step)`: diagnosis and detection table.
- `table_revisions(answer_sets)`: table of admissible revisions.
- `table_evaluation(facts, step)`: ethical/legal evaluation table.