# Safety rules (deterministic engine)

Implemented in `lib/features/safety/safety_engine.dart`. **Every rule here is a
placeholder written by a developer, not a clinician. A qualified clinician must
review, amend and sign off all rules, thresholds, wording and emergency numbers
before any real-world use.** Tests in `test/safety_engine_test.dart` cover each
rule ID.

Precedence (most cautious wins): `emergency_guidance` >
`clinical_assessment_recommended` > `insufficient_information` >
`general_wellness_eligible`. Only `general_wellness_eligible` ever produces
exercises, meals or hydration notes. The AI layer (Phase 5) may only explain
output that already passed this engine and can never change the state.

A negative screen is never treated as proof that the user is safe; the
eligible state always carries that caveat.

## Emergency (stops the normal flow)

| ID | Trigger |
|----|---------|
| E1 | Chest pain/pressure with breathlessness, sweating, nausea or pain spreading to arm/jaw/back |
| E2 | Sudden face drooping, speech difficulty, or new one-sided weakness/numbness |
| E3 | Major trauma, obvious deformity, possible broken bone |
| E4 | New bladder/bowel control loss or groin/inner-thigh numbness |
| E5 | Hot, red, swollen joint with fever or chills |
| E6 | Severe breathing difficulty, fainting or collapse |
| E7 | Sudden, severe headache unlike any before |
| E8 | Free text mentions being unable to breathe, collapsing, unconscious (keyword match) |
| E9 | Free text mentions self-harm or suicide (keyword match; shows support guidance) |

## Clinical assessment recommended (no exercises or diet shown)

| ID | Trigger |
|----|---------|
| C1 | Pain intensity >= 8 |
| C2 | Onset after an injury and pain >= 4 |
| C3 | Numbness reported |
| C4 | Tingling lasting >= 4 days |
| C5 | Duration > 14 days and pain >= 4 |
| C6 | Pain >= 6 and daily activities, walking or sleep affected |
| C7 | Sudden onset and pain >= 6 |
| C8 | Chest region with pain > 0 |
| C9 | Abdomen region with pain >= 6 or sudden onset |
| C10 | Age range under 18 |
| C11 | Recent surgery |
| C12 | Free text mentions fever, lump, weight loss, night sweats, cannot move/walk, broken, fracture, dislocation, weakness |
| C13 | Heart condition with jaw, left shoulder or left upper-arm pain |

## Insufficient or conflicting information

| ID | Trigger |
|----|---------|
| I1 | No valid body region |
| I2 | Pain intensity missing |
| I3 | Pain intensity outside 0-10 |
| I4 | Duration missing |
| I5 | No sensation chosen |
| I6 | Onset missing |
| I7 | "Does movement worsen it?" unanswered |
| I8 | Warning-signs check not completed |
| I9 | Pain 0 but movement/daily activities reported as affected (conflict) |

## Known limitations

* Free-text scanning is simple keyword matching: it misses misspellings,
  other languages and indirect phrasing. It is a backstop, not a classifier.
* Thresholds are conservative guesses and are not validated.
* Emergency numbers in the guidance text are examples; market-specific
  numbers and crisis lines need to be set during localisation.
* Under-18 users are routed to a doctor/guardian rather than given exercises;
  whether to serve minors at all is a product, legal and clinical decision.
