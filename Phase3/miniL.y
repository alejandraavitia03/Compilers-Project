  /* cs152-miniL phase3 project*/
%{
#include<iostream>
#include<stdio.h>
#include<string>
#include<vector>
#include<string.h>
#include<sstream>
#include<fstream>
#include<queue>

extern int yylex(void);
void yyerror(const char *msg);
extern int col;

char *identToken;
int numberToken;
int  count_names = 0;

//every symbol has a name, value, type(either Integer or Array), 

enum Type { Integer, Array };
struct Symbol {
  std::string name;
  Type type;
  int value;
  int size;
  std::string index;
  Symbol(std::string n, Type t, int v, int s, std::string i)
  {
    name = n;
    type = t;
    value = v;
    size = s;
    index = i;
  }
  Symbol(){}
};
struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};
std::queue <std::string> params;
std::queue <std::string> expQueue;
std::vector <Function> symbol_table;
std::vector <std::string> whileVector;
std::vector <std::string> ifVector;
std::vector <std::string> Vector;

std::stringstream out;

std::string gen_temp() {
  static int count = 0;
  return "__temp__" + std::to_string(count++);
}
std::string gen_label(std::string l) {
  static int count = 0;
  return l + std::to_string(count++);
}
void gen_whilelabel(std::string &b, std::string &l,std::string &e){
  static int count = 0;
  b = b + std::to_string(count);
  l = l + std::to_string(count);
  e = e + std::to_string(count);
  count++;
}
void gen_iflabels(std::string &i, std::string &f){
  static int count = 0;
  i = i + std::to_string(count);
  f = f + std::to_string(count);
  count++;
}
Function *get_function() {
  int last = symbol_table.size()-1;
  return &symbol_table[last];
}

bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value; 
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}
Type get_type(std::string &value)
{
  for(int i=0; i<symbol_table.size(); i++) {
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      if (symbol_table[i].declarations[j].name.c_str() == value)
      {
        return symbol_table[i].declarations[j].type;
      }
    }
  }
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}


%}


%union {
  char *op_val;
  //struct CodeNode *node;
}

//%error-verbose
%locations
%define parse.error verbose

/* %start program */
%start prog_start

%token FUNCTION
%token BEGIN_PARAMS
%token END_PARAMS
%token BEGIN_LOCALS
%token END_LOCALS
%token BEGIN_BODY
%token END_BODY
%token INTEGER
%token ARRAY
%token OF 
%token IF
%token THEN
%token ENDIF
%token ELSE
%token WHILE
%token DO
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE
%token BREAK
%token READ
%token WRITE
%right NOT
%token TRUE
%token FALSE
%token RETURN
%token <op_val> NUMBER
%token <op_val> IDENT
%token SEMICOLON 
%token COLON 
%token COMMA
%token L_PAREN 
%token R_PAREN
%token L_SQUARE_BRACKET 
%token R_SQUARE_BRACKET

%token SUB ADD
%token MULT DIV
%token MOD NEQ
%token EQ ASSIGN
%token LT GT
%token LTE GTE

%type<op_val> identifier identifiers comp expressions
%type<op_val> statement expression multiplicative_expr
%type<op_val> declaration declarations bool_expr2 variable
%type<op_val> term bool_expr statements
%%
  /* write your rules here */
/*Start*/
prog_start:  functions {};

/*Function and Functions*/
function:     FUNCTION IDENT
              {
                //midrule: 
                //add the function to the symbol table and print 
                std::string func_name = $2;
                add_function_to_symbol_table(func_name);
                out << "func " << func_name << std::endl;             
              } 
              SEMICOLON BEGIN_PARAMS declarations END_PARAMS
              {
                int pCntr = 0;
                while(!params.empty())
                {
                  out << "= " << params.front() << ", $" << pCntr << std::endl;
                  pCntr++;
                  params.pop();
                }
              } BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
              {
                while(!params.empty())
                {
                  params.pop();
                }
                out << "endfunc" << std::endl;
              };

functions:    function functions {} | {};

/*Identifier and Identifiers*/
identifier:   IDENT 
              {
                $$=$1;
              };

identifiers:  identifier COMMA identifiers {} 
              | identifier 
                {
                  $$ = $1;
                };

