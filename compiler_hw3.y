/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
       
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)

    /* Symbol table function - you can add new functions if needed. */
    struct symbol_table{
        int index[10];
        char* name[10];
        char* type[10];
        int addr[10];
        int lineno[10];
        char* func_sig[10];
        int scope_level[10];
    }symbol_table;
    int CompNUM = 0;
    struct symbol_table table[93] = {};
    int switchNUM = 0;
    int caseNUM = 0;
    int pre_num = 0;
    int cas[10] = {};
    int ival = 0;
    int fval = 0;
    int scopeID = 0; // for symbol_table index initial
    int insert_flag = 0;
    int addr_cnt = -1;
    char returnT;
    char* para = "";
    int IDcnt[93] = {};
    char errMe[100] = "";
    int bool_val = 0;
    /* parameters and return type can be changed */
    // static void create_symbol(/* ... */);
    // static void insert_symbol(/* ... */);
    // static void lookup_symbol(/* ... */);
    // static void dump_symbol(/* ... */);
    static void create_symbol();
    static void insert_symbol(char*,char*);
    static void lookup_symbol(char *);
    static void dump_symbol();

    // hw3

    /* for variable */
    int ForCl_Num = 0;   
    int l_for = 0;
    int prev_for = 0;
    int for_num = 0;
    int postF = 0;

    /* if variable */
    int If_cnt = 0;
    int ifBlockNumOfTime = 0;

    /* To get address to modify register*/
    int get_addr(char* str);
    
    // hw2
    void func_prnt();
    void type_record(char*);
    char* get_type(char*);
    void dele_symbol();
    char* standard_type(char*);
    void error_undefine(char*);
    /* Global variables */

    /* To handle error and not to generate hw3.j  */
    bool g_has_error = false; 
    FILE *fout = NULL; //for write j.file
    int g_indent_cnt = 0;
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    bool b_val;
    /* ... */
}

/* Token without return */
%token VAR NEWLINE
%token INT FLOAT BOOL STRING IDENT
%token INC DEC GEQ LOR LAND EQL NEQ LEQ
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token IF ELSE FOR SWITCH CASE
%token PRINT PRINTLN
%token TRUE FALSE DEFAULT RETURN FUNC PACKAGE IndexExpr 
%token <i_val> int_lit INT_LIT
%token <s_val> string_lit STRING_LIT
%token <f_val> float_lit FLOAT_LIT
%token <b_val> bool_lit BOOL_LIT
/* Token with return, which need to sepcify type */
// %token <i_val> INT_LIT
// %token <s_val> STRING_LIT

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    :  GlobalStatementList {dump_symbol();}
;

GlobalStatementList 
    :  GlobalStatementList GlobalStatement
    |  GlobalStatement 
;

GlobalStatement
    : PackageStmt NEWLINE  
    | FunctionDeclStmt 
    | NEWLINE 
    
;

PackageStmt 
    : PACKAGE IDENT  { create_symbol(); printf("package: %s\n",$<s_val>2);}    
    |
;

FunctionDeclStmt 
    : FUNC IDENT {printf("func: %s\n",$<s_val>2); returnT = 'V';} '(' ParameterList ')' Type  '{' {insert_flag = 0; create_symbol();func_prnt();insert_symbol($<s_val>2,"func");} StatementList '}' {dump_symbol();dele_symbol();}
       
;

Type 
    : INT    {$<s_val>$ = strdup("int32");returnT = 'I';  type_record("int32");}; 
    | FLOAT   {$<s_val>$ = strdup("float32");  type_record("float32");};
    | STRING  {
                $<s_val>$ = strdup("string");  
                type_record("string");
                
                };
    | BOOL     {
                $<s_val>$ = strdup("bool"); 
                 type_record("bool");
                 
                 
                 };
    |
;




Statement 
    :DeclarationStmt NEWLINE 
    | SimpleStmt NEWLINE 
    | Block            
    | IfStmt             
    | ForStmt               
    | SwitchStmt          
    | CaseStmt          
    | PrintStmt NEWLINE     
    | ReturnStmt NEWLINE 
    | FuncStmt     
    | NEWLINE               

FuncStmt
    : IDENT '(' ParaList ')'
   
;

ParaList 
    : ParaList ',' IDENT     
    | ParaList ',' FLOAT_LIT 
    | ParaList ',' INT_LIT   
    | IDENT
    |
;

CaseStmt 
    :  CASE INT_LIT {
                    printf("case %d\n",$<i_val>2);
                    cas[caseNUM] = $<i_val>2;
                    CODEGEN("L_case_%d:\n",caseNUM);
                    caseNUM ++;
                    } ':' Block  {CODEGEN("\tgoto L_switch_end_%d\n",pre_num);}
    |  DEFAULT {
        cas[caseNUM] = -1; // default
        CODEGEN("L_case_%d:\n",caseNUM);
        caseNUM ++;
    } ':' Block {
                            
                            CODEGEN("\tgoto L_switch_end_%d\n",pre_num);
                            }       
;

