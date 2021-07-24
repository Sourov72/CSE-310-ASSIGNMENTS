%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include"symbolTable.cpp"
#define endl endl << endl;

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int line_count;
extern int error_count;
string tempvariable;
string returntype;
bool voidcheck = false;

SymbolInfo *tempsi;

SymbolTable *st = new SymbolTable(30);

FILE *logout;
fstream errorout;

//variable list string



struct parameter
{
   string name;
   string type;
   string variable;
   int size = -1;
};
vector <parameter> parameterlist;
vector<parameter> variable_list;


void yyerror(char *s)
{
	//write your code
	cout << "syntax error" << endl;
}


void errorfileoutput(string s){

	error_count++;
	errorout << "Error at line " << line_count  << ": " << s << endl;	
	cout << "Error at line " << line_count  << ": " << s << endl;	

}



void symboltableinsert()
{	
	
	for (auto& it : variable_list) 
	{
		if(st->Insert(it.name, it.type, it.variable))
		{
			if(it.size) 
			{
				tempsi = st->Lookup(it.name);
				tempsi->setarraySize(it.size);
			}
			tempsi = st->Lookup(it.name);
		}
		else
			errorfileoutput("Multiple declaration of " + it.name);
		
		
	}
	variable_list.clear();

}

void parametertableinsert()
{
	for (auto& it : parameterlist) 
	{
		
		if(!st->Insert(it.name, it.type, it.variable)){
			errorfileoutput("Multiple declaration of " + it.name + " in parameter");
		}
		
	}
	parameterlist.clear();


}

void funcparameterInsert(string name)
{
	tempsi = st->Lookup(name);
	for (auto& it : parameterlist) 
	{
		
		tempsi->setfuncParameters(it.name, it.variable);
	}


}

%}

%union 
{
	string *s;
	SymbolInfo* si;
}

%token  LPAREN RPAREN SEMICOLON COMMA LCURL RCURL LTHIRD RTHIRD FOR IF ELSE WHILE PRINTLN RETURN ASSIGNOP NOT INCOP DECOP INT FLOAT VOID
%token <si> ID ADDOP MULOP RELOP LOGICOP CONST_INT CONST_FLOAT 


%type <s> declaration_list var_declaration type_specifier unit program func_declaration func_definition parameter_list  statement statements compound_statement expression_statement arguments argument_list

%type <si> factor term unary_expression simple_expression rel_expression logic_expression expression variable

//%left 
//%right

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE



%%


start : program
				{
					//write your code in this block in all the similar blocks below
					cout << "Line " << line_count - 1 << ": " << "start : program" << endl;
					st->printallScopeTable();
					cout << "Total Lines: " << line_count - 1 << endl;
					cout << "Total errors: " << error_count << endl;
					
					
				}
	;

program : program unit 
				{ 
					cout << "Line " << line_count << ": " << "program : program unit" << endl; *$$ += *$2; cout << *$$ << endl;
				}
	| unit 			
				{ 
					cout << "Line " << line_count << ": " << "program : unit" << endl; $$ = new string(); *$$ += *$1; cout << *$$ << endl;
				}
	;
	
