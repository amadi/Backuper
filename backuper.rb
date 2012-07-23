require 'net/ftp'

#print "FTP: "
addr=gets

#print "Login: "
login=gets

#print "Password: "
pw=sets

ftp = Net::FTP.new(addr)
ftp.login(login,pw)

files = ftp.nlst


puts "keys of hash \"files\": "
for key in 0...files.length
	print "key  : ", files[key], "\n"
end
puts "List of files in current dir:"
puts files

ftp.close