SwitchStmt 
    : SWITCH  Expression {
         // caseNUM = 0;
         CODEGEN("iload %d\n",get_addr($<s_val>2));
        CODEGEN("goto L_switch_begin_%d\n",pre_num);
    } Block  {
               CODEGEN("L_switch_begin_%d:\n",pre_num);
               CODEGEN("lookupswitch\n");
               
               for(int i = pre_num;i<caseNUM;i++){
                   if(cas[i]==-1){
                        CODEGEN("\tdefault: L_case_%d\n",caseNUM-1);
                   }else{
                       CODEGEN("\t%d: L_case_%d\n",cas[i],i);
                   }
                  
               }
              
               CODEGEN("L_switch_end_%d:\n",pre_num);
               
               pre_num = caseNUM ; 
               switchNUM++;               
                                }    
;
SimpleStmt 
    : AssignmentStmt        
    | ExpressionStmt       
    | IncDecStmt            
;

DeclarationStmt 
    : VAR IDENT Type   {
                        insert_symbol($<s_val>2,$<s_val>3);
                        if(!strcmp($<s_val>3,"int32")){
                            CODEGEN("ldc 0\n");
                            CODEGEN("istore %d\n",get_addr($<s_val>2));
                            }else if(!strcmp($<s_val>3,"float32")){
                                CODEGEN("ldc 0.0\n");
                            CODEGEN("fstore %d\n",get_addr($<s_val>2));
                            }else if(!strcmp($<s_val>3,"string")){
                                       CODEGEN("ldc \"\"\n");
                                        CODEGEN("astore %d\n",get_addr($<s_val>2));
                                }else{
                                    CODEGEN("ldc 0\n");
                                    CODEGEN("istore %d\n",get_addr($<s_val>2));
                                }
                        }
    | VAR IDENT Type  '=' Expression  {insert_symbol($<s_val>2,$<s_val>3); 
                                        if(!strcmp($<s_val>3,"int32")){
                                        CODEGEN("istore %d\n",get_addr($<s_val>2));
                                        }else if(!strcmp($<s_val>3,"float32")){
                                        CODEGEN("fstore %d\n",get_addr($<s_val>2));
                                        }else if(!strcmp($<s_val>3,"string")){
                                        CODEGEN("astore %d\n",get_addr($<s_val>2));
                                        }else{
                                            CODEGEN("istore %d\n",get_addr($<s_val>2));
                                        }
                                        }

AssignmentStmt 
    : Expression  assign_op  Expression { 
                                        // ERROR: ASSIGN mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                    
                                       if(strcmp($<s_val>2,"ASSIGN")==0 ){
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       $<s_val>2, e1,e2);
                                            yyerror(errMe);
                                            g_has_error = 1;
                                          
                                        }
                                       }else{
                                          
                                           switch($<s_val>2[0]){
                                               case 'A': // add assign
                                                if(!strcmp(standard_type($<s_val>3),"int32")){
                                                    CODEGEN("iadd\n");
                                                    CODEGEN("istore %d\n",get_addr($<s_val>1));
                                                }else{
                                                    CODEGEN("fadd\n");
                                                    CODEGEN("fstore %d\n",get_addr($<s_val>1));
                                                }
                                               break;
                                               case 'F': // =
                                                if(!strcmp(standard_type($<s_val>3),"int32")){
                                                    CODEGEN("istore %d\n",get_addr($<s_val>1));
                                                }else if(!strcmp(standard_type($<s_val>3),"float32")){
                                                    CODEGEN("fstore %d\n",get_addr($<s_val>1));
                                                }else if(!strcmp(standard_type($<s_val>3),"string")){
                                                    CODEGEN("astore %d\n",get_addr($<s_val>1));
                                                }else{ // bool
                                                    CODEGEN("istore %d\n",get_addr($<s_val>1));
                                                }
                                               break;
                                               case 'S': // sub assign
                                               if(!strcmp(standard_type($<s_val>3),"int32")){
                                                   CODEGEN("isub\n");
                                                    CODEGEN("istore %d\n",get_addr($<s_val>1));
                                                }else{
                                                    CODEGEN("fsub\n");
                                                    CODEGEN("fstore %d\n",get_addr($<s_val>1));
                                                }
                                               break;
                                               case 'M': // mul assign
                                               if(!strcmp(standard_type($<s_val>3),"int32")){
                                                   CODEGEN("imul\n");
                                                    CODEGEN("istore %d\n",get_addr($<s_val>1));
                                                }else{
                                                    CODEGEN("fmul\n");
                                                    CODEGEN("fstore %d\n",get_addr($<s_val>1));
                                                }
                                               break;
                                               case 'Q': // quo assign
                                               if(!strcmp(standard_type($<s_val>3),"int32")){
                                                   CODEGEN("idiv\n");
                                                    CODEGEN("istore %d\n",get_addr($<s_val>1));
                                                }else{
                                                    CODEGEN("fdiv\n");
                                                    CODEGEN("fstore %d\n",get_addr($<s_val>1));
                                                }
                                               break;
                                               case 'R':  // rem assign
                                                    CODEGEN("irem\n");
                                                    CODEGEN("istore %d\n",get_addr($<s_val>1));
                                               
                                               break;

                                           }
                                       }

                                        printf("%s\n",$<s_val>2);
                                        
                                        }
