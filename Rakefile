# encoding: utf-8

require 'rubygems'
require 'rake'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "anveo-ec2ssh"
  gem.homepage = "http://github.com/anveo/ec2ssh"
  gem.license = "MIT"
  gem.summary = %Q{A script to make it easier to ssh into running amazon EC2 instances.}
  gem.description = %Q{Since ec2 instance public hostnames are dynamic, and not easy to remember or type, this script provides a list all your running instances so you can select the one you want to ssh into easily (without having to pass the aws console ritual each time you need the hostname).}
  gem.email = "bracer@gmail.com"
  gem.authors = ["Ramon Salvadó", "Brian Racer"]
  gem.executables = ["ec2ssh"]
  gem.add_dependency('aws', '>= 2.5.6')
  gem.add_dependency('activesupport', '~> 3.0.0')
  gem.add_dependency('colorize', '0.5.8')
  gem.add_dependency('highline', '>= 1.6.8')
  gem.add_dependency('text-table', '~> 1.2.2')
end
Jeweler::RubygemsDotOrgTasks.new
