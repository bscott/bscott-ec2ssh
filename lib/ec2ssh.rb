require 'etc'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/kernel/reporting'
require 'colorize'
require 'highline/import'
require 'text-table'
silence_warnings { require 'aws' }
require 'yaml'
require 'fileutils'

module Ec2ssh

  class UnavailableEC2Credentials < StandardError; end

  class App

    def initialize(file = "~/.ec2ssh", account=:default)
      @config = read_aws_config(file, account)
    end

    def select_instance(instances=[])
      # TODO: Ansi colors https://github.com/JEG2/highline/blob/master/examples/ansi_colors.rb
      instances = get_all_ec2_instances
      table_rows = []

      instances.each do |i|
        if i[:aws_state] == "running"
          table_rows << ['', i[:tags]["Name"].blank? ? '' : i[:tags]["Name"], i[:aws_instance_id], i[:aws_groups].join(','), i[:ssh_key_name], i[:aws_private_ip_address], i[:dns_name], i[:architecture], i[:aws_instance_type]]
        end
      end

      # sort tables by tag name
      table_rows.sort! do |a, b|
        a[1] <=> b[1]
      end

      # give them numbers
      table_rows.count.times do |i|
        table_rows[i][0] = i + 1
      end

      table_header = ['', 'Name', 'Instance ID', 'SecGroup', 'Key', 'Internal IP', 'Public DNS', 'Arch', 'Type']

      table = Text::Table.new :rows => table_rows, :head => table_header

      # output table
      puts table

      input = ask(">>  ")
      options = input.split

      # check if last arg is 'public' or 'private'. If so remove it from the options stack and save the value
      pub_priv_override = ''
      if options[-1] =~ /public|private/
        pub_priv_override = options.pop
      end

      input_host = options[0]
      input_user = options[1]
      input_key  = options[2]

      if input_host =~ /^\d+$/
        host = table_rows[input_host.to_i - 1]
      else
        host = table_rows.find { |h| h[1] == input_host }
      end

      host_ssh_key    = host[4]
      host_private_ip = host[5]
      host_public_dns = host[6]

      default_user = @config[:default_user] || Etc.getlogin

      template = @config[:template] || "ssh #{default_user}@<public_dns>"

      # if we have a public or private ip override, replace the template variable
      unless pub_priv_override.blank?
        case pub_priv_override
        when 'public'
          template.gsub!("<private_ip>", "<public_dns>")
        when 'private'
          template.gsub!("<public_dns>", "<private_ip>")
        end
      end

      # <instance> remains for compatibility with upstream
      command = template.gsub("<instance>", host_public_dns).
                         gsub("<public_dns>", host_public_dns).
                         gsub("<private_ip>", host_private_ip)

      # interpolate ssh user
      if input_user.blank?
        command.gsub!("<user>", default_user)
      else
        command.gsub!("<user>", input_user)
      end

      # interpolate ssh key
      if input_key.blank?
        command.gsub!("<key>", "")
      else
        command.gsub!("<key>", "-i ~/.ssh/#{input_key}.pem")
      end

      puts "!!! #{command}"
      exec(command)
    end

    private

    def read_aws_config(file, account=:default)
      file = File.expand_path(file)
      accounts = YAML::load(File.open(file))
      selected_account = accounts[account] || accounts.first[1]
    rescue Errno::ENOENT
      puts "ec2ssh config file doesn't exist. Creating a new ~/.ec2ssh. Please review it customize it."
      sample_config_file = File.join(File.dirname(__FILE__), "templates/ec2ssh_config_sample.yaml")
      FileUtils.cp sample_config_file, File.expand_path("~/.ec2ssh")
      exit
    end

    def get_all_ec2_regions
      %w(eu-west-1 us-east-1 ap-northeast-1 us-west-1 ap-southeast-1)
    end

    def get_all_ec2_instances
      id = @config[:id]
      key = @config[:key]
      regions ||= @config[:regions] || get_all_ec2_regions
      instances = regions.map do |region|
        silence_stream STDOUT do
          Aws::Ec2.new(id, key, :region => region).describe_instances
        end
      end.flatten
    rescue Aws::AwsError => e
      abort "AWS Error. #{e.message}"
    end

  end

end