unit : var_declaration 
				{ 
					cout << "Line " << line_count << ": " << "unit : var_declaration" << endl; 
					$$ = new string(); 
					*$$ += *$1 + "\n"; 
					cout << *$$ << endl;
					
					
				}
     | func_declaration 
				{ 
					cout << "Line " << line_count << ": " << "unit : func_declaration" << endl; 
					$$ = new string(); 
					*$$ += *$1 + "\n"; 
					cout << *$$ << endl;
				}
     | func_definition 
				{ 
					cout << "Line " << line_count << ": " << "unit : func_definition" << endl; 
					$$ = new string(); 
					*$$ += *$1 + "\n"; 
					cout << *$$ << endl;
				}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON 
				{	
					cout << "Line " << line_count << ": " << "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl;
					$$ = new string(); 
					*$$ += *$1 + " " + $2->getName() + "(" + *$4 +")" + ";"; 
					cout << *$$ << endl;

					if(st->Insert($2->getName(), $2->getType(), *$1))
					{
						funcparameterInsert($2->getName());
						tempsi = st->Lookup($2->getName());
				 		tempsi->setFunc(true);
						
					}
					else
					{
						tempsi = st->Lookup($2->getName());
						if(tempsi->isFunc())
						{
							if(*$1 != tempsi->getVariable())
							{
								errorfileoutput("FUNCTION DECLARATION VARIABLE TYPE IS UNMATCHED WITH PREVIOUS TYPE");
							}
							
							if(parameterlist.size() != tempsi->getparameterlistSize())
							{
								errorfileoutput("REDIFINITION OF FUNCTION " + $2->getName() + " WITH UNMATCHED PARAMETERS");
						
							}
							else if(parameterlist.size() == tempsi->getparameterlistSize())
							{
								
							
								for(int i = 0; i < parameterlist.size(); i++)
								{
									if(parameterlist[i].variable != tempsi->getfuncparameterVariable(i))
									{
										errorfileoutput(to_string((i+1)) + "th argument mismatch in function " + $2->getName());
									}
								
								}
								
							}
						}
						else
						{
							errorfileoutput(" Multiple declaration of " + tempsi->getName());
						}
						
						
					}
						
						
					parameterlist.clear();
				
				}
		| type_specifier ID LPAREN RPAREN SEMICOLON 
				{
					cout << "Line " << line_count << ": " << "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl; 
					$$ = new string(); 
					*$$ += *$1 + " " + $2->getName() + "(" +")" + ";"; 
					cout << *$$ << endl;

					
					if(st->Insert($2->getName(), $2->getType(), *$1))
					{
						funcparameterInsert($2->getName());
						tempsi = st->Lookup($2->getName());
				 		tempsi->setFunc(true);
						
					}
					else
					{
						tempsi = st->Lookup($2->getName());
						if(tempsi->isFunc())
						{
							if(tempsi->getparameterlistSize() != 0)
							{
								errorfileoutput("REDIFINITION OF FUNCTION " + $2->getName() + " WITH UNMATCHED PARAMETERS");
							
							}
						}
						else
						{
							errorfileoutput(" Multiple declaration of " + tempsi->getName());
						}
						
					}
						
					
					
					
				}
		;
		 
func_definition : type_specifier ID  LPAREN  parameter_list RPAREN
				 { 
				 	
				 	returntype = *$1;
				 	if(st->Insert($2->getName(), $2->getType(), *$1))
				 	{
				 		funcparameterInsert($2->getName());
					 	tempsi = st->Lookup($2->getName());
					 	tempsi->setFunc(true);
					 	tempsi->setfuncDefined(true);
				 	}
				 	else
				 	{
				 		tempsi = st->Lookup($2->getName());
				 		if(tempsi->isFunc())
				 		{
				 			if(!tempsi->isfuncDefined())
				 			{
				 				if(*$1 != tempsi->getVariable())
								{
									errorfileoutput("Return type mismatch with function declaration in function " + tempsi->getName());
								}
								
								if(parameterlist.size() != tempsi->getparameterlistSize())
								{
									errorfileoutput("Total number of arguments mismatch with declaration in function " + tempsi->getName());
							
								}
								else if(parameterlist.size() == tempsi->getparameterlistSize())
								{
									
								
									for(int i = 0; i < parameterlist.size(); i++)
									{
										if(parameterlist[i].variable != tempsi->getfuncparameterVariable(i))
										{
											errorfileoutput("Parameter type " + parameterlist[i].name +"is unmatched with the function declaration");
										}
									
									}
									
								}
								tempsi->setfuncDefined(true);
				 			}
				 			else
				 			{
				 				errorfileoutput("Function is defined before");
				 			}
							
						}
						else
						{
							errorfileoutput("Multiple declaration of " + tempsi->getName());
						}
				 		
				 	}
				 	
				 	
				 	
				 	
				 	
				 } 
				 compound_statement 
				 
				{
					cout << "Line " << line_count << ": " << "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl;
					$$ = new string(); 
					*$$ += *$1 + " " + $2->getName() + "(" + *$4 +")" + *$7;
					cout << *$$ << endl; 
				
				}
		| type_specifier ID LPAREN RPAREN 
				{ 

				 	returntype = *$1;
				 	if(st->Insert($2->getName(), $2->getType(), *$1))
				 	{
					 	tempsi = st->Lookup($2->getName());
					 	tempsi->setFunc(true);
					 	tempsi->setfuncDefined(true);
				 	}
				 	else
				 	{
				 		tempsi = st->Lookup($2->getName());
				 		if(tempsi->isFunc())
				 		{
				 			if(!tempsi->isfuncDefined())
				 			{
				 				if(*$1 != tempsi->getVariable())
								{
									errorfileoutput("Return type mismatch with function declaration in function " + tempsi->getName());
								}
								
								if(tempsi->getparameterlistSize() != 0)
								{
									errorfileoutput("Total number of arguments mismatch with declaration in function " + tempsi->getName());
							
								}
								tempsi->setfuncDefined(true);
				 			}
				 			else
				 			{
				 				errorfileoutput("Function is defined before");
				 			}
							
						}
						else
						{
							errorfileoutput("Multiple declaration of " + tempsi->getName());
						}
				 		
				 	}
				 	
					
					
				} 
				compound_statement  
				
				{
					cout << "Line " << line_count << ": " << "func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl;				
					$$ = new string(); 
					*$$ += *$1 + " " + $2->getName() + "(" +")" + *$6;
					cout << *$$ << endl; 
					
				}
 		;	
			


