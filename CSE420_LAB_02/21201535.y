%{

#include "symbol_table.h"
#include <cstring>

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// symbol table here.
symbol_table *table; 
string current_type;
string current_func_name;
string current_func_return_type;
vector<pair<string, string> > cur_funct_parameter;
bool is_function_definition = false;
bool error_found = false;

int lines = 1;
ofstream outlog;

void yyerror(const char *s)
{
    outlog << "Error at line " << lines << ": " << s << endl << endl;
    error_found = true;
}

bool var_exist_check(string name) {
    symbol_info* x = new symbol_info(name, "ID");
    symbol_info* found = table->lookup_current_scope(x);
    delete x;
    return found != NULL;
}



bool func_exist_check(string name) {
    symbol_info* x = new symbol_info(name, "ID");
    symbol_info* found = table->lookup(x);
    delete x;
    return found != NULL && found->get_is_function();
}



%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog << "At line no: " << lines << " start : program " << endl << endl;
		table->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog << "At line no: " << lines << " program : program unit " << endl << endl;
		outlog << $1->getname() + "\n" + $2->getname() << endl << endl;
		$$ = new symbol_info($1->getname() + "\n" + $2->getname(), "program");
	}
	| unit
	{
		outlog << "At line no: " << lines << " program : unit " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "program");
	}
	;

unit : var_declaration
	 {
		outlog << "At line no: " << lines << " unit : var_declaration " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "unit");
	 }
     | func_definition
     {
		outlog << "At line no: " << lines << " unit : func_definition " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "unit");
	 }
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {

			if(!func_exist_check($2->getname())) {
				vector<pair<string, string> > params = cur_funct_parameter;
				symbol_info* funct = new symbol_info($2->getname(), "ID", $1->getname());
				funct->set_as_function($1->getname(), params);
				table->insert(funct);
			}

		    // The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
           // However, note that the scope of the function and the scope of the compound statement are different.

		} compound_statement
		{	
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << "(" + $4->getname() + ")\n" << $7->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + $4->getname() + ")\n" + $7->getname(), "func_def");	
			
			// Clear function parameters for next function
			cur_funct_parameter.clear();
		}
		| type_specifier ID LPAREN RPAREN {
			
			if(!func_exist_check($2->getname())) {
				vector<pair<string, string> > params;
				symbol_info* funct = new symbol_info($2->getname(), "ID", $1->getname());
				funct->set_as_function($1->getname(), params);
				table->insert(funct);
			}
			
		} compound_statement
		{
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << "()\n" << $6->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + " " + $2->getname() + "()\n" + $6->getname(), "func_def");	
		}
		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID " << endl << endl;
			outlog << $1->getname() << "," << $3->getname() << " " << $4->getname() << endl << endl;
					
			$$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "param_list");
			
			// Store parameter info
			pair<string, string> parameter($3->getname(), $4->getname());
			cur_funct_parameter.push_back(parameter);
		}
		| parameter_list COMMA type_specifier
		{
			outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier " << endl << endl;
			outlog << $1->getname() << "," << $3->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + "," + $3->getname(), "param_list");
			
			//storing  the necessary information about the function parameters
			// They will be needed when you want to enter the function into the symbol table
			pair<string, string> parameter($3->getname(), "");
			cur_funct_parameter.push_back(parameter);
		}
 		| type_specifier ID
 		{
			outlog << "At line no: " << lines << " parameter_list : type_specifier ID " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + " " + $2->getname(), "param_list");
			
			//storing  the necessary information about the function parameters
			// They will be needed when you want to enter the function into the symbol table

			pair<string, string> parameter($1->getname(), $2->getname());
			cur_funct_parameter.push_back(parameter);
		}
		| type_specifier
		{
			outlog << "At line no: " << lines << " parameter_list : type_specifier " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "param_list");
			
			// Store parameter info without name
			pair<string, string> parameter($1->getname(), "");
			cur_funct_parameter.push_back(parameter);
		}
 		;

compound_statement : LCURL {
		// Enter a new scope
		table->enter_scope();
		
		// If we're in a function definition, add parameters to current scope
		if(!cur_funct_parameter.empty()) {
			for(auto parameter : cur_funct_parameter) {
				if(!parameter.second.empty()) {
					symbol_info* param_symbol = new symbol_info(parameter.second, "ID", parameter.first);
					table->insert(param_symbol);
				}
			}
		}
	} statements RCURL
	{ 
		outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
		outlog << "{\n" + $3->getname() + "\n}" << endl << endl;
		
		// Print current scope before exiting
		table->print_current_scope();
		
		// Exit the current scope
		table->exit_scope();
		
		$$ = new symbol_info("{\n" + $3->getname() + "\n}", "comp_stmnt");
	}
	| LCURL {
		// Enter a new scope
		table->enter_scope();
	} RCURL
	{ 
		outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
		outlog << "{\n}" << endl << endl;
		
		// Print current scope before exiting
		table->print_current_scope();
		
		// Exit the current scope
		table->exit_scope();
		
		$$ = new symbol_info("{\n}", "comp_stmnt");
	}
	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << ";" << endl << endl;
			
			$$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "var_dec");
			
			// Store the current type for use in declaration_list
			current_type = $1->getname();
			
			
			if(current_type == "void") {
				yyerror("Variable type cannot be void");
			}
		 }
 		 ;

