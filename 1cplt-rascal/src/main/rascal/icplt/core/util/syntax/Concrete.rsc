module icplt::core::\util::\syntax::Concrete

lexical Comma = [,] ;
lexical Semi = [;] ;

lexical Alnum = Alpha | Digit ;
lexical Alpha = Lower | Upper ;
lexical Blank = [\ \t] ;
lexical Digit = [0-9] ;
lexical Graph = Alnum | Punct ;
lexical Lower = [a-z] ;
lexical Print = Graph | [\ ] ;
lexical Punct = [! \" # $ % & \' ( ) * + , - . / : ; \< = \> ? @ \[ \\ \] ^ _ ` { | } ~] ;
lexical Space = [\  \t \n] ;
lexical Upper = [A-Z] ;

lexical Comment = @category="comment" "//" ![\n]* $;

layout Layout = (Comment | Space)* !>> [\ \t\n] !>> "//";
