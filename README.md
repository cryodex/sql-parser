## sql-parser

A Ruby library for parsing and generating SQL statements.

### Features

  * Parse arbitrary SQL strings into an AST (abstract syntax tree), which can
    then be traversed.

  * Allows your code to understand and manipulate SQL in a deeper way than
    just using string manipulation.

### Usage

**Parsing a statement into an AST**

```ruby
>> require 'sql-parser'
>> parser = SQLParser::Parser.new

# Build the AST from a SQL statement
>> ast = parser.scan_str('SELECT * FROM users WHERE id = 1')

# Find which columns where selected in the FROM clause
>> ast.query_expression.list.to_sql
=> "*"

# Output the table expression as SQL
>> ast.query_expression.table_expression.to_sql
=> "FROM users WHERE id = 1"

# Drill down into the WHERE clause, to examine every piece
>> ast.query_expression.table_expression.where_clause.to_sql
=> "WHERE id = 1"
>> ast.query_expression.table_expression.where_clause.search_condition.to_sql
=> "id = 1"
>> ast.query_expression.table_expression.where_clause.search_condition.left.to_sql
=> "id"
>> ast.query_expression.table_expression.where_clause.search_condition.right.to_sql
=> "1"
```

**Manually building an AST**

```ruby
>> require 'sql-parser'

# Let's build a tree representing the SQL statement
# "SELECT * FROM users WHERE id = 1"

# We'll start from the rightmost side, and work our way left as we go.

# First, the integer constant, "1"
>> integer_constant = SQLParser::Statement::Integer.new(1)
>> integer_constant.to_sql
=> "1"

# Now the column reference, "id"
>> column_reference = SQLParser::Statement::Column.new('id')
>> column_reference.to_sql
=> "id"

# Now we'll combine the two using an equals operator, to create a search
# condition
>> search_condition = SQLParser::Statement::Equals.new(column_reference, integer_constant)
>> search_condition.to_sql
=> "id = 1"

# Next we'll feed that search condition to a where clause
>> where_clause = SQLParser::Statement::WhereClause.new(search_condition)
>> where_clause.to_sql
=> "WHERE id = 1"

# Next up is the FROM clause.  First we'll build a table reference
>> users = SQLParser::Statement::Table.new('users')
>> users.to_sql
=> "users"

# Now we'll feed that table reference to a from clause
>> from_clause = SQLParser::Statement::FromClause.new(users)
>> from_clause.to_sql
=> "FROM users"

# Now to combine the FROM and WHERE clauses to form a table expression
>> table_expression = SQLParser::Statement::TableExpression.new(from_clause, where_clause)
>> table_expression.to_sql
=> "FROM users WHERE id = 1"

# Now we need to represent the asterisk "*"
>> all = SQLParser::Statement::All.new
>> all.to_sql
=> "*"

# Now we're ready to hand off these objects to a select statement
>> select_statement = SQLParser::Statement::Select.new(all, table_expression)
>> select_statement.to_sql
=> "SELECT * FROM users WHERE id = 1"
```
###License

This software is released under the MIT license.
