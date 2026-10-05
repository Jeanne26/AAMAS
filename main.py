from clyngor import ASP

try:
    from IPython.display import display, Markdown
except ImportError:                      # exécution hors notebook
    display, Markdown = print, str


SCENARIOS = {"rescue": ["main_v2.lp"]}


def solve(files):
    """Returns the list of answer sets (each: a set of (pred, args))."""
    program = "\n".join(open(f).read() for f in files)
    return [set(a) for a in ASP(program)]


def args(fact):
    return fact[1] if isinstance(fact[1], tuple) else (fact[1],)


def get(facts, pred):
    """All argument tuples of the predicate `pred`."""
    return [args(f) for f in facts if f[0] == pred]


def at(facts, pred, step, *rest):
    """Arguments of the `pred(step, ...)` facts filtered by `rest`."""
    out = []
    for a in get(facts, pred):
        if a[0] == step and tuple(a[1:1 + len(rest)]) == rest:
            out.append(a[1 + len(rest):])
    return out


def fmt(items):
    items = sorted(str(i) for i in items)
    return "{" + ", ".join(items) + "}" if items else "∅"


def events(facts, step, base):
    return [a[0] for a in at(facts, "holds", step, base)]


def beliefs(facts, step, base):
    return [a[0] for a in at(facts, "believe", step, base)]


def decision(facts, step):
    return [a[1] for a in get(facts, "decision") if a[0] == step]


def uti(facts, step, base):
    for a in get(facts, "totalUti"):
        if a[0] == step and a[1] == base:
            return a[2]
    return "----"


def flag(facts, pred, *key):
    return any(a[:len(key)] == key for a in get(facts, pred))


def table_diagnosis(facts, step=0):
    """Diagnosis and detection for the decision regarding step `step`."""
    md = f"**Step {step}**\n\n"
    md += f"- D = {fmt(decision(facts, step))}\n"
    md += f"- B_a = {fmt(beliefs(facts, step, 'ag'))}, B_env = {fmt(beliefs(facts, step, 'env'))}\n"
    md += (f"- admissible for agent : {flag(facts, 'adm', step, 'ag')} ; "
           f"for environnement : {flag(facts, 'adm', step, 'env')} ; "
           f"**contradicted : {flag(facts, 'contradicted', step)}**\n")
    md += f"- E_a = {fmt(events(facts, step, 'ag'))} ; E_env = {fmt(events(facts, step, 'env'))}\n"
    md += (f"- causes : "
           f"{fmt([a[2] for a in get(facts, 'cause') if a[0] == step and a[1] == 'pos'])} (+), "
           f"{fmt(['¬' + str(a[2]) for a in get(facts, 'cause') if a[0] == step and a[1] == 'neg'])} (−)\n")
    md += (f"- alert = "
           f"{fmt([a[2] if a[1] == 'pos' else '¬' + str(a[2]) for a in get(facts, 'alert') if a[0] == step])}"
           f" ; past to preserve P = {fmt([a[1] for a in get(facts, 'preserved') if a[0] == step])}\n\n")

    md += "| Choices | Missed | Incorrect | Witness | Forced | Capped | Case (Sec. 5.2) |\n"
    md += "|:---:|:---:|:---:|:---:|:---:|:---:|:---|\n"
    choices = sorted({a[1] for a in get(facts, "missed") if a[0] == step} |
                     {a[1] for a in get(facts, "incorrect") if a[0] == step})
    for g in choices:
        miss = flag(facts, "missed", step, g)
        inc = flag(facts, "incorrect", step, g)
        wit = "viol" if flag(facts, "wviol", step, g) else ("ma" if flag(facts, "wma", step, g) else "—")
        cases = [a[2] for a in get(facts, "case") if a[0] == step and a[1] == g]
        md += (f"| {g} | {'✓' if miss else ''} | {'✓' if inc else ''} | {wit} "
               f"| {'✓' if flag(facts, 'forced', g) else ''} "
               f"| {'✓' if flag(facts, 'capped', g) else ''} | {', '.join(cases) or '—'} |\n")
    return md


def table_revisions(answer_sets, s0=0, s1=1):
    """ an answer set = an element of Rev(B_a, D, Alert)."""
    md = "| # | B_a | D | E_a | E_env | expected uti | real uti | B_a = B_env |\n"
    md += "|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|\n"
    for i, facts in enumerate(answer_sets, start=1):
        b1 = beliefs(facts, s1, "ag")
        same = sorted(b1) == sorted(beliefs(facts, s1, "env"))
        md += (f"| {i} | {fmt(b1)} | {fmt(decision(facts, s1))} "
               f"| {fmt(events(facts, s1, 'ag'))} | {fmt(events(facts, s1, 'env'))} "
               f"| {uti(facts, s1, 'ag')} | {uti(facts, s1, 'env')} | {'✓' if same else ''} |\n")
    return md


def table_evaluation(facts, step=0):
    """ethical (consequences) and legal (observability) assessment."""
    md = "| Evaluation | Result |\n|:---|:---|\n"
    md += f"| expected utility (B_a) | {uti(facts, step, 'ag')} |\n"
    md += f"| real utility (B_env) | {uti(facts, step, 'env')} |\n"
    md += f"| expectations absolve, results no | {flag(facts, 'expectations_absolve', step)} |\n"
    for pred, label in [("excusable", "excusable"),
                        ("revision_required", "revision required"),
                        ("culpable_if_kept", "culpable if kept"),
                        ("modelling_contradiction", "modelling contradiction")]:
        md += f"| {label} | {fmt([a[1] for a in get(facts, pred) if a[0] == step])} |\n"
    md += f"| silent failure | {flag(facts, 'silent_failure', step)} |\n"
    return md

out = ""
for name, files in SCENARIOS.items():
    answer_sets = solve(files)
    if not answer_sets:
        out += f"## {name}\n\nUNSAT (inconsistent theories or D⁰ not admissible for the agent)\n\n"
        continue
    first = answer_sets[0]       # l'étape 0 est identique dans tous les answer sets
    out += f"## Scenario {name}\n\n### Diagnostic and detection\n\n{table_diagnosis(first)}\n"
    out += f"### Revisions possible ({len(answer_sets)} elements of Rev)\n\n{table_revisions(answer_sets)}\n"
    out += f"### Evaluation (before revision)\n\n{table_evaluation(first)}\n"

display(Markdown(out))
with open("output.md", "w") as f:
    f.write(out)