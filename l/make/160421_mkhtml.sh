#!/bin/bash

# =========================================================================== #
# I WOULD NOT RUN IT 
# IF I HAD NOT WROTE IT.
# BUT THAT'S ALL I WANTED TO DO.
# -
# MORE INFORMATION: lfkn.de/sdadsa
# =========================================================================== #

  MAIN=$1 ; HTML=$2

  MAINPATH=`cd "$( dirname "${MAIN}" )" && pwd` # USED FOR getFile

  TMPDIR=.
  REFURL="http://freeze.sh/etherpad/export/_/references.bib"
  PANDOCACTION="pandoc --ascii -r markdown -w html -S"
  COMSTART='<!--'; COMCLOSE='-->'
  HEADMARK="= FROM MDSH START ="
  FOOTMARK="= FROM MDSH END ="

# --------------------------------------------------------------------------- #
# INCLUDE/COMBINE FUNCTIONS
# --------------------------------------------------------------------------- #
  TMPID=$TMPDIR/TMP`date +%Y%m%H``echo $RANDOM | cut -c 1-4`
  SHPATH=`dirname \`readlink -f $0\``
  FUNCTIONSBASIC="${SHPATH}/201603_basic.functions"
  #FUNCTIONSPLUS="${SHDIR}/160209_html.functions"
   FUNCTIONSPLUS=`echo $* | sed 's/ /\n/g' | grep "\.functions$"`
       FUNCTIONS="$TMPID.functions"
  cat $FUNCTIONSBASIC $FUNCTIONSPLUS > $FUNCTIONS

  source $FUNCTIONS

# --------------------------------------------------------------------------- #
# CONFIGURE VARIABLES
# --------------------------------------------------------------------------- #
  SRCDUMP=${TMPID}.maindump ; touch $SRCDUMP
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

# --------------------------------------------------------------------------- #
# AND NOW: WAIT FOR ANSWERS
 --------------------------------------------------------------------------- #
  clear; echo -e "\n\n"


  # TODO: if $MAIN is http getFile

  if [ ! -f  "$MAIN" ] ||
     [ `echo "$HTML" | wc -c` -lt 2 ] ||
     [ `echo "$HTML" | grep ".html$"  | wc -l` -lt 1 ] ||
     [ `echo "$MAIN" | wc -c` -lt 2 ]
   then echo; echo "Define input and output file, please!"
              echo "e.g. $0 input.mdsh output.html"; echo
      exit 0;
  fi
  if [ -f $HTML ]; then
       echo "$HTML does exist"
       read -p "overwrite $HTML? [y/n] " ANSWER
       if [ X$ANSWER != Xy ]; then
            echo "BYE BYE!"; exit 0;
       else
            echo "Keep a copy"
            read -p "overwrite $HTML? [y/n] " ANSWER
         if [ X$ANSWER == Xy ]; then
              cp -p $HTML `dirname $HTML`/`date -r $HTML +%y%m%d%H%M`.html
         fi
       fi
  else
       HTMLBASE=`dirname $HTML`
       if [ ! -d $HTMLBASE ]; then
            echo "$HTMLBASE does not exist"
            read -p "create $HTMLBASE? [y/n] " ANSWER
          if [ X$ANSWER != Xy ] ; then echo "BYE BYE!"; exit 0; fi
            mkdir -p "$HTMLBASE"
       fi
           touch $HTML
  fi
     HTMLBASE=`readlink -f $HTML | rev | cut -d "/" -f 2- | rev`
     HTMLSRCDIRNAME="_"
     HTMLSRCDIR="$HTMLBASE/$HTMLSRCDIRNAME"
  if [ ! -d $HTMLSRCDIR ]; then
       echo
       echo "$HTMLSRCDIR does not exist"
       read -p "create $HTMLSRCDIR? [y/n] " ANSWER
       if [ X$ANSWER == Xy ] ; then 
       echo "creating $HTMLSRCDIR"; mkdir $HTMLSRCDIR
       else echo "BYE BYE!"; exit 1; fi
  fi


# |=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=| #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# ACTION HAPPENS HERE!
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

  mdsh2src $MAIN

# |=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=| #

# --------------------------------------------------------------------------- #
# POST PROCESS ALL HTML
# --------------------------------------------------------------------------- #

# MAKE HYPHENS IN WORDS NON-BREAKING (<p> only) BUGGY!!!!
# -------------------------------------------------------------
# sed -i '/^<p>.*<\/p>$/s/\([a-z]\)-/\1\&#8209;/g' $SRCDUMP


# OBSOLETE ????
# COPY MAINHTML TO MATCH SRCDUMP (AS SPLITDUMPS DO)
  MAINHTML="$HTML"
  cp $HTML `echo $SRCDUMP | sed 's/\.[a-z]*$/.html/'`
  touch ${TMPID}.splitlist # MAKE EXIST





   # GET REFERENCE FILE
   # ------------------------------------------------------------------------- #
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

  for THISDUMP in $SRCDUMP `cat ${TMPID}.splitlist | sort -u`
   do
      HTML=`echo $THISDUMP | sed 's/\.[a-z]*$/.html/'`

   # ------------------------------------------------------------------------- #
   # MAKE CITATIONS
   # ------------------------------------------------------------------------- #

     source $SHPATH/bibtex.functions
     citations2htmlfootnotes $BIBTMP $THISDUMP

   # ------------------------------------------------------------------------- #
   # MAKE FOOTNOTES
   # ------------------------------------------------------------------------- #

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

      tac $HTML | #
      sed -n "/<!--.*${HEADMARK}.*-->$/,\$p" | #
      tac                                            >  ${HTML}.tmp
      echo ""                                        >> ${HTML}.tmp

    # BUG: INCLUDES INTERPUNCTUATION
    # sed -i '/^<!-- /!s,\([>]*\)\(http.\?://[^ <]*\),\1<a href="\2" class="linkify">\2</a>,g' $THISDUMP

      cat $THISDUMP                                     | #
      sed "s/[ \t]*$APND//g"                            | # DOUBLED FROM FUNCTIONS (BUG?!)
      sed "s/[ \t]*$ESC//g"                             | # DOUBLED FROM FUNCTIONS (BUG?!)
      sed "/^${COMSTART}.*${COMCLOSE}$/s/---/-_/g"      | #
      sed -e :a -e '$!N;s/[ ]*\n<!--/<!--/;ta' -e 'P;D' | # RM EMPTY LINES BETWEEN COMMENTS
      tee                                            >> ${HTML}.tmp
    
      echo ""                                        >> ${HTML}.tmp
      sed -n "/<!--.*${FOOTMARK}.*-->$/,\$p" ${HTML} >> ${HTML}.tmp
    
      mv ${HTML}.tmp $HTML

      rm $THISDUMP

  done

  mv `echo $SRCDUMP | sed 's/\.[a-z]*$/.html/'` $MAINHTML

# =========================================================================== #
# CLEAN UP

# SHOULD HAVE rmif FUNCTION
 #rm tc.txt
  rm ${TMPID}*.[1-9]*.*
  rm ${TMPID}*.functions
  rm ${TMPID}*.included
  rm ${TMPID}*.tmp
  rm ${TMPID}*.txt
  rm ${TMPID}*.pdf
  rm ${TMPID}*.png
  rm ${TMPID}*.wget
  rm ${TMPID}*.*list
 #rm ${TMPID}bib*
  rm ${TMPID}.bibtmp 
  rm ${TMPID}*.fid
  
  
exit 0;

