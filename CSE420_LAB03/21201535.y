%{

#include "symbol_table.h"
#include <cstring>
#include <set>
set<string> reported_non_integer_indices;
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
int error_count = 0;
ofstream outlog;
ofstream outerror;

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

func_definition : type_specifier ID LPAREN 
    {
        current_func_name = $2->getname(); // Set function name early
        current_func_return_type = $1->getname();
    }
    parameter_list RPAREN 
    {
        outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN " << endl << endl;
        
        symbol_info* existing = table->lookup(new symbol_info($2->getname(), "ID"));
        if (existing) {
            
                outerror << "At line no: " << lines << " Multiple declaration of function " 
                         << $2->getname() << endl << endl;
                error_count++;
            
        } else {
            vector<pair<string, string>> params = cur_funct_parameter;
            symbol_info* funct = new symbol_info($2->getname(), "ID", $1->getname());
            funct->set_as_function($1->getname(), params);
            table->insert(funct);
        }
        is_function_definition = true;
    }
    compound_statement
    {	
        outlog << "At line no: " << lines << " func_definition compound_statement " << endl << endl;
        outlog << $1->getname() << " " << $2->getname() << "(" << $5->getname() << ")\n" << $8->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + $5->getname() + ")\n" + $8->getname(), "func_def");	
        
        cur_funct_parameter.clear();
        is_function_definition = false;
    }
    | type_specifier ID LPAREN 
    {
        current_func_name = $2->getname();
        current_func_return_type = $1->getname();
    }
    RPAREN 
    {
        outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN " << endl << endl;
        
        symbol_info* existing = table->lookup(new symbol_info($2->getname(), "ID"));
        if (existing) {
                outerror << "At line no: " << lines << " Multiple declaration of function " 
                         << $2->getname() << endl;
                error_count++;
            
        } else {
            vector<pair<string, string>> params;
            symbol_info* funct = new symbol_info($2->getname(), "ID", $1->getname());
            funct->set_as_function($1->getname(), params);
            table->insert(funct);
            
        }
        is_function_definition = true;
    }
    compound_statement
    { 
        outlog << "At line no: " << lines << " func_definition compound_statement " << endl << endl;
        outlog << $1->getname() << " " << $2->getname() << "()\n" << $7->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + " " + $2->getname() + "()\n" + $7->getname(), "func_def");	
        
        cur_funct_parameter.clear();
        is_function_definition = false;
    }
    ;

parameter_list : parameter_list COMMA type_specifier ID
    {
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID " << endl << endl;
        outlog << $1->getname() << "," << $3->getname() << " " << $4->getname() << endl << endl;
                
        bool duplicate_found = false;
        for (auto param : cur_funct_parameter) {
            if (param.second == $4->getname()) {
                outerror << "At line no: " << lines << " Multiple declaration of variable " 
                         << $4->getname() << " in parameter of " << current_func_name << endl << endl;
                error_count++;
                duplicate_found = true;
                break;
            }
        }

        $$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "param_list");
        
        if (!duplicate_found) {
            pair<string, string> parameter($3->getname(), $4->getname());
            cur_funct_parameter.push_back(parameter);
        }
    }
    | parameter_list COMMA type_specifier
    {
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier " << endl << endl;
        outlog << $1->getname() << "," << $3->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + "," + $3->getname(), "param_list");
        
        pair<string, string> parameter($3->getname(), "");
        cur_funct_parameter.push_back(parameter);
    }
    | type_specifier ID
    {
        outlog << "At line no: " << lines << " parameter_list : type_specifier ID " << endl << endl;
        outlog << $1->getname() << " " << $2->getname() << endl << endl;
        
        bool duplicate_found = false;
        for (auto param : cur_funct_parameter) {
            if (param.second == $2->getname()) {
                outerror << "At line no: " << lines << " Multiple declaration of variable " 
                         << $2->getname() << " in parameter of " << current_func_name << endl << endl;
                error_count++;
                duplicate_found = true;
                break;
            }
        }

        $$ = new symbol_info($1->getname() + " " + $2->getname(), "param_list");
        
        if (!duplicate_found) {
            pair<string, string> parameter($1->getname(), $2->getname());
            cur_funct_parameter.push_back(parameter);
        }
    }
    | type_specifier
    {
        outlog << "At line no: " << lines << " parameter_list : type_specifier " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "param_list");
        
        pair<string, string> parameter($1->getname(), "");
        cur_funct_parameter.push_back(parameter);
    }
    ;

