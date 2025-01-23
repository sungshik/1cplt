module icplt::core::\util::\semantics::JSON

import List;
import String;

int NEWLINE = 10;
int SPACE   = 32;
int COMMA   = 44;
int LBRACK  = 91;
int RBRACK  = 93;
int LBRACE  = 123;
int RBRACE  = 125;

str format(str s) {
    int level = 0;
    list[int] indent() = [SPACE | _ <- [0..2 * level]];
    list[bool] newlineAfterComma = [true];

    list[int] old = chars(s);
    list[int] new = [];

    for (ch <- old) {
        switch (ch) {
            case LBRACE: {
                level += 1;
                new += [ch, NEWLINE, *indent()];
                newlineAfterComma += true;
            }
            case RBRACE: {
                level -= 1;
                new += [NEWLINE, *indent(), ch];
                newlineAfterComma = newlineAfterComma[..-1];
            }
            case LBRACK: {
                new += [ch];
                newlineAfterComma += false;
            }
            case RBRACK: {
                new += [ch];
                newlineAfterComma = newlineAfterComma[..-1];
            }
            case COMMA: {
                new += [ch];
                new += newlineAfterComma[-1] ? [NEWLINE, *indent()] : [];
            }
            case NEWLINE: {;}
            case SPACE: {;}
            default: {
                new += ch;
            }
        }
    }

    return stringChars(new);
}
