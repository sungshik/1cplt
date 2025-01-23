module icplt::core::\data::\semantics::JSON

import List;
import String;

import icplt::core::\data::\syntax::Abstract;

str toJSON(DATA_TYPE _: pid(_))
    = "{ \"type\": \"string\", \"default\": true }";
str toJSON(DATA_TYPE _: null())
    = "{ \"type\": \"null\" }";
str toJSON(DATA_TYPE _: boolean())
    = "{ \"type\": \"boolean\" }";
str toJSON(DATA_TYPE _: number())
    = "{ \"type\": \"number\" }";
str toJSON(DATA_TYPE _: string())
    = "{ \"type\": \"string\" }";
str toJSON(DATA_TYPE _: array(t1))
    = "{ \"type\": \"array\", \"items\": <toJSON(t1)> }";

str toJSON(DATA_EXPRESSION _: val(PID _: <r, k>))
    = "\"<r>[<k>]\"" ;
str toJSON(DATA_EXPRESSION _: val(NULL _))
    = "null" ;
str toJSON(DATA_EXPRESSION _: val(BOOLEAN b))
    = "<b>" ;
str toJSON(DATA_EXPRESSION _: val(NUMBER n))
    = "<n>" ;
str toJSON(DATA_EXPRESSION _: val(STRING s))
    = "\"<s>\"" ;
str toJSON(DATA_EXPRESSION _: val(ARRAY a))
    = "[<intercalate(", ", [toJSON(val(vi)) | vi <- a])>]" ;
