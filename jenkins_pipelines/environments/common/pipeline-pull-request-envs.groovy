if (env.JOB_NAME == "uyuni-prs-ci-tests-jordi") {
    first_env = 9;
    last_env = 10;
    // if you change the sumaform repo or reference, you need to remove the sumaform directory from the results folder
    sumaform_gitrepo = "https://github.com/jordimassaguerpla/sumaform.git";
    sumaform_ref = "master";
} else {
    first_env = 1;
    last_env = 8;
}