compound_statement : LCURL {
        table->enter_scope();
        reported_non_integer_indices.clear();
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
        
        table->print_current_scope();
        
        table->exit_scope();
        
        $$ = new symbol_info("{\n" + $3->getname() + "\n}", "comp_stmnt");
    }
    | LCURL {
        table->enter_scope();
        reported_non_integer_indices.clear();
    } RCURL
    { 
        outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
        outlog << "{\n}" << endl << endl;
        
        table->print_current_scope();
        
        table->exit_scope();
        
        $$ = new symbol_info("{\n}", "comp_stmnt");
    }
    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
    {
        outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
        outlog << $1->getname() << " " << $2->getname() << ";" << endl << endl;
        
        $$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "var_dec");
        
        current_type = $1->getname();
        
        if (current_type == "void") {
            yyerror("variable type can not be void");
            outerror << "At line no: " << lines << " variable type can not be void" << endl << endl;
            error_count++;
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

        if (var_exist_check($3->getname())) {
            outerror << "At line no: " << lines << " Multiple declaration of variable " << $3->getname() << endl << endl;
            error_count++;
        } 
        else {
            symbol_info* new_var = new symbol_info($3->getname(), "ID", current_type);
            table->insert(new_var);
        }
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        outlog << $1->getname() + "," << $3->getname() << "[" << $5->getname() << "]" << endl << endl;
        $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");

        if (var_exist_check($3->getname())) {
            outerror << "At line no: " << lines << " Multiple declaration of variable " << $3->getname() << endl << endl;
            error_count++;
        } 
        else {
            int size = stoi($5->getname());
            if (size <= 0) {
                outerror << "At line no: " << lines << " Array size must be positive: " << $3->getname() << endl << endl;
                error_count++;
            }
            else {
                symbol_info* new_array = new symbol_info($3->getname(), "ID", current_type, size);
                table->insert(new_array);
            }
        }
    }
    | ID
    {
        outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
        outlog << $1->getname() << endl << endl;
        $$ = new symbol_info($1->getname(), "decl_list");

        if (var_exist_check($1->getname())) {
            outerror << "At line no: " << lines << " Multiple declaration of variable " << $1->getname() << endl << endl;
            error_count++;
        } 
        else {
            symbol_info* new_var = new symbol_info($1->getname(), "ID", current_type);
            table->insert(new_var);
        }
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;
        $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");

        if (var_exist_check($1->getname())) {
            outerror << "At line no: " << lines << " Multiple declaration of variable " << $1->getname() << endl << endl;
            error_count++;
        } 
        else {
            int size = stoi($3->getname());
            if (size <= 0) {
                outerror << "At line no: " << lines << " Array size must be positive: " << $1->getname() << endl;
                error_count++;
            }
            else {
                symbol_info* new_array = new symbol_info($1->getname(), "ID", current_type, size);
                table->insert(new_array);
            }
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

            symbol_info* x = new symbol_info($3->getname(), "ID");
        symbol_info* found = table->lookup(x);
        if (!found) {
            outerror << "At line no: " << lines << " Undeclared variable: " 
                    << $3->getname() << endl << endl;
            error_count++;
	  }
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
        
        symbol_info* x = new symbol_info($1->getname(), "ID");
        symbol_info* found = table->lookup(x);
        delete x;
        
        if (!found) {
            outerror << "At line no: " << lines << " Undeclared variable " 
                    << $1->getname() << endl << endl;
            error_count++;
        }
        else {
            $$->set_data_type(found->get_data_type());
            
            if (found->get_is_array()) {
                outerror << "At line no: " << lines << " variable is of array type : " 
                        << $1->getname() << endl << endl;
                error_count++;
            }
        }
    }
    | ID LTHIRD expression RTHIRD 
    {
        outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD " << endl << endl;
        outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;
        
        $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "varbl");
        symbol_info* lookup_symbol = new symbol_info($1->getname(), "ID");
        symbol_info* arr = table->lookup(lookup_symbol);
        
        if (!arr) {
            outerror << "At line no: " << lines << " Undeclared array: " 
                    << $1->getname() << endl;
            error_count++;
        }
        else {
            $$->set_data_type(arr->get_data_type());
            
            if (!arr->get_is_array()) {
                outerror << "At line no: " << lines << " variable is not of array type : " 
                        << $1->getname() << endl << endl;
                error_count++;
            }
            else {
                string index_type = $3->get_data_type();
                bool is_valid_index = false;
                
                if (index_type == "int") {
                    is_valid_index = true;
                }
                else if ($3->gettype() == "CONST_INT") {
                    is_valid_index = true;
                    $$->set_data_type("int");
                }
                else if ($3->gettype() == "ID") {
                    symbol_info* index_var = table->lookup(new symbol_info($3->getname(), "ID"));
                    if (index_var && index_var->get_data_type() == "int" && !index_var->get_is_array()) {
                        is_valid_index = true;
                        index_type = "int";
                    }
                }
                
                if (!is_valid_index && reported_non_integer_indices.find($1->getname()) == reported_non_integer_indices.end()) {
                    outerror << "At line no: " << lines 
                            << " array index is not of integer type : " 
                            << $1->getname() << endl << endl;
                    reported_non_integer_indices.insert($1->getname());
                    error_count++;
                }
                
                if ($3->gettype() == "CONST_INT") {
                    int index = stoi($3->getname());
                    if (index < 0 || index >= arr->get_array_size()) {
                        outerror << "At line no: " << lines 
                                << " Array index out of bounds: " 
                                << $1->getname() << "[" << index << "]" << endl;
                        error_count++;
                    }
                }
            }
        }
        delete lookup_symbol;
    }
    ;

