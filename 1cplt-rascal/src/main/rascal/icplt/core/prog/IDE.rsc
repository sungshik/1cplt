module icplt::core::\prog::IDE

import IO;
import Map;
import Message;
import ParseTree;
import Set;
import icplt::core::\chor::IDE;
import icplt::core::\chor::\semantics::Dynamic;
import icplt::core::\chor::\semantics::Static;
import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\prog::\semantics::Dynamic;
import icplt::core::\prog::\semantics::JSON;
import icplt::core::\prog::\semantics::JavaScript;
import icplt::core::\prog::\semantics::Static;
import icplt::core::\prog::\syntax::Abstract;
import icplt::core::\prog::\syntax::Concrete;
import icplt::core::\util::ShellExec;
import util::FileSystem;
import util::IDEServices;
import util::LanguageServer;
import util::Maybe;
import util::Reflective;
import util::UUID;

void register(Language lang = language()) {
    registerLanguage(lang);
}

void unregister(Language lang = language()) {
    unregisterLanguage(lang);
}

Language language() = language(
    pathConfig(srcs = [|std:///|, |project://1cplt-rascal/src/main/rascal|]),
    "1CPLT (Program Expressions)",
    {"1cp-prog"},
    "icplt::core::prog::IDE",
    "languageContributor"
);

set[LanguageService] languageContributor() = {
    parsing(parsingService, usesSpecialCaseHighlighting = false),
    analysis(analysisService, providesDocumentation = true, providesDefinitions = false, providesReferences = false, providesImplementations = false),
    codeLens(codeLensService),
    execution(executionService),
    inlayHint(inlayHintService)
};

Tree parsingService(str input, loc l) {
    return parse(#start[Prog], input, l);
}

Summary analysisService(loc l, start[Prog] input) {
    return analysisService(l, toAbstract(input.top.args[0]));
}

Summary analysisService(loc l, PROG_EXPRESSION e, PROG_CONTEXT c = toProgContext(e)) {
    CHOR_CONTEXT cChor = CHOR_CONTEXT::context(c.gammas, c.deltas);

    Summary analysis = summary(l);
    analysis.messages += {<m.at, m> | m <- analyze(c, e)};
    analysis.documentation += {*analysisService(l, eChor, c = cChor, p = just("<p>")).documentation | /glob(p, _, proceds) := e, /proced(_, eChor) := proceds};
    return analysis;
}

lrel[loc, Command] codeLensService(start[Prog] input) {
    lrel[loc, Command] lenses = [];
    lenses += [<e.src, directive("<e>", [], input, title = "Run directive")> | /e: (Directive) _ := input, "<e>" in {"#analyze", "#compile", "#execute"}];
    return lenses;
}

data Command
    = directive(str name, list[str] args, start[Prog] input)
    ;

void executionService(directive("#analyze", [], start[Prog] input)) {
    PROG_EXPRESSION e = toAbstract(input.top.args[0]);
    PROG_CONTEXT c = toProgContext(e);

    if ([] != analyze(c, e)) {
        Content content = plainText("Run aborted. Fix static errors (type checking failures), warnings (type inference failures), and infos (uninstantiated names) first.");
        showInteractiveContent(content, title = "Run");
        return;
    }

    PROG_STATE s = toProgState(e);
    if (state({map[PID, tuple[CHOR_STATE, CHOR_EXPRESSION]] alt}) := s) {
        alt = (rk: alt[rk] | rk <- alt);
        s = state({alt});
    }

    int threshold = 1000;
    int n = 0;
    tuple[PROG_STATE, PROG_EXPRESSION] initial = <s, e>;
    tuple[PROG_STATE, PROG_EXPRESSION] final   = initial;
    tuple[PROG_STATE, PROG_EXPRESSION] source  = <state({getOneFrom(initial<0>.alts)}), e>;
    for (int i <- [1..threshold + 1]) {
        tuple[PROG_STATE, PROG_EXPRESSION] target = reduce(source);
        if (source == target || i == threshold) {
            n = i;
            final = target;
            break;
        } else {
            source = <state({getOneFrom(target<0>.alts)}), e>;
            continue;
        }
    }

    str toPlainText(<PROG_STATE s, PROG_EXPRESSION e>) {
        str ret = "";

        if ({} := s.alts) {
            return "No alternatives";
        } else {
            int i = 1;
            for (alt <- s.alts) {
                ret += {_, _, *_} := s.alts ? "Alternative <i>:\n" : "";
                ret += {_, _, *_} := s.alts ? "\n" : "";
                for (/proc(rk: <r, _>, _, _) := e, /glob(r, formals, _) := e) {
                    ret += "  - <toStr(val(rk))>\n";
                    ret += "\n";
                    for (/formal(xData, _) := formals) {
                        ret += "      - <xData> = <toStr(alt[rk]<0>.phi[xData])>\n";
                    }
                    ret += "\n";
                }
                i += 1;
            }
        }

        return ret[..-2];
    }

    str text =
        "# Analysis
        '
        '## Initial state
        '
        '<toPlainText(initial)>
        '
        '## Final state (after <n> transitions)<n == threshold ? " -- out of fuel" : "">
        '
        '<toPlainText(final)>
        '";
    
    loc tmp = |tmp:///1cplt/<uuid().authority>/analysis.md|;
    writeFile(tmp, text);
    edit(tmp);
}

void executionService(directive("#compile", [], start[Prog] input)) {
    PROG_EXPRESSION e = toAbstract(input.top.args[0]);
    str name = input.src.file[..-4];
    loc directory = input.src.parent + "<name>";
  
    for (f <- files(|project://1cplt-rascal/src/main/js/icplt|)) {
        copy(f, directory + f.file);
    }

    void generateFile(loc target, str s) {
        loc source = |tmp:///1cplt/<uuid().authority>|;
        writeFile(source, s);
        copy(source, target);
    }
    generateFile(directory + "main.json", toJSON(e));
    generateFile(directory + "library.mjs", toJavaScript(e));
}

void executionService(directive("#execute", [], start[Prog] input)) {
    executionService(directive("#compile", [], input));
    str name = input.src.file[..-4];
    loc directory = input.src.parent + "<name>";

    int pid = execAsync("node", args = ["main.mjs"], workingDir = directory, callback = void() {
        println("Ended executing <name> (#<pid>)");
        edit(directory + "execution.md");
    });
    println("Began executing <name> (#<pid>)");
}

list[InlayHint] inlayHintService(start[Prog] input) {
    return inlayHintService(toAbstract(input.top.args[0]));
}

list[InlayHint] inlayHintService(PROG_EXPRESSION e) {
    return [*inlayHintService(eChor) | /proced(_, eChor) := e];
}
