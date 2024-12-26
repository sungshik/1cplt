module icplt::core::AutoName

import IO;
import ParseTree;
import String;
import lang::rascal::\syntax::Rascal;
import util::FileSystem;

void main() {
    loc l = |project://1cplt-rascal/src/main/rascal/icplt/core|;
    autoNameTestsLoc(l);
}

void autoNameTestsLoc(loc l) {
    if (isDirectory(l)) {
        for (f <- find(l, "rsc")) {
            autoNameTestsLoc(f);
        }
    } else {
        println("Auto-naming tests at <l>");
        str old = readFile(l);
        str new = autoNameTestsStr(old);
        writeFile(l, new);
    }
}

str autoNameTestsStr(str s) {
    old = parse(#start[Module], s);
    new = visit (old) {
        case fd: (FunctionDeclaration) `@autoName test bool <Name name1> <Parameters _> = <Expression expression>;` =>
            visit (fd) {
                case (Name) name2 =>
                    name1 == name2 ? parse(#Name, "_<md5Hash("<expression>")>") : name2
            }
    }

    s = "<new>";
    return s;
}
