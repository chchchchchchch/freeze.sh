#!/bin/bash

# CREATE WWW VERSION FROM SVG WORK FILE                                       #

# --------------------------------------------------------------------------- #
# TODO: Xprovide subfolder option (like lokalize.sh)
#       X-f => force new write
#       Xcreate "_" if it does not exist
#       Xignore XX_ layers
#        multi layer support
#       Xcheck not by date but md5 of source file
#       Xrm different format
# --------------------------------------------------------------------------- #

# =========================================================================== #
# SET VARIABLES 
# --------------------------------------------------------------------------- #
  SHPATH=`dirname \`readlink -f $0\``
  SVGROOT="../_"
  THISSCRIPT="http://freeze.sh/utils/edit2www.sh"
  TMP=
# =========================================================================== #
# CHECK INPUT
# --------------------------------------------------------------------------- #
   ARGUMENTS=`echo $* | sed 's/ -[a-z]\b//g'`
   if [ `echo $ARGUMENTS | wc -c` -gt 1  ]
    then if [ -f `echo $ARGUMENTS | sed 's/\.svg$//'`.svg ]
         then SVGALL=`echo $ARGUMENTS | sed 's/\.svg$//'`.svg
         elif [ -d $ARGUMENTS ]
         then SVGALL=`find $ARGUMENTS -name "*.svg" | #
                      grep "EDIT/" | grep "\.svg$"`   #
         else echo "SOMETHING SEEMS WRONG";exit 0;fi
    else SVGALL=`find $SVGROOT -name "*.svg" | #
                 grep "EDIT/" | grep "\.svg$"`
         N=`echo $SVGALL | sed 's/ /\n/g' | wc -l`
        echo -e "$N FILES TO PROCESS. \
                 THIS WILL TAKE SOME TIME.\n" | tr -s ' '
        read -p "SHOULD WE DO IT? [y/n] " ANSWER
        if [ X$ANSWER != Xy ] ; then echo "BYE."; exit 1;
                                else echo; fi
   fi
   if [ `echo $* | sed 's/ /\n/g' | #
         grep -- "-f" | wc -l` -gt 0 ];then FORCEWRITE="YES"; fi
# =========================================================================== #
# CHECK EXIFTOOL
# --------------------------------------------------------------------------- #
  if [ `hash exiftool 2>&1 | wc -l` -gt 0 ]
  then EXIF="OFF";else EXIF="ON"; fi

# =========================================================================== #
# FUNCTIONS (USED LATER)
# --------------------------------------------------------------------------- #
  function saveOptimized() {

    EDITSRC=$1;SAVETHIS=$2;ORIGINAL=$EDITSRC
    MD5SRC=`md5sum "$EDITSRC" | cut -d " " -f 1`;

 # ------------------------------------------------------------------------- #
 # REMOVE 'XX_' LAYERS
 # ------------------------------------------------------------------------- #
   BFOO=NL`echo ${RANDOM} | cut -c 1`F00
   SFOO=SP`echo ${RANDOM} | cut -c 1`F0O
 
   sed ":a;N;\$!ba;s/\n/$BFOO/g" $EDITSRC | # REMOVE ALL LINEBREAKS (BUT SAVE)
   sed "s/ /$SFOO/g"                      | # REMOVE ALL SPACE (BUT SAVE)
   sed 's/<g/\n&/g'                       | # MOVE GROUP TO NEW LINES
   sed '/groupmode="layer"/s/<g/4Fgt7R/g' | # PLACEHOLDER FOR LAYERGROUP OPEN
   sed ':a;N;$!ba;s/\n//g'                | # REMOVE ALL LINEBREAKS
   sed 's/4Fgt7R/\n<g/g'                  | # RESTORE LAYERGROUP OPEN + NEWLINE
   sed 's/<\/svg>/\n&/g'                  | # CLOSE TAG ON SEPARATE LINE
   sed 's/display:none/display:inline/g'  | # MAKE VISIBLE EVEN WHEN HIDDEN
   grep -v 'label="XX_'                   | # REMOVE EXCLUDED LAYERS
   sed "s/$BFOO/\n/g"                     | # RESTORE LINEBREAKS
   sed "s/$SFOO/ /g"                      | # RESTORE LINEBREAKS
   tee > ${EDITSRC}.tmp
 
   cp ${EDITSRC} ${EDITSRC}.original        # MAKE BACKUP
   mv ${EDITSRC}.tmp ${EDITSRC}             # MOVE IN PLACE (TEMPORARILY)
 # ------------------------------------------------------------------------- #

  # HOW TO SAVE OPTIMIZED
  # ---------------------
   #echo -e "\e[34mCHECK $EDITSRC\e[0m"
    HASIMG=`grep "<image" $EDITSRC | wc -l`
    if [ $HASIMG -gt 0 ]; then
         #echo "BITMAP"

    # PIXEL: BASE EXPORT (PNG)                                 #
    # -------------------------------------------------------- #
      inkscape --export-png=${SAVETHIS}.png \
               --export-background-opacity=0   \
               $EDITSRC > /dev/null 2>&1
      NUMCOLOR=`convert ${SAVETHIS}.png -format %c \
                -depth 8  histogram:info:- | #
                sed '/^[[:space:]]*$/d' | wc -l`
      NOTRANSPARENCY=`convert ${SAVETHIS}.png \
                      -format "%[opaque]" info:`

      if [ X$NOTRANSPARENCY = "Xtrue" ]; then

      # NOT TRANSPARENT: COMPRESS (JPG/GIF)                    #
      # ------------------------------------------------------ #
        if [ $NUMCOLOR -lt 256 ]; then
             echo -e "\e[42m SAVE ${SAVETHIS}.gif \e[0m";
             convert ${SAVETHIS}.png \
                     ${SAVETHIS}.gif
             SAVETHISFORMAT="gif"
        else
             echo -e "\e[42m SAVE ${SAVETHIS}.jpg \e[0m";
             convert ${SAVETHIS}.png \
                     -quality 90 \
                     ${SAVETHIS}.jpg
             SAVETHISFORMAT="jpg"
        fi
      else   echo -e "\e[42m SAVE ${SAVETHIS}.png \e[0m"
             SAVETHISFORMAT="png"
      fi;    SAVED=`ls ${SAVETHIS}.${SAVETHISFORMAT} | #
                    head -n 1`
             if [ "$EXIF" == ON ]; then
                   exiftool -Software="$THISSCRIPT" \
                  -Source="$MD5SRC" $SAVED > /dev/null 2>&1
             fi
    else

    # VECTOR: BREAK FONTS, FORGET ABOUT HIDDEN STUFF         #
    # ------------------------------------------------------ #
      echo -e "\e[102m\e[97m SAVE ${SAVETHIS}.svg \e[0m";
      inkscape --export-pdf=${SAVETHIS}.pdf \
               -T $EDITSRC > /dev/null 2>&1
      inkscape --export-plain-svg=${SAVETHIS}.svg \
               ${SAVETHIS}.pdf > /dev/null 2>&1
      SAVETHISFORMAT="svg"
      SRCSTAMP="<!-- $MD5SRC ("`date +%d.%m.%Y" "%T`")-->"
      sed -i "1s,^.*$,&\n$SRCSTAMP,"  ${SAVETHIS}.svg
   fi
     for SAVETHISOLD in `ls ${SAVETHIS}.* | #
                         grep -v ".${SAVETHISFORMAT}$"`
              do if [ -f "$SAVETHISOLD" ];then
                      rm "$SAVETHISOLD"
                 fi
             done
 # ------------------------------------------------------------------------- #
    mv ${EDITSRC}.original ${EDITSRC} # MOVE BACK IN PLACE
  }
