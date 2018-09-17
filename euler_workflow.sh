# ------------------------------------------------------------------------------------------------------------
# Set of BASH functions to manage the workflow on Euler (could be edited to adapt to other server)
# ------------------------------------------------------------------------------------------------------------
#
# 
# ------------------------------------------------------------------------------------------------------------
# Author: Benoit Guillod (benoit.guillod@env.ethz.ch)
#
# 
# ------------------------------------------------------------------------------------------------------------
# Goal: When editing a file locally which needs to be tested on Euler, the files can be easily sent onto a temporary folder on Euler for testing. If changes are applied to the file on Euler, the file can be easily copied back locally. Source this file in your .bashrc or .bash_profile to always have these functions loaded in your environment.
#
# 
# ------------------------------------------------------------------------------------------------------------
# Principle: set of three functions:
#     1) test2euler : Copy the desired file on Euler in a folder "tests" on your Euler home.
#     2) euler2local_check : Print the difference between the file on euler and the local file, as well as the list of other files on Euler with matching names.
#     3) euler2local_get : Copy the file from Euler back locally (prompt confirmation after printing the diff)
#
#
# ------------------------------------------------------------------------------------------------------------
# Pre-requisites:
#     1) The local username matches the username on Euler. If not, a variable $USER_EULER must be already defined.
#     2) A folder "tests" must exists in your home on euler.
#
#
# ------------------------------------------------------------------------------------------------------------
# Description of the functions:
#     1) test2euler : copy the desired file on Euler in a folder "tests" on your home. The local file name (and path) of the last call to test2euler is stored in bash as __localfile_uploaded while the file name (and path) on euler is stored in bash as __eulerfile_uploaded, which are both used in the other functions
#         Arguments:
#             1) file to be send onto Euler
#             2 (optional) name to be given on the file on euler
#                 Can take the following values:
#                 - orig : original name of the file (i.e., unchanged)
#                 - not given : add a random 8 character string to the end of the file name
#                 - other : name to be used
#             3 (optional) name of bash variable where the file name on euler should be stored (optional, can be handy when calling the other functions)
#        Examples:
#             test2euler file.m                    # copies file.m in folder tests on the home and adds a 8-digit random string (e.g., file_b4701a83.m)
#             test2euler file.m orig               # copies file.m in folder tests on the home (without altering the file name)
#             test2euler file.m file_to_edit.m     # copies file.m in folder tests on the home which will be named file_to_edit.m
#             test2euler file.m filen23.m FNAME2   # copies file.m in folder tests on the home as filen23.m and store filen23.m in FNAME2 for later use in bash
#
#     2) euler2local_check : Print the difference between the file on euler and the local file, as well as the list of other files on Euler with matching names. If no input is given, the files from the last call to test2euler will be used. If a single file name is given (local file), the file is assumed to have the same name on Euler. If two arguments are given, the first is the local file while the second is the file name on Euler.
#         Arguments:
#             1 (optional) local file name. If empty, uses file names from the last call to test2euler (stored as __localfile_uploaded and __eulerfile_uploaded)
#             2 (optional) file name on euler. If empty, assuming it is as the local file name.
#        Examples:
#             euler2local_check                    # print a diff of __eulerfile_uploaded (on Euler) vs __localfile_uploaded (locally) and print similar file names on Euler.
#             euler2local_check file.m             # print a diff of file.m (on Euler) vs file.m (locally) and print similar file names on Euler.
#             euler2local_check file.m file_23.m   # print a diff of file_23.m (on Euler) vs file.m (locally) and print similar file names on Euler.
# 
#
#     3) euler2local_get : Copy the modified file from Euler on the local disk, print a diff and ask confirmation that the local file should be overwritten with these modifications. If declined, ask whether to keep a copy of the modified file locally or to delete it.
#         Arguments:
#             1 (optional) local file name. If empty, uses file names from the last call to test2euler (stored as __localfile_uploaded and __eulerfile_uploaded)
#             2 (optional) file name on euler. If empty, assuming it is as the local file name.
#        Examples:
#             euler2local_get                      # print a diff of __eulerfile_uploaded (on Euler) vs __localfile_uploaded (locally) and ask whether to overwrite the local file with the Euler file.
#             euler2local_get file.m             # print a diff of file.m (on Euler) vs file.m (locally) and ask whether to overwrite the local file with the Euler file.
#             euler2local_get file.m file_23.m   # print a diff of file_23.m (on Euler) vs file.m (locally) and ask whether to overwrite the local file with the Euler file.
#
# ------------------------------------------------------------------------------------------------------------


if [ -z "$USER_EULER" ]; then
    USER_EULER=$USER
fi

