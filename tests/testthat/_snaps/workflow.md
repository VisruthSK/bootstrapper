# workflow step: create_package creates git-backed package skeleton

    Code
      files[!grepl("^\\.git/", files)]
    Output
       [1] ".Rbuildignore"                        
       [2] ".github/dependabot.yml"               
       [3] ".github/workflows/check-standard.yaml"
       [4] ".github/workflows/format-suggest.yaml"
       [5] ".github/workflows/test-coverage.yaml" 
       [6] ".vscode/extensions.json"              
       [7] "AGENTS.md"                            
       [8] "DESCRIPTION"                          
       [9] "LICENSE.md"                           
      [10] "NEWS.md"                              
      [11] "README.md"                            
      [12] "air.toml"                             
      [13] "tests/jarl.toml"                      
      [14] "tests/testthat.R"                     

