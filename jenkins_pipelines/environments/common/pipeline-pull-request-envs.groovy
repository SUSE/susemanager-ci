if (env.JOB_NAME == "uyuni-prs-ci-tests-jordi") {
    first_env = 10;
    last_env = 10;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/jordimassaguerpla/sumaform.git";
    sumaform_ref = "master";
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-reference") {
    email_to = "aaaaeoayla72kj6blracdlufr4@suse.slack.com";
    pull_request_number = "master";
    first_env = 9;
    last_env = 9;
    additional_repo_url = "http://minima-mirror.mgr.prv.suse.net/jordi/reference_job_additional_repo";
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-reference-secondary") {
    email_to = "aaaaeoayla72kj6blracdlufr4@suse.slack.com";
    run_all_scopes = true;
    first_env = 8;
    last_env = 8;
    cucumber_gitrepo = "https://github.com/jordimassaguerpla/uyuni.git";
    cucumber_ref = "remove_failing_tests";
    pull_request_number = "5379";
} else if (env.JOB_NAME == "uyuni-prs-ci-tests-reference-secondary-full") {
    email_to = "aaaaeoayla72kj6blracdlufr4@suse.slack.com";
    run_all_scopes = true;
    first_env = 7;
    last_env = 7;
    cucumber_gitrepo = "https://github.com/jordimassaguerpla/uyuni.git";
    cucumber_ref = "remove_flaky_tags";
    pull_request_number = "5568";
} else { //regular ci test
    first_env = 1;
    last_env = 6;
}

