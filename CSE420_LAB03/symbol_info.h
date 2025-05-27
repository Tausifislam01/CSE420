#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <iostream>
#include <string>
#include <vector>
#include <list>

using namespace std;

class symbol_info
{
private:
    string name;
    string type;
    symbol_info *next;

    bool func_flag;
    string return_type;
    vector<pair<string, string>> parameters;

    string data_type;
    bool arr_flag;
    int array_size;

    // For temporary storage during parsing
    vector<symbol_info*> temp_args;

public:
    symbol_info() {   
        func_flag = false;
        next = NULL;
        array_size = 0;
        arr_flag = false;     
    }

    symbol_info(string name, string type) {
        this->name = name;
        this->type = type;
        arr_flag = false;
        next = NULL;
        func_flag = false;
        array_size = 0;
    }

    symbol_info(string name, string type, string data_type) {
        this->name = name;
        this->type = type;
        this->data_type = data_type;
        this->arr_flag = false;
        this->func_flag = false;
        next = NULL;
        array_size = 0;
    }

    symbol_info(string name, string type, string data_type, int array_size) {
        this->name = name;
        this->type = type;
        this->data_type = data_type;
        this->array_size = array_size;
        this->arr_flag = true;
        next = NULL;
        this->func_flag = false;
    }

    symbol_info(string name, string type, string return_type, vector<pair<string, string>> params) {
        this->name = name;
        this->type = type;
        this->return_type = return_type;
        this->parameters = params;
        this->func_flag = true;
        this->arr_flag = false;
        next = NULL; 
        array_size = 0;
    }

    // Getters
    string getname() { return name; }
    string gettype() { return type; }
    symbol_info *getnext() { return next; }
    string get_data_type() { return data_type; }
    bool get_is_array() { return arr_flag; }
    int get_array_size() { return array_size; }
    bool get_is_function() { return func_flag; }
    string get_return_type() { return return_type; }
    vector<pair<string, string>> get_parameters() { return parameters; }
    
    // For argument lists
    vector<symbol_info*> get_args() { return temp_args; }
    int get_arg_count() { return temp_args.size(); }

    // Setters
    void setname(string name) { this->name = name; }
    void settype(string type) { this->type = type; }
    void setnext(symbol_info *next) { this->next = next; }
    void set_data_type(string data_type) { this->data_type = data_type; }
    void set_array_size(int size) {
        this->array_size = size;
        this->arr_flag = true;
    }
    void set_as_function(string return_type, vector<pair<string, string>> params) {
        this->func_flag = true;
        this->return_type = return_type;
        this->parameters = params;
    }
    void set_return_type(string type) { return_type = type; }
    void set_is_function(bool flag) { func_flag = flag; }
    void set_args(vector<symbol_info*> args) { temp_args = args; }

    ~symbol_info() {
        if (next)
            delete next;
    }

    // Helper function to print symbol info (for debugging)
    void print(ostream &out) {
        out << "<" << name << " : " << type << ">";
        if (arr_flag) {
            out << " (array of " << data_type << "[" << array_size << "])";
        } else if (func_flag) {
            out << " (function returning " << return_type << ")";
        } else if (!data_type.empty()) {
            out << " (" << data_type << ")";
        }
    }
};

#endif // SYMBOL_INFO_H