require_relative 'lib/sql-parser/version'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

GENERATED_PARSER = 'lib/sql-parser/parser.racc.rb'
GENERATED_LEXER = 'lib/sql-parser/parser.rex.rb'

file GENERATED_LEXER => 'lib/sql-parser/parser.rex' do |t|
  sh "rex -o #{t.name} #{t.prerequisites.first}"
end

file GENERATED_PARSER => 'lib/sql-parser/parser.racc' do |t|
  sh "racc -o #{t.name} #{t.prerequisites.first}"
end

task :parser => [GENERATED_LEXER, GENERATED_PARSER]

# Make sure the parser's up-to-date when we test.
Rake::Task['test'].prerequisites << :parser
