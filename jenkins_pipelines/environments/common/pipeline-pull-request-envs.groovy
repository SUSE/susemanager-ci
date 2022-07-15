if (env.JOB_NAME == "uyuni-prs-ci-tests-jordi") {
    first_env = 10;
    last_env = 10;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/jordimassaguerpla/sumaform.git";
    sumaform_ref = "master";
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-reference") {
    // email aliases for slack channel discuss-susemanager-pr-tests-results
    email_to = "discuss-susemanager-p-aaaag32rrv4bcp3adzknwc42m4@suse.slack.com";
    pull_request_number = "master";
    first_env = 9;
    last_env = 9;
    additional_repo_url = "http://minima-mirror.mgr.prv.suse.net/jordi/reference_job_additional_repo";
} else { //regular ci test
    first_env = 1;
    last_env = 5;
}

