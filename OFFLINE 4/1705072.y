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
string typevariable;
string returntype;
string code;
string optimizedcode;
string dataSegment = ".MODEL SMALL \n\n.STACK 100H \n\n.DATA \n\t";
string commonseg = " DW ?\n\t";
string funcid;

bool voidcheck = false;
bool mainreturn = false;
SymbolInfo *tempsi;
SymbolTable *st = new SymbolTable(30);

FILE *logout;
fstream errorout;
fstream dataout;
fstream opdataout;

//variable list string



struct parameter
{
   string name;
   string type;
   string variable;
   int size = -1;
};
vector <parameter> parameterlist;
vector <parameter> argumentlist;
vector<parameter> variable_list;
vector<string> reg_value;


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

int lebelcount = -1;
int tempvarcount = -1;
int simp = 0;

string getlebel(){
	
	lebelcount++;
	return "lebel" + to_string(lebelcount);

}

string gettempvar()
{
	tempvarcount++;
	dataSegment += "temp" + to_string(tempvarcount) + commonseg;
	return "temp" + to_string(tempvarcount);
	
}

string getsimp()
{
	
	simp = 1 - simp;
	return "simp" + to_string(simp);
	
}


void symboltableinsert(string type)
{	
	int count = 0;
	for (auto& it : variable_list) 
	{
		if(st->Insert(it.name, it.type, type))
		{
			if(it.size) 
			{
				tempsi = st->Lookup(it.name);
				tempsi->setarraySize(it.size);
			}
			tempsi = st->Lookup(it.name);
			tempsi->setReg(reg_value[count]);
		}
		else
			errorfileoutput("Multiple declaration of " + it.name);
		count++;
		
	}
	variable_list.clear();
	reg_value.clear();

}

void parametertableinsert()
{
	for (auto& it : parameterlist) 
	{
		
		if(!st->Insert(it.name, it.type, it.variable)){
			errorfileoutput("Multiple declaration of " + it.name + " in parameter");
		}
		tempsi = st->Lookup(it.name);
		tempsi->setReg(it.name + st->getcurrentId());
		dataSegment += it.name + st->getcurrentId() + commonseg;
		
	}
	tempsi = st->Lookup(funcid);
	
	for (auto& it : parameterlist) 
	{
		tempsi->setfuncParameters(it.name+st->getcurrentId(), it.variable);
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
	parameterlist.clear();


}

string getID(string name)
{

	tempsi = st->Lookup(name);
	
	
	return tempsi->getReg();
}


string assemblyFunc(string op, string op1, string op2)
{

	return op + " " + op1 + "," + op2 + "\n";
}

string mulfunc(string op, string op1)
{

	return op + " " + op1 + "\n";
}



string print = "PRINT PROC \n" + mulfunc("PUSH", "AX") + mulfunc("PUSH", "BX") + mulfunc("PUSH", "CX") + mulfunc("PUSH", "DX") + assemblyFunc("MOV", "AH", "2") + assemblyFunc("MOV", "DL", "32") + mulfunc("INT", "21H") + assemblyFunc("MOV", "AX", "print0") + assemblyFunc("OR", "AX", "AX") + mulfunc("JGE", "END_IF") + mulfunc("PUSH", "AX") + assemblyFunc("MOV", "DL", "'-'") + assemblyFunc("MOV", "AH", "2") + mulfunc("INT", "21H") + mulfunc("POP", "AX") + mulfunc("NEG", "AX") + "END_IF:\n" + assemblyFunc("XOR", "CX", "CX") + assemblyFunc("MOV", "BX", "10D") + "REPEAT2:\n" + assemblyFunc("XOR", "DX", "DX") + mulfunc("DIV", "BX") + mulfunc("PUSH", "DX") + mulfunc("INC", "CX") + assemblyFunc("OR", "AX", "AX") + mulfunc("JNE", "REPEAT2") + assemblyFunc("MOV", "AH", "2") + "PRINT_LOOP:\n" + mulfunc("POP", "DX") + assemblyFunc("OR", "DL", "30H") + mulfunc("INT", "21H") + mulfunc("LOOP", "PRINT_LOOP") + mulfunc("POP", "DX") + mulfunc("POP", "CX") + mulfunc("POP", "BX") + mulfunc("POP", "AX") + "RET \nPRINT ENDP \n\n"; 

%}

%union 
{
	string *s;
	SymbolInfo* si;
}

%token  LPAREN RPAREN SEMICOLON COMMA LCURL RCURL LTHIRD RTHIRD FOR IF ELSE WHILE PRINTLN RETURN ASSIGNOP NOT INCOP DECOP INT FLOAT VOID
%token <si> ID ADDOP MULOP RELOP LOGICOP CONST_INT CONST_FLOAT 


