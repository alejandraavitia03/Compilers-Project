/* cs152-miniL phase3 */
%option noyywrap
%{   
#include<string.h>
#include "y.tab.h"
   int col = 1, row = 1;
   
   extern char *identToken;
   extern int numberToken;
%}

NUMBER         [0-9]
SPACE          " "
COMMENT        ##.*
LETTER         [a-zA-Z]
IDENTIFIER     ({LETTER})|({LETTER}({LETTER}|{NUMBER}|"_")*({LETTER}|{NUMBER}))
INVALID1       ({NUMBER}|"_")+{IDENTIFIER}*
INVALID2       {IDENTIFIER}"_"
   
%%

function       {col += yyleng; return FUNCTION;}
beginparams    {col += yyleng; return BEGIN_PARAMS;}
endparams      {col += yyleng; return END_PARAMS;}
beginlocals    {col += yyleng; return BEGIN_LOCALS;}
endlocals      {col += yyleng; return END_LOCALS;}
beginbody      {col += yyleng; return BEGIN_BODY;}
endbody        {col += yyleng; return END_BODY;}
integer        {col += yyleng; return INTEGER;}
array          {col += yyleng; return ARRAY;}
of             {col += yyleng; return OF;}
if             {col += yyleng; return IF;}
then           {col += yyleng; return THEN;}
endif          {col += yyleng; return ENDIF;}
else           {col += yyleng; return ELSE;}
while          {col += yyleng; return WHILE;}
do             {col += yyleng; return DO;}
beginloop      {col += yyleng; return BEGINLOOP;}
endloop        {col += yyleng; return ENDLOOP;}
continue       {col += yyleng; return CONTINUE;}
break          {col += yyleng; return BREAK;}
read           {col += yyleng; return READ;}
write          {col += yyleng; return WRITE;}
not            {col += yyleng; return NOT;}
true           {col += yyleng; return TRUE;}
false          {col += yyleng; return FALSE;}
return         {col += yyleng; return RETURN;}
"-"            {col += yyleng; return SUB;}
"+"            {col += yyleng; return ADD;}
"*"            {col += yyleng; return MULT;}
"/"            {col += yyleng; return DIV;}
"%"            {col += yyleng; return MOD;}
"=="           {col += yyleng; return EQ;}
"<>"           {col += yyleng; return NEQ;}
"<"            {col += yyleng; return LT;}
">"            {col += yyleng; return GT;}
"<="           {col += yyleng; return LTE;}
">="           {col += yyleng; return GTE;}
";"            {col += yyleng; return SEMICOLON;}
":"            {col += yyleng; return COLON;}
","            {col += yyleng; return COMMA;}
"("            {col += yyleng; return L_PAREN;}
")"            {col += yyleng; return R_PAREN;}
"]"            {col += yyleng; return R_SQUARE_BRACKET;}
"["            {col += yyleng; return L_SQUARE_BRACKET;}
":="           {col += yyleng; return ASSIGN;}
{NUMBER}+       {
  col += yyleng; 
  yylval.op_val = strdup(yytext);
  numberToken = atoi(yytext); 
  return NUMBER;
}

##(.)*\n       {/* do not print comments */ row++; col = 1;}

[ \t]+         {/* ignore spaces */ col += yyleng;}

"\n"           {row++; col = 1;}

{IDENTIFIER}+     {
   col += yyleng;
   yylval.op_val = strdup(yytext);
   identToken = yytext; 
   return IDENT;
}

((("_")+)|(({NUMBER})+({LETTER}|"_")))({NUMBER}|{LETTER}|"_")*                { printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", row, col, yytext); exit(0);}

({LETTER})({NUMBER}|{LETTER}|"_")*("_")                                       {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", row, col, yytext); exit(0);}


.   {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", row, col, yytext); exit(0);}

%%