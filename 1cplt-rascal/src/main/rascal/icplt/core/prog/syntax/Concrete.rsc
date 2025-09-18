module icplt::core::\prog::\syntax::Concrete
extend icplt::core::\chor::\syntax::Concrete;
extend icplt::core::\data::\syntax::Concrete;
extend icplt::core::\util::\syntax::Concrete;

start syntax Prog = ProgExpression ;

syntax ProgExpression
    = RoleDefinition
    | ProcessDefinition
    | Directive
    > left ProgExpression ProgExpression
    ;

syntax RoleDefinition
    = "role" Role "(" {FormalParameter ","}* ")"
    | "role" Role "(" {FormalParameter ","}* ")" "{" Procedure* "}"
    ;

syntax Procedure = ChorVariable ":" ChorExpression ;

syntax ProcessDefinition
    = "process" Pid "(" {ActualParameter ","}* ")"
    | "process" Pid "(" {ActualParameter ","}* ")" "|\>" ChorExpression
    ;

syntax FormalParameter = {DataVariable ","}+ ":" DataType ;
syntax ActualParameter = DataExpression!comma ;

syntax Directive = @category="decorator" [#] (Alpha (Alnum | [_])*) !>> [0-9 A-Z a-z _] \ DataKeyword ;

keyword ProgKeyword =
    | "process"
    | "role"
    | "self"
    ;