;


assign_op 
    : '='            {$<s_val>$ = strdup("FORASSIGN");}
    | ADD_ASSIGN  {$<s_val>$ = strdup("ADD");}
    | SUB_ASSIGN   {$<s_val>$ = strdup("SUB");}
    | MUL_ASSIGN  {$<s_val>$ = strdup("MUL");}
    | QUO_ASSIGN  {$<s_val>$ = strdup("QUO");}
    | REM_ASSIGN  {$<s_val>$ = strdup("REM");}
;

ExpressionStmt 
    : Expression 
;

Expression
    : Expression LOR ExpressionB   { 
         if(!strcmp($<s_val>1,"bool")||!strcmp($<s_val>3,"bool")){
           $<s_val>$ = strdup("bool"); 
        }
                                    // ERROR: LOR type error handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                        
                                         
                                        if(strcmp(e1,"bool")!=0||strcmp(e2,"bool")!=0){
                                            if(strcmp(e1,"bool")!=0){
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: (operator %s not defined on %s)",
                                                       "LOR", e1);
                                                       }
                                            else{
                                                snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: (operator %s not defined on %s)",
                                                       "LOR", e2);
                                                       }
                                            yyerror(errMe);
                                            g_has_error = 1;
                                            }else{
                                                CODEGEN("ior\n");
                                            }
        printf("LOR\n"); 
    }
    
    | ExpressionB {$<s_val>$ = strdup($<s_val>1);}
;

ExpressionB
    : ExpressionB LAND ExpressionC  { 
         if(!strcmp($<s_val>1,"bool")||!strcmp($<s_val>3,"bool")){
           $<s_val>$ = strdup("bool"); 
        }
                                        // ERROR: LAND type error handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                        
                                        if(strcmp(e1,"bool")!=0||strcmp(e2,"bool")!=0){
                                            if(strcmp(e1,"bool")!=0){
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: (operator %s not defined on %s)",
                                                       "LAND", e1);
                                                       }
                                            else{
                                                snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: (operator %s not defined on %s)",
                                                       "LAND", e2);
                                                       }
                                            yyerror(errMe);
                                            g_has_error = 1;
                                            }else{
                                                CODEGEN("iand\n");
                                            }
        printf("LAND\n"); 
    }
    | ExpressionC {$<s_val>$ = strdup($<s_val>1);}
;

