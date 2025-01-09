module icplt::core::\chor::IDE

import Message;
import ParseTree;
import util::LanguageServer;
import util::Maybe;
import util::Reflective;

import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\chor::\syntax::Concrete;
import icplt::core::\chor::\semantics::Static;
import icplt::core::\data::IDE;
import icplt::core::\data::\semantics::Static;

void register(Language lang = language()) {
    registerLanguage(lang);
}

void unregister(Language lang = language()) {
    unregisterLanguage(lang);
}

Language language() = language(
    pathConfig(srcs = [|std:///|, |project://1cplt-rascal/src/main/rascal|]),
    "1CPLT (Choreography Expressions)",
    {"1cp-chor"},
    "icplt::core::chor::IDE",
    "languageContributor"
);

set[LanguageService] languageContributor() = {
    parsing(parsingService, usesSpecialCaseHighlighting = false),
    analysis(analysisService, providesDocumentation = true, providesDefinitions = false, providesReferences = false, providesImplementations = false),
    inlayHint(inlayHintService)
};

Tree parsingService(str input, loc l) {
    return parse(#start[Chor], input, l);
}

Summary analysisService(loc l, start[Chor] input) {
    return analysisService(l, toAbstract(input.top.args[0]));
}

Summary analysisService(loc l, CHOR_EXPRESSION e, CHOR_CONTEXT c = toChorContext(e), Maybe[ROLE] p = nothing()) {

    rel[loc, str] toDocumentation(CHOR_EXPRESSION e, Maybe[ROLE] p) {
        DATA_CONTEXT cData = context(p is just && p.val in c.gammas ? c.gammas[p.val] : ());

        rel[loc, str] documentation = {};
        top-down-break visit (e) {
            case CHOR_EXPRESSION e: asgn(xData, eData): {
                documentation += analysisService(l, DATA_EXPRESSION::var(xData)[src = e.xDataSrc], c = cData).documentation;
                documentation += analysisService(l, eData, c = cData).documentation;
            }
            case CHOR_EXPRESSION e: comm(eData1, eData2, xData, e1): {
                DATA_CONTEXT cDataP = cData;
                DATA_CONTEXT cDataQ = context(just(pid(q)) := infer(cData, eData2) && q in c.gammas ? c.gammas[q] : ());
                documentation += analysisService(l, eData1, c = cDataP).documentation;
                documentation += analysisService(l, eData2, c = cDataP).documentation;
                documentation += analysisService(l, DATA_EXPRESSION::var(xData)[src = e.xDataSrc], c = cDataQ).documentation;
                documentation += {*toDocumentation(e1, just(q)) | just(pid(q)) := infer(cData, eData2)};
            }
            case CHOR_EXPRESSION _: choice(eData, e1, e2): {
                documentation += analysisService(l, eData, c = cData).documentation;
                documentation += toDocumentation(e1, p);
                documentation += toDocumentation(e2, p);
            }
            case CHOR_EXPRESSION _: loop(eData, e1): {
                documentation += analysisService(l, eData, c = cData).documentation;
                documentation += toDocumentation(e1, p);
            }
            case CHOR_EXPRESSION _: at(eData, e1): {
                documentation += analysisService(l, eData, c = cData).documentation;
                documentation += {*toDocumentation(e1, just(q)) | just(pid(q)) := infer(context(()), eData)};
            }
        }
        return documentation;
    }

    Summary analysis = summary(l);
    analysis.messages += {<m.at, m> | m <- analyze(c, e)};
    analysis.documentation += toDocumentation(e, p);
    return analysis;
}

list[InlayHint] inlayHintService(start[Chor] input) {
    return inlayHintService(toAbstract(input.top.args[0]));
}

list[InlayHint] inlayHintService(CHOR_EXPRESSION e, str name = "self") {
    str label = toLabel(name);

    list[InlayHint] toHints(DATA_EXPRESSION e, str label)
        = [hint(e.src, "<label>(", InlayKind::\type(), atEnd = false) | e is app && app("array", _) !:= e]
        + [hint(e.src, ")", InlayKind::\type(), atEnd = true) | e is app && app("array", _) !:= e]
        + [hint(e.src, "<label>", InlayKind::\type(), atEnd = false) | !(e is app) || app("array", _) := e] ;
    list[InlayHint] toHints(CHOR_EXPRESSION e, str label)
        = [hint(e.src, label, InlayKind::\type(), atEnd = false)];

    list[InlayHint] hints = [];
    top-down-break visit (e) {
        case CHOR_EXPRESSION e: var(_): {
            hints += toHints(e, label);
        }
        case CHOR_EXPRESSION e: asgn(_, _): {
            hints += toHints(e, label);
        }
        case CHOR_EXPRESSION e: comm(_, eData2, _, e1): {
            hints += toHints(e, label);
            hints += inlayHintService(e1, name = "<toStr(eData2)>");
        }
        case CHOR_EXPRESSION _: choice(eData, e1, e2): {
            hints += toHints(eData, label);
            hints += inlayHintService(e1, name = name);
            hints += inlayHintService(e2, name = name);
        }
        case CHOR_EXPRESSION _: select(eData, branches): {
            hints += toHints(eData, label);
            hints += [*inlayHintService(ei, name = name) | <_, ei> <- branches];
        }
        case CHOR_EXPRESSION _: loop(eData, e1): {
            hints += toHints(eData, label);
            hints += inlayHintService(e1, name = name);
        }
        case CHOR_EXPRESSION _: at(eData, e1): {
            hints += inlayHintService(e1, name = "<toStr(eData)>");
        }
    }
    return [hint | hint <- hints, "unknown" != hint.position.scheme];
}

str toLabel(str _: /^<name:[0-9A-Za-z]+>$/)
    = "<name>." ;

/* -------------------------------------------------------------------------- */
/*                                 `foreach`                                  */
/* -------------------------------------------------------------------------- */

str toLabel(str _: /^\(foreach\<[0-9A-Za-z]+\> <name:[0-9A-Za-z]+>, [0-9]*\).elem$/)
    = "<name>." ;
