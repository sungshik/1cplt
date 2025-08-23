module icplt::core::\data::IDE

import List;
import Message;
import ParseTree;
import util::LanguageServer;
import util::Maybe;
import util::Reflective;

import icplt::core::\data::\semantics::Dynamic;
import icplt::core::\data::\semantics::Static;
import icplt::core::\data::\syntax::Abstract;
import icplt::core::\data::\syntax::Concrete;

void register(Language lang = language()) {
    registerLanguage(lang);
}

void unregister(Language lang = language()) {
    unregisterLanguage(lang);
}

Language language() = language(
    pathConfig(srcs = [|std:///|, |project://1cplt-rascal/src/main/rascal|]),
    "1CPLT (Data Expressions)",
    {"1cp-data"},
    "icplt::core::data::IDE",
    "languageContributor"
);

set[LanguageService] languageContributor() = {
    parsing(parsingService, usesSpecialCaseHighlighting = false),
    analysis(analysisService, providesDocumentation = true, providesDefinitions = false, providesReferences = false, providesImplementations = false),
    inlayHint(inlayHintService)
};

Tree parsingService(str input, loc l) {
    return parse(#start[Data], input, l);
}

Summary analysisService(loc l, start[Data] input) {
    return analysisService(l, toAbstract(input.top.args[0]));
}

Summary analysisService(loc l, DATA_EXPRESSION e, DATA_CONTEXT c = toDataContext(e)) {
    Summary analysis = summary(l);
    analysis.messages += {<m.at, m> | app(",", args) := e, ei <- args, m <- analyze(c, ei)};
    analysis.messages += {<m.at, m> | app(",", _) !:= e, m <- analyze(c, e)};
    analysis.documentation += {<x.src, "`<toStr(t)>`"> | /x: var(_) := e, just(t) := infer(c, x)};
    analysis.documentation += {<ki.src, "`<toStr(ti)>`"> | /app("object", args) := e, <ki, ei> <- zip2(args[0,2..], args[1,3..]), just(ti) := infer(c, ei)};
    analysis.documentation += {<e2.src, "`<toStr(entries[k])>`"> | /app("read", [e1, e2: val(k)]) := e, just(object(entries)) := infer(c, e1), k in entries};
    return analysis;
}

list[InlayHint] inlayHintService(start[Data] input) {
    return inlayHintService(toAbstract(input.top.args[0]));
}

list[InlayHint] inlayHintService(DATA_EXPRESSION e) {

    InlayHint toHint(DATA_EXPRESSION e) {
        str label = " == ";
        try {
            label += "<toStr(normalize(<toState(e), e>)<1>)>"; }
        catch _: {
            label += "undefined";
        }
        return hint(e.src, label, InlayKind::\parameter(), atEnd = true);
    }

    list[InlayHint] hints = [];
    hints += [toHint(ei) | app(",", args) := e, ei <- args, ei is app];
    hints += [toHint(e) | app(",", _) !:= e];
    return [hint | hint <- hints, "unknown" != hint.position.scheme];
}
