module icplt::core::\util::\syntax::Abstract

bool compare(value v1, value v2)
    = v1 := v2 && v2 := v1 ; // Ignore keyword parameters
