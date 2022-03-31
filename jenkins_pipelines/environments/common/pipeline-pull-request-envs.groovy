must_build = true;
must_test = true;
if (env.JOB_NAME == "uyuni-prs-ci-tests-jordi") {
    first_env = 9;
    last_env = 10;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/jordimassaguerpla/sumaform.git";
    sumaform_ref = "master";
} else {
    if (env.JOB_NAME == "uyuni-prs-ci-tests-reference") {
        email_to = "aaaaeoayla72kj6blracdlufr4@suse.slack.com";
        pull_request_number = "master";
        first_env = 9;
        last_env = 10;
        sumaform_gitrepo = "https://github.com/jordimassaguerpla/sumaform.git";
        sumaform_ref = "master";
    } else { //not jordi, not reference
        first_env = 1;
        last_env = 8;
    }
}