ExpressionC
    : ExpressionC '<' ExpressionD   { // ERROR: LSS mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                     
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "LSS", e1,e2);
                                            printf("error:%d: %s\n",yylineno+1,errMe);
                                          
                                        }else{
                                            if(!strcmp(e1,"float32")){
                                                CODEGEN("fcmpl\n");
                                            }else{
                                                CODEGEN("isub\n");
                                            }
                                            
                                            CODEGEN("iflt comp_true_%d\n",CompNUM);
                                            CODEGEN("\ticonst_0\n");
                                            CODEGEN("\tgoto comp_end_%d\n",CompNUM);
                                            CODEGEN("comp_true_%d:\n",CompNUM);
                                            CODEGEN("\ticonst_1\n");
                                            CODEGEN("comp_end_%d:\n",CompNUM);
                                            CompNUM++;
                                        }
        
           $<s_val>$ = strdup("bool"); 
       
        printf("LSS\n"); 
    }
    | ExpressionC '>' ExpressionD   { 
        
           $<s_val>$ = strdup("bool"); 
         // ERROR: GTR mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                      
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "GTR", e1,e2);
                                            printf("error:%d: %s\n",yylineno+1,errMe);
                                          
                                        }else{
                                            if(!strcmp(e1,"float32")){
                                                CODEGEN("fcmpl\n");
                                            }else{
                                                CODEGEN("isub\n");
                                            }
                                            
                                            CODEGEN("ifgt comp_true_%d\n",CompNUM);
                                            CODEGEN("\ticonst_0\n");
                                            CODEGEN("\tgoto comp_end_%d\n",CompNUM);
                                            CODEGEN("comp_true_%d:\n",CompNUM);
                                            CODEGEN("\ticonst_1\n");
                                            CODEGEN("comp_end_%d:\n",CompNUM);
                                            CompNUM++;
                                        }
        printf("GTR\n"); 
    }
    | ExpressionC LEQ ExpressionD   { // ERROR: LEQ mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                        
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "LEQ", e1,e2);
                                            printf("error:%d: %s\n",yylineno+1,errMe);
                                          
                                        }else{
                                            if(!strcmp(e1,"float32")){
                                                CODEGEN("fcmpl\n");
                                            }else{
                                                CODEGEN("isub\n");
                                            }
                                            
                                            CODEGEN("ifle comp_true_%d\n",CompNUM);
                                            CODEGEN("\ticonst_0\n");
                                            CODEGEN("\tgoto comp_end_%d\n",CompNUM);
                                            CODEGEN("comp_true_%d:\n",CompNUM);
                                            CODEGEN("\ticonst_1\n");
                                            CODEGEN("comp_end_%d:\n",CompNUM);
                                            CompNUM++;
                                        }
        
           $<s_val>$ = strdup("bool"); 
        
        printf("LEQ\n"); 
    }
    | ExpressionC GEQ ExpressionD   { // ERROR: GEQ mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                        
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "GEQ", e1,e2);
                                            printf("error:%d: %s\n",yylineno+1,errMe);
                                          
                                        }else{
                                            if(!strcmp(e1,"float32")){
                                                CODEGEN("fcmpl\n");
                                            }else{
                                                CODEGEN("isub\n");
                                            }
                                            
                                            CODEGEN("ifge comp_true_%d\n",CompNUM);
                                            CODEGEN("\ticonst_0\n");
                                            CODEGEN("\tgoto comp_end_%d\n",CompNUM);
                                            CODEGEN("comp_true_%d:\n",CompNUM);
                                            CODEGEN("\ticonst_1\n");
                                            CODEGEN("comp_end_%d:\n",CompNUM);
                                            CompNUM++;
                                        }
        
           $<s_val>$ = strdup("bool"); 
        
        printf("GEQ\n"); 
    }
    | ExpressionC EQL ExpressionD   { // ERROR: EQL mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                      
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "EQL", e1,e2);
                                            printf("error:%d: %s\n",yylineno+1,errMe);
                                          
                                        }else{
                                            if(!strcmp(e1,"float32")){
                                                CODEGEN("fcmpl\n");
                                            }else{
                                                CODEGEN("isub\n");
                                            }
                                            
                                            CODEGEN("ifeq comp_true_%d\n",CompNUM);
                                            CODEGEN("\ticonst_0\n");
                                            CODEGEN("\tgoto comp_end_%d\n",CompNUM);
                                            CODEGEN("comp_true_%d:\n",CompNUM);
                                            CODEGEN("\ticonst_1\n");
                                            CODEGEN("comp_end_%d:\n",CompNUM);
                                            CompNUM++;
                                        }
        
           $<s_val>$ = strdup("bool"); 
        
        printf("EQL\n"); 
    }
    | ExpressionC NEQ ExpressionD   { // ERROR: NEQ mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                      
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "NEQ", e1,e2);
                                            printf("error:%d: %s\n",yylineno+1,errMe);
                                          
                                        }else{
                                            if(!strcmp(e1,"float32")){
                                                CODEGEN("fcmpl\n");
                                            }else{
                                                CODEGEN("isub\n");
                                            }
                                            
                                            CODEGEN("ifne comp_true_%d\n",CompNUM);
                                            CODEGEN("\ticonst_0\n");
                                            CODEGEN("\tgoto comp_end_%d\n",CompNUM);
                                            CODEGEN("comp_true_%d:\n",CompNUM);
                                            CODEGEN("\ticonst_1\n");
                                            CODEGEN("comp_end_%d:\n",CompNUM);
                                            CompNUM++;
                                        }
        
           $<s_val>$ = strdup("bool"); 
       
        printf("NEQ\n"); 
    }
    | ExpressionD {$<s_val>$ = strdup($<s_val>1);}
;

ExpressionD
    : ExpressionD '+' ExpressionE   {
                                // ERROR: ADD mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                      
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "ADD", e1,e2);
                                            yyerror(errMe);
                                            g_has_error = 1;
                                          
                                        }else{

                                            if(!strcmp(e1,"int32")){
                                                CODEGEN("iadd\n");
                                            }else{
                                                CODEGEN("fadd\n");
                                            }
                                        }
                                       
         if(!strcmp($<s_val>1,"bool")||!strcmp($<s_val>3,"bool")){
           $<s_val>$ = strdup("bool"); 
        }
        printf("ADD\n");    
    }
    | ExpressionD '-' ExpressionE   { 
                                    // ERROR: SUB mismatched handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                       
                                   
                                        if(strcmp(e1,e2)!=0){
                                            
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: %s (mismatched types %s and %s)",
                                                       "SUB", e1,e2);
                                            yyerror(errMe);
                                            g_has_error = 1;
                                          
                                        }else{
                                            if(!strcmp(e1,"int32")){
                                        
                                                CODEGEN("isub\n");
                                            }else{
                                          
                                                CODEGEN("fsub\n");
                                            }
                                        }
         if(!strcmp($<s_val>1,"bool")||!strcmp($<s_val>3,"bool")){
           $<s_val>$ = strdup("bool"); 
        }
        printf("SUB\n"); 
    }
    | ExpressionE {$<s_val>$ = strdup($<s_val>1);}
;

