#!/usr/bin/env ruby

# rpass list => list groups
# rpass add <name> => add group
# rpass del <name> => delete group
# rpass <group> list => list passwords
# rpass <group> add <name> => add password
# rpass <group> del <name> => delete password
# rpass <group> show <name> => display password

require 'rubygems'
require 'yaml'
require 'aes'

class RPassCmd
  def initialize dir, cmd
    @rpass = RPass.new(dir)
    case cmd[0]
    when 'list'
      @rpass.list_groups
    when 'add'
      @rpass.add_group cmd[1]
    when 'del'
      @rpass.del_group cmd[1]
    else
      case cmd[1]
      when 'list'
        @rpass.list_passwords cmd[0]
      when 'add'
        @rpass.add_password cmd[0], cmd[2]
      when 'del'
        @rpass.del_password cmd[0], cmd[2]
      when 'show'
        @rpass.show_password cmd[0], cmd[2]
      end
    end
  end
end


class RPass
  KEY_DIR = File.join(ENV["HOME"], ".rpassmgr")
  def initialize key_dir = KEY_DIR
    @key_dir = key_dir
    Dir.mkdir(@key_dir)  if !File.exist?(@key_dir)
  end

  def list_groups
    Dir.entries(@key_dir).each do |entry|
      next  if entry =~ /^\./
      puts entry.sub(/\.yml$/, '')
    end
  end

  def add_group name
    pass = ask("Password for group #{name}")
    write_group name, {}, pass
  end

  def del_group name
    File.delete(File.join(@key_dir, "#{name}.yml"))
  end

  def list_passwords group
    pass = ask("Password for group #{group}")
    passwords = read_group(group, pass)
    puts *passwords.keys
  end

  def add_password group, name
    pass = ask("Password for group #{group}")
    passwords = read_group(group, pass)
    newpass = ask("Password #{name}")
    newpass2 = ask("Password #{name}")
    if newpass == newpass2
      passwords[name] = newpass
      write_group(group, passwords, pass)
    else
      puts "Passwords don't match!"
    end
  end

  def del_password group, name
    pass = ask("Password for group #{group}")
    passwords = read_group(group, pass)
    passwords.delete(name)
    write_group(group, passwords, pass)
  end

  def show_password group, name
    pass = ask("Password for group #{group}")
    passwords = read_group(group, pass)
    STDOUT.sync = true
    pw = passwords[name]
    print pw
    STDOUT.flush
    sleep 10
    print "\r" + " " * pw.length + "\r"
    STDOUT.flush
  end

  private

  def read_group name, pass
    encrypted = File.open(File.join(@key_dir, "#{name}.yml")).read
    yaml = AES::AES.new(pass).decrypt(encrypted)
    YAML::load(yaml)
  end

  def write_group name, data, pass
    File.open(File.join(@key_dir, "#{name}.yml"), 'w') do |file|
      encrypted = AES::AES.new(pass).encrypt(data.to_yaml)
      file.write encrypted
    end
  end

  def ask desc = "Password"
    print "#{desc}: "
    system "stty -echo"
    pass = STDIN.gets
    system "stty echo"
    puts
    pass.strip
  end

end




RPassCmd.new(File.join(ENV["HOME"], ".rpass"), ARGV)