%type <s> declaration_list var_declaration type_specifier unit program func_declaration func_definition parameter_list  arguments argument_list

%type <si> factor term unary_expression simple_expression rel_expression logic_expression expression variable expression_statement statement compound_statement statements

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
					dataSegment += "func0"  + commonseg;
					dataSegment += "print0"  + commonseg;
					dataSegment += "\n.CODE\n\n";
					dataout << dataSegment << endl ;
					dataout << print << endl;
					code += "\n END MAIN\n";
					if(error_count == 0){
					
						dataout << code << endl;
						
					}
					fstream newfile;
					
					newfile.open("code.asm",ios::in); //open a file to perform read operation using file object
					if (newfile.is_open())
					{   //checking whether the file is open
						string one, two, mov, reg1, reg2;
						while(getline(newfile, one))
						{
							if(one.empty())
								continue;
							mov = one.substr(0, 3);
							
							if(mov == "MOV")
							{
								
								mov = one.substr(4, one.length() - 4);
								vector<string> v;

								stringstream ss(mov);
							 
								while (ss.good()) 
								{
									string substr;
									getline(ss, substr, ',');
									v.push_back(substr);
							    	}
							    	reg1 = v[0];
							    	reg2 = v[1];
							    	optimizedcode += one + "\n";
							    	
								break;
							}
							optimizedcode += one + "\n";	
							
							
						}
						
						while(getline(newfile, two))
						{
							if(two.empty())
								continue;
							mov = two.substr(0, 3);
							if(mov == "MOV")
							{
								mov = two.substr(4, two.length() - 4);
								vector<string> v;
	 
								stringstream ss(mov);
							 
								while (ss.good()) 
								{
									string substr;
									getline(ss, substr, ',');
									v.push_back(substr);
							    	}
							    	if(reg1 == v[1] && reg2 == v[0])
							    	{
							    	  
							    	  optimizedcode += ";optimized here\n";
							    	
							    	}
							    	else
							    	{
							    		optimizedcode += two + "\n";
							    	
							    	}
							    	reg1 = v[0];
							    	reg2 = v[1];
							    		
							
							}
							else
							{
								
								optimizedcode += two + "\n";
								if(two[0] != ';')
								{
									reg1 = "";
									reg2 = "";
								}
								
							
							}
							
							
								
						}
						
					}
					
					if(error_count == 0)
					{
					
						opdataout << optimizedcode << endl;
						
					}
					newfile.close(); //close the file object.
					
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
				 		tempsi->setReg($2->getName() + st->getcurrentId());
						
					}
					else
					{
						tempsi = st->Lookup($2->getName());
						funcparameterInsert($2->getName());
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
				 		tempsi->setReg($2->getName()+st->getcurrentId());
						
					}
					else
					{
						tempsi = st->Lookup($2->getName());
						funcparameterInsert($2->getName());
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
				 	funcid = $2->getName();
				 	if($2->getName() != "main")
				 	{
				 		code += $2->getName() + st->getcurrentId() + " PROC\n\n" + mulfunc("PUSH", "AX") + mulfunc("PUSH", "BX") + mulfunc("PUSH", "CX") + mulfunc("PUSH", "DX") + mulfunc("PUSH", "BP") + assemblyFunc("MOV", "BP", "SP"); 
				 		
				 		
				 		
				 	
				 	}
				 	
				 	else
				 		code += $2->getName() + " PROC\n\n" + assemblyFunc("MOV", "AX", "@DATA") + assemblyFunc("MOV", "DS", "AX") + "\n";
				 	if($2->getName() == "main") mainreturn = true;
				 	returntype = *$1;
				 	if(st->Insert($2->getName(), $2->getType(), *$1))
				 	{
				 		
					 	tempsi = st->Lookup($2->getName());
					 	tempsi->setFunc(true);
					 	tempsi->setfuncDefined(true);
					 	tempsi->setReg($2->getName()+st->getcurrentId());
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
					*$$ += *$1 + " " + $2->getName() + "(" + *$4 +")" + $7->getName();
					cout << *$$ << endl; 
					
					
					SymbolInfo *parapop = st->Lookup($2->getName());
					
					 int count = 12;
					string bp;			
					for(int i = parapop->getparameterlistSize() - 1; i >= 0 ; i--)
					{
						bp = "[BP+" + to_string(count) + "]";
						code += assemblyFunc("MOV", "DX", bp) + assemblyFunc("MOV", parapop->getfuncparameterName(i), "DX");
				
						count += 2;
						
						
					}

					
					code += $7->getCode();
					if($2->getName() != "main")
					code += "\n" + mulfunc("POP", "BP") + mulfunc("POP", "DX") + mulfunc("POP", "CX") + mulfunc("POP", "BX") + mulfunc("POP", "AX") + "RET\n" +$2->getName() + st->getcurrentId() + " ENDP\n\n";
					
				
				}
				
				
		| type_specifier ID LPAREN RPAREN 
				{ 
					if($2->getName() != "main")
					code += $2->getName() + st->getcurrentId() + " PROC\n\n" + mulfunc("PUSH", "AX") + mulfunc("PUSH", "BX") + mulfunc("PUSH", "CX") + mulfunc("PUSH", "DX") + mulfunc("PUSH", "BP") + assemblyFunc("MOV", "BP", "SP");
					else
						code += $2->getName() + " PROC\n\n" + assemblyFunc("MOV", "AX", "@DATA") + assemblyFunc("MOV", "DS", "AX") + "\n";
					if($2->getName() == "main") mainreturn = true;
				 	returntype = *$1;
				 	if(st->Insert($2->getName(), $2->getType(), *$1))
				 	{
					 	tempsi = st->Lookup($2->getName());
					 	tempsi->setFunc(true);
					 	tempsi->setfuncDefined(true);
					 	tempsi->setReg($2->getName()+st->getcurrentId());
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
					*$$ += *$1 + " " + $2->getName() + "(" +")" + $6->getName();
					cout << *$$ << endl; 
					code += $6->getCode();
					if($2->getName() != "main")
						code += "\n" + mulfunc("POP", "BP") + mulfunc("POP", "DX") + mulfunc("POP", "CX") + mulfunc("POP", "BX") + mulfunc("POP", "AX") + "RET\n" + $2->getName() + st->getcurrentId() + " ENDP\n\n";
					else
						code += "\n" + assemblyFunc("MOV", "AH", "4CH") + mulfunc("INT", "21H") + "\n" + $2->getName() + " ENDP\n\n";
					
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

						$$ = new SymbolInfo("{\n" + $3->getName() + "\n}" , "", "");
						cout << $$->getName() << endl;
						$$->setReg($3->getReg());
						
						$$->setCode($3->getCode());
						st->printallScopeTable();
						st->ExitScope();
						
					}
 		    | LCURL enter_new_scope RCURL 
 		    			{
 		    				cout << "Line " << line_count << ": " << "compound_statement : LCURL RCURL" << endl;
 		    				$$ = new SymbolInfo("" , "", "");
						st->ExitScope();
						mainreturn = false;

						
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
						 	symboltableinsert(*$1);
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
						dataSegment += $3->getName() + st->getcurrentId() + commonseg;
						reg_value.push_back($3->getName() + st->getcurrentId());
						
						
					 }
					 
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
 		  			
 		  			{
 		  				cout << "Line " << line_count << ": " << "declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl;				
 		  				*$$ = *$1 + "," + $3->getName() + "[" + $5->getName() + "]";
 		  				cout << *$$ << endl;
 		  				variable_list.push_back({ $3->getName(), $3->getType(), tempvariable, stoi($5->getName())});
 		  				dataSegment += $3->getName() + st->getcurrentId() + " DW " + $5->getName() + " DUP (?)\n\t";
 		  				if(stoi($5->getName()) < 0)
 		  				{
 		  					errorfileoutput("Array size is negative");
 		  				}
 		  				reg_value.push_back($3->getName() + st->getcurrentId());
 		  				
 		  				
 		  			}
 		  			
 		  | ID 			{	
 		  				cout << "Line " << line_count << ": " << "declaration_list : ID" << endl;
 		   				$$ = new string(); 
 		   				*$$ += $1->getName();
 		   				cout << *$$ << endl; 
 		   				variable_list.push_back({ $1->getName(), $1->getType(), tempvariable});
 		   				reg_value.push_back($1->getName() + st->getcurrentId());
 		   				dataSegment += $1->getName() + st->getcurrentId() + commonseg;
 		   				
 		   				
 		   			}
 		   			
 		  | ID LTHIRD CONST_INT RTHIRD 
 		  			
 		  			{
 		  				cout << "Line " << line_count << ": " << "declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl;
 		  				$$ = new string(); 
 		  				
 		   				*$$ += $1->getName() + "[" + $3->getName() + "]";
 		   				cout << *$$ << endl;
 		   				variable_list.push_back({ $1->getName(), $1->getType(), tempvariable, stoi($3->getName())});
 		   				dataSegment += $1->getName() + st->getcurrentId() + " DW " + $3->getName() + " DUP (?)\n\t";
 		   				reg_value.push_back($1->getName() + st->getcurrentId());
 		   				
 		  			}
 		  ;
 		  
statements : statement 
					{
						cout << "Line " << line_count << ": " << "statements : statement" << endl;

 		   				$$ = new SymbolInfo($1->getName(), "", "");
						cout << $$->getName() << endl;  
						$$->setReg($1->getReg());
 		   				
 		   				//$$->setCode($1->getCode() + "\n;" + $1->getName() + "\n");
 		   				$$->setCode($1->getCode());
 		   				
 		   				 
 		   				
					}
					
	   | statements statement 	{
	   					cout << "Line " << line_count << ": " << "statements : statements statement" << endl;
	   					
 		   				
 		   				$$->setName($1->getName() + "\n" + $2->getName());
						cout << $$->getName() << endl; 
 		   				
 		   				//$$->setCode($1->getCode() + $2->getCode() +  + "\n;" + $2->getName() + "\n");
 		   				$$->setCode($1->getCode() + $2->getCode());
	   				}
	   ;
	   
statement : var_declaration 
					{
						cout << "Line " << line_count << ": " << "statement : var_declaration" << endl;
						$$ = new SymbolInfo(*$1, "", "");
						cout << $$->getName() << endl;
					}
	  | expression_statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : expression_statement" << endl;

						$$ = new SymbolInfo($1->getName(), "", "");
						cout << $$->getName() << endl;
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
	  				}
	  | compound_statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : compound_statement" << endl;

						$$ = new SymbolInfo($1->getName(), "", "");
						cout << $$->getName() << endl;
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
	  				}
	  				
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl;
	  					$$->setName("for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName());
						cout << $$->getName() << endl;
						string ret = getlebel();
						string ret1 = getlebel();
						$$->setCode($$->getCode() + $3->getCode() + ret + ":\n" + $4->getCode() + mulfunc($4->getLebel(), ret1) + $7->getCode() + $5->getCode() +  mulfunc("JMP", ret) + ret1 + ":\n") ; 
						
						
	  				
	  				}
	  				
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  
	  				{
	  					cout << "Line " << line_count << ": " << "statement : IF LPAREN expression RPAREN statement" << endl;
	  					
	  					$$->setName("if (" + $3->getName() +")" + $5->getName());
	  					cout << $$->getName() << endl;
	  					string rel;
	  					if($3->getLebel()!="")
	  					{
	  						
	  						rel =getlebel();
	  						$$->setCode($$->getCode() + $3->getCode() + mulfunc($3->getLebel(), rel) + "\n" + $5->getCode() + "\n" + rel +":\n");
	  					}
	  					else
	  					{
	  						rel = getlebel();
	  						$$->setCode($$->getCode() + $3->getCode() + assemblyFunc("CMP", $3->getReg(), "0") + mulfunc("JE", rel) + $5->getCode() + "\n" + rel +":\n");
	  					
	  					}
	  					
	  					
	  					
	  				}
	  | IF LPAREN expression RPAREN statement ELSE statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : IF LPAREN expression RPAREN statement ELSE statement" << endl;
						string rel;
	  					if($3->getLebel()!="")
	  					{
	  						string ret = getlebel();
	  						rel = getlebel();
	  						$$->setCode($$->getCode() + $3->getCode() +  mulfunc($3->getLebel(), rel) + "\n" + $5->getCode()  + "\n" + mulfunc("JMP", ret) + "\n" + rel + ":\n" + $7->getCode() + "\n" + ret + ":");
	  					}
	  					else
	  					{
	  						string ret = getlebel();
	  						rel = getlebel();
	  						$$->setCode($$->getCode() + $3->getCode() + assemblyFunc("CMP", $3->getReg(), "0") + mulfunc("JE", rel) + $5->getCode()  + "\n" + mulfunc("JMP", ret) + "\n" + rel + ":\n" + $7->getCode() + "\n" + ret + ":");
	  					
	  					}
	  					
	  					$$->setName("if (" + $3->getName() +")" + $5->getName() + "\n" + "else" + "\n" + $7->getName());
	  					cout << $$->getName() << endl;
	  					
	  					
	  					
	  				}
	  | WHILE LPAREN expression RPAREN statement 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : WHILE LPAREN expression RPAREN statement" << endl;
						string rel;
	  					if($3->getLebel()!="")
	  					{
	  						
	  						rel = getlebel();
	  						string ret = getlebel();
	  						$$->setCode($$->getCode() + ret + ":\n" + $3->getCode() +  mulfunc($3->getLebel(), rel) + $5->getCode() + mulfunc("JMP", ret) + rel + ":\n") ; 
	  						
	  					}
	  					else
	  					{
	  						rel = getlebel();
	  						string ret = getlebel();
	  						
	  						$$->setCode($$->getCode() + ret + ":\n" + $3->getCode() + assemblyFunc("CMP", $3->getReg(), "0") + mulfunc("JE", rel) + $5->getCode() + mulfunc("JMP", ret) + rel + ":\n") ; 
	  					
	  					}
	  					
	  					$$->setName("while (" + $3->getName() +")"  + $5->getName());
	  					cout << $$->getName() << endl;
	  					
						
	  				}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl;
	  			

	  					
	  					$$ = new SymbolInfo("printf(" + $3->getName() +")" + ";", "", "");
	  					cout << $$->getName() << endl;
	  					
	  					if(!st->Lookup($3->getName()))
	  					{
	  						errorfileoutput("Undeclared variable " + $3->getName());
	  					}
	  					$$->setCode(assemblyFunc("MOV", "BX", getID($3->getName())) + assemblyFunc("MOV", "print0", "BX") + "\nCALL PRINT \n");
	  					$$->setCode($$->getCode() + ";" + $$->getName() + "\n");
	  					
	  				}
	  | RETURN expression SEMICOLON 
	  				{
	  					cout << "Line " << line_count << ": " << "statement : RETURN expression SEMICOLON" << endl;
						
						$$ = new SymbolInfo("return " + $2->getName() + ";", "", "");
	  					cout << $$->getName() << endl;
						if(!mainreturn)
						$$->setCode($2-> getCode() + assemblyFunc("MOV", "BX", $2->getReg()) + assemblyFunc("MOV", "func0","BX") + mulfunc("POP", "BP") + mulfunc("POP", "DX") + mulfunc("POP", "CX") + mulfunc("POP", "BX") + mulfunc("POP", "AX") + "RET\n");
						else
				
						if(returntype != $2->getVariable())
						{
							errorfileoutput("Function return type is not matched with the function type");
						}
						$$->setCode($$->getCode() + ";" + $$->getName() + "\n");
	  				}
	  ;
	  
