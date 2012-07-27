require 'net/ftp'
require 'yaml'
require 'fileutils'

class Backuper
	attr_accessor :files, :folders, :addr, :size, :server
	def initialize(addr, login, pw, root_dir, backup_dir, server)
		@addr, @login, @pw, @root_dir, @backup_dir, @server = addr, login, pw, root_dir, backup_dir, server
		@folders = Array.new
		@files = Hash.new
		@size = 0
	end

	def listFolders(dir = @root_dir)
		@ftp.chdir(dir)
		@regexp = %r{(?<isDir>.{1})(?<mode>.{9})\s+(?<links>\d+)\s+(?<owner>\w+)\s+(?<group>\w+)\s+(?<size>\d+)\s+(?<modifed>\w+\s+\d+\s+\S+)\s(?<name>.+)}x
		@ftp.ls("-al").each do |item|
			r = @regexp.match(item)
			if r[:isDir]=='l' then next end
			if (r[:isDir] == "d") and (r[:name]!='.' and r[:name]!='..')
				@folders.push("#{dir}/#{r[:name]}")
			end
			if r[:isDir] != "d"
				@size = @size + r[:size].to_i
				file = { "#{dir}/#{r[:name]}" => { "filename" => r[:name], "size" => r[:size], "modifed" => r[:modifed] } }
				@files.merge!(file)
			end
		end
	end

	def backup
		time = Time.new
		dir = "#{@backup_dir}/#{@server}/#{time.day}_#{time.month}_#{time.year}"
		FileUtils.mkdir_p(dir)
		FileUtils.mkdir_p("#{dir}#{@root_dir}")
		@folders.each do |item|
			FileUtils.mkdir("#{dir}#{item}")
		end
		downloaded_summary = 0
		i=0
		@files.each do |key, value|
			downloaded = 0
			i=i+1
			@ftp.getbinaryfile( key, "#{dir}#{key}", 128) do |blk|
  				downloaded = downloaded + 128
  				printf("\rfile #{i}(#{(value['size'].to_i) / 1024}Kb) of #{@files.length}.  Downloaded: #{(downloaded_summary) / 1024} Kb     ")
    			$stdout.flush
  			end
  			downloaded_summary = downloaded_summary+value['size'].to_i
		end
		puts ''
		puts "#{@server} backup complete!"
	end

	def connect
		puts "\e[30;47mConnecting to #{@addr} as #{@login}\e[0m"
		@ftp = Net::FTP.new(@addr)
		@ftp.passive = true
		@ftp.login(@login,@pw)
		@ftp.chdir(@root_dir)
		puts "\e[32mSuccess!\e[0m"
	end

	def	close
		@ftp.close
		puts "\e[30;47mConnection closed\e[0m"
	end
end


YAML::ENGINE.yamler = 'syck'
servers = begin
	YAML.load_file('ftp.yml')
rescue ArgumentError => e
	puts "Could not parse ftp.yml file. #{e.message}"
end

servers.each do |server, field|
	ftp = Backuper.new(field["host"], field["login"], field["pw"], field["root_dir"], field['backup_dir'], server)
	ftp.connect

	#get dirs of ftp
	ftp.listFolders
	puts "Request directories of #{ftp.addr}"
	ftp.folders.each do |folder|
		ftp.listFolders(folder)
	end
	puts "Count of folders: #{ftp.folders.length}"

	#get files
	size = 0
	puts "Files count: #{ftp.files.length}, total size: #{ftp.size/1024} Kb"

	ftp.backup

	ftp.close
end