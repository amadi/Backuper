require 'net/ftp'
require 'yaml'

class Backuper
	attr_accessor :files, :folders, :addr, :size
	def initialize(addr, login, pw, root_dir)
		@addr, @login, @pw, @root_dir = addr, login, pw, root_dir
		@folders = Array.new
		@files = Hash.new
		@size = 0
	end

	def listFolders(dir = @root_dir)
		@ftp.chdir(dir)
		@regexp = %r{(?<isDir>.{1})(?<mode>.{9})\s+(?<links>\d+)\s+(?<owner>\w+)\s+(?<group>\w+)\s+(?<size>\d+)\s+(?<modifed>\w+\s+\d+\s+\d{2}:\d{2})\s(?<name>.+)}x
		@ftp.ls("-al").each do |item|
			r = @regexp.match(item)
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
	ftp = Backuper.new(field["host"], field["login"], field["pw"], field["root_dir"])
	ftp.connect

	#get dirs of ftp
	ftp.listFolders
	puts "Request directories of #{ftp.addr}"
	ftp.folders.each {|folder| ftp.listFolders(folder)}
	puts "Count of folders: #{ftp.folders.length}"

	#get files
	size = 0
	puts "Files count: #{ftp.files.length}, total size: #{ftp.size/1024} Kb"


	ftp.close
end