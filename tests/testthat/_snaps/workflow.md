# workflow step: create_package creates git-backed package skeleton

    Code
      files[!grepl("^\\.git/", files)]
    Output
       [1] ".Rbuildignore"                        
       [2] ".gitattributes"                       
       [3] ".github/dependabot.yml"               
       [4] ".github/workflows/check-standard.yaml"
       [5] ".github/workflows/format-suggest.yaml"
       [6] ".github/workflows/test-coverage.yaml" 
       [7] ".vscode/extensions.json"              
       [8] "AGENTS.md"                            
       [9] "DESCRIPTION"                          
      [10] "LICENSE.md"                           
      [11] "NEWS.md"                              
      [12] "README.md"                            
      [13] "air.toml"                             
      [14] "demoPkg.Rproj"                        
      [15] "jarl.toml"                            
      [16] "tests/testthat.R"                     

