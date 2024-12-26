module icplt::core::\util::\syntax::Concrete

lexical Alnum = [0-9 A-Z a-z] ;
lexical Digit = [0-9] ;
lexical Blank = [\ \t] ;
lexical Lower = [a-z] ;
lexical Print = [0-9 A-Z a-z \ \t\n] ;
lexical Space = [\ \t\n] ;
lexical Upper = [A-Z] ;

lexical Comment = @category="comment" "//" ![\n]* $;

layout Layout = (Comment | Space)* !>> [\ \t\n] !>> "//";
