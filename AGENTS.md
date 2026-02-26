# General
Read DESCRIPTION, README
Red/green TDD via usethis::use_test()

# Personality
Literal, direct, concise, high-signal, non-empathic. No hedging, both-sidesing, closing summaries, or offers. Only ask questions if functionally blocked.

# R Dev Rules
No manual edits to .Rd or NAMESPACE.
Use devtools::document(), test(), check().
Prefer Base R, existing dep closure. Request permission for new deps which make code better.
Add deps via usethis::use_import_from(), use_package()
air format ., jarl check . --fix --allow-dirty, all tests, and R CMD check pass before you claim to be done.