ExpressionE
    : ExpressionE '*' ExpressionF   { 
         if(!strcmp($<s_val>1,"bool")||!strcmp($<s_val>3,"bool")){
           $<s_val>$ = strdup("bool"); 
        }
         if(!strcmp(standard_type($<s_val>1),"int32")&&!strcmp(standard_type($<s_val>3),"int32")){
     
            CODEGEN("imul\n");
            }else{
          
            CODEGEN("fmul\n");
        }
        printf("MUL\n"); 
    }
    | ExpressionE '/' ExpressionF   { 
         if(!strcmp($<s_val>1,"bool")||!strcmp($<s_val>3,"bool")){
           $<s_val>$ = strdup("bool"); 
        }
        if(!strcmp(standard_type($<s_val>1),"int32")&&!strcmp(standard_type($<s_val>3),"int32")){
         
            CODEGEN("idiv\n");
            }else{
           
            CODEGEN("fdiv\n");
        }
        printf("QUO\n"); 
    }
    | ExpressionE '%' ExpressionF   { 
        if(!strcmp($<s_val>1,"bool")||!strcmp($<s_val>3,"bool")){
           $<s_val>$ = strdup("bool"); 
        }
                                        // ERROR: REM type error handlind
                                        char e1[10] = "";
                                        char e2[10] = "";
                                       
                                         strcpy(e1 , standard_type($<s_val>1));
                                         strcpy(e2 , standard_type($<s_val>3));
                                        
                                       
                                        if(strcmp(e1,"int32")!=0||strcmp(e2,"int32")!=0){
                                            if(strcmp(e1,"int32")!=0){
                                            snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: (operator %s not defined on %s)",
                                                       "REM", e1);
                                                       }
                                            else{
                                                snprintf(errMe,sizeof(errMe),
                                                        "invalid operation: (operator %s not defined on %s)",
                                                       "REM", e2);
                                                       }
                                            yyerror(errMe);
                                            g_has_error = 1;
                                            }else{
                                        
                                                CODEGEN("irem\n");
                                            }
                                            
                                          
                                        
        printf("REM\n"); 
    }
    | ExpressionF {$<s_val>$ = strdup($<s_val>1);}
;

ExpressionF
    : UnaryExpr {$<s_val>$ = strdup($<s_val>1);}
;

UnaryExpr 
    : PrimaryExpr {$<s_val>$ = strdup($<s_val>1);}
    | unary_op UnaryExpr {
                            printf("%s\n",$<s_val>1); $<s_val>$ = strdup($<s_val>2);
                            switch($<s_val>1[2]){
                                case 'G':
                                switch(standard_type($<s_val>2)[0]){
                                   case 'i':
                                   CODEGEN("ineg\n");
                                   break;
                                   case 'f': 
                                   CODEGEN("fneg\n");
                                   break;
                                }
                                break;
                                case 'T':
                                
                                CODEGEN("iconst_1\nixor\n");
                                break;
                                default:
                                break;
                            }    
                        }
;

PrimaryExpr 
    : Operand  {$<s_val>$ = strdup($<s_val>1);}
 //   | IndexExpr  
    | ConversionExpr {$<s_val>$ = strdup($<s_val>1);}
    | TRUE  {printf("TRUE 1\n");$<s_val>$ = strdup("bool");CODEGEN("iconst_1\n");bool_val = 1;}
    | FALSE {printf("FALSE 0\n");$<s_val>$ = strdup("bool");CODEGEN("iconst_0\n");bool_val = 0;}
    | 
;
Operand 
    : Literal  {$<s_val>$ = strdup($<s_val>1);}
    | IDENT     {
                    $<s_val>$ = strdup($<s_val>1); 
                    lookup_symbol($<s_val>1);
                    error_undefine($<s_val>1);

                    if(!strcmp(standard_type($<s_val>1),"float32")){
                        CODEGEN("fload %d\n",get_addr($<s_val>1));
                    }else if(!strcmp(standard_type($<s_val>1),"string")){
                        CODEGEN("aload %d\n",get_addr($<s_val>1));
                    }else{
                        CODEGEN("iload %d\n",get_addr($<s_val>1));
                    }
                }
    | '(' Expression ')' {$<s_val>$ = strdup($<s_val>2);}
    | FuncStmt 
;

Literal 
    : INT_LIT    {$<s_val>$ = strdup("int32"); printf("INT_LIT %d\n", $<i_val>1); CODEGEN("ldc %d\n",$<i_val>1);}
    | FLOAT_LIT   {$<s_val>$ = strdup("float32"); printf("FLOAT_LIT %f\n",  $<f_val>1);CODEGEN("ldc %f\n",$<f_val>1);}
    | BOOL        {$<s_val>$ = strdup("bool");}
    | STR         {$<s_val>$ = strdup("string");  } 
;

STR
    :'"' STRING_LIT '"' {printf("STRING_LIT %s\n",$<s_val>2);CODEGEN("ldc \"%s\"\n",$<s_val>2);}
   
;

IfStmt 
    : IF IfCondition IfBlock Else   {
        CODEGEN("if_end_%d:\n", If_cnt);
        If_cnt++;
    }
;

 
IfBlock
    : '{'  {
        create_symbol(); 
        CODEGEN("ifeq if_false_%d\n", ifBlockNumOfTime);    
        } 
        NEWLINE   StatementList '}' {   
                                        CODEGEN("goto if_end_%d\nif_false_%d:\n", If_cnt,ifBlockNumOfTime++);
                                        dump_symbol();
                                        dele_symbol();
                                        }
    | '{' {create_symbol(); CODEGEN("ifeq if_false_%d\n",ifBlockNumOfTime);}  '}' {CODEGEN("goto if_end_%d\nif_false_%d:\n", If_cnt,ifBlockNumOfTime++);;dump_symbol(); dele_symbol();}
