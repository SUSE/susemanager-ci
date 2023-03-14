if (env.JOB_NAME == "uyuni-prs-ci-tests-jordi") {
    first_env = 10;
    last_env = 10;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/witekest/sumaform.git";
    sumaform_ref = "server_monitoring";
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-ion") {
    first_env = 9;
    last_env = 9;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/uyuni-project/sumaform.git";
    sumaform_ref = "master-cobbler-3.3.1";
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-qe") {
    first_env = 8;
    last_env = 8;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/nodeg/sumaform.git";
    sumaform_ref = "qe-update-ruby32";
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-reference") {
    // email aliases for slack channel discuss-susemanager-pr-tests-results
    email_to = "discuss-susemanager-p-aaaag32rrv4bcp3adzknwc42m4@suse.slack.com";
    pull_request_number = "master";
    first_env = 9;
    last_env = 9;
    additional_repo_url = "http://minima-mirror.mgr.prv.suse.net/jordi/reference_job_additional_repo";
} else { //regular ci test
    first_env = 1;
    last_env = 8;
}