type_specifier : INT
		{
			outlog << "At line no: " << lines << " type_specifier : INT " << endl << endl;
			outlog << "int" << endl << endl;
			
			$$ = new symbol_info("int", "type");
			current_type = "int";
	    }
 		| FLOAT
 		{
			outlog << "At line no: " << lines << " type_specifier : FLOAT " << endl << endl;
			outlog << "float" << endl << endl;
			
			$$ = new symbol_info("float", "type");
			current_type = "float";
	    }
 		| VOID
 		{
			outlog << "At line no: " << lines << " type_specifier : VOID " << endl << endl;
			outlog << "void" << endl << endl;
			
			$$ = new symbol_info("void", "type");
			current_type = "void";
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
 		  	outlog << $1->getname() + "," << $3->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + "," + $3->getname(), "decl_list");

            if(var_exist_check($3->getname())) {
                
                $$ = new symbol_info($1->getname() + "," + $3->getname(), "decl_list");
            } 
			
			else {
                symbol_info* new_var = new symbol_info($3->getname(), "ID", current_type);
                table->insert(new_var);
                $$ = new symbol_info($1->getname() + "," + $3->getname(), "decl_list");
            }
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
 		  	outlog << $1->getname() + "," << $3->getname() << "[" << $5->getname() << "]" << endl << endl;
			$$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");

            if(var_exist_check($3->getname())) {
                
                $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");
            }
			
			else {
                
                int size = stoi($5->getname());
                symbol_info* new_array = new symbol_info($3->getname(), "ID", current_type, size);
                table->insert(new_array);
                $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");
            }
 		  }
 		  |ID
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "decl_list");

            if(var_exist_check($1->getname())) {
                
                $$ = new symbol_info($1->getname(), "decl_list");
            } 
			
			else {
                // Create and insert new variable
                symbol_info* new_var = new symbol_info($1->getname(), "ID", current_type);
                table->insert(new_var);
                $$ = new symbol_info($1->getname(), "decl_list");
            }
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
			outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;
			$$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");

            if(var_exist_check($1->getname())) {
                
                $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");
            } 
			
			else {
                // Create and insert new array
                int size = stoi($3->getname());
                symbol_info* new_array = new symbol_info($1->getname(), "ID", current_type, size);
                table->insert(new_array);
                $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");
            }
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog << "At line no: " << lines << " statements : statement " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "stmnts");
	   }
	   | statements statement
	   {
	    	outlog << "At line no: " << lines << " statements : statements statement " << endl << endl;
			outlog << $1->getname() << "\n" << $2->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + "\n" + $2->getname(), "stmnts");
	   }
	   ;
	   