parameter_list  : parameter_list COMMA type_specifier ID 
				{
					cout << "Line " << line_count << ": " << "parameter_list : parameter_list COMMA type_specifier ID" << endl;
					*$$ += "," + *$3 + " " + $4->getName();
					cout << *$$ << endl;
					parameterlist.push_back({$4->getName(), $4->getType(), *$3});
					if(*$3 == "void")
					{
						errorfileoutput("Parameter type cannot be void");
					}
					
				}
		| parameter_list COMMA type_specifier 
				{
					cout << "Line " << line_count << ": " << "parameter_list : parameter_list COMMA type_specifier" << endl;
					*$$ += "," + *$3;
					cout << *$$ << endl;
					parameterlist.push_back({"", "", *$3});
					if(*$3 == "void")
					{
						errorfileoutput("Parameter type cannot be void");
					}
					
				}
 		| type_specifier ID 
		 		{
		 			cout << "Line " << line_count << ": " << "parameter_list : type_specifier ID" << endl;
		 			$$ = new string();
		 			*$$ += *$1 + " " + $2->getName();
		 			cout << *$$ << endl;
		 			parameterlist.push_back({$2->getName(), $2->getType(), *$1});
		 			if(*$1 == "void")
					{
						errorfileoutput("Parameter type cannot be void");
					}
		 			
		 		}
		| type_specifier 
				{
					cout << "Line " << line_count << ": " << "parameter_list : type_specifier" << endl;
					$$ = new string();
		 			*$$ += *$1;
		 			cout << *$$ << endl;
		 			parameterlist.push_back({"", "", *$1});
		 			if(*$1 == "void")
					{
						errorfileoutput("Parameter type cannot be void");
					}
				}
 		;

 		
compound_statement : LCURL enter_new_scope statements RCURL 
					{
						
						
						cout << "Line " << line_count << ": " << "compound_statement : LCURL statements RCURL" << endl;
						$$ = new string();
						*$$ += "{" ;
						*$$ += "\n";
						*$$ += *$3;
						*$$ += "\n";
						*$$ += "}" ;
						cout << *$$ << endl;
						
						st->printallScopeTable();
						st->ExitScope();
						
					}
 		    | LCURL enter_new_scope RCURL 
 		    			{
 		    				cout << "Line " << line_count << ": " << "compound_statement : LCURL RCURL" << endl;
 		    				
						st->ExitScope();
 		    			}
 		    ;
enter_new_scope:     			{
						
						st->EnterScope();
						parametertableinsert();
						
					};
					
 		    
var_declaration : type_specifier declaration_list SEMICOLON 
					{
						cout << "Line " << line_count << ": " << "var_declaration : type_specifier declaration_list SEMICOLON" << endl;
						 $$ = new string(); 
						 *$$ += *$1 + " " + *$2 + ";"; 
						 cout << *$$ << endl;
						
						 if(*$1 == "void")
						 {
						 	errorfileoutput("Variable type cannot be void");
						 }
						 else
						 	symboltableinsert();
					}
 		 ;
 		 
