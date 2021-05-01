%option noyywrap

%x singlestring

%x singlelinecomment
%x multilinecomment

%{
#include<stdio.h>
#include<stdlib.h>
#include"symbolTable.cpp"


SymbolTable st(7);

FILE *logout;
fstream tokenout;

int line_count=1;
int error_count=0;
int initial_line;
#define endl endl << endl;

string same, actual;
string singleline;
string multiline;

	
void tokenfileoutput(string name, string type){
	tokenout << "<" << type <<", " << name << "> "; 
}

void LexemeFound(string type, string name){

	cout << "Line no " << line_count << " : Token <" << type << "> Lexeme " << name << " found" << endl;
	tokenfileoutput(name, type);
	
} 

void ConstLexemeFound(string type, string name){

	cout << "Line no " << line_count << " : Token <" << type << "> Lexeme " << name << " found" << endl;
	tokenout << "<" << type << "> "; 
	
} 

void TableInsert(string name, string type){

	if(st.Insert(name, type))
		st.printallScopeTable();

}

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

void stringprint(){
	cout << "Line No " << initial_line << ": Token <STRING> Lexeme " << same << " found --> <STRING, " << actual << "> " << endl; 
	tokenfileoutput(actual, "STRING");
}

void singlelineprint(){
	cout << "Line No " << initial_line << ": Token <COMMENT> Lexeme " << singleline << " found"<< endl; 
}	


void printmultiline(){
	cout << "Line No " << initial_line << ": Token <COMMENT> Lexeme " << multiline << " found"<< endl; 
}

void charprint(){
 	cout << "Line No " << line_count << ": Token <CONST_CHAR> Lexeme " << same << " found --> <"<< "CONST_CHAR, "<< actual << ">" << endl; 
 	tokenfileoutput(actual, "CHAR_CONST");	
}



%}

Letter [a-zA-Z]
digit [0-9]
specialchar (\\n)|(\\t)|(\\\\)|(\\')|(\\a)|(\\f)|(\\r)|(\\b)|(\\v)|(\\0)
id [a-zA-Z_][a-zA-Z0-9]*
float ({digit}+)?(\.{digit}+)?(E[+-]?{digit}+)?
op [+-]
newline \r?\n
mulop [\*\/%]
incop (\+)(\+)|(\-)(\-)
relop >=|<=|<|>|==|!=
logicop &&|(\|)(\|)
char '({specialchar}|{Letter}|\\\")'
mullchar '[^\r\n]*'
emptychar ''
unfinishedchar '([^\n\r']*|\n|\r|\\')
excessdecimal (\.)*{digit}+((\.{digit}+)*)?(E[+-]?{digit}*)?(\.{digit}*)?
weakformed {digit}+(\.{digit}*)?(E[+-]?{digit}*((\.)?{digit}*))?
prefix {digit}*((\.)*{digit}*)*(E[+-]?{digit}*)*({Letter}+(\.)*{digit}*)+((\.)*{digit}*)*(E[+-]?{digit}*)*

%%

<singlestring>(\\\") 			{ same += "\\\""; actual += "\""; }
<singlestring>\\			{ same += yytext; actual += yytext; }
<singlestring>[^\n\r\\\"]*  		{ same += yytext; actual += yytext;}
<singlestring>\\{newline} 			{ same += yytext;line_count++;}
<singlestring>{specialchar} 		{ same += yytext; actual += specialcharcheck(yytext);}
<singlestring>\" 			{ 
						same += yytext;
						actual += yytext;
						stringprint();
						BEGIN INITIAL;

					}
<singlestring>{newline}			{ line_count++;cout << "Error at line no "<< initial_line << ":  Unterminated String " << same << endl; BEGIN INITIAL; error_count++;} 


<singlelinecomment>[^\r\n\\]*|\\ 	{ singleline += yytext;}
<singlelinecomment>(\\{newline}) 		{ singleline += yytext; line_count++;}
<singlelinecomment>{newline} 		{ singlelineprint(); line_count++; BEGIN INITIAL;}



<multilinecomment>[\*]*\/ 		{ multiline += yytext; printmultiline(); BEGIN INITIAL;}
<multilinecomment>[^\n\r\*]*|[\*]*	{ multiline += yytext;}
<multilinecomment>{newline} 		{ line_count++; multiline += yytext;}
<multilinecomment><<EOF>> 		{
						cout << "Error at line no "<< initial_line << ":  Unterminated Comment " << multiline << endl;
						error_count++;
						st.printallScopeTable(); 
						cout << "total lines " << line_count << endl;
						cout << "total errors " << error_count << endl;
						return 0;
					}