# =========================================================================== #


# =========================================================================== #
#  LOOP THROUGH ALL SVG FILES (AS DEFINED ABOVE)
# --------------------------------------------------------------------------- #
  for EDITSRC in $SVGALL
   do
         EDITPATH=`echo "$EDITSRC"  | rev | #
                   cut -d "/" -f 2- | rev`  #
         WWWPATH=`echo "$EDITPATH"  |       #
                  sed 's,/EDIT.*$,/_,g'`    #

         BASENAME=`basename "$EDITSRC" |    #
                   cut -d "." -f 1`         #
         MD5SRC=`md5sum "$EDITSRC" | cut -d " " -f 1`;

         if [ ! -d "$WWWPATH" ]
         then mkdir -p "$WWWPATH"
         else
           if [ `find ${WWWPATH} -maxdepth 1 \
                                 -name "${BASENAME}.*" | #
                 wc -l` -lt 1 ]; then
                 echo "NO WWW VERSION"
                 saveOptimized "$EDITSRC" "${WWWPATH}/${BASENAME}"
           else
              SAVED=`ls -t ${WWWPATH}/${BASENAME}.* | head -n 1`
              if [ "$SAVED" -nt "$EDITSRC" ] &&
                 [ "$FORCEWRITE" != "YES"  ]; then
                    echo "$SAVED IS UP-TO-DATE ($EDITSRC)"
              else
            # ------------------------------------------------------ #
               if [ "$EXIF" == "ON" ] &&
                  [ `echo $SAVED | grep -v "\.svg$" | wc -l` -gt 0 ]
                then  MD5CHECK=`exiftool $SAVED | #
                                grep "^Source[ ]*:[ ]*[a-f0-9]*" | #
                                cut -d ":" -f 2 | #
                                sed 's/[^a-f0-9]*//g'`
                fi
                if [ `echo $SAVED | grep "\.svg$" | wc -l` -gt 0 ]
                then    MD5CHECK=`grep '<!-- [a-f0-9]' $SAVED | #
                                  cut -d " " -f 2`
                fi
            # ------------------------------------------------------ #
                if [ "$MD5CHECK" != "$MD5SRC" ];then
                      echo -e "\e[31m$SAVED NEEDS UPDATE\e[0m ($EDITSRC)"
                      saveOptimized "$EDITSRC" "${WWWPATH}/${BASENAME}"
                else  echo "$SAVED IS UP-TO-DATE ($EDITSRC)"
              fi
             fi
           fi
         fi
  done
# =========================================================================== #


exit 0;