type_specifier	: INT 
					{
						cout << "Line " << line_count << ": " << "type_specifier : INT" << endl; 
						$$ = new string(); 
						*$$ += "int";
						cout << *$$ << endl;
						tempvariable = "int";	
					}
					
 		| FLOAT 		{
 						cout << "Line " << line_count << ": " << "type_specifier : FLOAT" << endl; 
 						$$ = new string(); 
 						*$$ += "float";
 						cout << *$$ << endl;
 						tempvariable = "float";
 					}
 					
 		| VOID 			{
 						cout << "Line " << line_count << ": " << "type_specifier : VOID" << endl; 
 						$$ = new string(); 
 						*$$ += "void";
 						cout << *$$ << endl;
 						tempvariable = "void";
 					}
 		;
 		
declaration_list : declaration_list COMMA ID 
					{
						cout << "Line " << line_count << ": " << "declaration_list : declaration_list COMMA ID" << endl; 
						*$$ = *$1 + "," + $3->getName(); 
						cout << *$$ << endl;
						variable_list.push_back({ $3->getName(), $3->getType(), tempvariable});
						
					 }
					 
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
 		  			
 		  			{
 		  				cout << "Line " << line_count << ": " << "declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl;				
 		  				*$$ = *$1 + "," + $3->getName() + "[" + $5->getName() + "]";
 		  				cout << *$$ << endl;
 		  				variable_list.push_back({ $3->getName(), $3->getType(), tempvariable, stoi($5->getName())});
 		  				if(stoi($5->getName()) < 0)
 		  				{
 		  					errorfileoutput("Array size is negative");
 		  				}
 		  				
 		  			}
 		  			
 		  | ID 			{	
 		  				cout << "Line " << line_count << ": " << "declaration_list : ID" << endl;
 		   				$$ = new string(); 
 		   				*$$ += $1->getName();
 		   				cout << *$$ << endl; 
 		   				variable_list.push_back({ $1->getName(), $1->getType(), tempvariable});
 		   				
 		   			}
 		   			
 		  | ID LTHIRD CONST_INT RTHIRD 
 		  			
 		  			{
 		  				cout << "Line " << line_count << ": " << "declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl;
 		  				$$ = new string(); 
 		  				
 		   				*$$ += $1->getName() + "[" + $3->getName() + "]";
 		   				cout << *$$ << endl;
 		   				variable_list.push_back({ $1->getName(), $1->getType(), tempvariable, stoi($3->getName())});
 		   				
 		  			}
 		  ;
 		  
statements : statement 
					{
						cout << "Line " << line_count << ": " << "statements : statement" << endl;
						$$ = new string(); 
						*$$ += *$1;
 		   				cout << *$$ << endl; 
					}
					
	   | statements statement 	{
	   					cout << "Line " << line_count << ": " << "statements : statements statement" << endl;
	   					
	   					*$$ = *$1 + "\n" + *$2 ;
 		   				cout << *$$ << endl; 
	   				}
	   ;
	   