expression_statement : SEMICOLON		
					{
						cout << "Line " << line_count << ": " << "expression_statement : SEMICOLON" << endl;
						$$ = new SymbolInfo(";" , "", "");
						
						
						cout << $$->getName() << endl;
						
						
					}	
		| expression SEMICOLON 	
					{	
						cout << "Line " << line_count << ": " << "expression_statement : expression SEMICOLON" << endl;
						
						$$ = new SymbolInfo($1->getName(), $1->getType(),$1->getVariable());
						$$->setName($1->getName() + ";");
						
						cout << $$->getName() << endl;
						if(voidcheck){
						
							errorfileoutput("Void function used in expression");
							
							voidcheck = false;
						
						}
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
						$$->setLebel($1->getLebel());
						$$->setCode($$->getCode() + ";" + $$->getName() + "\n");
						
					}
			;
	  
variable : ID 		
					{
						cout << "Line " << line_count << ": " << "variable : ID" << endl;
						tempsi = st->Lookup($1->getName());
						if(tempsi != NULL)
						{
							$$ = new SymbolInfo($1->getName(), $1->getType(), tempsi->getVariable());
							$1->setReg(getID($1->getName()));
							$$->setReg($1->getReg());
							
							if(tempsi->getarraySize() != -1)
							{
								errorfileoutput("Type mismatch, "+ $1->getName() + " is an array");
							}
						}
							
							
						else 
						{
							errorfileoutput("Undeclared variable " + $1->getName());
							$$ = new SymbolInfo($1->getName(), $1->getType(), "");
							$1->setReg(getID($1->getName()));
							$$->setReg($1->getReg());
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
							$1->setReg($1->getName() + st->getcurrentId());
							$$->setCode($3->getCode() +  assemblyFunc("LEA", "SI", $1->getReg()) + assemblyFunc("MOV", "AX", $3->getReg()) + assemblyFunc("MOV", $3->getReg(), "2") + mulfunc("IMUL", $3->getReg())+ assemblyFunc("ADD", "SI", "AX"));
							$$->setReg("[SI]");
							if(tempsi->getarraySize() == -1)
							{
								errorfileoutput($1->getName() + " not an array");
							}
						}
							
						else 
						{
							errorfileoutput("Undeclared variable " + $1->getName());
							$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", $3->getType(), "");
							$1->setReg($1->getName() + st->getcurrentId());
							$$->setReg($1->getReg());
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
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
						$$->setLebel($1->getLebel());
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
						
						$$->setReg($1->getReg());
						$$->setLebel($3->getLebel());
						
						$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "BX", $3->getReg()) + assemblyFunc("MOV", $1->getReg(), "BX"));
			 			
			 				
							
		   			}
	   ;
			
