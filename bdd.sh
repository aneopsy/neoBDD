#!/bin/sh

### VARIABLES ####

E_NOARGS=68
VERBOSE=1
DB_FILE="sh.db"
DB_HEADER="neoBDSH V0.1\nLast update:   `date`"
SEPARATOR=' #:@:# '
KEY=""
VALUE=""


###########################
####    FUNCTIONS      ####
###########################

usage ()
{
    echo "Usage:" >&2
    cat<<EOF
bdsh.sh [-v] [(-f | -c) <db_file>] (put (<key> | $<key>) (<value> | $<key>) |
                                    del (<key> | $<key>) [<value> | $<key>] |
                                    select [<expr> | $<key>]
                                    flush)
EOF
}


file_error ()
{
    echo "No base found : $DB_FILE" >&2
    exit 1
}

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
    if [ -n "$1" ] && [ -n "$2" ]
    then
    KEY="$1"
    VALUE="$2"
    set_output
    ### check if $ is in ###
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
    #### if in form $<key> ###
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
        cat "$DB_FILE" | sed "/^$KEY / s/[^ ]*$/$VALUE/g" > "$DB_FILE.temp"
        cat $DB_FILE.temp > $DB_FILE && rm $DB_FILE.temp
    else                     ### Creating new key
        echo "$KEY $SEPARATOR $VALUE" >> "$DB_FILE"
    fi
    fi
}

db_del ()
{
    KEY="$1"
    VALUE="$2"
    ### if in form $key ###
    if [ `echo "$KEY" | grep '^\$.*$'` ]
    then
        ### parse value of $key ###
        KEY=`echo "$KEY" | sed 's/^\$\([^ ]*\)/\1/g'`
        SEARCH_KEY=`grep "^$KEY $SEPARATOR" "$DB_FILE"`
        KEY=`echo "$SEARCH_KEY" | sed 's/.* \([^ ]*\)$/\1/g'`
    fi
    if [ -z "$2" ]
    then
        ### searching key ###
        SEARCH_KEY=`grep "^$KEY $SEPARATOR" "$DB_FILE"`
        ### Check if key found ###
        if [ -n "$SEARCH_KEY" ]
        then
            VALUE=`echo "$SEARCH_KEY" | sed 's/.* \([^ ]*\)$/\1/g'`
            cat "$DB_FILE" | sed "/^$KEY / s/[^ ]*$//g" > "$DB_FILE.temp"
            cat $DB_FILE.temp > $DB_FILE && rm $DB_FILE.temp
        fi
    else
        ### Detecting value form
        if [ `echo "$VALUE" | grep '^\$.*$'` ]
        then
            VALUE=`echo "$VALUE" | sed 's/^\$\([^ ]*\)/\1/g'`
            SEARCH_VALUE=`grep "^$VALUE $SEPARATOR" "$DB_FILE"`
            VALUE=`echo "$SEARCH_VALUE" | sed 's/.* \([^ ]*\)$/\1/g'`
        fi
        if [ -n "$VALUE" ]
        then
            cat "$DB_FILE" | sed "/^$KEY/d" > "$DB_FILE.temp"
            cat $DB_FILE.temp > $DB_FILE && rm $DB_FILE.temp
        fi
    fi
    exit 0
}

db_select ()
{
    ### if $key or $value no set ###
    if [ ! "$1" ]
    then
        cat "$DB_FILE" | sed "s/^.* $SEPARATOR //g"
        exit 0
    else
        KEY="$1"
        ### $key state ###
        if [ `echo "$KEY" | grep '^\$.*$'` ]
        then
            ### parse $key value ###
            KEY=`echo "$KEY" | sed 's/^\$\([^ ]*\)/\1/g'`
            SEARCH_KEY=`grep "^$KEY $SEPARATOR" "$DB_FILE"`
            KEY=`echo "$SEARCH_KEY" | sed 's/.* \([^ ]*\)$/\1/g'`
            SEARCH_KEY=`grep "^$KEY $SEPARATOR" "$DB_FILE"`
            ### Check if key exist ###
            if [ -z "$SEARCH_KEY" ]
            then
                echo "No such key : \$<$KEY>" >&2
                exit 1
            fi
            # VALUE=`echo "$SEARCH_KEY" | sed 's/.* \([^ ]*\)$/\1/g'`
            VALUE=`echo "$SEARCH_KEY" | awk -F "$SEPARATOR" '{print $2}'`
            if [ $VERBOSE = "0" ]
            then
                echo "<$KEY>=<$VALUE>"
            else
                echo $VALUE
            fi
            exit 0
        else
            if [ $VERBOSE = "0" ]
            then
                TMP=`grep ".*$KEY.* $SEPARATOR" "$DB_FILE"`
                if [ -z "$TMP" ]
                then
                    echo "$KEY="
                else
                    grep ".*$KEY.* $SEPARATOR" "$DB_FILE" | sed "s/ $SEPARATOR /=/g"
                fi
                exit 0
            else
                grep ".*$KEY.* $SEPARATOR" "$DB_FILE"  | sed "s/^.* $SEPARATOR //g"
            fi
            exit 0
        fi
    fi
}

dump ()
{
    [ -f sh.db ] && cat sh.db
    [ ! -f sh.db ] && cat *.db
}

#############################
#### PROGRAM STARTS HERE ####
#############################

if [ ! "$1" ]
then
    usage
    exit $E_NOARGS
fi

while [ $# -gt 0 ]; do
    case "$1" in
    -v)
        VERBOSE=0
        ;;
    -c|-f)
        DB_FILE="$2"
        if [ -n "$2" ]
        then
            if [ ! -f "$DB_FILE" ] && [ "$1" = "-f" ]
            then
                echo "File not found : $DB_FILE " >&2
                exit 1
            else
                shift 1
            fi
        else
            usage
            exit $E_NOARGS
        fi
        ;;
    -*)
        usage
        exit $E_NOARGS
        ;;
    put)
        if [ $# -ne 3 ]
        then
            echo "Syntax error : put" >&2
            usage
            exit $E_NOARGS
                #statements
        else
            ### Put cmd ###
            db_put "$2" "$3"
            shift 2
        fi
        ;;
    del)
        if [ -n "$2" ] && [ ! $4 ]
        then
            ### Del cmd ###
            db_del "$2" "$3"
            shift 2
        else
            echo "Syntax error : del" >&2
            usage
            exit $E_NOARGS
        fi
        ;;
    select)
        if [ $# -lt 3 ]
        then
            ### Select cmd ###
            db_select "$2"
            shift 1
            exit 0
        else
            echo "Syntax error : select" >&2
            usage
            exit $E_NOARGS
        fi
        ;;
    flush)
        if [ "$#" -eq "1" ]
        then
            ### Flush cmd ###
            echo "$DB_HEADER" > "$DB_FILE"
            exit 0
        else
            usage
            exit $E_NOARGS
        fi
        ;;
    dump)
        dump
        ;;
    *)
        usage
        break;;
    esac
    shift 1
done
#END
