module icplt::core::\prog::\syntax::Concrete
extend icplt::core::\chor::\syntax::Concrete;
extend icplt::core::\data::\syntax::Concrete;
extend icplt::core::\util::\syntax::Concrete;

start syntax Prog = ProgExpression ;

syntax ProgExpression
    = Global
    | Process
    > left ProgExpression ProgExpression
    ;

syntax Global
    = "global" Role "(" {FormalParameter ","}* ")"
    | "global" Role "(" {FormalParameter ","}* ")" "{" Procedure* "}"
    ;

syntax Procedure = ChorVariable ":" ChorExpression ;

syntax Process
    = "process" Pid "(" {ActualParameter ","}* ")"
    | "process" Pid "(" {ActualParameter ","}* ")" "|\>" ChorExpression
    ;

syntax FormalParameter = {DataVariable ","}+ ":" DataType ;
syntax ActualParameter = DataExpression!comma ;

keyword ProgKeyword =
    | "process"
    | "global"
    | "self"
    ;
