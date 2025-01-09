module icplt::core::\chor::\syntax::Concrete
extend icplt::core::\data::\syntax::Concrete;
extend icplt::core::\util::\syntax::Concrete;

start syntax Chor = ChorExpression ;

syntax ChorType
    = "chor" [\[] Role [\]]
    ;

syntax ChorExpression
    = ChorVariable
    | DataVariable ":=" DataExpression
    | DataExpression "-\>" DataExpression "." DataVariable
    | "{" ChorExpression "}"
    > DataExpression "-\>" DataExpression "." DataVariable "|\>" ChorExpression
    | "if" DataExpression "then" ChorExpression
    | "if" DataExpression "then" ChorExpression "else" ChorExpression
    | "case" DataExpression "of" Branch+
    | "while" DataExpression "do" ChorExpression
    > DataExpression "." ChorExpression
    > left seq: ChorExpression ";" ChorExpression
    ;

syntax Branch = Number ":" ChorExpression!seq ;

lexical ChorVariable
    = "main"
    | (Lower Alnum*) !>> [0-9 A-Z a-z] \ ChorKeyword
    ;

keyword ChorKeyword
    = "chor"
    | "if"
    | "then"
    | "else"
    | "while"
    | "do"
    | "main"
    ;

/* -------------------------------------------------------------------------- */
/*                                 `foreach`                                  */
/* -------------------------------------------------------------------------- */

syntax ChorExpression
    = "foreach" [\<] DataType [\>] DataVariable "in" DataExpression "do" ChorExpression!seq ;

keyword ChorKeyword
    = "foreach"
    | "in"
    ;