statement : var_declaration 
					{
						cout << "Line " << line_count << ": " << "statement : var_declaration" << endl;
						$$ = new string();
						*$$ += *$1;
						cout << *$$ << endl;
					}
	  | expression_statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : expression_statement" << endl;
	  					$$ = new string();
						*$$ += *$1;
						cout << *$$ << endl;
	  				}
	  | compound_statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : compound_statement" << endl;
	  					$$ = new string();
						*$$ += *$1;
						cout << *$$ << endl;
	  				}
	  				
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl;
	  				
						*$$ = "for(" + *$3 + *$4 + $5->getName() + ")" + *$7;
						cout << *$$ << endl;
	  				
	  				}
	  				
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  
	  				{
	  					cout << "Line " << line_count << ": " << "statement : IF LPAREN expression RPAREN statement" << endl;
	  					*$$ = "if (" + $3->getName() +")" + *$5;
	  					cout << *$$ << endl;
	  				}
	  | IF LPAREN expression RPAREN statement ELSE statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : IF LPAREN expression RPAREN statement ELSE statement" << endl;
	  					*$$ = "if (" + $3->getName() +")" + *$5 + "\n" + "else" + "\n" + *$7;
	  					cout << *$$ << endl;
	  					
	  				}
	  | WHILE LPAREN expression RPAREN statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : WHILE LPAREN expression RPAREN statement" << endl;
	  					*$$ = "while (" + $3->getName() +")"  + *$5;
	  					cout << *$$ << endl;
	  				}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl;
	  			
	  					$$ = new string();
	  					*$$ += "printf(" + $3->getName() +")" + ";";
	  					cout << *$$ << endl;
	  					if(!st->Lookup($3->getName()))
	  					{
	  						errorfileoutput("Undeclared variable " + $3->getName());
	  					}
	  				}
	  | RETURN expression SEMICOLON 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : RETURN expression SEMICOLON" << endl;
	  					$$ = new string();
						*$$ += "return " + $2->getName() + ";";
						cout << *$$ << endl;
						if(returntype != $2->getVariable())
						{
							errorfileoutput("Function return type is not matched with the function type");
						}
	  				}
	  ;
	  
expression_statement : SEMICOLON		
					{
						cout << "Line " << line_count << ": " << "expression_statement : SEMICOLON" << endl;
						$$ = new string();
						*$$ += ";";
						cout << *$$ << endl;
					}	
		| expression SEMICOLON 	
					{	
						cout << "Line " << line_count << ": " << "expression_statement : expression SEMICOLON" << endl;
						$$ = new string();
						*$$ += $1->getName() + ";";
						cout << *$$ << endl;
						if(voidcheck){
						
							errorfileoutput("Void function used in expression");
							
							voidcheck = false;
						
						}
					}
			;
	  
variable : ID 		
					{
						cout << "Line " << line_count << ": " << "variable : ID" << endl;
						tempsi = st->Lookup($1->getName());
						if(tempsi != NULL)
						{
							$$ = new SymbolInfo($1->getName(), $1->getType(), tempsi->getVariable());
							if(tempsi->getarraySize() != -1)
							{
								errorfileoutput("Type mismatch, "+ $1->getName() + " is an array");
							}
						}
							
							
						else 
						{
							errorfileoutput("Undeclared variable " + $1->getName());
							$$ = new SymbolInfo($1->getName(), $1->getType(), "");
						}
						cout << $$->getName() << endl;
						
					}
	 | ID LTHIRD expression RTHIRD 
	 				{
	 					cout << "Line " << line_count << ": " << "variable : ID LTHIRD expression RTHIRD" << endl;
	 					tempsi = st->Lookup($1->getName());
						
						if(tempsi != NULL)
						{
							$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", $3->getType(), tempsi->getVariable());
							if(tempsi->getarraySize() == -1)
							{
								errorfileoutput($1->getName() + " not an array");
							}
						}
							
						else 
						{
							errorfileoutput("Undeclared variable " + $1->getName());
							$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", $3->getType(), "");
						}
						cout << $$->getName() << endl;
						if($3->getVariable() != "int") 
							errorfileoutput("Expression inside third brackets not an integer");
						
						
	 				}
	 ;
	 
expression : logic_expression	
					{
						cout << "Line " << line_count << ": " << "expression : logic expression" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(),$1->getVariable());
						cout << $$->getName() << endl;
					}
	   | variable ASSIGNOP logic_expression 	
		   			{
		   				cout << "Line " << line_count << ": " << "expression : variable ASSIGNOP logic_expression" << endl;
		   				
						$$ = new SymbolInfo($1->getName() + "=" + $3->getName(), "", $1->getVariable());
						cout << $$->getName() << endl;
						
						//tempsi = st->Lookup($1->getName().substr(0, $1->getName().find("[")));
						
						if($1->getVariable() == "int" && $3->getVariable() == "float")
							errorfileoutput("Type Mismatch");
						
						if(voidcheck == false && ($1->getVariable() == "void") || $3->getVariable() == "void")
						{
							voidcheck = true;
							$$->setVariable("void");
						}
			 			
			 				
							
		   			}
	   ;
			
