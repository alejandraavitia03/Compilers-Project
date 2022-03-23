CS152 Project - Compiler Design Project 
===============================================================
## Created By:
Alejandra A. | Duke P.
Our quarter long project for CS150 Compilers class. 

# Phase 1 - Lexical Analyzer Generation Using flex
  Using the flex tool my team generated a lexical analyzer for a high-level source code language called "MINI-L". Our lexical analyzer takes as input a MINI-L program, parses it, and output the sequence of lexical tokens associated with the program. 
  
# Phase 2 - Parser Generation Using bison
  Building off of Phase 1 my team created a parser using the buson tool that check to see whether the identified sequence of tokens adheres to the specified grammar of MINI-L. Our parser outputs the list of production used during the parsing process. When parsing we check for syntax errors. If a syntax error is encountered, our parser emits the appropriate message. 
  
 # Phase 3 - Code Generator
   Building off of our Phase 2 my teadm built a code generator. We can convert a syntax free MINI-L program, veryify there are no semantic errors and generate the corresponding intermediate code. Once we have our intermediate code, we can execute the code with the toold mil_run. To verify we have the correct generated code we use min_c on the .min file.
