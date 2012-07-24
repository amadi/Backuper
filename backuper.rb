require 'net/ftp'
require 'yaml'

class Backuper
	attr_accessor :files, :folders
	def initialize(addr, login, pw, root_dir)
		@addr, @login, @pw, @root_dir = addr, login, pw, root_dir
		@folders = Array.new
	end

	def ls
		@files = @ftp.ls("--almost-all")
		@files
	end

	def listFolders(dir = @root_dir)
		@ftp.chdir(dir)
		@regexp = %r{(?<isDir>.{1}).+\d{2}:\d{2}\s(?<name>.+)}x
		@ftp.ls("-al").each do |item|
			r = @regexp.match(item)
			#puts "isDir: #{r[:isDir]}, name: #{r[:name]}"
			if (r[:isDir] == "d") and (r[:name]!='.' and r[:name]!='..')
				@folders.push("#{dir}/#{r[:name]}")
			end
		end
		#puts @folders
	end

	def connect
		puts "\e[30;47mConnecting to #{@addr} as #{@login}\e[0m"
		@ftp = Net::FTP.new(@addr)
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

	ftp.listFolders

	ftp.folders.each {|folder| ftp.listFolders(folder)}
	puts ftp.folders

	ftp.close
end