logic_expression : rel_expression 	
					{
						cout << "Line " << line_count << ": " << "logic_expression : rel_expression" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
						$$->setLebel($1->getLebel());
						
						
					}
		 | rel_expression LOGICOP rel_expression 
			 		{
			 			cout << "Line " << line_count << ": " << "logic_expression : rel_expression LOGICOP rel_expression" << endl;
						$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "", $1->getVariable());
						cout << $$->getName() << endl;
						
						string temp1 = getlebel();
						string temp2 = getlebel();
						
						if(voidcheck == false && ($1->getVariable() == "void") || $3->getVariable() == "void")
						{
							voidcheck = true;
							
						}
						
						if($2->getName() == "&&")
						{
							$$->setLebel("JE");
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "AX", $1->getReg()) + mulfunc("IMUL", $3->getReg()) + assemblyFunc("CMP", "AX", "0") + mulfunc("JNE", temp1)  + assemblyFunc("MOV", $1->getReg(), "0") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", $1->getReg(), "1") + temp2 + ":\n" + assemblyFunc("CMP", "AX", "0"));
							$$->setReg($1->getReg());
							
						}
						else
						{
						
								
							$$->setLebel("JE");
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "AX", $1->getReg()) + assemblyFunc("ADD", "AX", $3->getReg()) + assemblyFunc("CMP", "AX", "0") + mulfunc("JNE", temp1)  + assemblyFunc("MOV", $1->getReg(), "0") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", $1->getReg(), "1") + temp2 + ":\n" + assemblyFunc("CMP", "AX", "0"));
							$$->setReg($1->getReg());
						
						}
			 		}
		 ;
			