expression : logic_expression
    {
        outlog << "At line no: " << lines << " expression : logic_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "expr");
        $$->set_data_type($1->get_data_type());
    }
    | variable ASSIGNOP logic_expression
    {
        outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression " << endl << endl;
        outlog << $1->getname() << "=" << $3->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + "=" + $3->getname(), "expr");
        string var_type = $1->get_data_type();
        string expr_type = $3->get_data_type();
        if ($3->gettype() == "CONST_FLOAT") {
            expr_type = "float";
        } else if ($3->gettype() == "CONST_INT") {
            expr_type = "int";
        }
        else if (expr_type=="void"){
            outerror << "At line no: " << lines << " operation on void type" << endl << endl;
            error_count++;
        }
        if (var_type == "int" && expr_type == "float") {
            outerror << "At line no: " << lines << " Warning: Assignment of float value into variable of integer type" << endl << endl;
            error_count++;
        }
        $$->set_data_type($1->get_data_type());
    }
    ;
			
logic_expression : rel_expression
    {
        outlog << "At line no: " << lines << " logic_expression : rel_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "lgc_expr");
        $$->set_data_type($1->get_data_type());
    }
    | rel_expression LOGICOP rel_expression 
    {
        outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression " << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "lgc_expr");
        $$->set_data_type("int");
    }
    ;
			
rel_expression : simple_expression
    {
        outlog << "At line no: " << lines << " rel_expression : simple_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "rel_expr");
        $$->set_data_type($1->get_data_type());
    }
    | simple_expression RELOP simple_expression
    {
        outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression " << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "rel_expr");
        $$->set_data_type("int");
    }
    ;

simple_expression : term
    {
        outlog << "At line no: " << lines << " simple_expression : term " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "simp_expr");
        $$->set_data_type($1->get_data_type());
    }
    | simple_expression ADDOP term 
    {
        outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term " << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "simp_expr");
        string type1 = $1->get_data_type();
        string type3 = $3->get_data_type();
        if (type1 == "float" || type3 == "float") {
            $$->set_data_type("float");
        }
        else {
            $$->set_data_type(type1);
        }
    }
    ;
					
