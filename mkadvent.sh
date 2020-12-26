#!/bin/bash

function log () {
  echo `date` $*
}

log "$0 Started"

export PERLBREW_ROOT=/home/len/perl5/perlbrew
export PERLBREW_HOME=/home/len/.perlbrew
. ${PERLBREW_ROOT}/etc/bashrc

export PB_DEFAULT_VERSION=5.30.2
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
  echo "usage: $0 (pre|gen|git|pre+gen|gen+git) year [last_day]"
  log "usage: $0 (pre|gen|git|pre+gen|gen+git) year [last_day]"
elif [[ ! -z "$(echo "$1" | grep '[^0-9]')" ]]; then     # year is not numeric
  echo "usage: $0 (pre|gen|git|pre+gen|gen+git) year [last_day]"
  log "usage: $0 (pre|gen|git|pre+gen|gen+git) year [last_day]"
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
      else
        LAST_DAY=25
      fi
    else
      LAST_DAY=1
    fi
  fi

  OUTDIR=out/${YEAR}
  CONFIGDIR=config/${YEAR}
  ARTICLE_DIR=articles/post/${YEAR}

  HTML_ROOT=/home/len/AdventPlanet/${YEAR}
  REPO=/home/len/repos/lenjaffe.com/AdventPlanet/${YEAR}

  if [ $PREPROCESS == 1 ]; then
    ${PERL} ${RUNDIR}/preprocesspod.pl -v ${YEAR} ${LAST_DAY}
  fi

  if [ $GENERATE == 1 ]; then
    cd ${RUNDIR}
    if [ ! -d $OUTDIR ]; then
      mkdir -p $OUTDIR
    fi

    if [ ! -d $CONFIGDIR ]; then
      mkdir -p $CONFIGDIR
    fi

    log "Generate $YEAR"
    ${ADVCAL} -c ${CONFIGDIR}/advent.ini --article-dir ${ARTICLE_DIR} --out ${OUTDIR}  --year-links
    mkdir -p ${HTML_ROOT}
    cp -r ${OUTDIR}/* ${HTML_ROOT}
    make -f makefiles/makefile.main
    if [ ! -e makefiles/makefile.${YEAR} ]; then
      ./mkmakefile.sh ${YEAR}
    fi
    make -f makefiles/makefile.${YEAR}
    if [ $LAST_DAY -ne 0 ]; then
      make -f makefiles/makefile.${YEAR} days
    fi

    #cd ${HTML_ROOT}
    #for htmlfile in *.html
    #do
    #  gzip -c $htmlfile > ${htmlfile}.gz
    #done

    mkdir -p ${REPO}
    cd ${REPO}
    git checkout development
    cp ${HTML_ROOT}/* ${REPO}
  fi

  if [ $GIT_PUSH == 1 ]; then
    log "Commit $YEAR to repo"
    cd ${REPO}
    git add .
    git status
    git commit -m "ran $YEAR $LAST_DAY"
    cd ..
    git checkout master

    log "merge dev into master"
    git merge --no-ff -m 'merge development into master' development

    log "push to the origin"
    git push origin development
    git push origin master
    log "deploy to production"
    git push deploy master
  fi
fi

log "$0 Finished" 

