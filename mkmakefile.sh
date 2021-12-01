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
  echo -e "\t(cd \$(DESTDIR); git checkout development; gzip -c ${file} > ${file}.gz; git add ${file}.gz)" >> ${MAKEFILE}
done


for DAY in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
do
  date="${YEAR}-12-${DAY}"
  html_file=${date}.html
  echo  >> ${MAKEFILE}
  echo "${DAY}:          ${html_file}.gz"  >> ${MAKEFILE}
  echo "${date}:  ${html_file}.gz"  >> ${MAKEFILE}
  echo "${html_file}.gz:"                  >> ${MAKEFILE}
  echo -e "\t(cd \$(DESTDIR); git checkout development; -f ${html_file} && gzip -c ${html_file} > ${html_file}.gz; -f ${html_file} && git add ${html_file}.gz)" >> ${MAKEFILE}
done

echo  >> ${MAKEFILE}

for DAY in 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02
do
  day02=$(echo $DAY | awk '{day=$1;printf("%02d",day-1)}')
  echo "days${DAY}: ${DAY} days${day02}"  >> ${MAKEFILE}
done
  echo "days01: 01"  >> ${MAKEFILE}