term : unary_expression
    {
        outlog << "At line no: " << lines << " term : unary_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "term");
        $$->set_data_type($1->get_data_type());
        
        //if ($1->get_data_type() == "void") {
            //outerror << "At line no: " << lines << " operation on void type" << endl << endl;
            //error_count++;
       // }
    }
    | term MULOP unary_expression
    {
        outlog << "At line no: " << lines << " term : term MULOP unary_expression " << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
        
        string type1 = $1->get_data_type();
        string type2 = $3->get_data_type();
        string op = $2->getname();
        
        if (type1.empty() || type2.empty()) {
            // Skip if types unknown
        }
        else if (type2 == "void") {
            outerror << "At line no: " << lines << " operation on void type" << endl <<endl;
            error_count++;
        }
        
        if (op == "%") {
            if (type1 != "int" || type2 != "int") {
                outerror << "At line no: " << lines << " Modulus operator on non integer type" << endl << endl;
                error_count++;
            }
            if ($3->get_data_type() == "int" && $3->getname() == "0") {
                outerror << "At line no: " << lines << " Modulus by 0" << endl << endl;
                error_count++;
            }
            $$ = new symbol_info($1->getname() + op + $3->getname(), "term");
            $$->set_data_type("int");
        }
        else {
            $$ = new symbol_info($1->getname() + op + $3->getname(), "term");
            if (type1 == "float" || type2 == "float") {
                $$->set_data_type("float");
            }
            else {
                $$->set_data_type(type1);
            }
        }
    }
    ;
unary_expression : ADDOP unary_expression
    {
        outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression " << endl << endl;
        outlog << $1->getname() << $2->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname() + $2->getname(), "un_expr");
        $$->set_data_type($2->get_data_type());
    }
    | NOT unary_expression 
    {
        outlog << "At line no: " << lines << " unary_expression : NOT unary_expression " << endl << endl;
        outlog << "!" << $2->getname() << endl << endl;
        
        $$ = new symbol_info("!" + $2->getname(), "un_expr");
        $$->set_data_type("int");
    }
    | factor 
    {
        outlog << "At line no: " << lines << " unary_expression : factor " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "un_expr");
        $$->set_data_type($1->get_data_type());
    }
    ;
	
factor : variable
    {
        outlog << "At line no: " << lines << " factor : variable " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "fctr");
        $$->set_data_type($1->get_data_type());
    }
    | ID LPAREN argument_list RPAREN
    {
        outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
        outlog << $1->getname() << "(" << $3->getname() << ")" << endl << endl;
        
        symbol_info* func = table->lookup(new symbol_info($1->getname(), "ID"));
        if (!func || !func->get_is_function()) {
            outerror << "At line no: " << lines << " Undeclared function: " << $1->getname() << endl << endl;
            error_count++;
        }
        else {
            vector<pair<string, string>> params = func->get_parameters();
            vector<symbol_info*> args = $3->get_args();
            
            if (params.size() != args.size()) {
                outerror << "At line no: " << lines << " Inconsistencies in number of arguments in function call: " 
                         << $1->getname() << endl << endl;
                error_count++;
            }
            else {
                for (int i = 0; i < params.size(); i++) {
                    string expected_type = params[i].first;
                    string actual_type = args[i]->get_data_type();
                    
                    // Determine actual type for arguments
                    if (args[i]->gettype() == "CONST_INT") {
                        actual_type = "int";
                    }
                    else if (args[i]->gettype() == "CONST_FLOAT") {
                        actual_type = "float";
                    }
                    else if (args[i]->gettype() == "ID") {
                        symbol_info* arg_var = table->lookup(new symbol_info(args[i]->getname(), "ID"));
                        if (arg_var) {
                            actual_type = arg_var->get_data_type();
                            if (arg_var->get_is_array()) {
                                actual_type = arg_var->get_data_type(); // Arrays pass as same type
                            }
                        }
                    }
                    else if (args[i]->gettype() == "varbl") {
                        symbol_info* arg_var = table->lookup(new symbol_info(args[i]->getname(), "ID"));
                        if (arg_var) {
                            actual_type = arg_var->get_data_type();
                        }
                    }
                    
                    // Skip type checking if actual type is unknown or void
                    if (actual_type.empty() || actual_type == "void") {
                        continue;
                    }
                    
                    // Allow implicit conversion from int to float
                    if (expected_type == "float" && actual_type == "int") {
                        continue;
                    }
                    
                    // Report type mismatch only if types differ
                    if (expected_type != actual_type) {
                        outerror << "At line no: " << lines << " argument " << i+1 
                                 << " type mismatch in function call: " << $1->getname() << endl << endl;
                        error_count++;
                    }
                }
            }
        }
        
        $$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "fctr");
        string return_type = func ? func->get_return_type() : "";
        $$->set_return_type(return_type);
        $$->set_data_type(return_type);
        $$->set_is_function(true);
    }
    | LPAREN expression RPAREN
    {
        outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN " << endl << endl;
        outlog << "(" << $2->getname() << ")" << endl << endl;
        
        $$ = new symbol_info("(" + $2->getname() + ")", "fctr");
        $$->set_data_type($2->get_data_type());
    }
    | CONST_INT 
    {
        outlog << "At line no: " << lines << " factor : CONST_INT " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "fctr");
        $$->set_data_type("int");
    }
    | CONST_FLOAT
    {
        outlog << "At line no: " << lines << " factor : CONST_FLOAT " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "fctr");
        $$->set_data_type("float");
    }
    | variable INCOP 
    {
        outlog << "At line no: " << lines << " factor : variable INCOP " << endl << endl;
        outlog << $1->getname() << "++" << endl << endl;
        
        symbol_info* var = table->lookup(new symbol_info($1->getname(), "ID"));
        if (var && var->get_data_type() == "void") {
            outerror << "At line no: " << lines << " Cannot increment void variable" << endl;
            error_count++;
        }
        
        $$ = new symbol_info($1->getname() + "++", "fctr");
        $$->set_data_type(var ? var->get_data_type() : "");
    }
    | variable DECOP
    {
        outlog << "At line no: " << lines << " factor : variable DECOP " << endl << endl;
        outlog << $1->getname() << "--" << endl << endl;
        
        symbol_info* var = table->lookup(new symbol_info($1->getname(), "ID"));
        if (var && var->get_data_type() == "void") {
            outerror << "At line no: " << lines << " Cannot decrement void variable" << endl;
            error_count++;
        }
        
        $$ = new symbol_info($1->getname() + "--", "fctr");
        $$->set_data_type(var ? var->get_data_type() : "");
    }
    ;
	
