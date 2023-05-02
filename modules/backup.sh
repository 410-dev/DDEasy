#!/bin/bash

# Load the configuration
source ./config.env
if [[ $? -ne 0 ]]; then
    echo -e "${RED}E.B01: Failed to load config.env${NC}"
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

# Detect the device name
if [[ -z "$SOURCE" ]]; then
    SOURCESHORT="$(lsblk -no pkname $(findmnt -n / | awk '{ print $2 }'))"
    SOURCE="/dev/$SOURCESHORT"
fi
DEVS="$(lsblk -o NAME -n -i -r)"

# Check if the devices are found
if [[ -z "$DEVS" ]]; then
    echo -e "${RED}E.B02: No devices found. (lsblk empty)${NC}"
    exit 1
elif [[ -z "$(echo -e "$DEVS" | grep "$SOURCESHORT")" ]]; then
    echo -e "${RED}E.B03: Device $SOURCE not found. (source not in lsblk)${NC}"
    exit 1
fi

if [[ "$NOINTERACTION" == 1 ]]; then
    if [[ -z "$SOURCE" ]]; then
        SOURCE="$1"
        if [[ -z "$SOURCE" ]]; then
            echo -e "${RED}E.B04: Source device must be specified when running in no interaction mode. (define in config.env, or put as first argument)${NC}"
            exit 1
        fi
    fi

    if [[ -z "$TARGET" ]]; then
        TARGET="$2"
        if [[ -z "$TARGET" ]]; then
            echo -e "${RED}E.B05: Destinatinon path must be specified when running in no interaction mode. (define in config.env, or put as second argument)${NC}"
            exit 1
        fi
    fi

    if [[ -z "$NAMING" ]]; then
        NAMING="$3"
        if [[ -z "$NAMING" ]]; then
            echo -e "${RED}E.B06: Naming scheme must be specified when running in no interaction mode. (define in config.env, or put as third argument)${NC}"
            exit 1
        fi
    fi
    
    if [[ -z "$BS" ]]; then
        BS="64k"
    fi

else
    echo -e "Available devices:"
    echo -e "$DEVS"
    echo -e -n "Enter the source device name ($SOURCE): "
    read -r SOURCETMP
    if [[ ! -z "$SOURCETMP" ]]; then
        SOURCE="$SOURCETMP"
    fi
    if [[ "$NOCONFIRM" != 1 ]]; then
        echo -e -n "Confirm source device: $SOURCE (y/n): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
            echo -e "Aborting"
            exit 1
        fi
    fi
    if [[ -z "$SOURCE" ]]; then
        echo -e "${RED}E.B07: Source device must be specified.${NC}"
        exit 1
    fi

    echo -e -n "Enter the destination path ($TARGET): "
    read -r TARGETTMP
    if [[ ! -z "$TARGETTMP" ]]; then
        TARGET="$TARGETTMP"
    fi
    if [[ "$NOCONFIRM" != 1 ]]; then
        echo -e -n "Confirm destination directory path: $TARGET (y/n): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
            echo -e "Aborting"
            exit 1
        fi
    fi
    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}E.B08: Destination directory path must be specified.${NC}"
        exit 1
    fi

    echo -e -n "Enter the naming scheme ($NAMING): "
    read -r NAMINGTMP
    if [[ ! -z "$NAMINGTMP" ]]; then
        NAMING="$NAMINGTMP"
    fi
    if [[ "$NOCONFIRM" != 1 ]]; then
        echo -e -n "Confirm naming scheme: $NAMING (y/n): "
        read -r CONFIRM
        if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
            echo -e "Aborting"
            exit 1
        fi
    fi
    if [[ -z "$NAMING" ]]; then
        echo -e "${RED}E.B09: Naming scheme must be specified.${NC}"
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

# Check if the destination is a directory, and is in the source device
if [[ -d "$TARGET" ]]; then
    DFRESULT="$(df "$TARGET" | awk '{ print $1 }' | grep "$SOURCE")"
    if [[ ! -z "$DFRESULT" ]]; then
        echo -e "${RED}E.B10: Destination directory must not be in the source device.${NC}"
        exit 1
    fi
else
    echo -e "${RED}E.B11: Destination must be a directory.${NC}"
    exit 1
fi

echo -e ""
echo -e "Configurations:"
echo -e "Source: $SOURCE"
echo -e "Destination: $TARGET/$NAMING.img.gz"
echo -e "Action: $ACTION"
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
echo "Backing up $SOURCE to $TARGET/$NAMING.img.gz"
if [[ "$*" == "--progress" ]] || [[ "$PROGRESS" == 1 ]]; then
    sudo dd if="$SOURCE" conv=sync,noerror bs=64K status=progress | gzip -c > "$TARGET"/"$NAMING".img.gz
    SUCCESS="$?"
else
    sudo dd if="$SOURCE" conv=sync,noerror bs=64K | gzip -c > "$TARGET"/"$NAMING".img.gz
    SUCCESS="$?"
fi

if [[ "$SUCCESS" != 0 ]]; then
    echo -e "${RED}E.B12: Backup failed.${NC}"
    exit 1
else
    echo -e "${GREEN}Backup successful.${NC}"
    exit 0
fi