/*Declartion and Declarations*/
declaration:  identifiers COLON INTEGER
              { 
                std::string value = $1;
                if(find(value))
                {
                  yyerror(strcpy(new char[value.length() + 1], value.c_str()));
                  YYABORT;
                }
                params.push(value);
                Type t = Integer;
                add_variable_to_symbol_table(value, t);
                out << ". " << value << std::endl;
              } 
              | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
              {
                std::string value = $1;
                if(find(value))
                {
                  yyerror(strcpy(new char[value.length() + 1], value.c_str()));
                  YYABORT;
                }
                params.push(value);
                Type t = Array;
                add_variable_to_symbol_table(value, t);
                out << ".[] " << value << ", " <<  $5 << std::endl;
              };

declarations: declaration SEMICOLON declarations {} | {};

/*Statement and Statements*/
statement:    variable ASSIGN expression 
              {
                // = dst, src AND = dst,$0
                //Check if the variable is of type int or arry
                // a[0] := b + c; variable -> a[0] ; expression b + c
                std::string var = $1; //if array  "a[0]" else temp
                bool isArray = false;
                Type t;

                for(int i = 0; i < var.length(); i++)
                {
                  if(var[i] == '[')
                  {
                      isArray = true;
                  }
                }
                if(isArray)
                {
                  //should check for number in the [] and put in correct place
                  std::string index($1); //index = a[0]
                  for(int i = 0; i < index.length(); i++)
                  {
                    if(index[i] == '0' || index[i] == '1' || index[i] == '2' || index[i] == '3')
                    {
                      index = index[i]; //index = 0
                    }
                  }
                    out << "[]=  " << var[0] << ", " << index << ", " << $3 << std::endl; //[]= a, 0, _temp 
                }
                else
                {
                  if(find(var))
                  {
                    out << "= " << $1 << ", " << $3 << std::endl;
                  }
                  else
                  {
                    yyerror(strcpy(new char[var.length() + 1], var.c_str()));
                  }
                }
              }
              | IF bool_expr THEN 
              {
                std::string if_true =  "if_true";
                std::string endif_ =  "endif";
                gen_iflabels(if_true,endif_);
                std::string val($2);
                out << "?:= " << if_true << ", " << val << std::endl;
                ifVector.push_back(if_true);
                ifVector.push_back(endif_);

              }statements
              {
                std::string endif_ =  ifVector.back();
                ifVector.pop_back();
                std::string if_true =  ifVector.back();
                ifVector.pop_back();
                out << ":= " << endif_ << std::endl;
                out << ": " << if_true << std::endl;
                ifVector.push_back(endif_);
              } 
              ENDIF 
              {
                std::string endif_ =  ifVector.back();
                ifVector.pop_back();
                out << ":= endloop0" << std::endl;
                out << ": " << endif_ << std::endl;
              }
              | IF bool_expr THEN
              {
                std::string val($2);
                out << "?:= iftrue0, " << val << std::endl;
              } statements ELSE 
              {
                out << ":= endif0" << std::endl;
                out << ": else" << std::endl;

              }statements ENDIF 
              {
                out << ": endif0" << std::endl;
              }
              | WHILE 
              {
                //midrule:
                std::string beginloop =  "beginloop";
                std::string loopbody =  "loopbody";
                std::string endloop =  "endloop";
                gen_whilelabel(beginloop, loopbody, endloop);
                out << ": " << beginloop << std::endl;
                whileVector.push_back(beginloop);
                whileVector.push_back(loopbody);
                whileVector.push_back(endloop);
              }bool_expr BEGINLOOP
              {
                std::string val($3);
                std::string endloop = whileVector.back();
                whileVector.pop_back();
                std::string loopbody = whileVector.back();
                whileVector.pop_back();
                out << "?:= " << loopbody << ", " << val << std::endl;
                out << ":= "<< endloop << std::endl;
                out << ": "<< loopbody << std::endl;
                whileVector.push_back(endloop);
              } statements ENDLOOP 
              {
                std::string endloop = whileVector.back();
                whileVector.pop_back();
                std::string beginloop = whileVector.back();
                whileVector.pop_back();
                out << ":= "<< beginloop << std::endl;
                out << ": "<< endloop << std::endl;
              }
              | DO BEGINLOOP
              {
                std::string loop = gen_label("beginloop");
                out << ": " << loop << std::endl;
                whileVector.push_back(loop);
              } statements ENDLOOP WHILE bool_expr 
              {
                std::string val($7);
                std::string loop = whileVector.back();
                out << "?:= " << loop << ", " << val << std::endl;
                out << ": endloop0" << std::endl; 
                whileVector.pop_back();

              }
              | READ variable 
              {
                std::string var = $2;
                std::string name = std::to_string(var[0]);
                if(!find(name))
                {
                 yyerror(strcpy(new char[var.length() + 1], var.c_str()));

                }
                bool isArray = false;

                for(int i = 0; i < var.length(); i++)
                {
                  if(var[i] == '[')
                  {
                    isArray = true;
                  }
                }
                // .> .>[]
                if(isArray)
                {
                  out << ".[]< " << $2 << std::endl;
                }
                else
                {
                  out << ".< " <<  $2 << std::endl;
                }
              }
              | WRITE variable 
              {
                std::string var = $2;
                bool isArray = false;
                for(int i = 0; i < var.length(); i++)
                {
                  if(var[i] == '[')
                  {
                    isArray = true;
                  }
                }
                // .> .>[]
                if(isArray)
                {
                  std::string temp = gen_temp();
                  out << ". " << temp << std::endl;
                  std::string index($2); //index = a[0]
                  for(int i = 0; i < index.length(); i++)
                  {
                    if(index[i] == '0' || index[i] == '1' || index[i] == '2' || index[i] == '3')
                    {
                      index = index[i]; //indemx = 0
                    }
                  }
                  out << "=[] " << temp << ", " << var[0] << ", " << index << std::endl; 
                  out << ".> " << temp << std::endl;
                }
                else
                {
                  out << ".> " <<  $2 << std::endl;
                }
                
              }
              | CONTINUE 
              {
                std::string error = "Cannot use CONTINUE outside of loop";
                char* c = strcpy(new char[error.length() + 1], error.c_str());
                if(whileVector.empty() || ifVector.empty())
                {
                  yyerror(c);

                }

              }
              | BREAK 
              {
                std::string error = "Cannot use BREAK outside of loop";
                char* c = strcpy(new char[error.length() + 1], error.c_str());
                if(whileVector.empty() || ifVector.empty())
                {
                  yyerror(c);

                }
              }
              | RETURN expression 
              {
                std::string val($2);
                out << "ret " << val << std::endl;
              } ;