;

Else
    : 
    | ELSE IfStmt
    | ELSE '{' { create_symbol();} StatementList '}' {dump_symbol();dele_symbol();}
;

IfCondition
    : Expression {
         if(strcmp("bool",standard_type($<s_val>1))!=0){
            snprintf(errMe,sizeof(errMe),"non-bool (type %s) used as for condition",standard_type($<s_val>1));
        printf("error:%d: %s\n", yylineno+1, errMe);
        g_has_error = 1;
        }
    }
;

ForStmt
    :{ l_for++; } TwoForStmt NEWLINE { l_for--; }
;

TwoForStmt 
    : FOR { for_num++; switch(l_for){
                         case 1:
                            prev_for = for_num;
                        break;
                        default:
                        break;
            } CODEGEN("L%d_for_begin:\n", for_num); } 
    ForBody  { 
        switch(ForCl_Num){
            case 0:
                switch(l_for){
                    case 1:
                        if(postF){
                            CODEGEN("\tgoto L%d_ForPost\n", prev_for);
                        }else{
                        CODEGEN("\tgoto L%d_for_begin\n", prev_for); 
                        }
                    break;
                    default:
                        if(postF){
                            CODEGEN("\tgoto L%d_ForPost\n", for_num);
                        }else{
                        CODEGEN("\tgoto L%d_for_begin\n", for_num); 
                        }
                    break;
                }
            break;
            default:
                switch(l_for){
                    case 1:
                        CODEGEN("\tgoto L%d_ForPost\n", prev_for); 
                    break;
                    default:
                        CODEGEN("\tgoto L%d_ForPost\n", for_num);
                    break;
                }
                
            break;
        }
      
        // for multi level
        switch(l_for){
            case 1:
                CODEGEN("L%d_ForExit:\n", prev_for); 
            break;
            default:
                CODEGEN("L%d_ForExit:\n", for_num);
            break;
        }
        ForCl_Num--;
    }
;

ForBody
    : Condition { CODEGEN("\tifeq L%d_ForExit \n", for_num); } ForBlock 
    | ForClause { CODEGEN("L%d_FBlock:\n", for_num); } ForBlock
;

ForBlock
    : '{' { create_symbol();} StatementList '}' {dump_symbol();dele_symbol();}
;

ForClause 
    : InitStmt { ForCl_Num++; CODEGEN("L%d_ForCondition:\n", for_num);} ';' 
    Condition { CODEGEN("\tifeq L%d_ForExit \n\tgoto L%d_FBlock \n", for_num,for_num);  } ';' 
    { CODEGEN("L%d_ForPost:\n", for_num);postF=1; } PostStmt { CODEGEN("\tgoto L%d_ForCondition \n", for_num); } 
;


InitStmt 
    : SimpleStmt {  $<s_val>$ = strdup($<s_val>1);
                    }
;

PostStmt 
    : SimpleStmt  {  $<s_val>$ = strdup($<s_val>1);
                    }
;

Condition 
    : Expression  {  $<s_val>$ = strdup($<s_val>1);
                    }
;


ConversionExpr 
    : Type '(' Expression ')'  {
                                if((!strcmp($<s_val>3,"int32"))||(!strcmp($<s_val>3,"float32"))){
                                    printf("%c2%c\n",$<s_val>3[0],$<s_val>1[0]);
                                   
                                    CODEGEN("%c2%c\n",$<s_val>3[0],$<s_val>1[0]);
                                }else{
                                    printf("%c2%c\n",get_type($<s_val>3)[0],$<s_val>1[0]);
                                    CODEGEN("%c2%c\n",get_type($<s_val>3)[0],$<s_val>1[0]);
                                }
                                $<s_val>$ = strdup($<s_val>1);
                                }
;

IncDecStmt 
    : Expression  INC  {
                        printf("INC\n");
                        if(!strcmp(standard_type($<s_val>1),"int32"))
                            {
                          //  CODEGEN("iload %d\n",get_addr($<s_val>1));
                            CODEGEN("ldc 1\n");CODEGEN("iadd\n");
                            CODEGEN("istore %d\n",get_addr($<s_val>1));
                            ival = 1;
                            }
                            else{
                                CODEGEN("fload %d\n",get_addr($<s_val>1));
                                CODEGEN("ldc 1.0\n");
                                CODEGEN("fadd\nfstore %d\n",get_addr($<s_val>1));
                                fval = 1;
                                }
                                } 
    | Expression  DEC  {
                        printf("DEC\n");
                        if(!strcmp(standard_type($<s_val>1),"int32"))
                        {
                          //  CODEGEN("iload %d\n",get_addr($<s_val>1));
                            CODEGEN("ldc 1\n");
                            CODEGEN("isub\n");
                            CODEGEN("istore %d\n",get_addr($<s_val>1));
                            ival = 1;
                        }else{
                            CODEGEN("fload %d\n",get_addr($<s_val>1));
                            CODEGEN("ldc 1.0\n");
                            CODEGEN("fsub\nfstore %d\n",get_addr($<s_val>1));
                            fval =1;
                        
                            }
                            }
