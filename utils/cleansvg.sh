#!/bin/bash

# CLEAN UP, TAKE CARE OF LINKED IMAGES (UPDATE LINKS/INSERT PLACEHOLDER)
# =========================================================================== #

# TODO: - test,test,test
#       - 'grep "EDIT/[^/]*\.svg"' not working for subdirs (?)
#      X- grep -v # (-> UNNECESSARY ???)
#       - md5ify ids
#      X- image search modes (?)
#      (- run if image is missing)
#      (- rm sodipodi named view)
#      X- do nothing if src = xbase64
#      X- add/check md5 for src
#      X- if images is missing
#      X  -> comment (=save image src)
#      X  -> add placeholder (xbase64/color)

# =========================================================================== #
# CONFIGURE VARIABLES
# =========================================================================== #
  MODE="1" # FIND CLOSEST TO SVG FILE
 #MODE="2" # FIND BESTMATCH IN CENTRAL LOCATION
  XLINKID="xlink:href"
# =========================================================================== #
# SET VARIABLES 
# =========================================================================== #
  SHPATH=`dirname \`readlink -f $0\``
  SVGROOT="$SHPATH/../_"
  SRCPATH="$SHPATH/../_"
  # ----------------------------------------------------------------------- #
    ARGUMENTS=`echo $* | sed 's/ -[a-z]\b//g'`
    if [ `echo $ARGUMENTS | wc -c` -gt 1  ]
     then if [ -f `echo $ARGUMENTS | sed 's/\.svg$//'`.svg ]
          then SVGALL=`echo $ARGUMENTS | sed 's/\.svg$//'`.svg
          elif [ -d $ARGUMENTS ]
          then SVGALL=`find $ARGUMENTS -name "*.svg" | #
                       grep "EDIT/" | grep "\.svg$"`
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
  # ----------------------------------------------------------------------- #
  IMGFOO="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1Pe
        AAAAA3NCSVQICAjb4U/gAAAADElEQVQImWP4z8AAAAMBAQCc479ZAAAAAElFTkSuQmCC"
  IMGFOO=`echo $IMGFOO | sed 's/ //g'`
  DORELINK=`echo $* | sed 's/ /\n/g' | grep "^-r$" | wc -l`
  ROOTDEPTH=`realpath $SVGROOT | sed 's/[^\/]//g' | wc -c`
# =========================================================================== #
# FUNCTIONS
# =========================================================================== #
  function insertChecksum() {
           SVG2MOD=$1
           # RM (OLD) MD5 CHECKS
           # -------------------------------------------------------- #
             sed -i 's/[ ]*checksum="[a-f0-9]\{16\}"[ ]*//g' $SVG2MOD
   
           # UPDATE (INSERT NEW) MD5 CHECKS
           # -------------------------------------------------------- #
             for IMGHREF in `cat $SVG2MOD   | #
                             sed 's/ /\n/g' | #
                             grep $XLINKID  | #
                             grep -v 'data:image/png;base64' | #
                             sort -u`         #
              do
                 IMGSRC=`echo $IMGHREF | #
                         cut -d '"' -f 2`
                 if [ -f $IMGSRC ];then
                 MD5SRC=`md5sum $IMGSRC | cut -c 1-16`              
                 MD5CHECK="checksum=\"$MD5SRC\""
                 I=$IMGHREF;M=$MD5CHECK
                 sed -i "s,\(^[ ]*\)\($I\),\1\2\n\1$M,g" $SVG2MOD
                 sed -i '/^[ \t]*$/d'                    $SVG2MOD
                 fi
             done
           # -------------------------------------------------------- #
  }
