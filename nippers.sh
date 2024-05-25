#!/bin/bash

#   "Nippers" - Multimedia file cutter
# 
#   Copyright (C) Codemeow 2024
# 
#   This file is part of Project "Nippers".
# 
#   Project "Nippers" is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
# 
#   Project "Nippers" is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU Lesser General Public License for more details.
# 
#   You should have received a copy of the GNU Lesser General Public License
#   along with Project "Nippers". If not, see <http://www.gnu.org/licenses/>.

##! \brief Nippers - multimedia file cutter
# The script cuts the provided multimedia file into pieces of the same format,
# using the provided config file as the time and naming guide.
# Ex. of use:
# ~~~
# $ cat config.txt
# 00:00 Entering the void
# 03:15 Warm abyss
# 06:11 ---
# 07:21 The end
#
# $ nippers.sh -i /mnt/music/void.avi -c ./config.txt -o /mnt/music/Void
# Extracting: "Entering the void"
#  - Time info: 0 + 195 s
# Extracting: "Warm abyss"
#  - Time info: 195 + 154 s
# Skipping:
#  - Time info: 394 + 92 s
# Extracting: "04. Everything_s Alright"
#  - Time info: 441 + 110 s
#
# $ ls /mnt/music/Void
# 'Entering the void.avi' 'Warm abyss.avi' 'The end.avi'
# ~~~

set -e

##! \brief Config file
# Expected format:
# ~~~
# [HH:]MM:SS Track name
# ...
# ~~~
# Ex.:
# ~~~
#   00:00 01. Overture
#   05:39 02. Heaven On Their Minds
#    ...
# 1:42:04 35. John Nineteen - Forty-One
# 1:44:20 ---
# ~~~
# \note Special track name "---" is used to skip the track when exporting
file_config=""

##! \brief Multimedia file
# Anything that is supported by ffmpeg
file_multimedia=""

##! \brief Output directory
dir_output=""

    # @TODO Meta-info
    # @TODO Format change
    # @TODO Additional ffmpeg params
    # @TODO Check for config file sanity (time must not exceed input file)

##! \brief Prints usage and exits
function util_help() {
    echo "# Use:"                       >&2
    echo "#    -i <multimedia file>"    >&2
    echo "#    -c <timings file>"       >&2
    echo "#    -o <output directory>"   >&2
    exit 1
}

##! \brief Returns file's track length
# \param[in] $1 Filename
# \return Multimedia duration in seconds (integer)
function multimedia_length() {
    ffprobe -i "$1" -show_entries format=duration -v quiet -of csv="p=0" | awk -F'.' '{print $1}'
}

##! \brief Extracts part of the multimedia file
# \param[in] $1 Track name/target file name
# \param[in] $2 Start time
# \param[in] $3 End time
function multimedia_extract() {
    local time_length=$((10#$3-10#$2))
    local file_extension="${file_multimedia##*.}"

    if [ ! -z "$1" ]; then
        if [ "$1" == "---" ]; then
            echo "Skipping:"
            echo " - Time info: $2 + ${time_length} s"
        else
            echo "Extracting: \"$1\""
            echo " - Time info: $2 + ${time_length} s"
            ffmpeg                                      \
                -nostdin                                \
                -y                                      \
                -v quiet                                \
                -ss "$2"                                \
                -t ${time_length}                       \
                -i "$file_multimedia"                   \
                -acodec copy                            \
                "${dir_output}/${1}.${file_extension}"
        fi
    fi
}

##! \brief Processes program inputs
# \param[in] $@ List of program arguments
function step_arguments() {
    local has_c=false
    local has_i=false
    local has_o=false

    while getopts "c:i:o:h" opt; do
        case $opt in
            c)
                if [ "$has_c" = true ]; then
                    echo "! Config file cannot be set twice" >&2
                    util_help
                fi
                has_c=true
                file_config=$OPTARG
                ;;
            i)
                if [ "$has_i" = true ]; then
                    echo "! Multimedia file cannot be set twice" >&2
                    util_help
                fi
                has_i=true
                file_multimedia=$OPTARG
                ;;
            o)
                if [ "$has_o" = true ]; then
                    echo "! Output directory cannot be set twice" >&2
                    util_help
                fi
                has_o=true
                dir_output=$OPTARG
                ;;
            h)
                util_help
                ;;
            \?)
                echo "! Unknown option: -$OPTARG" >&2
                util_help
                ;;
        esac
    done

    if [ -z "$file_multimedia" ]; then
        echo "! No multimedia file provided" >&2
        util_help
    fi

    if [ -z "$file_config" ]; then
        echo "! No config file provided" >&2
        util_help
    fi

    if [ -z "$dir_output" ]; then
        echo "! No output directory provided" >&2
        util_help
    fi
}

##! \brief Trims the spaces from the string
# \param[in] $1 Input string
# \return Trimmed string
function util_trim() {
    echo -n "${1##*([[:space:]])}"
}

##! \brief Sanitizes the dangerous symbols from string
# \param[stdin] String
# \return Safe string
function util_sanitize() {
    echo -n "$(cat)" | sed 's/[\/\\:*?"'\'']/_/g'
}

##! \brief Extracts time block from the config line
# \param[in] Config line
# \return Time part
function str_time() {
    echo "$1" | awk '{print $1}'
}

##! \brief Extracts track name block from the config line
# \param[in] Config line
# \return Track name part
function str_name() {
    echo "$1" | awk '{$1=""; print substr($0,2)}' | util_sanitize
}

##! \brief Converts time block into seconds
# \param[in] Time string
# \return Seconds as integer
function str_position() {
    IFS=':' read -r -a time_array <<< "$1"

    case ${#time_array[@]} in
        2) 
            echo $((10#${time_array[0]} * 60 + 10#${time_array[1]}))
            ;;
        3)  
            echo $((10#${time_array[0]} * 3600 + 10#${time_array[1]} * 60 + 10#${time_array[2]}))
            ;;
        *) 
            echo "! Incorrect time format: \"$line_time\", expected MM:SS or HH:MM:SS" >&2
            exit 1
            ;;
    esac
}

##! /brief Processes provided multimedia and config file
function step_process() {
    local time_last=0;
    local time_position=0;
    local name_last="";

    while IFS= read -r line; do
        local line_trimmed=""
        local line_time=""
        local line_name=""

        if [ -z "$line" ]; then
            continue
        fi

        line_trimmed=$(util_trim "$line")
        line_time=$(str_time "$line_trimmed")
        line_name=$(str_name "$line_trimmed")

        time_position=$(str_position "$line_time")

        multimedia_extract "$name_last" "$time_last" "$time_position"
        
        time_last=$time_position
        name_last=$line_name

    done < "$file_config"

    time_position=$(multimedia_length "$file_multimedia")

    multimedia_extract "$name_last" "$time_last" "$time_position"
}

step_arguments $@
step_process
