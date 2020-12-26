#!/bin/bash

usage="usage: $0 pod_file"

if [[ $# != 1 ]]; then
  echo ${usage}
  exit 1
fi


errors=$(pod2html --infile=$1 | grep 'id=\"Around-line-')
if [[ -z ${errors} ]]; then
  echo 'There were no errors'
  exit 0
fi

num_errors=$(echo $errors | wc -l)
echo -n "${num_errors} Error"
if [[ ${num_errros} -gt 1 ]]; then
    echo 's:'
else
    echo ':'
fi

echo $errors

# TODO: add fix loop
