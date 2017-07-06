require 'dotenv'

Dotenv.load File.join(File.dirname(File.dirname(__dir__)), '.env')

execute 'curl -s https://packagecloud.io/install/repositories/linyows/octopass/script.rpm.sh | sudo bash' do
  not_if 'rpm -q octopass-0.3.2-1.x86_64'
end
package 'octopass-0.3.2-1.x86_64'

template '/etc/octopass.conf' do
  owner 'root'
  group 'root'
  mode '644'
  variables(
      endpoint: node['octopass']['endpoint'],
      token: ENV['GITHUB_TOKEN_FOR_OCTOPASS'],
      organization: node['octopass']['organization'],
      team: node['octopass']['team']
  )
end

remote_file '/etc/sudoers.d/operators' do
  owner 'root'
  group 'root'
  mode '440'
end

[
    {
        filename: '/etc/ssh/sshd_config',
        gsub_list: [
            {
                pattern: /^AuthorizedKeysCommand\s+\S+$/,
                replacement: 'AuthorizedKeysCommand /usr/bin/octopass'
            },
            {
                pattern: /^AuthorizedKeysCommandUser\s+\S+$/,
                replacement: 'AuthorizedKeysCommandUser root'
            },
            {
                pattern: /^UsePAM\s+\S+$/,
                replacement: 'UsePAM yes'
            },
            {
                pattern: /^PasswordAuthentication\s+\S+$/,
                replacement: 'PasswordAuthentication no'
            }
        ]
    },
    {
        filename: '/etc/nsswitch.conf',
        gsub_list: [
            {
                pattern: /^passwd:\s+\S+.+$/,
                replacement: "passwd:\tfiles octopass sss"
            },
            {
                pattern: /^shadow:\s+\S+.+$/,
                replacement: "shadow:\tfiles octopass sss"
            },
            {
                pattern: /^group:\s+\S+.+$/,
                replacement: "group:\tfiles octopass sss"
            }
        ]
    },
    {
        filename: '/etc/pam.d/system-auth-ac',
        gsub_list: [
            {
                pattern: /^.*auth\s+sufficient\s+pam_unix.so nullok try_first_pass$/,
                replacement: "# auth\tsufficient\tpam_unix.so nullok try_first_pass"
            },
            {
                pattern: /^auth\s+requisite\s+pam_exec.so\squiet\sexpose_authtok\s\/usr\/bin\/octopass\spam$/,
                replacement: "auth\trequisite\tpam_exec.so quiet expose_authtok /usr/bin/octopass pam"
            },
            {
                pattern: /^auth\s+optional\s+pam_unix.so\snot_set_pass\suse_first_pass\snodelay$/,
                replacement: "auth\toptional\tpam_unix.so not_set_pass use_first_pass nodelay"
            }
        ]
    },
    {
        filename: '/etc/pam.d/sshd',
        gsub_list: [
            {
                pattern: /^#\soctopass\nsession\s+required\s+pam_mkhomedir.so\sskel=\/etc\/skel\/\sumask=0022$/,
                replacement: "# octopass\nsession\trequired\tpam_mkhomedir.so skel=/etc/skel/ umask=0022"
            }
        ]
    }
].each do |conf|
  file conf[:filename] do
    action :edit
    block do |content|
      conf[:gsub_list].each do |i|
        content.match(i[:pattern]) ? content.gsub!(i[:pattern], i[:replacement]) : content.concat("\n" + i[:replacement])
      end
    end
    only_if "test -f #{conf[:filename]}"
  end
end
