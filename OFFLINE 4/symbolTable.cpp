#include<bits/stdc++.h>

using namespace std;

typedef long long ll;



struct funcstruct
{
	string parameter_name;
	string variable_type;
};

class SymbolInfo

{

    string Name;

    string Type;
    
    string Variable_type;
    
    string code;
    
    int arraysize = -1;
    
    vector <funcstruct> func;
   
    bool isfunc = false;
    
    bool funcdefined = false;
    
    string reg;
    string lebel;
    

public:

    SymbolInfo* next = NULL;
    SymbolInfo(string Name, string Type, string Variable_type)
    {
    	this->Name = Name;
    	this->Type = Type;
    	this->Variable_type = Variable_type;
    	
    }
    
    void setName(string Name)
    {
    	this->Name = Name;
    }
    
    void setType(string Type)
    {
    	this->Type = Type;
    }
    
    void setVariable(string Variable)
    {
    	this->Variable_type = Variable;
    }
    
    void setarraySize(int size)
    {
    	this->arraysize = size;
    }
    
    void setfuncParameters(string parameter_name, string variable_type)
    {
    	func.push_back({parameter_name, variable_type});
    }
    
    void setFunc(bool isfunc)
    {
    	this->isfunc = isfunc;
    }
    
    void setfuncDefined(bool defined)
    {
    	this->funcdefined = defined;
    }
    
    void setCode(string code)
    {
    	this->code = code;
    }
	
    void setReg(string reg)
    {
    
    	this->reg = reg;
    }
    
     void setLebel(string lebel)
    {
    
    	this->lebel = lebel;
    }
    string getLebel()

    {

        return this->lebel;

    }
    string getName()

    {

        return this->Name;

    }
    
    string getReg()
    {
    	return reg;
    
    }


    string getType()

    {

        return Type;

    }
    
    string getCode()
    {
    	return code;
    }
    
    int getarraySize()
    {
    	return arraysize;
    }
    
    string getVariable()
    {
    	return Variable_type;
    }
    
    string getfuncparameterName(int index)
    {
    	return func[index].parameter_name;
    
    }
    string getfuncparameterVariable(int index)
    {
    	return func[index].variable_type;
    
    }
    
    int getparameterlistSize()
    {
    	return func.size();
    }
    
    bool isFunc()
    {
    	return isfunc;
    }
    
    bool isfuncDefined()
    {
    	return funcdefined;
    }
};









class ScopeTable

{

    SymbolInfo** t_buckets;

public:



    string id;

    int count;

    int total_buckets;

    ScopeTable* parentscope;

    ScopeTable(int total_buckets)

    {

        this->total_buckets = total_buckets;

        t_buckets = new SymbolInfo*[total_buckets];

        for(int i = 0; i < total_buckets; i++)

        {

            t_buckets[i] = NULL;

        }

        count = 0;

    }

    //Destructor

    ~ScopeTable()

    {

        for(int i = 0; i < total_buckets; i++)

        {

            SymbolInfo* head = t_buckets[i];



            if(head != NULL)

            {

                SymbolInfo* temp = head->next;

                delete head;

                head = temp;



            }

        }

        delete [] t_buckets;

    }



    void createScopetable(int);

    int HashFunc(string s)
    {
        ll sum = 0;

        for (int i = 0; s[i] != '\0'; i++)

            sum = sum + s[i];



        sum %= total_buckets;

        return sum;
    }

    bool Insert(string name, string type, string variable)
    {
        int index = HashFunc(name);


        SymbolInfo *listitem = t_buckets[index];

        while(listitem != NULL)

        {

            if(listitem->getName() == name)

            {

                //cout << name << " already exists in current ScopeTable" << endl;

                return false;

            }

            listitem = listitem->next;

        }



        SymbolInfo* head = t_buckets[index];

        if(head == NULL)

        {
	    SymbolInfo* newitem = new SymbolInfo(name, type, variable);
           
            t_buckets[index] = newitem;

            //cout << "Inserted in ScopeTable# " << id <<" at position " << index << ", " << "0" << endl;



        }

        else

        {

            int count = 1;

            SymbolInfo* temp = head;

            while(temp->next != NULL)

            {

                temp = temp->next;

                count++;

            }



            SymbolInfo* newitem = new SymbolInfo(name, type, variable);

            temp->next = newitem;

            //cout << "Inserted in ScopeTable# " << id <<" at position " << index << ", " << count << endl;

	



        }

        return true;
    }

