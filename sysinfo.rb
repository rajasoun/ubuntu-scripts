#!/usr/bin/env ruby

require 'forwardable'

module Sysinfo
  class RamInfo

    def total
      @total ||= @raw.match(/MemTotal:\s*(\d+)/)[1].to_i
    end

    def free
      @free ||= @raw.match(/MemFree:\s*(\d+)/)[1].to_i
    end

    def used
      total - free
    end

    def ram_utilization
      (used.to_f/ total * 100).to_i
    end

    def used_megs
      used / 1024
    end

    def total_megs
      total / 1024
    end

    def initialize
      @raw = `cat /proc/meminfo`
    end
  end

  class UptimeInfo
    def up_days
      time[1] || 0
    end

    def up_hours
      time[2]
    end

    def up_minutes
      time[3]
    end

    def time
      @up ||= raw.sub(/.+\sup/, '').match(/(?:(\d+)\s+days?,)?\s*(\d+):(\d+)/)
    end

    def load3
      load_avg[2]
    end

    def load_avg
      @load_avg ||= raw.sub(/.+average:/, '').scan(/\d+\.\d+/)
    end

    # sample: 11:31:42 up 154 days, 16:54,  1 user,  load average: 0.02, 0.05, 0.02
    def initialize
      @raw ||= `uptime`
    end
    attr_reader :raw
  end

  class LoginInfo
    def initialize
      @users = `users`
    end

    def logged_users_num
      @users.strip.split("\n").length
    end
  end

  class DiskInfo
    attr_accessor :raw

    def initialize(mount_point)
      @raw = `df -m #{mount_point}`.strip.split("\n").last
    end

    def used
      raw.split(/\s+/)[2].to_i
    end

    def total
      raw.split(/\s+/)[1].to_i
    end

    %w[used total].each do |m|
      define_method "#{m}_gb" do
        send(m) / 1024.0
      end
    end

    def utilization
      raw.match(/\d+%/)
    end
  end

  class Report
    extend Forwardable
    def_delegators :@ram_info, :used_megs, :total_megs, :ram_utilization
    def_delegators :@uptime, :up_days, :up_hours, :up_minutes, :load3
    def_delegators :@login, :logged_users_num

    def initialize
      @ram_info = RamInfo.new
      @uptime = UptimeInfo.new
      @login = LoginInfo.new
      @disk_tmp = DiskInfo.new('/tmp')
    end

    %w[tmp_used_gb tmp_total_gb tmp_utilization].each do |m|
      define_method m do
        @disk_tmp.send(m.sub('tmp_', ''))
      end
    end

    def date
      Time.now.strftime('%d/%m/%y')
    end

    def time
      Time.now.strftime('%T')
    end

    def hostname
      `hostname`.strip
    end

    def text
      "----------------------- System Report ---------------------------------------\n" +
      "Date: #{date}		Time: #{time}		System Name: #{hostname}\n" +
      "-----------------------------------------------------------------------------\n" +
      "Uptime: #{up_days} days, #{up_hours} hours, #{up_minutes} minutes\n" +
      "Memory Usage: #{used_megs}/#{total_megs}MB (#{ram_utilization}%)		Disk Usage: #{'%0.1f' % tmp_used_gb}/#{'%0.1f' % tmp_total_gb}GB (#{tmp_utilization})\n" +
      "Current Users: #{logged_users_num}				CPU Load: #{load3}\n" +
      "------------------------- End Report ----------------------------------------\n"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  puts Sysinfo::Report.new.text
end
