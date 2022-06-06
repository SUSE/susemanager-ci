if (env.JOB_NAME == "uyuni-prs-ci-tests-jordi") {
    first_env = 10;
    last_env = 10;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/jordimassaguerpla/sumaform.git";
    sumaform_ref = "master";
} else {
    if (env.JOB_NAME == "uyuni-prs-ci-tests-reference") {
        must_build = false;
        email_to = "aaaaeoayla72kj6blracdlufr4@suse.slack.com";
        pull_request_number = "master";
        first_env = 9;
        last_env = 9;
        additional_repo_url = "http://minima-mirror.mgr.prv.suse.net/jordi/reference_job_additional_repo";
    } else { //not jordi, not reference
        first_env = 1;
        last_env = 8;
    }
}

