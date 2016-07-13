require File.dirname(__FILE__) + '/../lib/sql-parser'
require 'test/unit'

class TestStatement < Test::Unit::TestCase
  def test_direct_select
    assert_sql 'SELECT * FROM `users`', SQLParser::Statement::DirectSelect.new(select(all, tblx(from(tbl('users')))))
  end

  def test_order_by
    assert_sql 'ORDER BY `name` ASC', order_by(asc(col('name')))
  end

  def test_limit
    assert_sql 'LIMIT 10', limit(10)
  end

  def test_subquery
    assert_sql '(SELECT 1)', SQLParser::Statement::Subquery.new(select(int(1)))
  end

  def test_select
    assert_sql 'SELECT 1', select(int(1))
    assert_sql 'SELECT * FROM `users`', select(all, tblx(from(tbl('users'))))
  end

  def test_select_list
    assert_sql '`id`', slist(col('id'))
    assert_sql '`id`, `name`', slist([col('id'), col('name')])
  end

  def test_insert
    assert_sql "INSERT INTO `users` VALUES ('Mr', 'President')",
      SQLParser::Statement::Insert.new(tbl("users"), nil, SQLParser::Statement::InValueList.new([str("Mr"), str("President")]))
  end

  def test_insert_with_column_list
    assert_sql "INSERT INTO `users` (`first`, `last`) VALUES ('Mr', 'President')",
      SQLParser::Statement::Insert.new(
        tbl("users"),
        SQLParser::Statement::InColumnList.new([col("first"), col("last")]),
        SQLParser::Statement::InValueList.new([str("Mr"), str("President")]))
  end

  def test_update
    assert_sql "UPDATE `users` SET `first` = 'boom' WHERE `last` = 'bam' ORDER BY `first` ASC",
      SQLParser::Statement::Update.new(
        tbl("users"),
        [SQLParser::Statement::Assignment.new(col("first"), str("boom"))],
        where(equals(col("last"), str("bam"))),
        order_by(asc(col('first'))))
  end

  def test_delete
    assert_sql "DELETE FROM `users` WHERE `first` = 'boom'",
      SQLParser::Statement::Delete.new(
        tbl("users"),
        where(equals(col("first"), str("boom"))))
  end

  def test_distinct
    assert_sql 'DISTINCT(`username`)', distinct(col('username'))
  end

  def test_all
    assert_sql '*', all
  end

  def test_table_expression
    assert_sql 'FROM `users` WHERE `id` = 1 GROUP BY `name`', tblx(from(tbl('users')), where(equals(col('id'), int(1))), group_by(col('name')))
  end

  def test_from_clause
    assert_sql 'FROM `users`', from(tbl('users'))
  end

  def test_full_outer_join
    assert_sql '`t1` FULL OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a`', SQLParser::Statement::FullOuterJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::On.new(equals(qcol(tbl('t1'), col('a')), qcol(tbl('t2'), col('a')))))
    assert_sql '`t1` FULL OUTER JOIN `t2` USING (`a`)', SQLParser::Statement::FullOuterJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::Using.new(col('a')))
  end

  def test_full_join
    assert_sql '`t1` FULL JOIN `t2` ON `t1`.`a` = `t2`.`a`', SQLParser::Statement::FullJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::On.new(equals(qcol(tbl('t1'), col('a')), qcol(tbl('t2'), col('a')))))
  end

  def test_right_outer_join
    assert_sql '`t1` RIGHT OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a`', SQLParser::Statement::RightOuterJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::On.new(equals(qcol(tbl('t1'), col('a')), qcol(tbl('t2'), col('a')))))
  end

  def test_right_join
    assert_sql '`t1` RIGHT JOIN `t2` ON `t1`.`a` = `t2`.`a`', SQLParser::Statement::RightJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::On.new(equals(qcol(tbl('t1'), col('a')), qcol(tbl('t2'), col('a')))))
  end

  def test_left_outer_join
    assert_sql '`t1` LEFT OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a`', SQLParser::Statement::LeftOuterJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::On.new(equals(qcol(tbl('t1'), col('a')), qcol(tbl('t2'), col('a')))))
  end

  def test_left_join
    assert_sql '`t1` LEFT JOIN `t2` ON `t1`.`a` = `t2`.`a`', SQLParser::Statement::LeftJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::On.new(equals(qcol(tbl('t1'), col('a')), qcol(tbl('t2'), col('a')))))
  end

  def test_inner_join
    assert_sql '`t1` INNER JOIN `t2` ON `t1`.`a` = `t2`.`a`', SQLParser::Statement::InnerJoin.new(tbl('t1'), tbl('t2'), SQLParser::Statement::On.new(equals(qcol(tbl('t1'), col('a')), qcol(tbl('t2'), col('a')))))
  end

  def test_cross_join
    assert_sql '`t1` CROSS JOIN `t2`', SQLParser::Statement::CrossJoin.new(tbl('t1'), tbl('t2'))
    assert_sql '`t1` CROSS JOIN `t2` CROSS JOIN `t3`', SQLParser::Statement::CrossJoin.new(SQLParser::Statement::CrossJoin.new(tbl('t1'), tbl('t2')), tbl('t3'))
  end

  def test_order_clause
    assert_sql 'ORDER BY `name` DESC', order_by(desc(col('name')))
    assert_sql 'ORDER BY `id` ASC, `name` DESC', order_by([asc(col('id')), desc(col('name'))])
  end

  def test_having_clause
    assert_sql 'HAVING `id` = 1', SQLParser::Statement::HavingClause.new(equals(col('id'), int(1)))
  end

  def test_group_by_clause
    assert_sql 'GROUP BY `name`', group_by(col('name'))
    assert_sql 'GROUP BY `name`, `status`', group_by([col('name'), col('status')])
  end

  def test_where_clause
    assert_sql 'WHERE 1 = 1', where(equals(int(1), int(1)))
  end

  def test_or
    assert_sql '(FALSE OR FALSE)', SQLParser::Statement::Or.new(SQLParser::Statement::False.new, SQLParser::Statement::False.new)
  end

  def test_and
    assert_sql '(TRUE AND TRUE)', SQLParser::Statement::And.new(SQLParser::Statement::True.new, SQLParser::Statement::True.new)
  end

  def test_is_not_null
    assert_sql '1 IS NOT NULL', SQLParser::Statement::Not.new(SQLParser::Statement::Is.new(int(1), SQLParser::Statement::Null.new))
  end

  def test_is_null
    assert_sql '1 IS NULL', SQLParser::Statement::Is.new(int(1), SQLParser::Statement::Null.new)
  end

  def test_not_like
    assert_sql "'hello' NOT LIKE 'h%'", SQLParser::Statement::Not.new(SQLParser::Statement::Like.new(str('hello'), str('h%')))
  end

  def test_like
    assert_sql "'hello' LIKE 'h%'", SQLParser::Statement::Like.new(str('hello'), str('h%'))
  end

  def test_not_in
    assert_sql '1 NOT IN (1, 2, 3)', SQLParser::Statement::Not.new(SQLParser::Statement::In.new(int(1), SQLParser::Statement::InValueList.new([int(1), int(2), int(3)])))
  end

  def test_in
    assert_sql '1 IN (1, 2, 3)', SQLParser::Statement::In.new(int(1), SQLParser::Statement::InValueList.new([int(1), int(2), int(3)]))
  end

  def test_not_between
    assert_sql '2 NOT BETWEEN 1 AND 3', SQLParser::Statement::Not.new(SQLParser::Statement::Between.new(int(2), int(1), int(3)))
  end

  def test_between
    assert_sql '2 BETWEEN 1 AND 3', SQLParser::Statement::Between.new(int(2), int(1), int(3))
  end

  def test_between_strings
    assert_sql "'2' BETWEEN '1' AND '3'", SQLParser::Statement::Between.new(str('2'), str('1'), str('3'))
  end

  def test_gte
    assert_sql '1 >= 1', SQLParser::Statement::GreaterOrEquals.new(int(1), int(1))
  end

  def test_lte
    assert_sql '1 <= 1', SQLParser::Statement::LessOrEquals.new(int(1), int(1))
  end

  def test_gt
    assert_sql '1 > 1', SQLParser::Statement::Greater.new(int(1), int(1))
  end

  def test_lt
    assert_sql '1 < 1', SQLParser::Statement::Less.new(int(1), int(1))
  end

  def test_not_equals
    assert_sql '1 <> 1', SQLParser::Statement::Not.new(equals(int(1), int(1)))
  end

  def test_equals
    assert_sql '1 = 1', equals(int(1), int(1))
  end

  def test_sum
    assert_sql 'SUM(`messages_count`)', SQLParser::Statement::Sum.new(col('messages_count'))
  end

  def test_minimum
    assert_sql 'MIN(`age`)', SQLParser::Statement::Minimum.new(col('age'))
  end

  def test_maximum
    assert_sql 'MAX(`age`)', SQLParser::Statement::Maximum.new(col('age'))
  end

  def test_average
    assert_sql 'AVG(`age`)', SQLParser::Statement::Average.new(col('age'))
  end

  def test_count
    assert_sql 'COUNT(*)', SQLParser::Statement::Count.new(all)
  end

  def test_table
    assert_sql '`users`', tbl('users')
  end

  def test_qualified_column
    assert_sql '`users`.`id`', qcol(tbl('users'), col('id'))
  end

  def test_column
    assert_sql '`id`', col('id')
  end

  def test_as
    assert_sql '1 AS `a`', SQLParser::Statement::As.new(int(1), col('a'))
  end

  def test_multiply
    assert_sql '(2 * 2)', SQLParser::Statement::Multiply.new(int(2), int(2))
  end

  def test_divide
    assert_sql '(2 / 2)', SQLParser::Statement::Divide.new(int(2), int(2))
  end

  def test_add
    assert_sql '(2 + 2)', SQLParser::Statement::Add.new(int(2), int(2))
  end

  def test_subtract
    assert_sql '(2 - 2)', SQLParser::Statement::Subtract.new(int(2), int(2))
  end

  def test_unary_plus
    assert_sql '+1', SQLParser::Statement::UnaryPlus.new(int(1))
  end

  def test_unary_minus
    assert_sql '-1', SQLParser::Statement::UnaryMinus.new(int(1))
  end

  def test_true
    assert_sql 'TRUE', SQLParser::Statement::True.new
  end

  def test_false
    assert_sql 'FALSE', SQLParser::Statement::False.new
  end

  def test_null
    assert_sql 'NULL', SQLParser::Statement::Null.new
  end

  def test_current_user
    assert_sql 'CURRENT_USER', SQLParser::Statement::CurrentUser.new
  end

  def test_datetime
    assert_sql "'2008-07-01 12:34:56'", SQLParser::Statement::DateTime.new(Time.local(2008, 7, 1, 12, 34, 56))
  end

  def test_date
    assert_sql "DATE '2008-07-01'", SQLParser::Statement::Date.new(Date.new(2008, 7, 1))
  end

  def test_string
    assert_sql "'foo'", str('foo')

    # # FIXME
    # assert_sql "'O\\\'rly'", str("O'rly")
  end

  def test_approximate_float
    assert_sql '1E1', SQLParser::Statement::ApproximateFloat.new(int(1), int(1))
  end

  def test_float
    assert_sql '1.1', SQLParser::Statement::Float.new(1.1)
  end

  def test_integer
    assert_sql '1', int(1)
  end

  private

  def assert_sql(expected, ast)
    assert_equal expected, ast.to_sql
  end

  def qcol(table, column)
    SQLParser::Statement::QualifiedColumn.new(table, column)
  end

  def equals(left, right)
    SQLParser::Statement::Equals.new(left, right)
  end

  def all
    SQLParser::Statement::All.new
  end

  def str(value)
    SQLParser::Statement::String.new(value)
  end

  def int(value)
    SQLParser::Statement::Integer.new(value)
  end

  def col(name)
    SQLParser::Statement::Column.new(name)
  end

  def tbl(name)
    SQLParser::Statement::Table.new(name)
  end

  def distinct(col)
    SQLParser::Statement::Distinct.new(col)
  end

  def slist(ary)
    SQLParser::Statement::SelectList.new(ary)
  end

  def select(list, table_expression = nil)
    SQLParser::Statement::Select.new(nil, list, table_expression)
  end

  def tblx(from_clause, where_clause = nil, group_by_clause = nil, having_clause = nil, order_by = nil, limit = nil)
    SQLParser::Statement::TableExpression.new(from_clause, where_clause, group_by_clause, having_clause, order_by, limit)
  end

  def from(tables)
    SQLParser::Statement::FromClause.new(tables)
  end

  def where(search_condition)
    SQLParser::Statement::WhereClause.new(search_condition)
  end

  def group_by(columns)
    SQLParser::Statement::GroupByClause.new(columns)
  end

  def order_by(sort_spec)
    SQLParser::Statement::OrderBy.new(sort_spec)
  end

  def asc(column)
    SQLParser::Statement::Ascending.new(column)
  end

  def desc(column)
    SQLParser::Statement::Descending.new(column)
  end

  def limit(n)
    SQLParser::Statement::Limit.new(n)
  end
end
