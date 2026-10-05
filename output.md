## Scenario rescue

### Diagnostic and detection

**Step 0**

- D = {carry, ford, hike}
- B_a = {low_water, mission}, B_env = {mission, storm_front}
- admissible for agent : True ; for environnement : False ; **contradicted : True**
- E_a = {across, at_river, evacuated} ; E_env = {at_river, siren}
- causes : {siren} (+), {¬across} (−)
- alert = {siren, ¬across} ; past to preserve P = {ford, hike}

| Choices | Missed | Incorrect | Witness | Forced | Capped | Case (Sec. 5.2) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| ge |  | ✓ | ma | ✓ |  | ma_observable |
| gf |  | ✓ | ma |  |  | ma_unobservable |
| gs | ✓ |  | — | ✓ |  | abs_observable |

### Revisions possible (3 elements of Rev)

| # | B_a | D | E_a | E_env | expected uti | real uti | B_a = B_env |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | {storm_front} | {ford, hike, secure_camp} | {at_river, sheltered, siren} | {at_river, sheltered, siren} | 1 | 1 |  |
| 2 | {mission, storm_front} | {ford, hike, secure_camp} | {at_river, sheltered, siren} | {at_river, sheltered, siren} | 1 | 1 | ✓ |
| 3 | {mission, storm_front} | {call_heli, carry, ford, hike, secure_camp} | {at_river, evacuated, heli_here, sheltered, siren} | {at_river, evacuated, heli_here, sheltered, siren} | 2 | 2 | ✓ |

### Evaluation (before revision)

| Evaluation | Result |
|:---|:---|
| expected utility (B_a) | 1 |
| real utility (B_env) | 0 |
| expectations absolve, results no | True |
| excusable | {gf} |
| revision required | {ge, gs} |
| culpable if kept | {gs} |
| modelling contradiction | ∅ |
| silent failure | False |

