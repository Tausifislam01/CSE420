#include "symbol_info.h"
#include <list>
#include <fstream>
#include <string>
#include <iomanip>

extern ofstream outlog; // External log file stream


class scope_table
{
private:
    int bucket_count;                  // Number of buckets in hash table
    int unique_id;                     // Unique identifier for this scope
    scope_table *parent_scope = NULL;  // Pointer to parent scope 
    vector<list<symbol_info *>> table; // Hash table with chaining

    
    int hash_function(string name)
    {
        int sum = 0;
        for (char c : name)
        {
            sum += c;
        }
        return sum % bucket_count;
    }

public:
    // Default constructor
    scope_table()
    {
        bucket_count = 10;
        unique_id = 1;
        table.resize(bucket_count);
        outlog << "New ScopeTable with ID " << unique_id << " created" << endl
               << endl;
    }

    //Parameterized constructor
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
        outlog << "New ScopeTable with ID " << unique_id << " created" << endl
               << endl;
    }

    //destructor
    ~scope_table()
    {
        outlog << "Scopetable with ID " << unique_id << " removed" << endl
               << endl;
        for (auto &bucket : table)
        {
            for (auto symbol : bucket)
            {
                delete symbol;
            }
            bucket.clear();
        }
        table.clear();
    }

    // Getter for parent scope
    scope_table *get_parent_scope()
    {
        return parent_scope;
    }

    // Getter for scope ID
    int get_unique_id()
    {
        return unique_id;
    }

    //lookup in symbol table 
    symbol_info *lookup_in_scope(symbol_info *symbol)
    {
        int hash_val = hash_function(symbol->getname());

        // Search in the appropriate bucket
        for (symbol_info *current : table[hash_val])
        {
            if (current->getname() == symbol->getname())
            {
                return current;
            }
        }
        return NULL;
    }

    //Insert
    bool insert_in_scope(symbol_info *symbol)
    {
        // First check if symbol already exists in current scope
        if (lookup_in_scope(symbol) != NULL)
        {
            return false;
        }

        // Insert the symbol into appropriate bucket
        int hash_val = hash_function(symbol->getname());
        table[hash_val].push_back(symbol);
        return true;
    }

    //delete 
    bool delete_from_scope(symbol_info *symbol)
    {
        int hash_val = hash_function(symbol->getname());

        // Search and remove from the appropriate bucket
        auto &bucket = table[hash_val];
        for (auto it = bucket.begin(); it != bucket.end(); ++it)
        {
            if ((*it)->getname() == symbol->getname())
            {
                bucket.erase(it);
                return true;
            }
        }
        return false;
    }

    
    void print_scope_table(ofstream &outlog)
    {
        outlog << "ScopeTable # " << unique_id << endl;
        for (int i = 0; i < bucket_count; i++)
        {
            if (!table[i].empty())
            {
                outlog << i << " --> " << endl; // Print bucket number with newline
                for (auto current : table[i])
                {
                    // Print symbol information
                    outlog << "< " << current->getname() << " : " << current->gettype() << " >" << endl;

                    // Handle different types of symbols
                    if (current->get_is_function())
                    {
                        // Print function details
                        outlog << "Function Definition" << endl;
                        outlog << "Return Type: " << current->get_return_type() << endl;
                        vector<pair<string, string>> params = current->get_parameters();
                        outlog << "Number of Parameters: " << params.size() << endl;
                        outlog << "Parameter Details: ";
                        for (int j = 0; j < params.size(); j++)
                        {
                            outlog << params[j].first << " " << params[j].second;
                            if (j < params.size() - 1)
                                outlog << ", ";
                        }
                        outlog << endl;
                    }
                    else if (current->get_is_array())
                    {
                        // Print array details
                        outlog << "Array" << endl;
                        outlog << "Type: " << current->get_data_type() << endl;
                        outlog << "Size: " << current->get_array_size() << endl;
                    }
                    else
                    {
                        // Print variable details
                        outlog << "Variable" << endl;
                        outlog << "Type: " << current->get_data_type() << endl;
                    }
                }
            }
        }
        outlog << endl; 
    }
};