argument_list : arguments
    {
        outlog << "At line no: " << lines << " argument_list : arguments " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        // Create new symbol for argument list
        $$ = new symbol_info($1->getname(), "arg_list");
        
        // Copy arguments from the arguments rule
        vector<symbol_info*> args = $1->get_args();
        $$->set_args(args);
        
        // Propagate type information for semantic checks
        for (auto arg : args) {
            if (arg->get_data_type() == "void") {
                outerror << "At line no: " << lines << " Cannot pass void type as argument" << endl;
                error_count++;
            }
        }
    }
    | 
    {
        outlog << "At line no: " << lines << " argument_list : empty " << endl << endl;
        outlog << "" << endl << endl;
        
        // Create empty argument list
        $$ = new symbol_info("", "arg_list");
        $$->set_args({});
    }
    ;

arguments : arguments COMMA logic_expression
    {
        outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression " << endl << endl;
        outlog << $1->getname() << "," << $3->getname() << endl << endl;
        
        // Get existing arguments
        vector<symbol_info*> args = $1->get_args();
        
        // Add new argument
        args.push_back($3);
        
        // Create new argument list with updated arguments
        $$ = new symbol_info($1->getname() + "," + $3->getname(), "arg");
        $$->set_args(args);
        
        // Propagate type information
        $$->set_data_type($3->get_data_type());
        
        // Check for void argument
        if ($3->get_data_type() == "void") {
            outerror << "At line no: " << lines << " Cannot pass void type as argument" << endl;
            error_count++;
        }
    }
    | logic_expression
    {
        outlog << "At line no: " << lines << " arguments : logic_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        // Create new argument list with single argument
        $$ = new symbol_info($1->getname(), "arg");
        $$->set_args({$1});
        
        // Propagate type information
        $$->set_data_type($1->get_data_type());
        
        // Check for void argument
        if ($1->get_data_type() == "void") {
            outerror << "At line no: " << lines << " Cannot pass void type as argument" << endl;
            error_count++;
        }
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
	outerror.open("21201535_error.txt", ios::trunc);
	
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
	outerror << endl << "Total errors: " << error_count << endl;
	outlog.close();
	fclose(yyin);
	
	return 0;
}

