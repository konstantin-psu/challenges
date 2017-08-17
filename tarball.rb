require 'fileutils'

module Bundle
  class Logs
    def self.bundle(options, test_source = '')
      temp = 'logs'
      options.each do | opts |
        Log.new(opts, test_source).gather
      end

      # the temp dir won't be created if all source directories are empty
      if File.exist?(temp)
        # assuming we are running on a Unix like system
        # create tarball and remove temp dir
        system "tar -czf logs.tar.gz #{temp} && rm -rf #{temp}"
      end
    end
  end

  class Log
    def initialize(options, test_source = '')
      # if a required option is not defined we will throw, but it's ok since all of the options are required
      @location_dir = test_source + options[:source_dir]
      @destination_dir = File.join(Dir.pwd, 'logs', options[:destination_dir])
      @files = options[:files]
    end

    # Gather required files to the local logs dir
    # Assumptions:
    #  We have enough space on the disk
    #  Log files are readable and not locked
    #  Destination directory is writable
    #
    #  If any of the assumptions is violated this script will fail

    # if the location dir is not a dir it will be skipped
    def gather
      if File.exist?(@location_dir) && File.directory?(@location_dir)
        if Dir.glob(File.join(@location_dir, '*')).size > 0 # avoid creating the dest directory if the source dir is empty
          unless File.exists? @destination_dir
            FileUtils.mkpath @destination_dir
          end
          @files.each do |f|
            Dir.glob(File.join(@location_dir, f)).each do |file|
              FileUtils.cp_r file, @destination_dir
            end
          end
        end
      else
        puts "Error: #{@location_dir}, doesn't exist or not a directory"
      end
    end
  end
end

# Although the script is not crossplatform
#   Having such options allowes to tarball arbitrary files on the system and with minimal changes can be adopted to
#   different distros
#

options = [
  {source_dir: '/var/log',       files: %w(auth.log* dmesg* syslog*), destination_dir: 'system-logs'},
  {source_dir: '/var/log/nginx', files: %w(*)                       , destination_dir: 'web-logs'},
  {source_dir: '/var/log/mysql', files: %w(*)                       , destination_dir: 'database-logs'}
]

# Since I don't have mysql and nginx installed I created a simple test directory layout
# in my home dir, if it doesn't exist regular /var/log will be used

# Test dir layout:
#
# var
# └── log
# ├── auth.log
# ├── auth.log.1
# ├── auth.log.2.gz
# ├── auth.log.3.gz
# ├── auth.log.4.gz
# ├── dmesg
# ├── dmesg.0
# ├── dmesg.1.gz
# ├── dmesg.2.gz
# ├── dmesg.3.gz
# ├── dmesg.4.gz
# ├── mysql
# │   ├── log
# │   │   └── testlog
# │   └── mysql.log
# ├── nginx
# │   ├── access.log
# │   └── error.log
# ├── syslog
# ├── syslog.1
# ├── syslog.2.gz
# ├── syslog.3.gz
# ├── syslog.4.gz
# ├── syslog.5.gz
# ├── syslog.6.gz
# └── syslog.7.gz

test_source = File.exist?(File.join(Dir.home(), 'var', 'log')) ? Dir.home() : ''
Bundle::Logs.bundle(options, test_source)
