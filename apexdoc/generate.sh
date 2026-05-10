#!/bin/bash

readonly sourcedir=$(dirname "${0}")
readonly basedir="${sourcedir}/.."

rm -rf apexdoc.src
mkdir apexdoc.src
cp source/*/classes/*.cls apexdoc.src
java -jar ${sourcedir}/SfApexDoc.jar -t "${basedir}/docs" -s "${basedir}/apexdoc.src" -p global -a "${sourcedir}/sfapexdoc.author" -h "${sourcedir}/sfapexdoc.home"
find docs/SfApexDocs -name "*.html" | {
    while read file; do
	sed 1>"${file}.tmp" -e "s/<title>null -/<title> Force-Framework -/" "${file}"
	mv "${file}.tmp" "${file}"
    done
}