logic_expression : rel_expression 	
					{
						cout << "Line " << line_count << ": " << "logic_expression : rel_expression" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						
					}
		 | rel_expression LOGICOP rel_expression 
			 		{
			 			cout << "Line " << line_count << ": " << "logic_expression : rel_expression LOGICOP rel_expression" << endl;
						$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "", $1->getVariable());
						cout << $$->getName() << endl;
						if(voidcheck == false && ($1->getVariable() == "void") || $3->getVariable() == "void")
						{
							voidcheck = true;
							
						}
			 		}
		 ;
			
rel_expression	: simple_expression 
					{
						cout << "Line " << line_count << ": " << "rel_expression : simple_expression" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
					}
		| simple_expression RELOP simple_expression	
					{
						cout << "Line " << line_count << ": " << "rel_expression : simple_expression RELOP simple_expression" << endl;
						$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "", $1->getVariable());
						cout << $$->getName() << endl;
						
						if(voidcheck == false && ($1->getVariable() == "void") || $3->getVariable() == "void")
						{
							voidcheck = true;
							errorfileoutput("Non-Integer operand on relop operator");
							
						}
			 				
					}
		;
				
simple_expression : term 
					{
						cout << "Line " << line_count << ": " << "simple_expression : term" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
					}
		  | simple_expression ADDOP term 
					{
						cout << "Line " << line_count << ": " << "simple_expression : simple_expression ADDOP term" << endl;

						$$->setName($1->getName() + $2->getName() + $3->getName());
						if($3->getVariable() == "float")
							$$->setVariable("float");
			 			cout << $$->getName() << endl;
			 			if(voidcheck == false && ($1->getVariable() == "void") || $3->getVariable() == "void")
			 			
			 				voidcheck = true;
					}
		  ;
					
term :	unary_expression 
					{
						cout << "Line " << line_count << ": " << "term : unary_expression" << endl;

					 	$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
					 	
						cout << $$->getName() << endl;
					}
     |  term MULOP unary_expression 
					{
						cout << "Line " << line_count << ": " << "term : term MULOP unary_expression" << endl;
						$$->setName($1->getName() + $2->getName() + $3->getName());
			 			cout << $$->getName() << endl;
			 			
			 			
			 			if($1->getVariable() != "void" && $3->getVariable() == "float")
			 			{
			 				$$->setVariable("float");
			 			}
			 				
			 			
			 			if(voidcheck == false && ($1->getVariable() == "void") || $3->getVariable() == "void")
			 			{
			 				voidcheck = true;
			 			}
			 			
			 			if($2->getName() == "%" && stoi($3->getName()) == 0)
			 			{
			 				errorfileoutput("Modulus by Zero");
			 			}
			 			
			 			if($2->getName() == "/" && stoi($3->getName()) == 0)
			 			{
			 				errorfileoutput("Division by Zero");
			 			}
			 				
			 			
			 			if($2->getName() == "%" && ($1->getVariable() != "int" || $3->getVariable() != "int"))
			 			{
			 				errorfileoutput("Non-Integer operand on modulus operator");
			 				$$->setVariable("int");
			 				
			 			}
			 			
			 			
			 			
			 			
			 			
			 				
			 				/// start from hereeeeeeeeeeeeee
			 			/*else if($2->getName() != "%" && $1->getType() == "CONST_INT" && $3->getType() != "CONST_INT")
			 				errorfileoutput("opernands are not of integers type between modulas operator");*/
			 			
					}
     ;

unary_expression : ADDOP unary_expression  
					{
						cout << "Line " << line_count << ": " << "unary_expression : ADDOP unary_expression" << endl;
						$$->setName($1->getName() + $2->getName());
			 			cout << $$->getName() << endl;
					}
		 | NOT unary_expression 
			 		{
			 			cout << "Line " << line_count << ": " << "unary_expression : NOT unary_expression" << endl;
			 			
			 			$$->setName("!" + $2->getName());
			 			cout << $$->getName() << endl;
			 		}
		 | factor 
					{
						cout << "Line " << line_count << ": " << "unary_expression : factor" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
					}
		 ;
	
