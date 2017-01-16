require File.dirname(__FILE__) + '/../lib/sql-parser'
require 'test/unit'

class TestParser < Test::Unit::TestCase
  def test_current_user
    assert_understands 'SELECT CURRENT_USER'

    # Should be able to differentiate between the variable CURRENT_USER, and a
    # column named either `CURRENT_USER` or `current_user`.
    assert_understands 'SELECT `CURRENT_USER`'
    assert_understands 'SELECT `current_user`'
  end

  def test_delete_from
    assert_understands 'DELETE FROM `users`'
  end

  def test_delete_from_with_where
    assert_understands 'DELETE FROM `users` WHERE `id` = 1'
  end
  
  def test_insert_into_clause
    assert_understands 'INSERT INTO `users` VALUES (1, 2)'
  end
  
  def test_insert_into_clause_quoted
    assert_understands 'INSERT INTO `users` VALUES (`a`, `b`)'
  end
  
  def test_insert_with_quotes
    q =  'INSERT INTO "users" ("active", "created_on", "email", "last_login", "password", "salt", "username") VALUES ("a", "b", "c", "c", "e")'
    q.gsub!(/([^\\])"/) { $1 + '`' }
    puts q.inspect
    assert_understands q
    
  end

  def test_case_insensitivity
    assert_sql 'SELECT * FROM `users` WHERE `id` = 1', 'select * from users where id = 1'
  end

  def test_subquery_in_where_clause
    assert_understands 'SELECT * FROM `t1` WHERE `id` > (SELECT SUM(`a`) FROM `t2`)'
  end

  def test_order_by_constant
    assert_sql 'SELECT * FROM `users` ORDER BY 1 ASC', 'SELECT * FROM users ORDER BY 1'
    assert_understands 'SELECT * FROM `users` ORDER BY 1 ASC'
    assert_understands 'SELECT * FROM `users` ORDER BY 1 DESC'
  end

  def test_order
    assert_sql 'SELECT * FROM `users` ORDER BY `name` ASC', 'SELECT * FROM users ORDER BY name'
    assert_understands 'SELECT * FROM `users` ORDER BY `name` ASC'
    assert_understands 'SELECT * FROM `users` ORDER BY `name` DESC'
  end

  def test_full_outer_join
    assert_understands 'SELECT * FROM `t1` FULL OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a`'
    assert_understands 'SELECT * FROM `t1` FULL OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a` FULL OUTER JOIN `t3` ON `t2`.`a` = `t3`.`a`'
    assert_understands 'SELECT * FROM `t1` FULL OUTER JOIN `t2` USING (`a`)'
    assert_understands 'SELECT * FROM `t1` FULL OUTER JOIN `t2` USING (`a`) FULL OUTER JOIN `t3` USING (`b`)'
  end

  def test_full_join
    assert_understands 'SELECT * FROM `t1` FULL JOIN `t2` ON `t1`.`a` = `t2`.`a`'
    assert_understands 'SELECT * FROM `t1` FULL JOIN `t2` ON `t1`.`a` = `t2`.`a` FULL JOIN `t3` ON `t2`.`a` = `t3`.`a`'
    assert_understands 'SELECT * FROM `t1` FULL JOIN `t2` USING (`a`)'
    assert_understands 'SELECT * FROM `t1` FULL JOIN `t2` USING (`a`) FULL JOIN `t3` USING (`b`)'
  end

  def test_right_outer_join
    assert_understands 'SELECT * FROM `t1` RIGHT OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a`'
    assert_understands 'SELECT * FROM `t1` RIGHT OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a` RIGHT OUTER JOIN `t3` ON `t2`.`a` = `t3`.`a`'
    assert_understands 'SELECT * FROM `t1` RIGHT OUTER JOIN `t2` USING (`a`)'
    assert_understands 'SELECT * FROM `t1` RIGHT OUTER JOIN `t2` USING (`a`) RIGHT OUTER JOIN `t3` USING (`b`)'
  end

  def test_right_join
    assert_understands 'SELECT * FROM `t1` RIGHT JOIN `t2` ON `t1`.`a` = `t2`.`a`'
    assert_understands 'SELECT * FROM `t1` RIGHT JOIN `t2` ON `t1`.`a` = `t2`.`a` RIGHT JOIN `t3` ON `t2`.`a` = `t3`.`a`'
    assert_understands 'SELECT * FROM `t1` RIGHT JOIN `t2` USING (`a`)'
    assert_understands 'SELECT * FROM `t1` RIGHT JOIN `t2` USING (`a`) RIGHT JOIN `t3` USING (`b`)'
  end

  def test_left_outer_join
    assert_understands 'SELECT * FROM `t1` LEFT OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a`'
    assert_understands 'SELECT * FROM `t1` LEFT OUTER JOIN `t2` ON `t1`.`a` = `t2`.`a` LEFT OUTER JOIN `t3` ON `t2`.`a` = `t3`.`a`'
    assert_understands 'SELECT * FROM `t1` LEFT OUTER JOIN `t2` USING (`a`)'
    assert_understands 'SELECT * FROM `t1` LEFT OUTER JOIN `t2` USING (`a`) LEFT OUTER JOIN `t3` USING (`b`)'
  end

  def test_left_join
    assert_understands 'SELECT * FROM `t1` LEFT JOIN `t2` ON `t1`.`a` = `t2`.`a`'
    assert_understands 'SELECT * FROM `t1` LEFT JOIN `t2` ON `t1`.`a` = `t2`.`a` LEFT JOIN `t3` ON `t2`.`a` = `t3`.`a`'
    assert_understands 'SELECT * FROM `t1` LEFT JOIN `t2` USING (`a`)'
    assert_understands 'SELECT * FROM `t1` LEFT JOIN `t2` USING (`a`) LEFT JOIN `t3` USING (`b`)'
  end

  def test_inner_join
    assert_understands 'SELECT * FROM `t1` INNER JOIN `t2` ON `t1`.`a` = `t2`.`a`'
    assert_understands 'SELECT * FROM `t1` INNER JOIN `t2` ON `t1`.`a` = `t2`.`a` INNER JOIN `t3` ON `t2`.`a` = `t3`.`a`'
    assert_understands 'SELECT * FROM `t1` INNER JOIN `t2` USING (`a`)'
    assert_understands 'SELECT * FROM `t1` INNER JOIN `t2` USING (`a`) INNER JOIN `t3` USING (`b`)'
  end

  def test_cross_join
    assert_understands 'SELECT * FROM `t1` CROSS JOIN `t2`'
    assert_understands 'SELECT * FROM `t1` CROSS JOIN `t2` CROSS JOIN `t3`'
  end

  # The expression
  #   SELECT * FROM t1, t2
  # is just syntactic sugar for
  #   SELECT * FROM t1 CROSS JOIN t2
  def test_cross_join_syntactic_sugar
    assert_sql 'SELECT * FROM `t1` CROSS JOIN `t2`', 'SELECT * FROM t1, t2'
    assert_sql 'SELECT * FROM `t1` CROSS JOIN `t2` CROSS JOIN `t3`', 'SELECT * FROM t1, t2, t3'
  end

  def test_having
    assert_understands 'SELECT * FROM `users` HAVING `id` = 1'
  end

  def test_group_by
    assert_understands 'SELECT * FROM `users` GROUP BY `name`'
    assert_understands 'SELECT * FROM `users` GROUP BY `users`.`name`'
    assert_understands 'SELECT * FROM `users` GROUP BY `name`, `id`'
    assert_understands 'SELECT * FROM `users` GROUP BY `users`.`name`, `users`.`id`'
  end

  def test_or
    assert_understands 'SELECT * FROM `users` WHERE (`id` = 1 OR `age` = 18)'
  end

  def test_and
    assert_understands 'SELECT * FROM `users` WHERE (`id` = 1 AND `age` = 18)'
  end

  def test_not
    assert_sql 'SELECT * FROM `users` WHERE `id` <> 1', 'SELECT * FROM users WHERE NOT id = 1'
    assert_sql 'SELECT * FROM `users` WHERE `id` NOT IN (1, 2, 3)', 'SELECT * FROM users WHERE NOT id IN (1, 2, 3)'
    assert_sql 'SELECT * FROM `users` WHERE `id` NOT BETWEEN 1 AND 3', 'SELECT * FROM users WHERE NOT id BETWEEN 1 AND 3'
    assert_sql "SELECT * FROM `users` WHERE `name` NOT LIKE 'A%'", "SELECT * FROM users WHERE NOT name LIKE 'A%'"

    # Shouldn't negate subqueries
    assert_understands 'SELECT * FROM `users` WHERE NOT EXISTS (SELECT `id` FROM `users` WHERE `id` = 1)'
  end

  def test_not_exists
    assert_understands 'SELECT * FROM `users` WHERE NOT EXISTS (SELECT `id` FROM `users`)'
  end

  def test_exists
    assert_understands 'SELECT * FROM `users` WHERE EXISTS (SELECT `id` FROM `users`)'
  end

  def test_is_not_null
    assert_understands 'SELECT * FROM `users` WHERE `deleted_at` IS NOT NULL'
  end

  def test_is_null
    assert_understands 'SELECT * FROM `users` WHERE `deleted_at` IS NULL'
  end

  def test_not_like
    assert_understands "SELECT * FROM `users` WHERE `name` NOT LIKE 'Joe%'"
  end

  def test_like
    assert_understands "SELECT * FROM `users` WHERE `name` LIKE 'Joe%'"
  end

  def test_not_in
    assert_understands 'SELECT * FROM `users` WHERE `id` NOT IN (1, 2, 3)'
    assert_understands 'SELECT * FROM `users` WHERE `id` NOT IN (SELECT `id` FROM `users` WHERE `age` = 18)'
  end

  def test_in
    assert_understands 'SELECT * FROM `users` WHERE `id` IN (1, 2, 3)'
    assert_understands 'SELECT * FROM `users` WHERE `id` IN (SELECT `id` FROM `users` WHERE `age` = 18)'
  end

  def test_not_between
    assert_understands 'SELECT * FROM `users` WHERE `id` NOT BETWEEN 1 AND 3'
  end

  def test_between
    assert_understands 'SELECT * FROM `users` WHERE `id` BETWEEN 1 AND 3'
  end

  def test_gte
    assert_understands 'SELECT * FROM `users` WHERE `id` >= 1'
  end

  def test_lte
    assert_understands 'SELECT * FROM `users` WHERE `id` <= 1'
  end

  def test_gt
    assert_understands 'SELECT * FROM `users` WHERE `id` > 1'
  end

  def test_lt
    assert_understands 'SELECT * FROM `users` WHERE `id` < 1'
  end

  def test_not_equals
    assert_sql 'SELECT * FROM `users` WHERE `id` <> 1', 'SELECT * FROM users WHERE id != 1'
    assert_understands 'SELECT * FROM `users` WHERE `id` <> 1'
  end

  def test_equals
    assert_understands 'SELECT * FROM `users` WHERE `id` = 1'
  end

  def test_where_clause
    assert_understands 'SELECT * FROM `users` WHERE 1 = 1'
  end

  def test_sum
    assert_understands 'SELECT SUM(`messages_count`) FROM `users`'
  end

  def test_min
    assert_understands 'SELECT MIN(`age`) FROM `users`'
  end

  def test_max
    assert_understands 'SELECT MAX(`age`) FROM `users`'
  end

  def test_avg
    assert_understands 'SELECT AVG(`age`) FROM `users`'
  end

  def test_count
    assert_understands 'SELECT COUNT(*) FROM `users`'
    assert_understands 'SELECT COUNT(`id`) FROM `users`'
  end

  def test_from_clause
    assert_understands 'SELECT 1 FROM `users`'
    assert_understands 'SELECT `id` FROM `users`'
    assert_understands 'SELECT `users`.`id` FROM `users`'
    assert_understands 'SELECT * FROM `users`'
  end

  def test_select_list
    assert_understands 'SELECT 1, 2'
    assert_understands 'SELECT (1 + 1) AS `x`, (2 + 2) AS `y`'
    assert_understands 'SELECT `id`, `name`'
    assert_understands 'SELECT (`age` * 2) AS `double_age`, `first_name` AS `name`'
  end

  def test_as
    assert_understands 'SELECT 1 AS `x`'
    assert_sql 'SELECT 1 AS `x`', 'SELECT 1 x'

    assert_understands 'SELECT (1 + 1) AS `y`'
    assert_sql 'SELECT (1 + 1) AS `y`', 'SELECT (1 + 1) y'

    assert_understands 'SELECT * FROM `users` AS `u`'
    assert_sql 'SELECT * FROM `users` AS `u`', 'SELECT * FROM users u'
  end

  def test_parentheses
    assert_sql 'SELECT ((1 + 2) * ((3 - 4) / 5))', 'SELECT (1 + 2) * (3 - 4) / 5'
  end

  def test_order_of_operations
    assert_sql 'SELECT (1 + ((2 * 3) - (4 / 5)))', 'SELECT 1 + 2 * 3 - 4 / 5'
  end

  def test_numeric_value_expression
    assert_understands 'SELECT (1 * 2)'
    assert_understands 'SELECT (1 / 2)'
    assert_understands 'SELECT (1 + 2)'
    assert_understands 'SELECT (1 - 2)'
  end

  def test_quoted_identifier
    assert_sql 'SELECT `a`', 'SELECT `a`'
  end

  def test_date
    assert_sql "SELECT DATE '2008-07-11'", 'SELECT DATE "2008-07-11"'
    assert_understands "SELECT DATE '2008-07-11'"
  end

  def test_quoting
    assert_sql %{SELECT ''}, %{SELECT ""}
    assert_understands %{SELECT ''}

    assert_sql %{SELECT 'Quote "this"'}, %{SELECT "Quote ""this"""}
    assert_understands %{SELECT 'Quote ''this!'''}

    # # FIXME
    # assert_sql %{SELECT '"'}, %{SELECT """"}
    # assert_understands %{SELECT ''''}
  end

  def test_string
    assert_sql "SELECT 'abc'", 'SELECT "abc"'
    assert_understands "SELECT 'abc'"
  end

  def test_approximate_numeric_literal
    assert_understands 'SELECT 1E1'
    assert_understands 'SELECT 1E+1'
    assert_understands 'SELECT 1E-1'

    assert_understands 'SELECT +1E1'
    assert_understands 'SELECT +1E+1'
    assert_understands 'SELECT +1E-1'

    assert_understands 'SELECT -1E1'
    assert_understands 'SELECT -1E+1'
    assert_understands 'SELECT -1E-1'

    assert_understands 'SELECT 1.5E30'
    assert_understands 'SELECT 1.5E+30'
    assert_understands 'SELECT 1.5E-30'

    assert_understands 'SELECT +1.5E30'
    assert_understands 'SELECT +1.5E+30'
    assert_understands 'SELECT +1.5E-30'

    assert_understands 'SELECT -1.5E30'
    assert_understands 'SELECT -1.5E+30'
    assert_understands 'SELECT -1.5E-30'
  end

  def test_signed_float
    # Positives
    assert_sql 'SELECT +1', 'SELECT +1.'
    assert_sql 'SELECT +0.1', 'SELECT +.1'

    assert_understands 'SELECT +0.1'
    assert_understands 'SELECT +1.0'
    assert_understands 'SELECT +1.1'
    assert_understands 'SELECT +10.1'

    # Negatives
    assert_sql 'SELECT -1', 'SELECT -1.'
    assert_sql 'SELECT -0.1', 'SELECT -.1'

    assert_understands 'SELECT -0.1'
    assert_understands 'SELECT -1.0'
    assert_understands 'SELECT -1.1'
    assert_understands 'SELECT -10.1'
  end

  def test_unsigned_float
    assert_sql 'SELECT 1', 'SELECT 1.'
    assert_sql 'SELECT 0.1', 'SELECT .1'

    assert_understands 'SELECT 0.1'
    assert_understands 'SELECT 1.0'
    assert_understands 'SELECT 1.1'
    assert_understands 'SELECT 10.1'
  end

  def test_signed_integer
    assert_understands 'SELECT +1'
    assert_understands 'SELECT -1'
  end

  def test_unsigned_integer
    assert_understands 'SELECT 1'
    assert_understands 'SELECT 10'
  end

  private

  def assert_sql(expected, given)
    assert_equal expected, SQLParser::Parser.parse(given).to_sql
  end

  def assert_understands(sql)
    assert_sql(sql, sql)
  end
end