statement : var_declaration
	  {
	    	outlog << "At line no: " << lines << " statement : var_declaration " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "stmnt");
	  }
	  | func_definition
	  {
	  		outlog << "At line no: " << lines << " statement : func_definition " << endl << endl;
            outlog << $1->getname() << endl << endl;

            $$ = new symbol_info($1->getname(), "stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog << "At line no: " << lines << " statement : expression_statement " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "stmnt");
	  }
	  | compound_statement
	  {
	    	outlog << "At line no: " << lines << " statement : compound_statement " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog << "At line no: " << lines << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement " << endl << endl;
			outlog << "for(" << $3->getname() << $4->getname() << $5->getname() << ")\n" << $7->getname() << endl << endl;
			
			$$ = new symbol_info("for(" + $3->getname() + $4->getname() + $5->getname() + ")\n" + $7->getname(), "stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement " << endl << endl;
			outlog << "if(" << $3->getname() << ")\n" << $5->getname() << endl << endl;
			
			$$ = new symbol_info("if(" + $3->getname() + ")\n" + $5->getname(), "stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement ELSE statement " << endl << endl;
			outlog << "if(" << $3->getname() << ")\n" << $5->getname() << "\nelse\n" << $7->getname() << endl << endl;
			
			$$ = new symbol_info("if(" + $3->getname() + ")\n" + $5->getname() + "\nelse\n" + $7->getname(), "stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog << "At line no: " << lines << " statement : WHILE LPAREN expression RPAREN statement " << endl << endl;
			outlog << "while(" << $3->getname() << ")\n" << $5->getname() << endl << endl;
			
			$$ = new symbol_info("while(" + $3->getname() + ")\n" + $5->getname(), "stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog << "At line no: " << lines << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON " << endl << endl;
			outlog << "printf(" << $3->getname() << ");" << endl << endl; 
			
			$$ = new symbol_info("printf(" + $3->getname() + ");", "stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog << "At line no: " << lines << " statement : RETURN expression SEMICOLON " << endl << endl;
			outlog << "return " << $2->getname() << ";" << endl << endl;
			
			$$ = new symbol_info("return " + $2->getname() + ";", "stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog << "At line no: " << lines << " expression_statement : SEMICOLON " << endl << endl;
				outlog << ";" << endl << endl;
				
				$$ = new symbol_info(";", "expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog << "At line no: " << lines << " expression_statement : expression SEMICOLON " << endl << endl;
				outlog << $1->getname() << ";" << endl << endl;
				
				$$ = new symbol_info($1->getname() + ";", "expr_stmt");
	        }
			;
	  
variable : ID 	
      {
	    outlog << "At line no: " << lines << " variable : ID " << endl << endl;
		outlog << $1->getname() << endl << endl;
			
		$$ = new symbol_info($1->getname(), "varbl");
		
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD " << endl << endl;
		outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;
		
		$$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "varbl");
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog << "At line no: " << lines << " expression : logic_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "expr");
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression " << endl << endl;
			outlog << $1->getname() << "=" << $3->getname() << endl << endl;

			$$ = new symbol_info($1->getname() + "=" + $3->getname(), "expr");
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog << "At line no: " << lines << " logic_expression : rel_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "lgc_expr");
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "lgc_expr");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog << "At line no: " << lines << " rel_expression : simple_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "rel_expr");
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "rel_expr");
	    }
		;
				
simple_expression : term
          {
	    	outlog << "At line no: " << lines << " simple_expression : term " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "simp_expr");
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "simp_expr");
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog << "At line no: " << lines << " term : unary_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "term");
			
	 }
     |  term MULOP unary_expression
     {
	    	outlog << "At line no: " << lines << " term : term MULOP unary_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "term");
			
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname() + $2->getname(), "un_expr");
	     }
		 | NOT unary_expression 
		 {
	    	outlog << "At line no: " << lines << " unary_expression : NOT unary_expression " << endl << endl;
			outlog << "!" << $2->getname() << endl << endl;
			
			$$ = new symbol_info("!" + $2->getname(), "un_expr");
	     }
		 | factor 
		 {
	    	outlog << "At line no: " << lines << " unary_expression : factor " << endl << endl;
			outlog << $1->getname() << endl << endl;
			
			$$ = new symbol_info($1->getname(), "un_expr");
	     }
		 ;
	
factor	: variable
    {
	    outlog << "At line no: " << lines << " factor : variable " << endl << endl;
		outlog << $1->getname() << endl << endl;
			
		$$ = new symbol_info($1->getname(), "fctr");
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
		outlog << $1->getname() << "(" << $3->getname() << ")" << endl << endl;

		$$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "fctr");
	}
	| LPAREN expression RPAREN
	{
	   	outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN " << endl << endl;
		outlog << "(" << $2->getname() << ")" << endl << endl;
		
		$$ = new symbol_info("(" + $2->getname() + ")", "fctr");
	}
	| CONST_INT 
	{
	    outlog << "At line no: " << lines << " factor : CONST_INT " << endl << endl;
		outlog << $1->getname() << endl << endl;
			
		$$ = new symbol_info($1->getname(), "fctr");
	}
	| CONST_FLOAT
	{
	    outlog << "At line no: " << lines << " factor : CONST_FLOAT " << endl << endl;
		outlog << $1->getname() << endl << endl;
			
		$$ = new symbol_info($1->getname(), "fctr");
	}
	| variable INCOP 
	{
	    outlog << "At line no: " << lines << " factor : variable INCOP " << endl << endl;
		outlog << $1->getname() << "++" << endl << endl;
			
		$$ = new symbol_info($1->getname() + "++", "fctr");
	}
	| variable DECOP
	{
	    outlog << "At line no: " << lines << " factor : variable DECOP " << endl << endl;
		outlog << $1->getname() << "--" << endl << endl;
			
		$$ = new symbol_info($1->getname() + "--", "fctr");
	}
	;
	
argument_list : arguments
			  {
					outlog << "At line no: " << lines << " argument_list : arguments " << endl << endl;
					outlog << $1->getname() << endl << endl;
						
					$$ = new symbol_info($1->getname(), "arg_list");
			  }
			  |
			  {
					outlog << "At line no: " << lines << " argument_list :  " << endl << endl;
					outlog << "" << endl << endl;
						
					$$ = new symbol_info("", "arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression " << endl << endl;
				outlog << $1->getname() << "," << $3->getname() << endl << endl;
						
				$$ = new symbol_info($1->getname() + "," + $3->getname(), "arg");
		  }
	      | logic_expression
	      {
				outlog << "At line no: " << lines << " arguments : logic_expression " << endl << endl;
				outlog << $1->getname() << endl << endl;
						
				$$ = new symbol_info($1->getname(), "arg");
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout << "Please input file name" << endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("21201535_log.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout << "Couldn't open file" << endl;
		return 0;
	}

	// initialize the table
	table = new symbol_table(10);  
	
	yyparse();
	
	// clean up
	delete table;
	
	outlog << endl << "Total lines: " << lines << endl;
	outlog.close();
	fclose(yyin);
	
	return 0;
}