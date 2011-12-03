#!/usr/bin/env ruby
require 'readline'

while line = Readline.readline('> ', true)
  return exit  if line =~ /^q|quit|exit$/
  system("ruby rpassmgr.rb #{line}")
end
