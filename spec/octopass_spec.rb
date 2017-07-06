describe package('octopass') do
  it { should be_installed }
end

describe 'file permission' do
  files = [
      { path: '/etc/octopass.conf', mode: 644, owner: 'root', group: 'root' },
      { path: '/etc/sudoers.d/operators', mode: 440, owner: 'root', group: 'root' }
  ]
  
  files.each do |f|
    describe file(f[:path]) do
      it { should be_file }
      it { should be_mode f[:mode] }
      it { should be_owned_by f[:owner] }
      it { should be_grouped_into f[:group] }
    end
  end
end

[{
     path: '/etc/ssh/sshd_config',
     patterns: [
         /^AuthorizedKeysCommand\s+\/usr\/bin\/octopass$/,
         /^AuthorizedKeysCommandUser\s+root$/,
         /^UsePAM\s+yes$/,
         /^PasswordAuthentication\s+no$/,
     ]
 },
 {
     path: '/etc/nsswitch.conf',
     patterns: [
         /^passwd:\s+files\soctopass\ssss$/,
         /^shadow:\s+files\soctopass\ssss$/,
         /^group:\s+files\soctopass\ssss$/,
     ]
 },
 {
     path: '/etc/pam.d/system-auth-ac',
     patterns: [
         /^#\sauth\s+sufficient\s+pam_unix.so\snullok\stry_first_pass$/,
         /^auth\s+requisite\s+pam_exec.so\squiet\sexpose_authtok\s\/usr\/bin\/octopass\spam$/,
         /^auth\s+optional\s+pam_unix.so\snot_set_pass\suse_first_pass\snodelay$/,
     ]
 },
 {
     path: '/etc/pam.d/sshd',
     patterns: [
         /^#\soctopass\nsession\trequired\tpam_mkhomedir.so\sskel=\/etc\/skel\/\s+umask=0022$/
     ]
 }].each do |f|
  describe file(f[:path]) do
    f[:patterns].each do |pattern|
      its(:content) { should match(pattern) }
    end
  end
end