statements:   statement SEMICOLON statements {} | {};

/*BoolExpr*/
bool_expr:    bool_expr2 
              {
                $$ = $1;
              } | NOT bool_expr2 {};

bool_expr2:   expression comp expression
              {
                  std::string temp = gen_temp();
                  out << ". " << temp << std::endl;
                  out << $2 << " " << temp << ", " << $1 << ", " << $3 << std::endl;
                  char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                  $$ = c;
              }
              | L_PAREN bool_expr R_PAREN {};

/* Comparison */
comp:         EQ 
              {
                $$ = strcpy(new char[2], "==");
              }
              | NEQ 
              {
                $$ = strcpy(new char[2], "!=");
              }
              | LT 
              {
                $$ = strcpy(new char[1], "<");
              }
              | GT 
              {
                $$ = strcpy(new char[1], ">");
              }
              | LTE 
              {
                $$ = strcpy(new char[2], "<=");
              }
              | GTE 
              {
                $$ = strcpy(new char[1], ">=");
              };

/* Expression and Expressions*/
expression:   multiplicative_expr 
              {
                $$ = $1;
              }
              | multiplicative_expr SUB expression
              {
                std::string temp = gen_temp();
                out << ". " << temp << std::endl;
                out << "- " << temp << ", " << $1 << ", " << $3 << std::endl;
                char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                $$ = c;
              }
              | multiplicative_expr ADD expression 
              {
                std::string var = $1;
                bool isArray = false;

                for(int i = 0; i < var.length(); i++)
                {
                  if(var[i] == '[')
                  {
                    isArray = true;
                  }
                }
                if(isArray)
                {
                  std::string curr = gen_temp();
                  out << ". " << curr << std::endl;
                  std::string index($1); //index = a[0]
                  for(int i = 0; i < index.length(); i++)
                  {
                    if(index[i] == '0' || index[i] == '1' || index[i] == '2' || index[i] == '3')
                    {
                      index = index[i]; //index = 0
                    }
                  }
                  out << "=[] " << curr << ", " << var[0] << ", " << index << std::endl;
                  std::string temp = gen_temp();
                  out << ". " << temp << std::endl;
                  out << "+ " << temp << ", " << curr << ", " << $3 << std::endl;
                  char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                  $$ = c;
                }
                else
                {
                  std::string temp = gen_temp();
                  out << ". " << temp << std::endl;
                  out << "+ " << temp << ", " << $1 << ", " << $3 << std::endl;
                  char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                  $$ = c;
                }
              };
