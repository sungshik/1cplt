module icplt::core::\data::\syntax::Concrete
extend icplt::core::\util::\syntax::Concrete;

start syntax Data = DataExpression ;

syntax DataType
    = Role
    | @category="keyword" "null"
    | @category="keyword" "boolean"
    | @category="keyword" "number"
    | @category="keyword" "string"
    | DataType [\[] [\]]
    | [{] {DataTypeEntry [;]}* Semi? [}]
    ;

syntax DataTypeEntry
    = DataVariable [:] DataType ;

lexical Role = @category="type" Upper Alnum* ;

syntax DataExpression
    = "self"
    | DataVariable
    | DataValue
    | [\[] {DataExpression!comma ","}* Comma? [\]]
    | [{] {DataExpressionEntry ","}* Comma? [}]
    | DataExpression!comma "as" DataType
    | [(] DataExpression [)]
    > left DataExpression!comma [.] DataVariable
    | left DataExpression!comma [.] Concat [(] DataExpression!comma [)]
    | left DataExpression!comma [.] Slice [(] DataExpression!comma [)]
    | left DataExpression!comma [.] Slice [(] DataExpression!comma [,] DataExpression!comma [)]
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

lexical Concat             = @category="operator" "concat" ;
lexical Slice              = @category="operator" "slice" ;
lexical Prefix             = @category="operator" [! + \-] ;
lexical Exponentiation     = @category="operator" "**" ;
lexical Multiplication     = @category="operator" [* / %] ;
lexical Addition           = @category="operator" [+ \-] ;
lexical LessThan           = @category="operator" ("\<" | "\<=" | "\>" | "\>=") ;
lexical Equality           = @category="operator" ("==" | "!=") ;
lexical LogicalConjunction = @category="operator" "&&" ;
lexical LogicalDisjunction = @category="operator" ("||" | "??") ;

lexical DataVariable
    = @category="variable" (Lower Alnum*) !>> [0-9 A-Z a-z] \ DataKeyword ;

syntax DataValue
    = Pid
    | Null
    | Boolean
    | Number
    | String
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
    = @category="string" [\"]( {(Print | "\\\"") !>> [\"] ()}* (Print | "\\\""))? [\"] ;

keyword DataKeyword
    = "null"
    | "boolean"
    | "number"
    | "string"
    | "true"
    | "false"
    | "self"
    ;

/* -------------------------------------------------------------------------- */
/*                                 `foreach`                                  */
/* -------------------------------------------------------------------------- */

syntax DataExpression
    = ArrayFunction1 "(" DataExpression!comma ")"
    | ArrayFunction2 "(" DataExpression!comma "," DataExpression!comma ")"
    ;

lexical ArrayFunction1 = @category="operator" "isNil" ;
lexical ArrayFunction2 = @category="operator" ("cons" | "headOrDefault" | "tailOrDefault") ;
