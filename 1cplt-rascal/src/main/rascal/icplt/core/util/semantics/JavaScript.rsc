module icplt::core::\util::\semantics::JavaScript

import List;
import String;

int NEWLINE = 10;
int SPACE   = 32;
int SEMI    = 59;
int LBRACE  = 123;
int RBRACE  = 125;

str format(str s) {
    int level = 0;
    list[int] indent() = [SPACE | _ <- [0..2 * level]];

    list[int] old = chars(s);
    list[int] new = [];

    for (ch <- old) {
        switch (ch) {
            case LBRACE: {
                level += 1;
                new += [ch];
            }
            case RBRACE: {
                level -= 1;
                if ([] != new && new[-1] in {LBRACE}) {
                    new += ch;
                } else {
                    new += [NEWLINE, *indent(), ch];
                }
            }
            case SEMI: {
                new += ch;
            }
            case SPACE: {;}
            default: {
                if ([] != new && new[-1] in {LBRACE, RBRACE, SEMI}) {
                    new += [NEWLINE, *indent(), ch];
                } else {
                    new += ch;
                }
            }
        }
    }

    return stringChars(new);
}
