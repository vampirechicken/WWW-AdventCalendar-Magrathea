#!/bin/bash


YEAR=$1;
MAKEFILE=makefiles/makefile.${YEAR}


echo "DESTDIR=/home/len/repos/lenjaffe.com/AdventPlanet/${YEAR}" > ${MAKEFILE}

echo 'all: index atom css' >> ${MAKEFILE}
echo 'index: $(DESTDIR)/index.html.gz' >> ${MAKEFILE}
echo 'atom: $(DESTDIR)/atom.xml.gz' >> ${MAKEFILE}
echo 'css: $(DESTDIR)/style.css.gz' >> ${MAKEFILE}

echo -n 'days: ' >> ${MAKEFILE}
for DAY in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 
do
  file="\$(DESTDIR)/${YEAR}-12-${DAY}.html.gz"
  echo -n "${file} " >> ${MAKEFILE}
done
echo >> ${MAKEFILE}

for file in index.html atom.xml style.css
do
  echo  >> ${MAKEFILE}
  echo "\$(DESTDIR)/${file}.gz: \$(DESTDIR)/${file}" >>${MAKEFILE}
  echo "	(cd \$(DESTDIR); git checkout development; gzip -c ${file} > ${file}.gz; git add ${file}.gz)" >> ${MAKEFILE}
done


for DAY in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 
do
  file=${YEAR}-12-${DAY}.html
  echo  >> ${MAKEFILE}
  echo "\$(DESTDIR)/${file}.gz: \$(DESTDIR)/${file}" >>${MAKEFILE}
  echo "	(cd \$(DESTDIR); git checkout development; gzip -c ${file} > ${file}.gz; git add ${file}.gz)" >> ${MAKEFILE}
done
