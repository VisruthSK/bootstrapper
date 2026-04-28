# workflow step: create_package creates git-backed package skeleton

    Code
      files[!grepl("^\\.git/", files)]
    Output
       [1] ".Rbuildignore"                            
       [2] ".github/dependabot.yml"                   
       [3] ".github/workflows/check-standard.yaml"    
       [4] ".github/workflows/format-suggest.yaml"    
       [5] ".github/workflows/test-coverage.yaml"     
       [6] ".github/workflows/touchstone-comment.yaml"
       [7] ".github/workflows/touchstone-receive.yaml"
       [8] ".vscode/extensions.json"                  
       [9] "AGENTS.md"                                
      [10] "DESCRIPTION"                              
      [11] "LICENSE.md"                               
      [12] "NEWS.md"                                  
      [13] "README.md"                                
      [14] "air.toml"                                 
      [15] "tests/jarl.toml"                          
      [16] "tests/testthat.R"                         
      [17] "touchstone/.gitignore"                    
      [18] "touchstone/config.json"                   
      [19] "touchstone/footer.R"                      
      [20] "touchstone/header.R"                      
      [21] "touchstone/script.R"                      