{newline} {line_count++; }
[ \t\v]+ {}
\" { BEGIN singlestring; same = yytext; actual = yytext; initial_line = line_count;}
"//" {BEGIN singlelinecomment; singleline = "//";initial_line = line_count;}
"/\*" {BEGIN multilinecomment; multiline = "/*";initial_line = line_count;}
if { ConstLexemeFound("IF", yytext); }
for {ConstLexemeFound("FOR", yytext);}
do {ConstLexemeFound("DO", yytext);}
int {ConstLexemeFound("INT", yytext);}
float {ConstLexemeFound("FLOAT", yytext);}
void {ConstLexemeFound("VOID", yytext);}
switch {ConstLexemeFound("SWITCH", yytext);}
default {ConstLexemeFound("DEFAULT", yytext);}
else {ConstLexemeFound("ELSE", yytext);}
while {ConstLexemeFound("WHILE", yytext);}
break {ConstLexemeFound("BREAK", yytext);}
char {ConstLexemeFound("CHAR", yytext);}
double {ConstLexemeFound("DOUBLE", yytext);}
return {ConstLexemeFound("RETURN", yytext);}
case {ConstLexemeFound("CASE", yytext);}
continue {ConstLexemeFound("CONTINUE", yytext);}
{op} {LexemeFound("ADDOP", yytext);}
{mulop} { LexemeFound("MULOP", yytext);}
{incop} {LexemeFound("INCOP", yytext);}
{relop} {LexemeFound("RELOP", yytext);}
"=" {LexemeFound("ASSIGNOP", yytext);}
{logicop} {LexemeFound("LOGICOP", yytext);}
"!" {LexemeFound("NOT", yytext);}
"(" {LexemeFound("LPAREN", yytext);}
")" {LexemeFound("RPAREN", yytext);}
"{" {LexemeFound("LCURL", yytext); st.EnterScope();} 
"}" {LexemeFound("RCURL", yytext); st.ExitScope(); }
"[" {LexemeFound("LTHIRD", yytext);}
"]" {LexemeFound("RTHIRD", yytext);}
"," {LexemeFound("COMMA", yytext);}
";" {LexemeFound("SEMICOLON", yytext);}

{digit}+ 		{LexemeFound("CONST_INT", yytext); TableInsert(yytext, "CONST_ID");}

{float} 		{LexemeFound("CONST_FLOAT", yytext); TableInsert(yytext, "CONST_FLOAT");}

{id} 			{LexemeFound("ID", yytext); TableInsert(yytext, "ID");}

{weakformed} 		{error_count++; cout << "Error at line no "<< line_count << ": Ill formed number " << yytext << endl;}

{excessdecimal} 	{error_count++;cout << "Error at line no "<< line_count << ": Too many decimal points " << yytext << endl;}

{prefix} 		{error_count++;cout << "Error at line no "<< line_count << ": Invalid prefix on ID or invalid suffix on Number " << yytext << endl;}

{char} 			{ 	same = yytext; actual = yytext; actual.erase(0, 1);  		 
				actual.erase(actual.length()-1, 1);
				actual = specialcharcheck(actual);
				charprint();
				TableInsert(same, "CONST_CHAR");
			}

{emptychar} 		{cout << "Error at line no "<< line_count << ":  Empty character constant error " << yytext << endl; error_count++;}
{unfinishedchar} 	{ 
				same = yytext; if(same[same.length() - 1] == '\n' || same[same.length() - 1] == '\r')  line_count++; 
				cout << "Error at line no "<< line_count << ": Unterminated character " << yytext<< endl; 
				error_count++;
			}
{mullchar} 		{cout << "Error at line no "<< line_count << ": Multi character constant error  " << yytext<< endl;  error_count++;}
<<EOF>> 		{
			st.printallScopeTable(); 
			cout << "total lines " << line_count-1 << endl;
			cout << "total errors " << error_count << endl;
			
			return 0;}
. 			{cout << "Error at line no "<< line_count << ": Unrecognized character  " << yytext<< endl;  error_count++;}
%%


int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("1705072_log.txt","w");
	tokenout.open ("1705072_token.txt", ios::out);
	
	freopen("1705072_log.txt", "w", stdout);
	
	yyin= fin;
	yylex();
	fclose(yyin);
	
	fclose(logout);
	return 0;
}
