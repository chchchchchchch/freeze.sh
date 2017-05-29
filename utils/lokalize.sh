#!/bin/bash

# MAKE LOKAL ON DEMAND (KEEP THE BLOBS OUT)
# TODO: -f => force download
#       check for README/LICENSE AT REMOTE LOCATION
# ====================================================================== #
  SRCDIR=`echo $* | grep "/" | head -n 1`
# ---------------------------------------------------------------------- #
  if [ ! -d $SRCDIR ]
   then echo "----"; echo "$SRCDIR NOT A DIRECTORY."
      exit 0;
  elif [ `echo "$SRCDIR" | wc -c` -lt 2 ]
   then echo "----"; echo "CHECK/DOWNLOAD ALL SOURCES."
        SRCDIR="../_"
   if [ `find $SRCDIR -name "*.remote" | #
         wc -l` -gt 0 ]; then
        N=`cat \`find $SRCDIR -name "*.remote"\` | #
                 grep "^[ \t]*https\?:" | wc -l`
        echo -e "THIS MEANS CHECKING $N FILES \
                 AND WILL TAKE SOME TIME.\n" | tr -s ' '
        read -p "SHOULD WE DO IT? [y/n] " ANSWER
        if [ X$ANSWER != Xy ] ; then echo "BYE."; exit 1;
                                else echo; fi
    else echo "NOTHING TO DO.";exit 0;
   fi
  fi
# ---------------------------------------------------------------------- #
  echo -e "THE FOLLOWING PROCESS WILL DOWNLOAD FILES
  FROM DIFFERENT SOURCES WITH DIFFERENT COPYRIGHTS.
  IF NOT STATED OTHERWISE ALL RIGHTS RESERVED TO THE AUTHORS." | #
  sed 's/^[ ]*//'
  read -p "I KNOW WHAT I'M DOING? [y/n] " ANSWER
  if [ X$ANSWER != Xy ] ; then echo "BYE"; exit 1; \
                          else echo; fi
# ====================================================================== #

  for SRC in `find $SRCDIR -name "*.remote"`
    do
      SRCDIR=`echo $SRC | rev | cut -d "/" -f 2- | rev`
    # ------------------------------------------------- #
    ( IFS=$'\n'
      for REMOTE in `cat $SRC               | # USELESS USE OF CAT
                     grep -v "^%"           | # NO LINES STARTING WITH %
                     grep "^[ \t]*https\?:" | # SELECT HTTP(S)
                     sed 's/^[ \t]*//'      | # RM LEADING BLANKS
                     sort -u`                 # SORT/UNIQ
       do 
          if [ `echo $REMOTE |        # ECHO $REMOTE
                grep " -*> " |        # SELECT IF '-(--)>'
                wc -l` -gt 0 ]; then  # COUNT AND CHECK
                LOKALNAME=`echo $REMOTE     |      # ECHO $REMOTE
                           sed 's/^.* -*> //'`     # CUT AFTER ->
                  REMOTE=`echo $REMOTE      |      # ECHO $REMOTE
                          sed 's/ -*> .*$//'`      # CUT BEFORE ->
          else  LOKALNAME=`curl -sIL "$REMOTE"   | # CHECK URL
                           grep "^Location"      | # EXTRACT LOCATION
                           rev                   | # REWIND 
                           cut -d "/" -f 1       | # EXTRACT LAST FIELD
                           rev                   | # REWIND
                           tr -d '\r'`             # RM CARRIAGE RETURN
              # -- FALLBACK ------------------------------------------- #
                if [ `echo $LOKALNAME | wc -c` -lt 2 ];then
                      LOKALNAME=`echo "$REMOTE"  | # ECHO $REMOTE
                                 cut -d " " -f 1 | rev | # SELECT/REVERT
                                 cut -d "/" -f 1 | rev`  # SELECT/REVERT
                fi
              # ------------------------------------------------------- #
                   REMOTE=`echo "$REMOTE"  |       # ECHO $REMOTE
                           cut -d " " -f 1`        # SELECT FIELD
          fi
               LOKALNAME=`echo $LOKALNAME  | # ECHO $LOKALNAME
                          sed 's/^[ ]*//'  | # RM LEADING BLANCS
                          sed 's/[ ]*$//'`   # RM TRAILING BLANCS
                  LOKAL="$SRCDIR/$LOKALNAME" # ADD SRC PATH
               LOKALDIR=`echo $LOKAL | rev |      # ECHO $LOKAL/REWIND
                         cut -d "/" -f 2-  | rev` # SELECT/REWIND
               if [ ! -d $LOKALDIR ];then  # IF NECESSARY ...
                    mkdir -p $LOKALDIR     # ... CREATE DIRECTORY
               fi

     # IF REMOTE FILE EXISTS                          #
     # ---------------------------------------------- #
       if [ `curl -s -o /dev/null -IL  \
             -w "%{http_code}" "$REMOTE"` == '200' ]
       then 

     # IF LOKAL FILE EXISTS                           #
     # ---------------------------------------------- #
       if [ -f "$LOKAL" ]; then
 
     # DOWNLOAD IF REMOTE IS NEWER                    #
     # ---------------------------------------------- #
       if [ `curl "$REMOTE" -z "$LOKAL" -o "$LOKAL" \
             -s -L -w %{http_code}` == "200" ]; then
             echo "Download $LOKAL"
             curl -RL "$REMOTE" -o "$LOKAL"
       else  echo "$LOKAL is up-to-date"
       fi;else
 
     # DOWNLOAD IF NO LOKAL FILE                      #
     # ---------------------------------------------- #
             curl -RL "$REMOTE" -o "$LOKAL"
       fi
       fi
 
      done;)
    # ------------------------------------------------- #

   done
# ====================================================================== #

exit 0;