# =========================================================================== #
# ........................................................................... #
# --------------------------------------------------------------------------- #
# LOOP THROUGH ALL SVG FILES (AS DEFINED)
# --------------------------------------------------------------------------- #

  for SVG in $SVGALL
   do
     SVGNAME=`basename $SVG`     #
     SVGPATH=`realpath $SVG    | #
              rev              | #
              cut -d "/" -f 2- | #
              rev`

   # REMOVE PLACEHOLDER AND RESTORE OLD XLINK -> TRY TO RELINK
   # ----------------------------------------------------------------- #
     if [ $DORELINK -gt 0 ];then
          sed -i "s|xlink:href=\"$IMGFOO\"||g" $SVG
          sed -i "s|deadxlink=|xlink:href=|g"  $SVG
     fi

   # CHECK IF ANY IMAGES ARE INCLUDED
   # ----------------------------------------------------------------- #
     HASIMG=`grep $XLINKID $SVG | #
             grep -v 'data:image/png;base64' | #
             grep -v '"#"' | wc -l`

   # UPDATE IMG CHECKSUMS (IF POSSIBLE)
   # ----------------------------------------------------------------- #
     if [ $HASIMG -gt 0 ]; then
          cd $SVGPATH;insertChecksum $SVGNAME;cd - > /dev/null          
     fi

   # CHECK FOR CHANGES
   # ----------------------------------------------------------------- #
     MD5NOW=`sed '/^<!-- CLEANED:.*-->/d' $SVG | #
             md5sum | cut -d " " -f 1`
     MD5OLD=`grep "^<!-- CLEANED:.*-->" $SVG | #
             head -n 1 | cut -d "/" -f 2 | #
             cut -d " " -f 1`
     TOLD=`grep "^<!-- CLEANED:.*-->" $SVG | #
           head -n 1 | cut -d "/" -f 1 | #
           cut -d ":" -f 2 | sed 's/ //g'`     
     CLEANED=`grep "^<!-- CLEANED:.*-->" $SVG | #
              head -n 1 | cut -d ":" -f 2 | #
              sed 's/[^0-9a-fA-F]*//g'`

   # SET SWITCHES ...
   # ----------------------------------------------------------------- #
     if [ `echo $CLEANED | wc -c` -gt 2 ]; then
      if [ $MD5NOW != $MD5OLD ]; then
            DOCLEAN="Y";TNOW=`date +%s` #echo "CLEANING OUTDATED."
       else DOCLEAN="N";TNOW="$TOLD"    #echo "CLEANING UP-TO-DATE."
      fi   
      else DOCLEAN="Y"; TNOW=`date +%s` #echo "CLEANING NEVER DONE."
     fi

   # ... AND DO YOUR THING.
   # ----------------------------------------------------------------- #
     if [ "D$DOCLEAN" == "DY" ];then

       echo -e "\e[31mDO THE CLEANING\e[0m  ($SVG)"

     # CHANGE TO SVG FOLDER
     # ---------------------------------------------------------------- #
       cd $SVGPATH; # SVGNAME=`basename $SVG`
  
     # VACUUM DEFS, REMOVE PERSONAL/UNNECESSARY STUFF
     # ---------------------------------------------------------------- #
       sed -i 's/sodipodi:absref="[^"]*"//'   $SVGNAME
       sed -i 's/inkscape:[wcze].*="[^"]*"//' $SVGNAME
       inkscape --vacuum-defs                 $SVGNAME
       sed -i '/^[ \t]*$/d'                   $SVGNAME
    
     # ---------------------------------------------------------------- #
     # CHANGE ABSOLUTE PATHS TO RELATIVE
  
       for XLINK in `cat $SVGNAME  | #
                     sed "s/ /\n/g" | #
                     grep "$XLINKID" | #
                     grep -v 'data:image/png;base64'`
        do
         if [ `echo $XLINK   | # START WITH XLINK
               grep -v '="#' | # IGNORE NO IMAGES
               wc -l` -gt 0 ]; then
         IMGSRC=`echo $XLINK         | # START WITH XLINKG
                 cut -d "\"" -f 2    | # SELECT IN QUOTATION
                 sed "s/$XLINKID//g" | # RM XLINK
                 sed 's,file://,,g'`   # RM file://
         IMGNAME=`basename $IMGSRC`
         if [ -f "$IMGSRC" ]; then
              IMGPATH=`realpath $IMGSRC | rev | # PRINT FULL PATH
                       cut -d "/" -f 2- | rev`  # SELECT PATH ONLY  
              RELATIVEPATH=`python -c \
              "import os.path; print os.path.relpath('$IMGPATH','$SVGPATH')"`
              NEWXLINK="$XLINKID=\"$RELATIVEPATH/$IMGNAME\""
              sed -i "s,$XLINK,$NEWXLINK,g" $SVGNAME
              insertChecksum $SVGNAME
          else

          echo "LOOKING FOR $IMGNAME"

        # ---------------------------------------------------------------- #
        # MODE 1 = find image in closest location 
        # ---------------------------------------------------------------- #

          if [ "$MODE" == 1 ];then
          C="1";P="20";IMGPATH="" # RESET!
          while [ "$C" -lt 20 ]  &&
                [ "$P" -gt $ROOTDEPTH  ]; do 
           SEARCHPATH=`echo $SVGPATH       | #
                       rev                 | #
                       cut -d "/" -f ${C}- | #
                       rev`; C=`expr $C + 1`
           P=`echo $SEARCHPATH | sed 's/[^\/]//g' | wc -c`
           IMGFOUND=`find $SEARCHPATH -name "$IMGNAME"`
          if [ `echo $IMGFOUND | wc -c` -gt 2 ]; then             
           IMGPATH=`realpath $IMGFOUND | rev | # GET FULL PATH
                    cut -d "/" -f 2-   | rev`  #  
           RELATIVEPATH=`python -c \
          "import os.path; print os.path.relpath('$IMGPATH','$SVGPATH')"`
           NEWXLINK="$XLINKID=\"$RELATIVEPATH/$IMGNAME\""
           C=`expr $C + 10`
           echo "IMAGE FOUND: $IMGFOUND"
           sed -i "s,$XLINK,$NEWXLINK,g" $SVGNAME
           insertChecksum $SVGNAME
          fi
          done
          if [ `echo $IMGPATH | wc -c` -lt 2 ]; then              
                echo "$IMGNAME NOT FOUND."
                NEWXLINK="deadxlink=\"$IMGSRC\""
                FOO="xlink:href=\"$IMGFOO\""
                X=$XLINK;NX=$NEWXLINK
                sed -i "s|\(^[ ]*\)\($X\)|\1$FOO\n\1$NX|g" $SVGNAME
          fi
          fi
        # ---------------------------------------------------------------- #
        # MODE 2 = find image in central location
        #          that best matches original path
        # ---------------------------------------------------------------- #
          if [ "$MODE" == 2 ];then
          MATCH="" # RESET!        
          for CANDIDATE in `find $SRCPATH -name $IMGNAME`
           do
              C=1
              for DIR in `echo $CANDIDATE | #
                          sed 's,/,\n,g'`
               do
                 #echo $DIR
                  if [ `echo $IMGSRC  | #
                        grep "/$DIR/" | #
                        wc -l` -gt 0 ];then
                      C=`expr $C + 1`
                  fi
              done
             #echo "$C:$CANDIDATE"; echo
              MATCH="$MATCH|$C:$CANDIDATE"
          done
          BESTMATCH=`echo $MATCH | sed 's/|/\n/g' | #
                     sort -n | tac | head -n 1 | #
                     cut -d ":" -f 2-`
          if [ `echo $BESTMATCH | wc -c` -gt 2 ];then
                echo "BESTMATCH: $BESTMATCH";echo
                IMGPATH=`realpath $BESTMATCH | rev | # GET FULL PATH
                         cut -d "/" -f 2-   | rev`   #  
                RELATIVEPATH=`python -c \
               "import os.path; print os.path.relpath('$IMGPATH','$SVGPATH')"`
                NEWXLINK="$XLINKID=\"$RELATIVEPATH/$IMGNAME\""
                sed -i "s,$XLINK,$NEWXLINK,g" $SVGNAME
                insertChecksum $SVGNAME
          else
                echo "$IMGNAME NOT FOUND."
                NEWXLINK="deadxlink=\"$IMGSRC\""
                FOO="xlink:href=\"$IMGFOO\""
                X=$XLINK;NX=$NEWXLINK
                sed -i "s|\(^[ ]*\)\($X\)|\1$FOO\n\1$NX|g" $SVGNAME
          fi
          fi
        # ---------------------------------------------------------------- #
         fi
        fi
       done
      cd - > /dev/null
   # ------------------------------------------------------------------------ #
     else
          echo "NO NEED TO CLEAN ($SVG)"
          sleep 0
     fi
        # CHECK IF ANYTHING CHANGED
        # ---------------------------------------------------------- #
          MD5NOW=`sed '/^<!-- CLEANED:.*-->/d' $SVG | # SVG (-STAMP)
                  md5sum | cut -d " " -f 1`           # GET CHECKSUM
          if [ "C$MD5NOW" == "C$MD5OLD" ];then
                CLEANSTAMP="<!-- CLEANED: ${TOLD}/${MD5NOW} -->"
          else
                CLEANSTAMP="<!-- CLEANED: ${TNOW}/${MD5NOW} -->"
          fi
        # DELETE/INSERT CLEANSTAMP
        # ---------------------------------------------------------- #
          sed -i '/^<!-- CLEANED:.*-->$/d'    $SVG    # DELETE STAMP
          sed -i "1s,^.*$,&\n$CLEANSTAMP," $SVG       # INSERT STAMP  
        # ---------------------------------------------------------- #
 done
# --------------------------------------------------------------------------- #
# --------------------------------------------------------------------------- #


exit 0;

