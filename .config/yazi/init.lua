local ok, sshfs = pcall(require, "sshfs")

if ok then
	sshfs:setup()
end