rel_expression	: simple_expression 
					{
						cout << "Line " << line_count << ": " << "rel_expression : simple_expression" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
						$$->setLebel("");
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
						
						if($2->getName() == ">")
						{
							
							string temp1 = getlebel();
							string temp2 = getlebel();
							$$->setReg($1->getReg());
							$$->setLebel("JLE");
							
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("CMP", "CX", $3->getReg()) +  mulfunc("JLE", temp1)  + assemblyFunc("MOV", "BX", "1") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", "BX", "0") + temp2 + ":\n" + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", $1->getReg(),"BX") + assemblyFunc("CMP","CX", $3->getReg()));
							
						
						}
						else if($2->getName() == "<")
						{
							
							string temp1 = getlebel();
							string temp2 = getlebel();
							$$->setReg($1->getReg());
							$$->setLebel("JGE");
							
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("CMP", "CX", $3->getReg()) +  mulfunc("JGE", temp1)  + assemblyFunc("MOV", "BX", "1") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", "BX", "0") + temp2 + ":\n" + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", $1->getReg() , "BX") + assemblyFunc("CMP","CX", $3->getReg()));
						}
						else if($2->getName() == ">=")
						{
							
							string temp1 = getlebel();
							string temp2 = getlebel();
							$$->setReg($1->getReg());
							$$->setLebel("JL");
							
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("CMP", "CX", $3->getReg()) +  mulfunc("JL", temp1)  + assemblyFunc("MOV", "BX", "1") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", "BX", "0") + temp2 + ":\n" + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", $1->getReg() , "BX") + assemblyFunc("CMP","CX", $3->getReg()));
						}
						else if($2->getName() == "<=")
						{

							
							string temp1 = getlebel();
							string temp2 = getlebel();
							$$->setReg($1->getReg());
							$$->setLebel("JG");
							
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("CMP", "CX", $3->getReg()) +  mulfunc("JG", temp1)  + assemblyFunc("MOV", "BX", "1") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", "BX", "0") + temp2 + ":\n" + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", $1->getReg() , "BX") + assemblyFunc("CMP","CX", $3->getReg()));
						}
						else if($2->getName() == "==")
						{

							
							string temp1 = getlebel();
							string temp2 = getlebel();
							$$->setReg($1->getReg());
							$$->setLebel("JNE");
							
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("CMP", "CX", $3->getReg()) +  mulfunc("JNE", temp1)  + assemblyFunc("MOV", "BX", "1") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", "BX", "0") + temp2 + ":\n" + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", $1->getReg() , "BX") + assemblyFunc("CMP","CX", $3->getReg()));
						}
						else if($2->getName() == "!=")
						{
							string temp1 = getlebel();
							string temp2 = getlebel();
							$$->setReg($1->getReg());
							$$->setLebel("JE");
							
							
							$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("CMP", "CX", $3->getReg()) +  mulfunc("JE", temp1)  + assemblyFunc("MOV", "BX", "1") + mulfunc("JMP", temp2) + temp1 + ":\n" + assemblyFunc("MOV", "BX", "0") + temp2 + ":\n" + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", $1->getReg() , "BX") + assemblyFunc("CMP","CX", $3->getReg()));
						}
			 				
					}
		;
				
