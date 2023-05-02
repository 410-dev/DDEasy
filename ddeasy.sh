#!/bin/bash

# Check if config.env exists. If not, copy the template
if [[ ! -f ./config.env ]]; then
    cp ./config.env.default ./config.env
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}E.M01: Failed to copy config.env.default to config.env${NC}"
        exit 1
    fi
    echo -e "Copied config.env.default to config.env"
fi
source ./config.env
if [[ $? -ne 0 ]]; then
    echo -e "${RED}E.M06: Failed to load config.env${NC}"
    exit 1
fi

if [[ "$*" == *"--backup"* ]]; then
    ACTION="backup"
elif [[ "$*" == *"--restore"* ]]; then
    ACTION="restore"
fi

if [[ "$*" == *"--nointeraction"* ]] || [[ "$NOINTERACTION" == 1 ]]; then
    export NOINTERACTION=1
    echo -e "${YELLOW}Running in no interaction mode.${NC}"
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}E.M02: Running in no interaction mode requires root.${NC}"
        exit 1
    fi
    if [[ -z "$ACTION" ]]; then
        echo -e "${RED}E.M03: Action must be specified when running in no interaction mode. (use --backup or --restore, or define in config.env)${NC}"
        exit 1
    fi
else
    export NOINTERACTION=0
fi

if [[ "$*" == *"--noconfirm"* ]] || [[ "$NOCONFIRM" == 1 ]]; then
    export NOCONFIRM=1
    echo -e "${YELLOW}Running in no confirm mode.${NC}"
else
    export NOCONFIRM=0
fi

if [[ "$NOINTERACTION" == 0 ]]; then
    echo -e -n "Enter the action (backup/restore) ($ACTION): "
    read -r ACTIONTMP
    if [[ ! -z "$ACTIONTMP" ]]; then
        ACTION="$ACTIONTMP"
    fi
    if [[ "$NOCONFIRM" != 1 ]]; then
        echo -e -n "Confirm action: $ACTION (y/n): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
            echo -e "Aborting"
            exit 1
        fi
    fi
    if [[ -z "$ACTION" ]]; then
        echo -e "${RED}E.M04: Action must be specified.${NC}"
        exit 1
    fi
fi

if [[ -x "./modules/$ACTION.sh" ]]; then
    echo -e "Running $ACTION.sh"
    "./modules/$ACTION.sh" "$@"
else
    echo -e "${RED}E.M05: Action $ACTION not found.${NC}"
    exit 1
fi