expressions:   expression 
              {
                $$ =$1;
              }
              | expression COMMA expressions 
              {
                std::string e($3);
                expQueue.push(e);
              }
              | {};

/*Multiplicative Expression*/
multiplicative_expr:   term 
                      {
                        $$ = $1;  
                      }
                      | term DIV multiplicative_expr 
                      {
                        std::string temp = gen_temp();
                        out << ". " << temp << std::endl;
                        out << "/ " << temp << ", " << $1 << ", " << $3 << std::endl;
                        char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                        $$ = c;
                      }
                      | term MULT multiplicative_expr
                      {
                        //if term is an array then make temp and store in temp
                        std::string var = $1;
                        bool isArray = false;

                        for(int i = 0; i < var.length(); i++)
                        {
                          if(var[i] == '[')
                          {
                            isArray = true;
                          }
                        }
                        if(isArray)
                        {
                          std::string tempA = gen_temp();
                          out << ". " << tempA << std::endl;
                          std::string index($1); //index = a[0]
                          for(int i = 0; i < index.length(); i++)
                          {
                            if(index[i] == '0' || index[i] == '1' || index[i] == '2' || index[i] == '3')
                            {
                                index = index[i]; //index = 0
                            }
                          }
                          out << "=[] " << tempA << ", " << var[0] << ", " << index << std::endl;
                          std::string temp = gen_temp();
                          out << ". " << temp << std::endl;
                          out << "* " << temp << ", " << tempA << ", " << $3 << std::endl;
                          char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                          $$ = c;
                        }
                        else
                        {
                          std::string temp = gen_temp();
                          out << ". " << temp << std::endl;
                          out << "* " << temp << ", " << $1 << ", " << $3 << std::endl;
                          char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                          $$ = c;
                        } 
                      }
                      | term MOD multiplicative_expr 
                      {
                        std::string temp = gen_temp();
                        out << ". " << temp << std::endl;
                        out << "% " << temp << ", " << $1 << ", " << $3 << std::endl;
                        char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                        $$ = c;
                      } ;

/* Term */
term:   variable 
        {
          $$ = $1;
        }
        | NUMBER 
        {
          $$ = $1;
        }
        | L_PAREN expression R_PAREN 
        {
          $$ = $2;
        }
        | IDENT L_PAREN expressions R_PAREN //function(param)
        {
          std::string e($3);
          expQueue.push(e);
          while(!expQueue.empty())
          {
            out << "param " << expQueue.front() << std::endl;
            expQueue.pop();
          }
          std::string temp = gen_temp();
          out << ". " << temp << std::endl;
          out << "call " << $1 << ", " << temp << std::endl;
          char* c = strcpy(new char[temp.length() + 1], temp.c_str());
          $$ = c;
  
        }
        | IDENT L_PAREN R_PAREN 
        {
          std::string temp = gen_temp();
          out << ". " << temp << std::endl;
          out << "call " << $1 << ", " << temp << std::endl;
          char* c = strcpy(new char[temp.length() + 1], temp.c_str());
          $$ = c;
        } 
;
/*Variable and Variables*/
variable:   IDENT 
            {
              $$ = $1;
            }
            | IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET 
            {
              //Here we need too figure out how to do the array identifier
              //Error check, see if ident is in our symbol table if not then abbort
              // variable = 'a[0]''
              std::string name($1);         
              std::string index($3);
              std::string temp = name + "[" + index + "]";
              char* c = strcpy(new char[temp.length() + 1], temp.c_str());
              $$ = c;
            }
;
%%
int main(int argc, char **argv)
{
   yyparse();
   print_symbol_table();
   std::ofstream file("out.mil");
   file << out.str() << std::endl;
   return 0;
}

void yyerror(const char *msg)
{
   printf("** Line %d: %s\n", col, msg);
   exit(1);
}