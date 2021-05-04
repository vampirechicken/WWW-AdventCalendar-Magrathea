#!/bin/bash

function log () {
  echo `date '+%Y/%m/%d %H:%M:%S'` $*
}

function INFO () {
  log "INFO" $*
}

function ERROR () {
  log "ERROR" $*
}

function ABEND () {
  ERROR $*
  INFO "$0 Abended"
  exit
}

INFO "$0 Started"

# TODO: this is brittle.find a way around it.export these vars in the crontab?use mkadvent.rc? 
export PERLBREW_ROOT=/home/len/perl5/perlbrew
export PERLBREW_HOME=/home/len/.perlbrew
. ${PERLBREW_ROOT}/etc/bashrc

export PB_DEFAULT_VERSION=5.32.1
perlbrew use ${PB_VERSION-$PB_DEFAULT_VERSION}

RUNDIR=/home/len/AdventPlanet/WWW-AdventCalendar-Magrathea

ADVCAL="advcal"
PERL="/usr/bin/env perl"
SCP="/usr/bin/env scp"

PREPROCESS=1
GENERATE=1
GIT_PUSH=1

RUN_MODE=$1
case $RUN_MODE in
  pre) GIT_PUSH=0;   GENERATE=0;   shift;;
  gen) PREPROCESS=0; GIT_PUSH=0;   shift;;
  git) PREPROCESS=0; GENERATE=0;   shift;;
  pre+gen|gen+pre)   GIT_PUSH=0;   shift;;
  git+gen|gen+git)   PREPROCESS=0; shift;;
esac

if [ -z "$1" ]; then   # forgot the year
  ABEND "usage: $0 (pre|gen|git|pre+gen|gen+git) year [last_day]"
elif [[ ! -z "$(echo "$1" | grep '[^0-9]')" ]]; then     # year is not numeric
  ABEND "usage: $0 (pre|gen|git|pre+gen|gen+git) year [last_day]"
else   # year is numeric - let us proceed
  YEAR=$1
  if [ -n "$2" ]; then
    LAST_DAY=${2}
  else
    day=`date '+%d' |sed  s/^0//`
    month=`date '+%m'`
    year=`date '+%Y'`
    if [ $month == 12 ]; then
      if [ $YEAR == $year ]; then
        LAST_DAY=$day
        if [ ${LAST_DAY} -gt 25 ]; then
          LAST_DAY=25
        fi
      else
        LAST_DAY=25
      fi
    else
      LAST_DAY=0
    fi
  fi

  OUTDIR=out/${YEAR}
  CONFIGDIR=config/${YEAR}
  ARTICLE_DIR=articles/post/${YEAR}

  HTML_ROOT=/home/len/AdventPlanet/${YEAR}
  REPO=/home/len/repos/lenjaffe.com/AdventPlanet/${YEAR}

  if [ $PREPROCESS == 1 ]; then
    ${PERL} ${RUNDIR}/preprocesspod.pl ${YEAR} ${LAST_DAY}
  fi

  if [ $GENERATE == 1 ]; then
    cd ${RUNDIR}
    if [ ! -d $OUTDIR ]; then
      mkdir -p $OUTDIR
    fi

    if [ ! -d $CONFIGDIR ]; then
      mkdir -p $CONFIGDIR
    fi

    INFO "Generate $YEAR"
    ${ADVCAL} -c ${CONFIGDIR}/advent.ini --article-dir ${ARTICLE_DIR} --out ${OUTDIR}  --year-links
    mkdir -p ${HTML_ROOT}
    cp -r ${OUTDIR}/* ${HTML_ROOT}
    make -f makefiles/makefile.main
    if [ ! -e makefiles/makefile.${YEAR} ]; then
      ./mkmakefile.sh ${YEAR}
    fi
    make -f makefiles/makefile.${YEAR}
    if [ $LAST_DAY -ne 0 ]; then
      day02=$(echo $LAST_DAY | awk '{printf("%02d", $1)}')
      make -f makefiles/makefile.${YEAR} days${day02}
    fi

    mkdir -p ${REPO}
    cd ${REPO}
    git checkout development
    cp ${HTML_ROOT}/* ${REPO}
  fi

  if [ $GIT_PUSH == 1 ]; then
    INFO "Commit $YEAR to repo"
    cd ${REPO}
    git add .
    git status
    git commit -m "ran $YEAR $LAST_DAY"
    cd ..
    git checkout master

    INFO "merge dev into master"
    git merge --no-ff -m 'merge development into master' development

    INFO "push to the origin"
    git push origin development
    git push origin master
    INFO "deploy to production"
    git push deploy master
  fi
fi

INFO "$0 Finished"

