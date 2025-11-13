// Default to uyuni

domain = ""
if (params.platform_localisation == "NUE") {
  domain = "mgr.suse.de"
} else if (params.platform_localisation == "SLC") {
  domain = "mgr.slc1.suse.org"
} else {
  print("Platform not supporeted");
  sh "exit 1"
}
server_release_package = '000product:Uyuni-Server-release'
proxy_release_package = '000product:Uyuni-Proxy-release'
pull_request_repo = 'https://github.com/uyuni-project/uyuni.git'
builder_api = 'https://api.opensuse.org'
build_url = 'https://build.opensuse.org'
builder_project = 'systemsmanagement:Uyuni:Master:PR'
source_project = 'systemsmanagement:Uyuni:Master'
other_project = "${source_project}:Other"
el_client_repo = "${source_project}:EL9-Uyuni-Client-Tools"
EL = 'EL_9'
sles_client_repo = "${source_project}:SLE15-Uyuni-Client-Tools"
openSUSE_client_repo = "${source_project}:openSUSE_Leap_15-Uyuni-Client-Tools"
ubuntu_client_repo = "${source_project}:Ubuntu2404-Uyuni-Client-Tools"
sumaform_tools_project = 'systemsmanagement:sumaform:tools'
test_packages_project = 'systemsmanagement:Uyuni:Test-Packages:Pool'
build_repo = 'openSUSE_Leap_Micro_5.5'
other_build_repo = 'openSUSE_Leap_15.5'
url_prefix="https://ci.suse.de/view/Manager/view/Uyuni/job/${env.JOB_NAME}"
product_name = "Uyuni"
short_product_name = "suma"
update_repo = "http://minima-mirror-ci-bv.${domain}/jordi/some-updates/"
additional_repo = "http://minima-mirror-ci-bv.${domain}/jordi/dummy/"
build_packages = true

if (env.JOB_NAME == "uyuni-prs-ci-tests") {
    first_env = 1;
    last_env = 4;
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-reference") {
    // email aliases for slack channel discuss-susemanager-pr-tests-results
    email_to = "discuss-susemanager-p-aaaag32rrv4bcp3adzknwc42m4@suse.slack.com";
    pull_request_number = "master";
    first_env = 5;
    last_env = 5;
    additional_repo_url = "http://minima-mirror-ci-bv.${domain}/pull-request-repositories/reference_job_additional_repo";
} else if (env.JOB_NAME == "suma43-prs-ci-tests") {
    first_env = 6;
    last_env = 6;
    // spacewalk suma43 settings
    // TODO: what happens if we change the environment? Will it break the environment??
    server_release_package = '000product:sle-module-suse-manager-server-release'
    proxy_release_package = '000product:sle-module-suse-manager-proxy-release'
    pull_request_repo = 'https://github.com/SUSE/spacewalk.git'
    builder_api = 'https://api.suse.de'
    build_url = 'https://build.suse.de'
    builder_project = 'Devel:Galaxy:Manager:4.3:PR'
    source_project = 'Devel:Galaxy:Manager:4.3'
    sumaform_tools_project = 'openSUSE.org:systemsmanagement:sumaform:tools'
    test_packages_project = 'openSUSE.org:systemsmanagement:Uyuni:Test-Packages:Pool'
    other_project = 'Devel:Galaxy:Manager:Head:Other'
    el_client_repo = "${source_project}:EL9-SUSE-Manager-Tools"
    EL = 'SUSE_EL-9_Update_standard'
    sles_client_repo = "${source_project}:SLE15-SUSE-Manager-Tools"
    openSUSE_client_repo = "openSUSE.org:systemsmanagement:Uyuni:Master:openSUSE_Leap_15-Uyuni-Client-Tools"
    ubuntu_client_repo = "${source_project}:Ubuntu24.04-SUSE-Manager-Tools"
    build_repo = 'SLE_15_SP4'
    other_build_repo = 'openSUSE_Leap_15.4'
    url_prefix="https://ci.suse.de/view/Manager/view/Manager-4.3/job/${env.JOB_NAME}"
    product_name = "SUSE-Manager-4.3"
    short_product_name = "suma43"
    update_repo = "http://minima-mirror-ci-bv.${domain}/jordi/some-updates43/"
    additional_repo = "http://minima-mirror-ci-bv.${domain}/jordi/dummy43/"
    rn_package = "release-notes-susemanager"
    rn_project = "Devel:Galaxy:Manager:4.3:ToSLE"
} else if (env.JOB_NAME == "suma43-prs-ci-tests-reference") {
    email_to = "discuss-susemanager-p-aaaag32rrv4bcp3adzknwc42m4@suse.slack.com";
    cucumber_gitrepo = "https://github.com/SUSE/spacewalk.git";
    cucumber_ref = "Manager-4.3";
    pull_request_number = "Manager-4.3";
    product_version = "manager43";
    first_env = 6;
    last_env = 6;
    // spacewalk suma43 settings
    // TODO: what happens if we change the environment? Will it break the environment??
    server_release_package = '000product:sle-module-suse-manager-server-release'
    proxy_release_package = '000product:sle-module-suse-manager-proxy-release'
    pull_request_repo = 'https://github.com/SUSE/spacewalk.git'
    builder_api = 'https://api.suse.de'
    build_url = 'https://build.suse.de'
    builder_project = 'Devel:Galaxy:Manager:4.3:PR'
    source_project = 'Devel:Galaxy:Manager:4.3'
    sumaform_tools_project = 'openSUSE.org:systemsmanagement:sumaform:tools'
    test_packages_project = 'openSUSE.org:systemsmanagement:Uyuni:Test-Packages:Pool'
    other_project = 'Devel:Galaxy:Manager:Head:Other'
    el_client_repo = "${source_project}:EL9-SUSE-Manager-Tools"
    EL = 'SUSE_EL-9_Update_standard'
    sles_client_repo = "${source_project}:SLE15-SUSE-Manager-Tools"
    openSUSE_client_repo = "openSUSE.org:systemsmanagement:Uyuni:Master:openSUSE_Leap_15-Uyuni-Client-Tools"
    ubuntu_client_repo = "${source_project}:Ubuntu24.04-SUSE-Manager-Tools"
    build_repo = 'SLE_15_SP4'
    other_build_repo = 'openSUSE_Leap_15.4'
    url_prefix="https://ci.suse.de/view/Manager/view/Manager-4.3/job/${env.JOB_NAME}"
    product_name = "SUSE-Manager-4.3"
    short_product_name = "suma43"
    update_repo = "http://minima-mirror-ci-bv.${domain}/jordi/some-updates43/"
    additional_repo = "http://minima-mirror-ci-bv.${domain}/jordi/dummy43/"
    rn_package = "release-notes-susemanager"
    rn_project = "Devel:Galaxy:Manager:4.3:ToSLE"
} else {
   echo "This job is not supported: ${env.JOB_NAME}"
   sh "exit -1"
}