;
binary_op 
    : LOR    {$<s_val>$ = strdup("LOR");}
    | LAND  {$<s_val>$ = strdup("LAND");}
    | cmp_op  {$<s_val>$ = strdup($<s_val>1);}
    | add_op   {$<s_val>$ = strdup($<s_val>1);}
    | mul_op  {$<s_val>$ = strdup($<s_val>1);}
;

cmp_op 
    : EQL {$<s_val>$ = strdup("EQL");}
    | NEQ {$<s_val>$ = strdup("NEQ");}
    | '<' {$<s_val>$ = strdup("LSS");}
    | LEQ {$<s_val>$ = strdup("LEQ");}
    | '>' {$<s_val>$ = strdup("GTR");}
    | GEQ {$<s_val>$ = strdup("GEQ");}
;

add_op 
    : '+'   {$<s_val>$ = strdup("ADD");}
    | '-'   {$<s_val>$ = strdup("SUB");}
;

mul_op 
    : '*'  {$<s_val>$ = strdup("MUL");}
    | '/'  {$<s_val>$ = strdup("QUO");}
    | '%'  {$<s_val>$ = strdup("REM");}
;
unary_op 
    : '+'  {$<s_val>$ = strdup("POS");}
    | '-'  {$<s_val>$ = strdup("NEG");}
    | '!'  {$<s_val>$ = strdup("NOT");}
;

PrintStmt 
    :  PRINT '(' Expression ')'   { 
                                        if((!strcmp($<s_val>3,"int32"))||(!strcmp($<s_val>3,"float32"))||(!strcmp($<s_val>3,"string"))||(!strcmp($<s_val>3,"bool"))){
                                            printf("PRINT %s\n",$<s_val>3);
                                        }
                                        else{
                                            printf("PRINT %s\n",strdup(get_type($<s_val>3)));
                                        }
                                        if(ival){
                                            CODEGEN("iload %d\n",get_addr($<s_val>3));
                                            ival = 0;
                                        }
                                        if(fval){
                                            CODEGEN("fload %d\n",get_addr($<s_val>3));
                                            fval = 0;
                                        }
                                        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                        CODEGEN("swap\n");
                                        if(!strcmp("int32",standard_type($<s_val>3))){
                                            CODEGEN("invokevirtual java/io/PrintStream/print(I)V\n");
                                        }else if(!strcmp(standard_type($<s_val>3),"float32")){
                                             CODEGEN("invokevirtual java/io/PrintStream/print(F)V\n");
                                        }else if(!strcmp("bool",standard_type($<s_val>3))){
                                           CODEGEN("invokevirtual java/io/PrintStream/print(Z)V\n");
                                        }
                                        else{
                                            CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
                                        }
                                    }
    | PRINTLN  '(' Expression ')'  {    
                                        if((!strcmp($<s_val>3,"int32"))||(!strcmp($<s_val>3,"float32"))||(!strcmp($<s_val>3,"string"))||(!strcmp($<s_val>3,"bool"))){
                                            printf("PRINTLN %s\n",$<s_val>3);
                                             
                                        }
                                        else{
                                            printf("PRINTLN %s\n",strdup(get_type($<s_val>3)));
                                           
                                        }
                                        
                                        if(ival){
                                        //    CODEGEN("iload %d\n",get_addr($<s_val>3));
                                            ival = 0;
                                        }
                                        if(fval){
                                            CODEGEN("fload %d\n",get_addr($<s_val>3));
                                            fval = 0;
                                        }
                                        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                        CODEGEN("swap\n");
                                        if(!strcmp("int32",standard_type($<s_val>3))){
                                            CODEGEN("invokevirtual java/io/PrintStream/println(I)V\n");
                                        }else if(!strcmp(standard_type($<s_val>3),"float32")){
                                             CODEGEN("invokevirtual java/io/PrintStream/println(F)V\n");
                                        }else if(!strcmp("bool",standard_type($<s_val>3))){
                                           CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n");
                                        }
                                        else{
                                            CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
                                        }
                                    }
;



Block 
    : '{' { create_symbol();} StatementList '}' {dump_symbol();dele_symbol();}
;


StatementList 
    :  Statement 
    |  StatementList Statement 
    |
;

ParameterList 
    : ParameterList ',' IDENT Type 
    | IDENT Type  
    |
;



ReturnStmt 
    : RETURN {printf("return\n");}
    | RETURN Expression {printf("return\n");}
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source hw3.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");
    CODEGEN(".method public static main([Ljava/lang/String;)V\n");
    CODEGEN(".limit stack 100\n");
    CODEGEN(".limit locals 100\n\n");

    /* Symbol table init */
    // Add your code

    yylineno = 0;
    for(int i = 0;i<93;i++){
        for(int j = 0;j<10;j++){
            table[i].index[j] = -1;
            table[i].name[j] = "";
            table[i].type[j] = "";
            table[i].addr[j] = -2;
            table[i].lineno[j] = 0;
            table[i].func_sig[j] = "";
            table[i].scope_level[j] = 0;
        }
    }
    yyparse();

    /* Symbol table dump */
    // Add your code

	printf("Total lines: %d\n", yylineno);
    CODEGEN("\treturn\n");
    CODEGEN(".end method\n");
    fclose(fout);
    fclose(yyin);

    if (g_has_error) {
       remove(bytecode_filename);
    }
    yylex_destroy();
    return 0;
}
static void create_symbol() {
     
     printf("> Create symbol table (scope level %d)\n",scopeID);
     scopeID++;  //note
     
}

