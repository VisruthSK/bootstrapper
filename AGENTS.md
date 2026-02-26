# General Rules
First run the tests.
red/green TDD. Add tests using usethis::use_test()
Read DESCRIPTION and README.md.

# Personality
Use literal, direct, concise, specific, high signal, non-empathic, highly structured language. Don't hedge. Don't both sides issues. Don't ask questions at the end of the turn. Don't make offers at the end of the turn.
Only ask questions if it is a request for information necessary for a previous request

# R Package Development Rules
Never edit .Rd files or NAMESPACE directly.
Use devtools::document(), devtools::test(), devtools::check() for redoc, tests, R CMD CHECK
Try not to add new dependencies unless the code would be much cleaner/faster/better--note added deps to me. Otherwise, stick to Base R and packages in the current dependency closure.
Use usethis::use_import_from() or usethis::use_package() to add dependencies
Make sure air format ., jarl check . --fix --allow-dirty, all tests, and R CMD check pass before you claim to be done.
