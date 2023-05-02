#!/bin/bash

# Load the configuration
source ./config.env
if [[ $? -ne 0 ]]; then
    echo -e "${RED}E.R01: Failed to load config.env${NC}"
    exit 1
fi


if [[ "$*" == *"--nointeraction"* ]] || [[ "$NOINTERACTION" == 1 ]]; then
    export NOINTERACTION=1
else
    export NOINTERACTION=0
fi

if [[ "$*" == *"--noconfirm"* ]] || [[ "$NOCONFIRM" == 1 ]]; then
    export NOCONFIRM=1
else
    export NOCONFIRM=0
fi

# Check if the devices are found
DEVS="$(lsblk -o NAME -n -i -r)"
if [[ -z "$DEVS" ]]; then
    echo -e "${RED}E.R02: No devices found. (lsblk empty)${NC}"
    exit 1
fi

if [[ "$NOINTERACTION" == 1 ]]; then
    if [[ -z "$SOURCE" ]]; then
        SOURCE="$1"
        if [[ -z "$SOURCE" ]]; then
            echo -e "${RED}E.R03: Source file must be specified when running in no interaction mode. (define in config.env, or put as first argument)${NC}"
            exit 1
        fi
    fi
    if [[ ! -f "$SOURCE" ]]; then
        echo -e "${RED}E.R04: Source file does not exist.${NC}"
        exit 1
    fi

    if [[ -z "$TARGET" ]]; then
        TARGET="$2"
        if [[ -z "$TARGET" ]]; then
            echo -e "${RED}E.R05: Destinatinon device must be specified when running in no interaction mode. (define in config.env, or put as second argument)${NC}"
            exit 1
        fi
    fi

    if [[ -z "$BS" ]]; then
        BS="64k"
    fi

else
    echo -e "Available devices:"
    echo -e "$DEVS"
    echo -e -n "Enter the source file ($SOURCE): "
    read -r SOURCETMP
    if [[ ! -z "$SOURCETMP" ]]; then
        SOURCE="$SOURCETMP"
    fi
    if [[ "$NOCONFIRM" != 1 ]]; then
        echo -e -n "Confirm source file: $SOURCE (y/n): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
            echo -e "Aborting"
            exit 1
        fi
    fi
    if [[ -z "$SOURCE" ]]; then
        echo -e "${RED}E.R06: Source file must be specified.${NC}"
        exit 1
    fi

    echo -e -n "Enter the target device ($TARGET): "
    read -r TARGETTMP
    if [[ ! -z "$TARGETTMP" ]]; then
        TARGET="$TARGETTMP"
    fi
    if [[ "$NOCONFIRM" != 1 ]]; then
        echo -e -n "Confirm target device: $TARGET (y/n): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
            echo -e "Aborting"
            exit 1
        fi
    fi
    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}E.R07: Target device must be specified.${NC}"
        exit 1
    fi

    if [[ -z "$BS" ]]; then
        BS="64k"
    fi
    echo -e -n "Enter the block size ($BS): "
    read -r BSTMP
    if [[ ! -z "$BSTMP" ]]; then
        BS="$BSTMP"
    fi
    if [[ "$NOCONFIRM" != 1 ]]; then
        echo -e -n "Confirm block size: $BS (y/n): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
            echo -e "Aborting"
            exit 1
        fi
    fi
fi


if [[ ! -f "$SOURCE" ]]; then
    echo -e "${RED}E.R08: Source file does not exist.${NC}"
    exit 1
fi
if [[ -z "$(file "$SOURCE" | grep "gzip compressed data")" ]]; then
    echo -e "${RED}E.R09: Source file is not a gzip compressed file.${NC}"
    exit 1
fi
if [[ ! -b "$TARGET" ]]; then
    echo -e "${RED}E.R10: Target device does not exist.${NC}"
    exit 1
fi

BOOTDEVICE="$(lsblk -no pkname $(findmnt -n / | awk '{ print $2 }'))"
if [[ *"$BOOTDEVICE"* == *"$TARGET"* ]]; then
    echo -e "${RED}E.R11: Target device is the same as the boot device.${NC}"
    exit 1
fi
DFRESULT="$(df "$SOURCE" | awk '{ print $1 }' | grep "$TARGET")"
if [[ ! -z "$DFRESULT" ]]; then
    echo -e "${RED}E.R12: Target device cannot be restored if it contains backup file to restore.${NC}"
    exit 1
fi


echo -e ""
echo -e "Configurations:"
echo -e "Source: $SOURCE"
echo -e "Target: $TARGET"
echo -e "BS: $BS"

if [[ "$NOINTERACTION" == 0 ]] && [[ $NOCONFIRM != 1 ]]; then
    echo -e -n "Are these configurations correct? (y/n): "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
        echo -e "Aborting"
        exit 1
    fi
else
    echo -e "No interaction / confirm mode, skipping confirmation."
fi

echo ""
echo "Restoring $SOURCE to $TARGET with block size $BS"
if [[ "$*" == "--progress" ]] || [[ "$PROGRESS" == 1 ]]; then
    gzip -dc "$SOURCE" | sudo dd of="$TARGET" conv=sync,noerror bs="$BS" status=progress
    SUCCESS="$?"
else
    gzip -dc "$SOURCE" | sudo dd of="$TARGET" conv=sync,noerror bs="$BS"
    SUCCESS="$?"
fi

if [[ "$SUCCESS" != 0 ]]; then
    echo -e "${RED}E.R13: Restore failed.${NC}"
    exit 1
else
    echo -e "${GREEN}Restore successful.${NC}"
    exit 0
fi