static void insert_symbol(char* str,char* type) {
        char errMe[100] = "";
        int error_f = 0;
        int id = 0;
        if(!insert_flag){id = scopeID -2;}
        else {id = scopeID -1;}    

         for(int i = 0;i<10;i++){
             if(strcmp(str,table[scopeID-1].name[i])==0)
                 {
                     error_f = 1;
                     snprintf(errMe,sizeof(errMe),
                            "%s redeclared in this block. previous declaration at line %d",
                            str,table[scopeID-1].lineno[i]);
                     yyerror(errMe);
                     g_has_error = 1;
                 }
         }

       
            table[id].name[IDcnt[id]] = strdup(str);
            table[id].index[IDcnt[id]] = IDcnt[id];
            table[id].type[IDcnt[id]] = strdup(type);
            table[id].addr[IDcnt[id]] = addr_cnt;
            if(!strcmp(str,"main")){
            table[id].lineno[IDcnt[id]] = yylineno+1;
            table[id].func_sig[IDcnt[id]] = strdup("()V");
            }else{
                table[id].lineno[IDcnt[id]] = yylineno;
                table[id].func_sig[IDcnt[id]] = strdup("-");
            }
        

        printf("> Insert `%s` (addr: %d) to scope level %d\n", str, addr_cnt ,id);
       

         
   
    
   
        IDcnt[id]++;addr_cnt++;
        if(!insert_flag){insert_flag = 1;}
        
}

static void lookup_symbol(char* str) {
  
    int is_p = 0;
    for(int id = scopeID+2;id>-1;id--){
        if(is_p){break;}
        for(int i = 0;i<10;i++){
            if(strcmp(str,table[id].name[i])==0)
                {
                    printf("IDENT (name=%s, address=%d)\n", str,table[id].addr[i]);
                    is_p = 1;
                    break;

                }
        }
    }
    
}
void dele_symbol(){
     
    for(int j = 0;j<10;j++){
            table[scopeID-1].index[j] = -1;
            table[scopeID-1].name[j] = "";
            table[scopeID-1].type[j] = "";
            table[scopeID-1].addr[j] = -2;
            table[scopeID-1].lineno[j] = 0;
            table[scopeID-1].func_sig[j] = "";
            table[scopeID-1].scope_level[j] = 0;
        }
    IDcnt[scopeID-1] = 0;
    scopeID -= 1 ;
}

static void dump_symbol() {
    int id = 0;
    if (!scopeID){
        id = 0;
    }else{
        id = scopeID -1;
    }
                printf("\n> Dump symbol table (scope level: %d)\n", id);
                printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
                    "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");

                for(int j = 0;j<10;j++){
                    if(table[id].index[j]!=-1){
                    printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",
                        j, table[id].name[j], table[id].type[j], table[id].addr[j],table[id].lineno[j], table[id].func_sig[j]);
                    }
                }

                printf("\n");
}


void func_prnt(){
    printf("func_signature: (%s)%c\n",para,returnT);
  
    table[scopeID-2].func_sig[(addr_cnt+1)] = strdup("()V");
}

void type_record(char* str){
        if(scopeID-1>0)
        {
         table[scopeID-1].type[addr_cnt] = strdup(str);
         table[scopeID-1].func_sig[addr_cnt] = strdup("-");
        }
}
char* standard_type(char* str){
    char ret[10] = "";
    if(!strcmp("float32",str)||!strcmp("int32",str)||!strcmp("bool",str)||!strcmp("string",str)){
        strcpy(ret , str);
    }else{
        strcpy(ret , get_type(str));
    }
 
    return strdup(ret);
}
 

char* get_type(char* str){
   for(int i = scopeID+2;i>-1;i--){
        for(int j = 0;j<10;j++){
            if(!strcmp(str,table[i].name[j])){
                return table[i].type[j];
            }
        }
    }
    return "ERROR";
}

void error_undefine(char* str){
    int isdefine = 0;
    if(!strcmp("float32",str)||!strcmp("int32",str)||!strcmp("string",str)||!strcmp("bool",str)) {isdefine = 1;}
    
    for(int i = 0;i<scopeID;i++){
        for(int j = 0;j<10;j++){
            if(!strcmp(table[i].name[j],str)){
                isdefine = 1;
            }
        }
    }
    if(!isdefine){
        g_has_error = 1;
        printf("error:%d: undefined: %s\n",yylineno+1,str);
    }
}

int get_addr(char* str){
    for(int i = scopeID+2;i>-1;i--){
        for(int j = 0;j<10;j++){
            if(!strcmp(str,table[i].name[j])){
                return table[i].addr[j];
            }
        }
    }
    return 0;
} 