test2euler() {
    if [ $# -eq 0 ]; then
        echo '** no argument provided **'
        return
    elif [ $# -eq 1 ]; then
        local s=`cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c 8`
        local extension="${1##*.}"
        s=${1%.*}_${s}.${extension}
        s=${s##*/}
        local outfile="/cluster/home/${USER_EULER}/tests/${s}"
    elif [ $2 = 'orig' ]; then
        local outfile=/cluster/home/${USER_EULER}/tests/${1##*/}
    else
        local outfile=/cluster/home/${USER_EULER}/tests/${2}
    fi
    scp $1 ${USER_EULER}@euler.ethz.ch:$outfile
    echo "File now there on Euler: ${outfile}"
    if [ $# -eq 3 ]; then
        local __resultvar=$3
        eval $__resultvar="'$outfile'"
    fi
    local nowdir=`pwd`
    __localfile_uploaded=${nowdir}/${1}
    __eulerfile_uploaded="$outfile"
}

euler2local_check() {
    # no input variable: uses __localfile_uploaded and __eulerfile_uploaded from the last call
    # 1 input variable: must be the local file, the script assumes the same name is given on Euler
    # 2 input variables: $1 is the local file, $2 is the file on Euler
    local s=`cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c 8`
    if [ $# -eq 0 ]; then
        if [ -z "$__eulerfile_uploaded" ]; then
            echo '** unknown Euler file - either provide name or make sure __eulerfile_uploaded contains the file location on euler **'
        elif [ -z "$__localfile_uploaded" ]; then
            echo '** unknown local file - either provide name or make sure __localfile_uploaded contains the file location locally **'
        else
            local euler_file=${__eulerfile_uploaded##*/}
            local tempfile_orig=${__localfile_uploaded}
            local tempfile_modif=${tempfile_orig}_${s}
        fi
    elif [ $# -eq 1 ]; then
        local euler_file=${1##*/}
        local tempfile_orig=${1}
        local tempfile_modif=${tempfile_orig}_${s}
    else
        local euler_file=$2
        local tempfile_orig=${1}
        local tempfile_modif=${tempfile_orig}_${s}
    fi
    # check that euler_file exists on euler
    local temp1="ssh ${USER_EULER}@euler.ethz.ch 'if [ -f tests/$euler_file ]; then echo 1; else echo 0; fi'"
    local temp1=`eval $temp1`
    if [ $temp1 -eq 0 ]; then
        printf "\nThe file on euler:${euler_file} does not exist"
        printf "\nAll files with similar name on euler:"
        local tempfile_orig_short=${tempfile_orig##*/}
        tempfile_orig_short=${tempfile_orig_short%.*}
        for file in `ssh ${USER_EULER}@euler.ethz.ch "ls tests/${tempfile_orig_short}*"`; do printf "\n$file"; done
        printf "\n"
        return
    fi
    scp ${USER_EULER}@euler.ethz.ch:/cluster/home/${USER_EULER}/tests/${euler_file} ${tempfile_modif}
    printf "\nDifference between files (1) euler:${euler_file} and (2) ${tempfile_orig} :\n"
    diff -s $tempfile_modif $tempfile_orig
    rm $tempfile_modif
    printf "\nAll files with similar name on euler:\n"
    local tempfile_orig_short=${tempfile_orig##*/}
    tempfile_orig_short=${tempfile_orig_short%.*}
    for file in `ssh ${USER_EULER}@euler.ethz.ch "ls tests/${tempfile_orig_short}*"`; do printf "$file\n"; done
    printf "\n"
}

euler2local_get() {
    # no input variable: uses __localfile_uploaded and __eulerfile_uploaded from the last call
    # 1 input variable: must be the local file, the script assumes the same name is given on Euler
    # 2 input variables: $1 is the local file, $2 is the file on Euler
    local s=`cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c 8`
    if [ $# -eq 0 ]; then
        if [ -z "$__eulerfile_uploaded" ]; then
            echo '** unknown Euler file - either provide name or make sure __eulerfile_uploaded contains the file location on euler **'
        elif [ -z "$__localfile_uploaded" ]; then
            echo '** unknown local file - either provide name or make sure __localfile_uploaded contains the file location locally **'
        else
            local euler_file=${__eulerfile_uploaded##*/}
            local tempfile_orig=${__localfile_uploaded}
            local tempfile_modif=${tempfile_orig}_${s}
        fi
    elif [ $# -eq 1 ]; then
        local euler_file=${1$$*/}
        local tempfile_orig=${1}
        local tempfile_modif=${tempfile_orig}_${s}
    else
        local euler_file=$2
        local tempfile_orig=${1}
        local tempfile_modif=${tempfile_orig}_${s}
    fi
    # check that euler_file exists on euler
    local temp1="ssh ${USER_EULER}@euler.ethz.ch 'if [ -f tests/$euler_file ]; then echo 1; else echo 0; fi'"
    local temp1=`eval $temp1`
    if [ $temp1 -eq 0 ]; then
        printf "\nThe file on euler:${euler_file} does not exist"
        printf "\nAll files with similar name on euler:"
        local tempfile_orig_short=${tempfile_orig##*/}
        tempfile_orig_short=${tempfile_orig_short##*.}
        for file in `ssh ${USER_EULER}@euler.ethz.ch "ls tests/${tempfile_orig_short}*"`; do printf "\n$file"; done
        printf "\n"
        return
    fi
    scp ${USER_EULER}@euler.ethz.ch:/cluster/home/${USER_EULER}/tests/${euler_file} ${tempfile_modif}
    printf "\nDifference between files (1) euler:${euler_file} and (2) ${tempfile_orig} :"
    diff -s $tempfile_modif $tempfile_orig
    echo ""
    while true; do
        read -p "Do you wish to accept these changes and overwrite the local file? (y/n/c) " yn
        case $yn in
            [Yy]* ) mv ${tempfile_modif} $tempfile_orig; break;;
            [Cc]* ) rm ${tempfile_modif}; echo "operation cancelled, file deleted"; break;;
            [Nn]* ) read -p "Do you wish to keep the modified file? (y/n/c) " yynn;
                    case $yynn in
                        [Yy]* ) echo "modified file kept as ${tempfile_modif}"; break;;
                        [Cc]* ) rm ${tempfile_modif}; "operation cancelled, file deleted"; break;;
                        [Nn]* ) rm ${tempfile_modif}; echo "modified file deleted"; break;;
                    esac;
                    break;;
        esac
    done
}