simple_expression : term 
					{
						cout << "Line " << line_count << ": " << "simple_expression : term" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
						
						
					}
		  | simple_expression ADDOP term 
					{
						cout << "Line " << line_count << ": " << "simple_expression : simple_expression ADDOP term" << endl;
						string ret;
						ret = gettempvar();
						//ret = getsimp();
						$$->setName($1->getName() + $2->getName() + $3->getName());
						if($3->getVariable() == "float")
							$$->setVariable("float");
			 			cout << $$->getName() << endl;
			 			if(voidcheck == false && ($1->getVariable() == "void") || $3->getVariable() == "void")
			 			
			 				voidcheck = true;
			 			if($2->getName() == "+")
			 			{
			 			
			 				$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "AX", $1->getReg()) +  assemblyFunc("ADD", "AX", $3->getReg()) +  assemblyFunc("MOV", $1->getReg(), "AX"));
			 				
			 			}
			 			
			 			else
			 			
			 			{
			 			
			 				$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "AX", $1->getReg()) +  assemblyFunc("SUB", "AX", $3->getReg()) +  assemblyFunc("MOV", $1->getReg(), "AX"));
			 				
			 			}
			 				
			 			$$->setReg($1->getReg());
					}
		  ;
					
term :	unary_expression 
					{
						cout << "Line " << line_count << ": " << "term : unary_expression" << endl;

					 	$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
					 	
						cout << $$->getName() << endl;
						$$->setReg($1->getReg());
						$$->setCode($1->getCode());
						
						
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
			 			
			 			if($2->getName() == "*")
			 			{
			 				$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "AX", $1->getReg()) +  mulfunc("IMUL", $3->getReg()) +  assemblyFunc("MOV", $1->getReg(), "AX"));
			 				
			 			
			 			}
			 			
			 			if($2->getName() == "/")
			 			{
			 			
			 				
			 				$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "AX", $1->getReg()) +  mulfunc("IDIV", $3->getReg()) +  assemblyFunc("MOV", $1->getReg(), "AX"));
			 				
			 			}
			 			
			 			else if($2->getName() == "%")
			 			{
			 			
			 				$$->setCode($1->getCode() + $3->getCode() + assemblyFunc("MOV", "AX", $1->getReg()) +  mulfunc("IDIV", $3->getReg()) +  assemblyFunc("MOV", $1->getReg(), "DX"));
			 				
			 			}
			 			$$->setReg($1->getReg());
			 			
			 			
			 			
			 			
			 			
					}
     ;

