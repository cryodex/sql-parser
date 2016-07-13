class SQLParser::Parser

option
  ignorecase

macro
  DIGIT   [0-9]
  UINT    {DIGIT}+
  BLANK   \s+

  YEARS   {UINT}
  MONTHS  {UINT}
  DAYS    {UINT}
  DATE    {YEARS}-{MONTHS}-{DAYS}

  IDENT   \w+

rule
# [:state]  pattern             [actions]

# literals
            \"{DATE}\"          { [:date_string, Date.parse(text)] }
            \'{DATE}\'          { [:date_string, Date.parse(text)] }

            \'                  { @state = :STRS;  [:quote, text] }
  :STRS     ([^\\']|\\.|'')+    {                  [:character_string_literal, text.gsub(/''|\\'/, "'").gsub(/""|\\"/, '"')] }
  :STRS     \'                  { @state = nil;    [:quote, text] }

            \"                  { @state = :STRD;  [:quote, text] }
  :STRD     \"                  { @state = nil;    [:quote, text] }
  :STRD     ([^\\"]|\\.|"")+    {                  [:character_string_literal, text.gsub(/''|\\'/, "'").gsub(/""|\\"/, '"')] }

            {UINT}              { [:unsigned_integer, text.to_i] }

# skip
            {BLANK}             # no action

# keywords
            SELECT(?!\w)        { [:SELECT, text] }
            DATE(?!\w)          { [:DATE, text] }
            ASC(?!\w)           { [:ASC, text] }
            AS(?!\w)            { [:AS, text] }
            FROM(?!\w)          { [:FROM, text] }
            WHERE(?!\w)         { [:WHERE, text] }
            BETWEEN(?!\w)       { [:BETWEEN, text] }
            AND(?!\w)           { [:AND, text] }
            NOT(?!\w)           { [:NOT, text] }
            INNER(?!\w)         { [:INNER, text] }
            INSERT(?!\w)        { [:INSERT, text] }
            INTO(?!\w)          { [:INTO, text] }
            IN(?!\w)            { [:IN, text] }
            ORDER(?!\w)         { [:ORDER, text] }
            LIMIT(?!\w)         { [:LIMIT, text] }
            OR(?!\w)            { [:OR, text] }
            LIKE(?!\w)          { [:LIKE, text] }
            IS(?!\w)            { [:IS, text] }
            NULL(?!\w)          { [:NULL, text] }
            COUNT(?!\w)         { [:COUNT, text] }
            AVG(?!\w)           { [:AVG, text] }
            MAX(?!\w)           { [:MAX, text] }
            MIN(?!\w)           { [:MIN, text] }
            SUM(?!\w)           { [:SUM, text] }
            GROUP(?!\w)         { [:GROUP, text] }
            BY(?!\w)            { [:BY, text] }
            HAVING(?!\w)        { [:HAVING, text] }
            CROSS(?!\w)         { [:CROSS, text] }
            JOIN(?!\w)          { [:JOIN, text] }
            ON(?!\w)            { [:ON, text] }
            LEFT(?!\w)          { [:LEFT, text] }
            OUTER(?!\w)         { [:OUTER, text] }
            RIGHT(?!\w)         { [:RIGHT, text] }
            FULL(?!\w)          { [:FULL, text] }
            USING(?!\w)         { [:USING, text] }
            EXISTS(?!\w)        { [:EXISTS, text] }
            DESC(?!\w)          { [:DESC, text] }
            CURRENT_USER(?!\w)  { [:CURRENT_USER, text] }
            VALUES(?!\w)        { [:VALUES, text] }
            FOR(?!\w)           { [:FOR, text] }
            UPDATE(?!\w)        { [:UPDATE, text] }
            DELETE(?!\w)        { [:DELETE, text] }
            SET(?!\w)           { [:SET, text] }
            DISTINCT(?!\w)      { [:DISTINCT, text] }
            COALESCE(?!\w)      { [:COALESCE, text] }

# tokens
            E             { [:E, text] }

            <>            { [:not_equals_operator, text] }
            !=            { [:not_equals_operator, text] }
            =             { [:equals_operator, text] }
            <=            { [:less_than_or_equals_operator, text] }
            <             { [:less_than_operator, text] }
            >=            { [:greater_than_or_equals_operator, text] }
            >             { [:greater_than_operator, text] }

            \(            { [:left_paren, text] }
            \)            { [:right_paren, text] }
            \*            { [:asterisk, text] }
            \/            { [:solidus, text] }
            \+            { [:plus_sign, text] }
            \-            { [:minus_sign, text] }
            \.            { [:period, text] }
            ,             { [:comma, text] }

# identifier
            `{IDENT}`     { [:identifier, text[1..-2]] }
            {IDENT}       { [:identifier, text] }

---- header ----
require 'date'
