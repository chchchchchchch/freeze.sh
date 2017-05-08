#!/bin/bash

# =========================================================================== #
# I WOULD NOT RUN IT 
# IF I HAD NOT WROTE IT.
# BUT THAT'S ALL I WANTED TO DO.
# -
# MORE INFORMATION: freeze.sh/mdsh
# =========================================================================== #

# =========================================================================== #
# CONFIGURE                                                                   #
# =========================================================================== #
# --------------------------------------------------------------------------- #
  MAIN="$1";HTML="$2"
# --------------------------------------------------------------------------- #
  MAINPATH=`cd "$( dirname "${MAIN}" )" && pwd` # USED FOR getFile
  SHPATH=`dirname \`readlink -f $0\``
  OUTDIR="../_" ; TMPDIR="."
  REFURL="http://freeze.sh/etherpad/export/_/references.bib"
  TMPID=$TMPDIR/TMP`date +%Y%m%H``echo $RANDOM | cut -c 1-4`
  SRCDUMP=${TMPID}.maindump ; TMPTEX=${TMPID}.tex
  SELECTLINES="tee"
# --------------------------------------------------------------------------- #
  FUNCTIONSBASIC="$SHPATH/201701_basic.functions"
  FUNCTIONS="$TMPID.functions";
  FUNCTIONSPLUS=`echo $* | sed 's/ /\n/g' | grep "\.functions$"`
  cat $FUNCTIONSBASIC $FUNCTIONSPLUS > $FUNCTIONS
# --------------------------------------------------------------------------- #
# INCLUDE                                                                     #
# --------------------------------------------------------------------------- #
  source $FUNCTIONS
# --------------------------------------------------------------------------- #
# DEFINITIONS SPECIFIC TO OUTPUT
# --------------------------------------------------------------------------- #
  PANDOCACTION="pandoc --ascii -r markdown -w html -S"
  COMSTART='<!--'; COMCLOSE='-->'
  HEADMARK="= FROM MDSH START ="
  FOOTMARK="= FROM MDSH END ="
# --------------------------------------------------------------------------- #
# FOOTNOTES [^]{the end is near, the text is here}
# --------- PLACEHOLDERS:
  FOOTNOTEOPEN="FOOTNOTEOPEN$RANDOM{" ; FOOTNOTECLOSE="}FOOTNOTECLOSE$RANDOM"
# --------------------------------------------------------------------------- #
# CITATIONS [@xx:0000:aa] / [@[p.44]xx:0000:aa]
# --------- PLACEHOLDERS:
  CITEOPEN="CITEOPEN$RANDOM" ; CITECLOSE="CITECLOSE$RANDOM"
  CITEPOPEN="$CITEOPEN" ; CITEPCLOSE="CITEPCLOSE$RANDOM"
# --------------------------------------------------------------------------- #


# =========================================================================== #
# ACTION STARTS NOW!
# =========================================================================== #
# DO CONVERSION
# --------------------------------------------------------------------------- #
  mdsh2src $MAIN

  THISDUMP=$TMPID.thisdump
  cp $SRCDUMP $THISDUMP
# --------------------------------------------------------------------------- #
# GET AND PROCESS BIBLIOGRAPHY
# --------------------------------------------------------------------------- #
  BIBTMP=${TMPID}.bibtmp
  wget --no-check-certificate \
       -q -O - $REFURL           | #
  sed 's/@movie/@misc/g'          | #
  recode utf8..h0                  | # RECODE
  bib2xml                           | #
  sed 's/\(&amp;\)\([^ ]*;\)/\&\2/g' | # REDO & (IF CONTROL CHAR)
  sed ":a;N;\$!ba;s/\n//g"          | #
  sed 's/>[ ]*</></g'              | #
  sed 's/<mods /\n&/g'            | #
  sed 's/<\/mods>/&\n/g'         | #
  tee > $BIBTMP
# --------------------------------------------------------------------------- #
# MAKE CITATIONS
# --------------------------------------------------------------------------- #
  source $SHPATH/bibtex.functions
  citations2htmlfootnotes $BIBTMP $THISDUMP
