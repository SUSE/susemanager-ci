#! /bin/usr/ruby

obs_branch = ARGV[0]

def ck_pkgs_build_failed(obs_branch)
  ckfailed = "osc -v -A https://api.suse.de pr #{obs_branch} -s F"
  failed = `#{ckfailed}`
  puts 'RPM Packages that were FAILED are:'
  puts failed
  puts
end

def ck_pkgs_build_status(obs_branch)
  ckst = "osc -v -A https://api.suse.de pr #{obs_branch}"
  `#{ckst}`
end

def print_overall_status(status)
  puts 'status overall of'
  puts  status
  puts
end

# main check
loop do
  # loop until we do not find building
  ck_pkgs_build_failed(obs_branch)
  # check if the pr is building
  status = ck_pkgs_build_status(obs_branch)
  # break when we publish all_pkgs
  break if status.include? '(published)'
  print_overall_status(status)
  # sleep for 2 min
  puts 'Project is still building sleeping 120'
  sleep 120
  STDOUT.flush
end