factor	: variable 
					{	
						cout << "Line " << line_count << ": " << "factor : variable" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						
					}
	| ID LPAREN argument_list RPAREN 
					{	
						cout << "Line " << line_count << ": " << "factor : ID LPAREN argument_list RPAREN" << endl;
						tempsi = st->Lookup($1->getName());
						if(tempsi != NULL)
						{
							$$ = new SymbolInfo($1->getName() + "(" + *$3 + ")", tempsi->getType(), tempsi->getVariable());
							
							if(tempsi->isFunc())
							{
								if(tempsi->getparameterlistSize() != parameterlist.size())
								{
									errorfileoutput("Total number of arguments mismatch in function " + $1->getName());
								}
								else if(tempsi->getparameterlistSize() == parameterlist.size())
								{
								
									for(int i = 0; i < parameterlist.size(); i++)
									{
										if(parameterlist[i].variable != tempsi->getfuncparameterVariable(i))
										{
											errorfileoutput(to_string((i+1)) + "th argument mismatch in function " + $1->getName());
										}
									
									}
								
								}
							}
							
							else
							{ 
								errorfileoutput("Type mismatch, " + $1->getName() +" is not a function");
							}
							
							
						}
							
						else 
						{
							errorfileoutput("Undeclared function " + $1->getName());
							$$ = new SymbolInfo($1->getName() + "(" + *$3 + ")", $1->getType(), "");
						}
							
						cout << $$->getName() << endl;
						parameterlist.clear();
						
						
					}
				
	| LPAREN expression RPAREN 
					{
						cout << "Line " << line_count << ": " << "factor : LPAREN expression RPAREN" << endl;
						$$ = new SymbolInfo("(" + $2->getName() + ")", "", $2->getVariable());
						cout << $$->getName() << endl;
						
					}
	| CONST_INT  
					{
						cout << "Line " << line_count << ": " << "factor : CONST_INT" << endl;
						
						$$ = new SymbolInfo($1->getName(), $1->getType(), "int");
						cout << $$->getName() << endl;
					}
	| CONST_FLOAT 
					{	
						cout << "Line " << line_count << ": " << "factor : CONST_FLOAT" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), "float");
						cout << $$->getName() << endl;
					}
	| variable INCOP 
					{
						cout << "Line " << line_count << ": " << "factor : variable INCOP" << endl;
						// dont know if type has to be declared
						$$ = new SymbolInfo($1->getName() + "++", $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						if(voidcheck == false && ($1->getVariable() == "void"))
						{
							voidcheck = true;
							
						}
						
					}
				
	| variable DECOP 		{
						cout << "Line " << line_count << ": " << "factor : variable DECOP" << endl;
						// dont know if type has to be declared
						$$ = new SymbolInfo($1->getName() + "--", $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						if(voidcheck == false && ($1->getVariable() == "void"))
						{
							voidcheck = true;
							
						}
					}
	;
	
argument_list : arguments 
					{	
						cout << "Line " << line_count << ": " << "argument_list : arguments" << endl;
						$$ = new string(); 
						*$$ += *$1;
						cout << *$$ << endl;
					}
				
			|		{
						cout << "Line " << line_count << ": " << "argument_list : arguments NULL" << endl;
						$$ = new string(); 
						*$$ = "";
						cout << *$$ << endl;
					}
			  ;
	
arguments : arguments COMMA logic_expression 
					{
						cout << "Line " << line_count << ": " << "arguments : arguments COMMA logic_expression" << endl;
			 			*$$ = *$1 + "," + $3->getName();
			 			cout << *$$ << endl;
			 			parameterlist.push_back({$3->getName(), $3->getType(), $3->getVariable()});
					}
	      | logic_expression 
		      			{
		      				cout << "Line " << line_count << ": " << "arguments : logic_expression" << endl;
		      				$$ = new string();
			 			*$$ += $1->getName();
			 			cout << *$$ << endl;
			 			parameterlist.push_back({$1->getName(), $1->getType(), $1->getVariable()});
		      			}
	      ;


%%
int main(int argc,char *argv[])
{

	FILE *fp = fopen(argv[1], "r");
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	errorout.open ("error.txt", ios::out);
	logout= fopen("log.txt","w");
	freopen("log.txt", "w", stdout);

	yyin=fp;
	yyparse();
	fclose(fp);
	fclose(logout);
	
	
	return 0;
}