# --------------------------------------------------------------------------- #
# MAKE FOOTNOTES
# --------------------------------------------------------------------------- #
 ( IFS=$'\n' ; COUNT=1
  for FOOTNOTE in `sed "s/$FOOTNOTEOPEN/\n&/g" $THISDUMP | #
                   sed "s/$FOOTNOTECLOSE/&\n/"          | #
                   grep "^$FOOTNOTEOPEN"`
   do
      if [ $COUNT -eq 1 ]; then
           echo "<div id=\"footnotes\">"  >> $THISDUMP
           echo "<ol>"                    >> $THISDUMP
           FOOTNOTEBLOCKSTARTED="YES"
      fi
      FOOTNOTETXT=`echo $FOOTNOTE     | #
                   cut -d "{" -f 2    | #
                   cut -d "}" -f 1`     #
      FOOTNOTE=`echo $FOOTNOTE        | #
                sed 's/\[/\\\[/g'     | #
                sed 's/\]/\\\]/g'     | #
                sed 's/|/\\\|/g'`       #
      LNUM=`grep -n "$FOOTNOTE" $THISDUMP | #
            head -n 1 | cut -d ":" -f 1`    #
      ID=`echo ${FOOTNOTETXT}${COUNT} | #
          md5sum | cut -c 1-8`          #
      OLDFOOTNOTE="$FOOTNOTE"
      NEWFOOTNOTE="<sup><a href=\"#$ID\">$COUNT</a><\/sup>"
      sed -i "$((LNUM))s|$OLDFOOTNOTE|$NEWFOOTNOTE|" $THISDUMP
      echo "<li id=\"$ID\"> $FOOTNOTETXT </li>"   >> $THISDUMP
      COUNT=`expr $COUNT + 1` 
  done
 
  if [ "X${FOOTNOTEBLOCKSTARTED}" == "XYES" ]; then
        echo "</ol>"           >> $THISDUMP
        echo "</div>"          >> $THISDUMP
        sed -i "s|$FOOTNOTECLOSE||g" $THISDUMP # WORKAROUND (BUG!!)
  fi
 )
# --------------------------------------------------------------------------- #
# WRITE HTML
# --------------------------------------------------------------------------- #
  if [ ! -f $HTML ]; then
          echo "<html><body>"   >  $HTML
          cat $THISDUMP         >> $HTML
          echo "</body></html>" >> $HTML
  elif [ `grep "${HEADMARK}" $HTML | wc -l` -gt 0 ] ||
       [ `grep "${HEADMARK}" $HTML | wc -l` -gt 0 ];then
          tac $HTML | #
          sed -n "/<!--.*${HEADMARK}.*-->$/,\$p" | tac   >  ${HTML}.tmp
          echo ""                                        >> ${HTML}.tmp
          cat $THISDUMP                                     | #
          sed -e :a -e '$!N;s/[ ]*\n<!--/<!--/;ta' -e 'P;D' | # RM EMPTY LINES BETWEEN COMMENTS
          sed "/^${COMSTART}.*${COMCLOSE}$/d"               | # RM COMMENTS
          tee                                            >> ${HTML}.tmp
          echo ""                                        >> ${HTML}.tmp
          sed -n "/<!--.*${FOOTMARK}.*-->$/,\$p" ${HTML} >> ${HTML}.tmp
          mv ${HTML}.tmp ${HTML}
  else    tac $HTML | #
          sed -n "/<body>/,\$p" | tac     >  ${HTML}.tmp
          echo ""                         >> ${HTML}.tmp
          cat $THISDUMP                                     | #
          sed -e :a -e '$!N;s/[ ]*\n<!--/<!--/;ta' -e 'P;D' | # RM EMPTY LINES BETWEEN COMMENTS
          sed "/^${COMSTART}.*${COMCLOSE}$/d"               | # RM COMMENTS
          tee                                            >> ${HTML}.tmp
          echo ""                         >> ${HTML}.tmp
          sed -n "/<\/body>/,\$p" ${HTML} >> ${HTML}.tmp
          mv ${HTML}.tmp ${HTML}    
  fi

# =========================================================================== #
# CLEAN UP (MAKE SURE $TMPID IS SET FOR WILDCARD DELETE)

  if [ `echo ${TMPID} | wc -c` -ge 4 ] && 
     [ `ls ${TMPID}*.* 2>/dev/null | wc -l` -gt 0 ]
  then
        rm ${TMPID}*.*
  fi

exit 0;
