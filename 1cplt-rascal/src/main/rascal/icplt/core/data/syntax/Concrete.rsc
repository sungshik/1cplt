module icplt::core::\data::\syntax::Concrete
extend icplt::core::\util::\syntax::Concrete;

start syntax Data = DataExpression ;

syntax DataType
    = Role
    | @category="keyword" "null"
    | @category="keyword" "boolean"
    | @category="keyword" "number"
    | @category="keyword" "string"
    | left DataType!union [\[] [\]]
    | [{] {DataTypeEntry [;]}* Semi? [}]
    | [(] DataType [)]
    > left union: DataType!union [|] {DataType!union [|]}+
    ;

syntax DataTypeEntry
    = DataVariable [:] DataType ;

lexical Role = @category="type" [@] (Alpha (Alnum | [_])*) !>> [0-9 A-Z a-z _] ;

syntax DataExpression
    = "self"
    | DataVariable
    | DataValue
    | [\[] {DataExpression!comma ","}* Comma? [\]]
    | [{] {DataExpressionEntry ","}* Comma? [}]
    | DataExpression!comma "as" DataType
    | [(] DataExpression [)]
    > left DataExpression!comma [.] DataVariable
    | left DataExpression!comma [.] Nullary
    | left DataExpression!comma [.] Unary [(] DataExpression!comma [)]
    | left DataExpression!comma [.] Binary [(] DataExpression!comma [,] DataExpression!comma [)]
    | () !>> [@] DataExpression!comma [\[] DataExpression!comma [\]]
    > Prefix DataExpression!comma
    > right DataExpression!comma Exponentiation DataExpression!comma
    > left DataExpression!comma Multiplication DataExpression!comma
    > left DataExpression!comma Addition DataExpression!comma
    > left DataExpression!comma LessThan DataExpression!comma
    > left DataExpression!comma Equality DataExpression!comma
    > left DataExpression!comma LogicalConjunction DataExpression!comma
    > left DataExpression!comma LogicalDisjunction DataExpression!comma
    > right DataExpression!comma [?] DataExpression!comma [:] DataExpression!comma
    > left comma: DataExpression!comma "," {DataExpression!comma ","}+
    ;

syntax DataExpressionEntry
    = DataVariable [:] DataExpression!comma
    | "..." DataExpression!comma
    ;

lexical Nullary            = @category="operator" ("role" | "rank" | "length");
lexical Unary              = @category="operator" ("concat" | "slice") ;
lexical Binary             = @category="operator" "slice" ;
lexical Prefix             = @category="operator" [! + \-] ;
lexical Exponentiation     = @category="operator" "**" ;
lexical Multiplication     = @category="operator" [* / %] ;
lexical Addition           = @category="operator" [+ \-] ;
lexical LessThan           = @category="operator" ("\<" | "\<=" | "\>" | "\>=") ;
lexical Equality           = @category="operator" ("==" | "!=") ;
lexical LogicalConjunction = @category="operator" "&&" ;
lexical LogicalDisjunction = @category="operator" ("||" | "??") ;

lexical DataVariable
    = @category="variable" (Alpha (Alnum | [_])*) !>> [0-9 A-Z a-z _] \ DataKeyword ;

syntax DataValue
    = Undefined
    | Pid
    | Null
    | Boolean
    | Number
    | String
    ;

lexical Undefined
    = "undefined"
    ;

lexical Pid
    = Role
    | Role [\[] Number [\]]
    ;

lexical Null
    = "null"
    ;

lexical Boolean
    = "true"
    | "false"
    ;

lexical Number
    = @category="number" Digit+ !>> [0-9] ;

lexical String
    = @category="string" [\"] ({Print !>> [\"] ()}* Print)? [\"] ;

keyword DataKeyword
    = "undefined"
    | "null"
    | "boolean"
    | "number"
    | "string"
    | "true"
    | "false"
    | "self"
    | "role"
    | "rank"
    | "length"
    ;
