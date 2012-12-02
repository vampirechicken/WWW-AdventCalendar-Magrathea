:

RUNDIR=/home/len/PerlAdventPlanet/WWW-AdventCalendar-Magrathea

ADVCAL="/usr/bin/env advcal"
PERL="/usr/bin/env perl"
SCP="/usr/bin/env scp"

while [ -n "$1" ]; do
  YEAR=$1
  OUTDIR=out/${YEAR}
  CONFIGDIR=config/${YEAR}
  ARTICLE_DIR=articles/post/${YEAR}

  HTML_ROOT=/home/len/PerlAdventPlanet/${YEAR}

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
  shift
done
