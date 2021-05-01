#include<bits/stdc++.h>
using namespace std;
typedef long long ll;

class SymbolInfo
{
    string Name;
    string Type;
public:
    SymbolInfo* next;

    void setName(string Name)
    {
        this->Name = Name;
    }

    string getName()
    {
        return Name;
    }

    void setType(string Type)
    {
        this->Type = Type;
    }

    string getType()
    {
        return Type;
    }
};

class SymbolInfo *newSymbolInfo(string name, string type)
{
    class SymbolInfo *temp = new SymbolInfo;

    temp -> setName(name);
    temp -> setType(type);
    temp ->next = NULL;

    return temp;

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
    int HashFunc(string);
    bool Insert(string, string);
    SymbolInfo* Lookup(string);
    bool Delete(string);
    void printCurrrentScopeTable();




};

int ScopeTable::HashFunc(string s)
{
    ll sum = 0;
    for (int i = 0; s[i] != '\0'; i++)
        sum = sum + s[i];

    sum %= total_buckets;
    return sum;

}

bool ScopeTable::Insert(string name, string type)
{

    int index = HashFunc(name);
    SymbolInfo *listitem = t_buckets[index];
    while(listitem != NULL)
    {
        if(listitem->getName() == name)
        {
            cout << "<" << name << "," << type <<">" << " already exists in current ScopeTable" << endl;
            return false;
        }
        listitem = listitem->next;
    }

    SymbolInfo* head = t_buckets[index];
    if(head == NULL)
    {
        head = newSymbolInfo(name, type);
        t_buckets[index] = head;
        cout << "Inserted in ScopeTable# " << id <<" at position " << index << ", " << "0" << endl;

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

        SymbolInfo* newitem = newSymbolInfo(name, type);
        temp->next = newitem;
        cout << "Inserted in ScopeTable# " << id <<" at position " << index << ", " << count << endl;


    }
    return true;
}

SymbolInfo* ScopeTable::Lookup(string name)
{
    int index = HashFunc(name);
    SymbolInfo *listitem = t_buckets[index];
    int count = 0;
    while(listitem != NULL)
    {
        if(listitem->getName() == name)
        {
            cout << "Found in ScopeTable# " << id << " at position " << index << ", " << count << endl;
            return listitem;
        }
        count++;
        listitem = listitem->next;
    }

    return NULL;

}

bool ScopeTable::Delete(string name)
{
    int index = HashFunc(name);
    SymbolInfo* head = t_buckets[index];
    int count = 0;
    if(head != NULL && head->getName() == name)
    {
        t_buckets[index] = head->next;
        delete head;
        cout << "Deleted Entry " << index << ", " << count << " from current ScopeTable" << endl;
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
                cout << "Deleted Entry " << index << ", " << count + 1 << " from current ScopeTable" << endl;
                return true;

            }
            count++;
            temp = temp->next;
        }
        cout << "Not Found" << endl;
        cout << name << " not found" << endl;
        return false;
    }
}


void ScopeTable::printCurrrentScopeTable()
{
    cout << "ScopeTable # " << id << endl;
    for (int i=0; i<total_buckets; i++)
    {

        cout << i << " --> ";

        SymbolInfo* head = t_buckets[i];
        while (head)
        {
            cout << " < " << head->getName() <<" : " << head->getType() << ">";
            head = head->next;
        }

       cout << endl;

    }
    cout << endl;
}


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

    void EnterScope();
    void ExitScope();
    bool Insert(string, string);
    bool Remove(string);
    SymbolInfo* Lookup(string);
    void printcurrentScopeTable();
    void printallScopeTable();
};


void SymbolTable::EnterScope()
{
    ScopeTable* temp = new ScopeTable(total_buckets);
    temp->parentscope = current;
    temp->id = current->id + "." + to_string(current->count + 1);
    current->count++;

    current = temp;
    scopetableList.push_back(temp);
    cout << "New ScopeTable with id " << current->id <<" created" << endl;
}

void SymbolTable::ExitScope()
{
    cout << "ScopeTable with id " << current->id <<" removed" << endl;
    ScopeTable* temp = current->parentscope;
    scopetableList.pop_back();
    delete current;
    current = temp;

}

bool SymbolTable::Insert(string name, string type)
{
    if(current->Insert(name, type))
        return true;
    else
        return false;
}

bool SymbolTable::Remove(string name)
{
    current->Lookup(name);
    if(current->Delete(name))
        return true;
    else
        return false;
}


SymbolInfo* SymbolTable::Lookup(string name)
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
    cout << "Not found" << endl;
    return NULL;
}


void SymbolTable::printcurrentScopeTable()
{
    current->printCurrrentScopeTable();

}

void SymbolTable::printallScopeTable()
{
    ScopeTable* temp = current;
    SymbolInfo* tempinfo;
    while(temp != NULL)
    {
        temp->printCurrrentScopeTable();
        temp = temp->parentscope;
        cout << endl << endl;
    }

}





int main()
{

    ifstream myfileinput;
    fstream myfileoutput;
    myfileinput.open("input.txt", ios::in);
    myfileoutput.open("myfileoutput.txt", ios::out);
    if(!myfileinput)
    {
        cout << "NO INPUT FILE" << endl;
        return 0;
    }
    cout << "1. File print." << "\n";
    cout << "2. Console print." << "\n";
    int c;
    cin >> c;
    if(c == 1)
        freopen("myfileoutput.txt", "w", stdout);

    int total_buckets;
    string x;
    myfileinput >> total_buckets;
    string name, type;

    SymbolTable st(total_buckets);
    while(myfileinput >> x)
    {
        cout << x << " ";

        if(x == "S")
        {
            cout << endl << endl;
            st.EnterScope();
        }
        else if(x == "E")
        {
            cout << endl << endl;
            st.ExitScope();

        }
        else if(x == "I")
        {
            myfileinput >> name;
            myfileinput >> type;

            cout << name << " " << type << endl << endl;
            st.Insert(name, type);

        }

        else if(x == "D")
        {
            myfileinput >> name;

            cout << name << endl << endl;
            st.Remove(name);
        }

        else if(x == "L")
        {
            myfileinput >> name;
            cout << name << endl << endl;
            st.Lookup(name);
        }
        else if(x == "P")
        {
            myfileinput >> name;
            cout << name << endl << endl;
            if(name == "C")
                st.printcurrentScopeTable();
            if(name == "A")
                st.printallScopeTable();
        }

        cout << endl;

    }

}
