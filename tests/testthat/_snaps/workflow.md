# workflow step: create_package creates git-backed package skeleton

    Code
      sort(list.files(".", recursive = TRUE, all.files = TRUE, no.. = TRUE))
    Output
       [1] ".Rbuildignore"                        
       [2] ".git/config"                          
       [3] ".git/hooks/pre-commit"                
       [4] ".github/dependabot.yml"               
       [5] ".github/workflows/check-standard.yaml"
       [6] ".github/workflows/format-suggest.yaml"
       [7] ".github/workflows/test-coverage.yaml" 
       [8] ".vscode/extensions.json"              
       [9] "AGENTS.md"                            
      [10] "DESCRIPTION"                          
      [11] "LICENSE.md"                           
      [12] "NEWS.md"                              
      [13] "README.md"                            
      [14] "air.toml"                             
      [15] "tests/jarl.toml"                      
      [16] "tests/testthat.R"                     

