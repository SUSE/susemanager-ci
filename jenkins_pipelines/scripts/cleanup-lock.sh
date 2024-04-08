#!/bin/bash

usage()
{
    echo "Usage: ${0} -u user -p pull -x suma"
    echo "Where:"
    echo "  -u user email that started the test"
    echo "  -p pull request number"
    echo "  -x product name"
}

while getopts "u:p:x:" opts;do
    case "${opts}" in
        u) user_email=${OPTARG};;
        p) pull_request_number=${OPTARG};;
        x) product_name=${OPTARG};;
        \?)usage;exit -1;;
    esac
done
shift $((OPTIND-1))
if [ -z "${user_email}" ] || \
   [ -z "${pull_request_number}" ] || \
   [ -z "${product_name}" ] ;then
     usage
     echo "user email :${user_email}"
     echo "pull request numbeR: ${pull_request_number}"
     echo "product_name: ${product_name}"
     exit -1
fi

echo "DEBUG: removing previous environment for user: ${user_email}, PR ${pull_request_number} and product ${product_name}"
lockfiles=$(grep -H PR:${pull_request_number} /tmp/env-suma-pr-*.lock.info | cut -d: -f1 | xargs grep -H user:${email_to} | cut -d: -f1 | xargs grep -H product:${product_name} | cut -d: -f1 | xargs grep -H keep: | cut -d: -f1 | rev | cut -d. -f1 --complement | rev)
if [ "${lockfiles}" != "" ];then
    echo "DEBUG: found lockfiles ${lockfiles}"
    echo "DEBUG: remove job"
    echo ${lockfiles} | xargs -I ARG grep -H ARG /var/spool/atjobs/* | cut -d: -f1 |xargs rm -fv
    echo "DEBUG: remove files"
    echo ${lockfiles} | xargs rm -vf
    echo ${lockfiles} | xargs -I ARG rm -vf ARG.info
else
  echo "DEBUG: No lockfiles found"
  echo "DEBUG: Nothing to do"
fi
