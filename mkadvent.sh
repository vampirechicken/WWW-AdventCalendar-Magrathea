#!/bin/bash

echo "$0 Started: " `date`


export PERLBREW_ROOT=/home/len/perl5/perlbrew
export PERLBREW_HOME=/home/len/.perlbrew
. ${PERLBREW_ROOT}/etc/bashrc
perlbrew use 5.20.1
#perlbrew use 5.18.2

RUNDIR=/home/len/AdventPlanet/WWW-AdventCalendar-Magrathea

ADVCAL="/usr/bin/env advcal"
PERL="/usr/bin/env perl"
SCP="/usr/bin/env scp"

PREPROCESS=1
GENERATE=1
GIT_PUSH=1

RUN_MODE=$1
case $RUN_MODE in
  pre) GIT_PUSH=0; GENERATE=0; shift;;
  gen) PREPROCESS=0; GIT_PUSH=0; shift;;
  git) PREPROCESS=0; GENERATE=0; shift;;
  pre+gen|gen+pre) GIT_PUSH=0; shift;;
  git+gen|gen+git) PREPROCESS=0; shift;;
esac

while [ -n "$1" ]; do
  YEAR=$1
  OUTDIR=out/${YEAR}
  CONFIGDIR=config/${YEAR}
  ARTICLE_DIR=articles/post/${YEAR}

  HTML_ROOT=/home/len/AdventPlanet/${YEAR}
  REPO=/home/len/repos/lenjaffe.com/AdventPlanet/${YEAR}

  if [ $PREPROCESS == 1 ]; then
    ${PERL} ${RUNDIR}/preprocesspod.pl -v $YEAR
  fi

  if [ $GENERATE == 1 ]; then
    cd ${RUNDIR}
    if [ ! -d $OUTDIR ]; then
      mkdir -p $OUTDIR
    fi

    if [ ! -d $CONFIGDIR ]; then
      mkdir -p $CONFIGDIR
    fi

    echo "Generate $YEAR"
    ${ADVCAL} -c ${CONFIGDIR}/advent.ini --article-dir ${ARTICLE_DIR} --out ${OUTDIR}  --year-links
    mkdir -p ${HTML_ROOT}
    cp -r ${OUTDIR}/* ${HTML_ROOT}

    mkdir -p ${REPO}
    cd ${REPO}
    git checkout development
    cp ${HTML_ROOT}/* ${REPO}
  fi

  if [ $GIT_PUSH == 1 ]; then
    echo "Commit $YEAR to the repo"
    cd ${REPO}
    git add .
    git status
    git commit -m "ran $YEAR"
    cd ..
    git checkout master
    git merge --no-ff development
    git push origin
    git push mirror
  fi

  shift
done


echo "$0 Finished: " `date`

