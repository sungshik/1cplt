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
    = RoleKeyword Role "(" {FormalParameter ","}* ")"
    | RoleKeyword Role "(" {FormalParameter ","}* ")" "{" Procedure* "}"
    ;

lexical RoleKeyword
    = @category="keyword" "role"
    | @category="keyword" "role*"
    ;

syntax Procedure = ChorVariable ":" ChorExpression ;

syntax ProcessDefinition
    = "process" Pid "(" {ActualParameter ","}* ")"
    ;

syntax FormalParameter
    = DataVariable ":" DataType ("=" DataExpression)?
    | DataVariable "?" ":" DataType ("=" DataExpression)?
    ;

syntax ActualParameter
    = DataVariable "=" DataExpression!comma ;

syntax Directive = @category="decorator" [#] (Alpha (Alnum | [_])*) !>> [0-9 A-Z a-z _] \ DataKeyword ;

keyword ProgKeyword =
    | "process"
    | "role"
    | "self"
    ;
