#!/bin/bash

#--------------------------------------------------------------------------
#                                                                
#                        ▌        ▜    ▐  ▐                ▌  
#           ▞▀▘▝▀▖▛▚▀▖▞▀▖▌▗▘▞▀▖▌ ▌▐ ▞▀▖▜▀ ▜▀ ▞▀▖▙▀▖▞▀▘  ▞▀▘▛▀▖
#           ▝▀▖▞▀▌▌▐ ▌▛▀ ▛▚ ▛▀ ▚▄▌▐ ▛▀ ▐ ▖▐ ▖▛▀ ▌  ▝▀▖▗▖▝▀▖▌ ▌
#           ▀▀ ▝▀▘▘▝ ▘▝▀▘▘ ▘▝▀▘▗▄▘ ▘▝▀▘ ▀  ▀ ▝▀▘▘  ▀▀ ▝▘▀▀ ▘ ▘
#
# Description:
#   This was inspired by https://what-if.xkcd.com/75/.
#
#   It manages to find out which words demand the maximum amount of 
#   consecutive keypresses when typed in an old phone keypad 
#   (https://en.wikipedia.org/wiki/Telephone_keypad#Layout_and_characters) — 
#   but it tries to extrapolate those findings to 15 languages.
#
#   Try it.
#   I discovered all those languages tie at 6 keypresses.
#   Except English and Finnish, with 7. 
#
#   Finnish words were always at key 8, by the way:
#   kouriintuntuvuutta, muututtua, puututtu, suututtu, ulottuvuuteen, 
#   uutuutta, uutuuttaan
#
#--------------------------------------------------------------------------
#
# Found this useful? Appalling? Appealing? Please let me know.
# The Unabashed welcomes your impressions. 
#
# You will find the
#   unabashed
# at the location opposite to
#   moc • thgimliam
#
#--------------------------------------------------------------------------
#
# License:
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# Check for missing commands
needed_commands="apt-get dpkg-query recode"

missing_counter=0
for needed_command in $needed_commands; do
    if ! hash "$needed_command" >/dev/null 2>&1; then
        printf "Command not found in PATH: %s\n" "$needed_command" >&2
        : $((missing_counter++))
    fi
done

if [[ $missing_counter -eq 1 ]]; then
    printf "At least %d command is missing, install it\n" "$missing_counter" >&2
    exit 1
elif [[ $missing_counter -gt 1 ]]; then
    printf "At least %d commands are missing, install them\n" "$missing_counter" >&2
    exit 2
fi
#--------------------------------------------------------------------------

# Program name from its filename
prog=${0##*/}

# Some colors
LIGHTRED='\e[1;31m'
LIGHTPURPLE='\e[1;35m'
YELLOW='\e[1;33m'
NC='\e[0m'  

# Calling for help is the same as calling without arguments.
case $1 in --help|-h)  $prog; exit 1  ;; esac


############################################################################
# Some variables
dictsDirectory="/usr/share/dict"
languagesArray=(brazilian catalan danish english faroese finnish french german irish italian manx polish spanish swedish ukrainian)
dictsArray=(brazilian catalan danish american-english-insane faroese finnish french ngerman irish italian manx polish spanish swedish ukrainian)
packagesArray=(wbrazilian wcatalan wdanish wamerican-insane wfaroese wfinnish wfrench wngerman wirish witalian wmanx wpolish wspanish wswedish wukrainian)
############################################################################

# If I want to print all results with 6 or more identical consecutive key presses
# (only English and Finnish have it for 7, it seems)
[[ $1 = "--print-all" ]] && {
    # Creates a temp file
    mkdir -p $HOME/tmp  &&  
    tempFile=$(mktemp --tmpdir=$HOME/tmp ${prog}.XXXXXXXXXX)

    # Find out what's missing and install it
    clear
    echo -e "You'll be prompted for your password: 
    (a) to install any missing dictionary, or 
    (b) to recode dictionaries, if needed.
Alternatively, you can cancel this and install it manually with:
sudo apt-get install ${packagesArray[*]}"
    echo
    echo "Checking for missing dictionaries..."
    missingPackages=$( \
        for package in ${packagesArray[*]}
        do
            dpkg-query -W -f='${Status} ${Version}\n' $package 2>&- >/dev/null ||
                echo $package 
        done)
    [[ -z $missingPackages ]] || sudo apt-get install $missingPackages

    # Makes sure to recode all to UTF-8, or <?> stuff appears
    (cd $dictsDirectory && 
        for language in $(file * | grep ISO-8859 | sed 's/:.*//')
        do 
            sudo recode iso885915..utf8 $dictsDirectory/$language
        done)
    sudo sed -i 's/\$\\$//' $dictsDirectory/finnish
    echo -e "All dictionaries installed and recoded.\n"

    # Populates it
    echo -n "Calculating for "

    for language in ${languagesArray[*]}
    do 
        [[ $language =~ finnish|english ]] && 
            minReps=7 || 
            minReps=6
        echo -n "$language... "
        echo -e "\n$language\n---------------" >> $tempFile
        $prog $language $minReps | 
            sed "s/ /,/g" | column -s, -t >> $tempFile
    done

    cat $tempFile
    echo "This file is located at $tempFile"

    exit 0
}

