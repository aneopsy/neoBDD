#!/bin/sh

### VARIABLES ####
DB_FILE="sh.db"
DB_HEADER="neoBDSH V0.1\nLast update:   `date`"
SEPARATOR=' #:@:# '
KEY=""
VALUE=""

### MAKE_HEADER ###
set_output ()
{
    ### Check if file is exist ###
    if [ ! -f "$DB_FILE" ]
    then
        ### Put header in file ###
        echo "$DB_HEADER" > "$DB_FILE"
    fi
}

db_put ()
{
    ### Check if $1 and $2 is not empty ###
    if [ -n "$1" ] && [ -n "$2" ]
    then
        KEY="$1"
        VALUE="$2"
        set_output
        if [ `echo "$VALUE" | grep '^\$.*$'` ]
        then
            VALUE=`echo "$VALUE" | sed 's/^\$\([^ ]*\)/\1/g'`
            SEARCH_VALUE=`grep "^$VALUE $SEPARATOR" "$DB_FILE"`
            if [ -z "$SEARCH_VALUE" ]
            then
                echo "No such key : \$<$VALUE>" >&2
                exit 1
            else
                VALUE=`echo "$SEARCH_VALUE" | sed 's/.* \([^ ]*\)$/\1/g'`
            fi
        fi
        ### if in form $<key> ###
        if [ `echo "$KEY" | grep '^\$.*$'` ]
        then
            ### parse value of $key ###
            KEY=`echo "$KEY" | sed 's/^\$\([^ ]*\)/\1/g'`
            SEARCH_KEY=`grep "^$KEY $SEPARATOR" "$DB_FILE"`
            if [ -z "$SEARCH_KEY" ]
            then        ### KEY NOT FOUND ###
                echo "No such key : \$<$KEY>" >&2
                exit 1
            else
                ### KEY FOUND ###
                KEY=`echo "$SEARCH_KEY" | sed 's/.* \([^ ]*\)$/\1/g'`
                SEARCH_KEY=`grep "^$KEY $SEPARATOR" "$DB_FILE"`
                if [ -z "$SEARCH_KEY" ]
                then
                    echo "$KEY $SEPARATOR $VALUE" >> "$DB_FILE"
                else
                    cat "$DB_FILE" | sed "/^$KEY $SEPARATOR/ s/[^ ]*$/$VALUE/g" > "$DB_FILE.temp"
                    cat $DB_FILE.temp > $DB_FILE && rm $DB_FILE.temp
                fi
            fi
            exit 0
        fi
        ### KEY in form <KEY>
        SEARCH_KEY=`grep "^$KEY $SEPARATOR" "$DB_FILE"`
        if [ -n "$SEARCH_KEY" ]  ### if key exists
        then                     ### Replacing key
            cat "$DB_FILE" | sed "/^$KEY / s/[^ ]*$/$VALUE/g" "$DB_FILE"
        else                     ### Creating new key
            echo "$KEY $SEPARATOR $VALUE" >> "$DB_FILE"
        fi
    fi
}

#STARTS#
if [ $# -ne 2 ]
then
    echo "Syntax error : put" >&2
    exit 1
else
    db_put "$1" "$2"
fi