unary_expression : ADDOP unary_expression  
					{
						cout << "Line " << line_count << ": " << "unary_expression : ADDOP unary_expression" << endl;
						$$->setName($1->getName() + $2->getName());
			 			cout << $$->getName() << endl;
			 			if($2->getName() == "+")
			 			{
			 				$$->setCode($2->getCode());
							$$->setReg($2->getReg());
			 			}
			 				
			 			else
			 			{
			 				$$->setCode($2->getCode() + mulfunc("NEG", $2->getReg()));
							$$->setReg($2->getReg());
			 			}
			 				
					}
		 | NOT unary_expression 
			 		{
			 			cout << "Line " << line_count << ": " << "unary_expression : NOT unary_expression" << endl;
			 			
			 			$$->setName("!" + $2->getName());
			 			cout << $$->getName() << endl;
			 			$$->setCode($2->getCode() + mulfunc("NOT", $2->getReg()));
						$$->setReg($2->getReg());
			 		}
		 | factor 
					{
						cout << "Line " << line_count << ": " << "unary_expression : factor" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						$$->setCode($1->getCode());
						$$->setReg($1->getReg());
					}
		 ;
	
factor	: variable 
					{	
						cout << "Line " << line_count << ": " << "factor : variable" << endl;
						$$ = new SymbolInfo($1->getName(), $1->getType(), $1->getVariable());
						cout << $$->getName() << endl;
						string ret = gettempvar();
						$$->setCode($1->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", ret, "CX"));
						$$->setReg(ret);
						
						
					}
	| ID LPAREN argument_list RPAREN 
					{	
						cout << "Line " << line_count << ": " << "factor : ID LPAREN argument_list RPAREN" << endl;
						tempsi = st->Lookup($1->getName());
						SymbolInfo *tempreg;
						if(tempsi != NULL)
						{
							$$ = new SymbolInfo($1->getName() + "(" + *$3 + ")", tempsi->getType(), tempsi->getVariable());
							
							if(tempsi->isFunc())
							{
								cout << tempsi->getparameterlistSize() << endl;
								cout << argumentlist.size() << endl;
								cout << tempsi->getName() << endl;
								if(tempsi->getparameterlistSize() != argumentlist.size())
								{
									errorfileoutput("Total number of arguments mismatch in function " + $1->getName());
								}
								else if(tempsi->getparameterlistSize() == argumentlist.size())
								{
								
									for(int i = 0; i < argumentlist.size(); i++)
									{
										if(argumentlist[i].variable != tempsi->getfuncparameterVariable(i))
										{
											errorfileoutput(to_string((i+1)) + "th argument mismatch in function " + $1->getName());
										}
										//$$->setCode($$->getCode() + assemblyFunc("MOV", "DX", tempreg->getReg()) + assemblyFunc("MOV", tempsi->getfuncparameterName(i), "DX"));
										tempreg = st->Lookup(argumentlist[i].name);
										if(tempreg != NULL)
											$$->setCode($$->getCode() + mulfunc("PUSH", tempreg->getReg()));
										else
											$$->setCode($$->getCode() + mulfunc("PUSH", argumentlist[i].name));
										
									
									}
									$1->setReg(getID($1->getName()));
									$$->setCode($$->getCode() + mulfunc("CALL", $1->getReg()));
									$$->setReg("func0");
									for(int i = argumentlist.size() - 1; i >=  0; i--)
									{
									//$$->setCode($$->getCode() + assemblyFunc("MOV", "DX", tempreg->getReg()) + assemblyFunc("MOV", tempsi->getfuncparameterName(i), "DX"));		
										tempreg = st->Lookup(argumentlist[i].name);
										if(tempreg != NULL)
											$$->setCode($$->getCode() + mulfunc("POP", tempreg->getReg()));
										else
											$$->setCode($$->getCode() + mulfunc("POP", "BX"));
										
									
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
						argumentlist.clear();
						
						
					}
				
	| LPAREN expression RPAREN 
					{
						cout << "Line " << line_count << ": " << "factor : LPAREN expression RPAREN" << endl;
						$$ = new SymbolInfo("(" + $2->getName() + ")", "", $2->getVariable());
						cout << $$->getName() << endl;
						$$->setCode($2->getCode());
						$$->setReg($2->getReg());
						
						
					}
	| CONST_INT  
					{
						cout << "Line " << line_count << ": " << "factor : CONST_INT" << endl;
						
						$$ = new SymbolInfo($1->getName(), $1->getType(), "int");
						cout << $$->getName() << endl;
						
						string ret = gettempvar();
						$$->setCode($1->getCode() + assemblyFunc("MOV", ret, $1->getName()));
						$$->setReg(ret);
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
						
						string ret = gettempvar();
						$$->setCode($1->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", ret, "CX") + "INC [" + $1->getReg() + "]\n");
						$$->setReg(ret);
						
						
						
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
						string ret = gettempvar();
						$$->setCode($1->getCode() + assemblyFunc("MOV", "CX", $1->getReg()) + assemblyFunc("MOV", ret, "CX") + "DEC [" + $1->getReg() + "]\n" );
						$$->setReg(ret);
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
			 			argumentlist.push_back({$3->getName(), $3->getType(), $3->getVariable()});
					}
	      | logic_expression 
		      			{
		      				cout << "Line " << line_count << ": " << "arguments : logic_expression" << endl;
		      				$$ = new string();
			 			*$$ += $1->getName();
			 			cout << *$$ << endl;
			 			argumentlist.push_back({$1->getName(), $1->getType(), $1->getVariable()});
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
	dataout.open ("code.asm", ios::out);
	opdataout.open("optimized_code.asm", ios::out);
	logout= fopen("log.txt","w");
	freopen("log.txt", "w", stdout);

	yyin=fp;
	yyparse();
	fclose(fp);
	fclose(logout);
	
	
	return 0;
}

