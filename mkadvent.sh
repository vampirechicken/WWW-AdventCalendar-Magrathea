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
  URI_BASE=theycomewithcheese.com/PerlAdventPlanet/${YEAR}
  #URI=http://${URI_BASE}

  HTML_ROOT=laj@vampirechicken.com:/home/laj/${URI_BASE}

  cd ${RUNDIR}
  if [ ! -d $OUTDIR ]; then
    mkdir -p $OUTDIR
  fi

  if [ ! -d $CONFIGDIR ]; then
    mkdir -p $CONFIGDIR
  fi

  ${PERL} preprocesspod.pl -v $YEAR
  ${ADVCAL} -c ${CONFIGDIR}/advent.ini --article-dir ${ARTICLE_DIR} --out ${OUTDIR}
  ${SCP} out/${YEAR}/* ${HTML_ROOT}
  shift
done
