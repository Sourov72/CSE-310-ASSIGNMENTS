%option noyywrap

%{
#include<iostream>
#include<stdlib.h>
#include<string.h>
#include"symbolTable.cpp"
//#define YYSTYPE SymbolInfo*
#include "y.tab.h"


using namespace std;

extern YYSTYPE yylval;
extern SymbolTable *st;
extern string tempvariable;
void yyerror(char *);

int line_count =1 ;
int error_count = 0;

string same, actual;
string singleline;
string multiline;

	
string specialcharcheck(string ch){

	string ret=ch;
	if(ch == "\\t") {
		ret =  "\t";
	}
	else if(ch == "\\n") {
		ret =  "\n";
	}
	else if(ch == "\\'") {
		ret =  "\'";
	}
	else if(ch == "\\\\") {
		ret =  "\\";
	}
	else if(ch == "\\a") {
		ret =  "\a";
	}
	else if(ch == "\\v") {
		ret =  "\v";
	}
	else if(ch == "\\r") {
		ret =  "\r";
	}
	else if(ch == "\\0") {
		ret =  "\0";
	}
	else if(ch == "\\b") {
		ret =  "\b";
	}
	else if(ch == "\\f") {
		ret =  "\f";
	}
	
	return ret;

}

%}



Letter [a-zA-Z]
digit [0-9]
specialchar (\\n)|(\\t)|(\\\\)|(\\')|(\\a)|(\\f)|(\\r)|(\\b)|(\\v)|(\\0)
id [a-zA-Z_][a-zA-Z0-9_]*
float ({digit}+)?(\.{digit}+)?(E[+-]?{digit}+)?
op [+-]
newline \r?\n
mulop [*/%]
incop (\+)(\+)
decop (\-)(\-)
relop >=|<=|<|>|==|!=
logicop &&|(\|)(\|)
char '({specialchar}|{Letter}|\\\")'
mullchar '[^\r\n]*'
emptychar ''

%%

{newline} {line_count++;}
[ \t\v]+ {}
if { return IF; }
for {return FOR; }

else {return ELSE;}
while {return WHILE;}
return {return RETURN; }

"=" {return ASSIGNOP; }

"!" {return NOT; }
"(" {return LPAREN; }
")" {return RPAREN; }
"{" {return LCURL; } 
"}" {return RCURL; }
"[" {return LTHIRD; }
"]" {return RTHIRD; }
"," {return COMMA; }
";" {return SEMICOLON; }
"println" {return PRINTLN; }


int 			{ 
				
				return INT; 
			}
			
float 			{
				
				return FLOAT; 
			}
			
void 			{
				
				return VOID; 
			}

{op} 			{
				SymbolInfo* s = new SymbolInfo(yytext, "ADDOP", "");
				yylval.si = s;
				return ADDOP; 
			}
			
{mulop} 		{ 
				SymbolInfo* s = new SymbolInfo(yytext, "MULOP", "");
				yylval.si = s;
				return MULOP; 
			}
			
{incop} 		{	
				return INCOP; 
			}
			
{decop} 		{
				return DECOP;
			}
			
{relop} 		{
				SymbolInfo* s = new SymbolInfo(yytext, "RELOP", "");
				yylval.si = s;
				return RELOP; 
			}
			
{logicop} 		{
				SymbolInfo* s = new SymbolInfo(yytext, "LOGICOP", "");
				yylval.si = s;
				return LOGICOP; 
			}
			

{digit}+ 		{
				SymbolInfo* s = new SymbolInfo(yytext, "CONST_INT", "");
				yylval.si = s;
							
				return CONST_INT;
			}

{float} 		{
				SymbolInfo* s = new SymbolInfo(yytext, "CONST_FLOAT", "");
				yylval.si = s;
							
				return CONST_FLOAT;
				
				}








{id} 			{	 
						
				SymbolInfo* s = new SymbolInfo(yytext, "ID", "");
				yylval.si = s;			
				return ID;
			}
			
. 			{}


%%