    SymbolInfo* Lookup(string name)
    {
        int index = HashFunc(name);

        SymbolInfo *listitem = t_buckets[index];

        int count = 0;

        while(listitem != NULL)

        {

            if(listitem->getName() == name)

            {

                //cout << "Found in ScopeTable# " << id << " at position " << index << ", " << count << endl;

                return listitem;

            }

            count++;

            listitem = listitem->next;

        }



        return NULL;
    }

    bool Delete(string name)
    {
        int index = HashFunc(name);

        SymbolInfo* head = t_buckets[index];

        int count = 0;

        if(head != NULL && head->getName() == name)

        {

            t_buckets[index] = head->next;

            delete head;

            //cout << "Deleted Entry " << index << ", " << count << " from current ScopeTable" << endl;

            return true;

        }

        else

        {

            SymbolInfo* temp = head;

            while(temp != NULL && temp->next != NULL)

            {

                if(temp->next->getName() == name)

                {

                    SymbolInfo* tempnext = temp->next->next;

                    delete temp->next;

                    temp->next = tempnext;

                   // cout << "Deleted Entry " << index << ", " << count + 1 << " from current ScopeTable" << endl;

                    return true;



                }

                count++;

                temp = temp->next;

            }

            //cout << "Not Found" << endl;

           // cout << name << " not found" << endl;

            return false;

        }
    }

    void printCurrrentScopeTable()
    {
        cout << "ScopeTable # " << id << endl;

        for (int i=0; i<total_buckets; i++)

        {



            SymbolInfo* head = t_buckets[i];
            

            if(head)

                cout << " " << i << " --> ";

            while (head)

            {
		
                cout << "< " << head->getName() << " , " << head->getType() << " > ";

                head = head->next;


            }

	    if(t_buckets[i])

		cout << endl;



        }

        cout << endl;
    }









};







class SymbolTable

{

    vector<ScopeTable*> scopetableList;

    int total_buckets;



public:

    ScopeTable* current;

    SymbolTable(int n)

    {

        total_buckets = n;

        ScopeTable *temp = new ScopeTable(total_buckets);

        temp->parentscope = NULL;

        temp->id = "1";

        temp->count = 0;

        current = temp;

        scopetableList.push_back(current);

    }



    ~SymbolTable()

    {

        while(current)

        {

            ScopeTable* temp = current->parentscope;

            delete current;

            current = temp;

        }



    }



    void EnterScope()
    {
    	ScopeTable* temp = new ScopeTable(total_buckets);

        temp->parentscope = current;

        temp->id = current->id + to_string(current->count + 1);

        current->count++;



        current = temp;

        scopetableList.push_back(temp);

        //cout << "New ScopeTable with id " << current->id <<" created" << endl;
    }
    
    string getcurrentId(){
    
     	return current->id;
    }

    void ExitScope()
    {
    	//cout << "ScopeTable with id " << current->id <<" removed" << endl;

        ScopeTable* temp = current->parentscope;

        scopetableList.pop_back();

        delete current;

        current = temp;
     }

    bool Insert(string name, string type, string variable)
    { 
        if(current->Insert(name, type, variable))

            return true;

       	 else

            return false;
    }

    bool Remove(string name)
    {
        current->Lookup(name);

        if(current->Delete(name))

            return true;

        else

            return false;
    }

    SymbolInfo* Lookup(string name)
    {
        ScopeTable* temp = current;

        SymbolInfo* tempinfo;

        while(temp != NULL)

        {

            tempinfo = temp->Lookup(name);

            if(tempinfo)

                return tempinfo;

            temp = temp->parentscope;

        }

        //cout << "Not found" << endl;

        return NULL;
    }

    void printcurrentScopeTable()
    {
        current->printCurrrentScopeTable();
    }

    void printallScopeTable()
    {
        ScopeTable* temp = current;

        SymbolInfo* tempinfo;

        while(temp != NULL)

        {

            temp->printCurrrentScopeTable();

            temp = temp->parentscope;



        }
    }


};