# Calls the help
[[ $# -ne 2 ]] && {
    clear
    echo -e "
${LIGHTRED}Description:${NC}
    Based on the code snippet in the beginning of ${LIGHTPURPLE}https://what-if.xkcd.com/75/${NC}
    extrapolated to other languages.

    It manages to find out which words demand the maximum amount of 
    consecutive keypresses when typed in an old phone keypad 
    (${LIGHTPURPLE}https://en.wikipedia.org/wiki/Telephone_keypad#Layout_and_characters${NC}) — 
    only it tries to extrapolate those important findings to 15 languages.

    Try it.
    I discovered all those languages tie at 6 keypresses.
    Except English and Finnish, with 7. 

    Finnish's were always at key 8, by the way:
    kouriintuntuvuutta, muututtua, puututtu, suututtu,  
    ulottuvuuteen, uutuutta, uutuuttaan
    
    If you want to install all dictionaries manually, try:
    ${YELLOW}sudo apt-get install ${packagesArray[*]}${NC}

${LIGHTRED}Usage:${NC}
   ${YELLOW}$prog [language] [number-of-consecutive-letters-to-consider]${NC}
${LIGHTRED}Example:${NC}
   ${YELLOW}$prog danish 5${NC}     # Prints results in Danish, 5 OR MORE letters
   ${YELLOW}$prog --print-all${NC}  # Prints results in the available languages

${LIGHTRED}Available languages:${NC}"
    echo "    ${languagesArray[*]}" | par 80p4
    echo
    exit 1
}

getIndexOfArrayElement()
# Usage: getIndexOfArrayElement [array] [string]
{
    myArray=($1)

    for i in "${!myArray[@]}"
    do
        if [[ "${myArray[i]}" = "$2" ]]
        then
            echo "$i"
            ((i++))
        fi
    done
}

############################################################################
## Some more variables
myLanguage=$1

# Basically, that's a string of "\1" repeated one time less 
# than the number of repetitions we need. Used as a back
# reference in a grep below
consecutiveLetters=$(i=1; while [[ i -lt $2 ]]; do echo -n "\1"; ((i++)); done)

myIndex=$(getIndexOfArrayElement "${languagesArray[*]}" "$myLanguage")

[[ -z $myIndex ]] && {
    echo -e "Uh-oh. Language not available. Try just $prog for help."
    exit 1
}

myDict=${dictsArray[$myIndex]}
myPackage=${packagesArray[$myIndex]}

############################################################################

[[ -f "$dictsDirectory/$myDict" ]] || { 
    echo "Dictionary for $myLanguage not available. Let's install it."
    sudo apt-get install $myPackage 
}

# This is not perfect. But good enough. Does the job.
< $dictsDirectory/$myDict \
    sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/" |
    awk '{print $0, toupper($0)}' |
    sed "y|ÁÉÍÓÚÄËÏÖÜÀÈÌÒÙÂÊÎÔÛÃẼĨÕŨÝŸỲŶÇÑÅØČĎŘŠŽĐĆŃÓŚŹŻĄĘŁȘȚIİĞŞĈĜĤĴŜŬĊĠĦ|AEIOUAEIOUAEIOUAEIOUAEIOUYYYYCNAOCDRSZDCNOSZZAELSTIIGSCGHJSUCGH|" |
    sed "s|Æ|2|g; s|Œ|6|g; s|Ð|3|g; s|Þ|8|g; s|\([A-Z]\)ß|\17|g" |
    tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' '22233344455566677778889999' | 
    grep -P "(.)$consecutiveLetters" 
   
#------------------END of PROGRAM----------------------------

