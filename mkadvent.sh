#!/bin/bash

export PERLBREW_ROOT=/home/len/perl5/perlbrew
export PERLBREW_HOME=/home/len/.perlbrew
. ${PERLBREW_ROOT}/etc/bashrc
perlbrew use 5.16.2

RUNDIR=/home/len/PerlAdventPlanet/WWW-AdventCalendar-Magrathea

ADVCAL="/usr/bin/env advcal"
PERL="/usr/bin/env perl"
SCP="/usr/bin/env scp"

RUN_MODE=$1
case $RUN_MODE in
	gen | git)  shift;;
esac

while [ -n "$1" ]; do
  YEAR=$1
  OUTDIR=out/${YEAR}
  CONFIGDIR=config/${YEAR}
  ARTICLE_DIR=articles/post/${YEAR}

  HTML_ROOT=/home/len/PerlAdventPlanet/${YEAR}
  REPO=/home/len/repos/lenjaffe.com/PerlAdventPlanet/${YEAR}

  if [ $RUN_MODE != 'git' ]; then
    cd ${RUNDIR}
    if [ ! -d $OUTDIR ]; then
      mkdir -p $OUTDIR
    fi

    if [ ! -d $CONFIGDIR ]; then
      mkdir -p $CONFIGDIR
    fi

    ${PERL} preprocesspod.pl -v $YEAR
    ${ADVCAL} -c ${CONFIGDIR}/advent.ini --article-dir ${ARTICLE_DIR} --out ${OUTDIR}
    mkdir -p ${HTML_ROOT}
    cp -r out/${YEAR}/* ${HTML_ROOT}

    mkdir -p ${REPO}
    cd ${REPO}
    git checkout development
    cp ${HTML_ROOT}/* ${REPO}
  fi

  if [ $RUN_MODE != "gen" ]; then
    cd ${REPO}
    git add .
    git status
    git commit -m "ran $YEAR"
    cd ..
    git checkout master
    git merge --no-ff development
    git push
  fi

  shift
done



