#!/bin/bash -e
# (c) Copyright 2025 Manuel Schreiner
#
# general build script for KiCAD projects

working_directory=$(cd "$(dirname "$0")"; pwd)
cd "$working_directory"

KICAD_CLI=$(which kicad-cli)
DATETIME=$(date +"%Y-%m-%d-%H%M")
KICAD_PROJECT=$(basename *.kicad_pro)


if [ ! "$PROJECT_NAME" ]; then
    if [ "${CI_PROJECT_NAME}" ]; then
        PROJECT_NAME="$CI_PROJECT_NAME"
    elif [ "$KICAD_PROJECT" ]; then
        PROJECT_NAME=${KICAD_PROJECT%.*}
    else
        PROJECT_NAME="$(basename $(pwd))"
    fi
fi

if [ ! "${BASE_FILE_NAME}" ]; then
    BASE_FILE_NAME="${PROJECT_NAME}"
    if [ "${CI_COMMIT_BRANCH}" ]; then
        BASE_FILE_NAME="${BASE_FILE_NAME}-${CI_COMMIT_BRANCH}"
    fi
fi

if [ ! "${KICAD_SCH_FILE}" ]; then
    KICAD_SCH_FILE="${PROJECT_NAME}.kicad_sch"
fi

if [ ! "${KICAD_PCB_FILE}" ]; then
    KICAD_PCB_FILE="${PROJECT_NAME}.kicad_pcb"
fi

if [ ! "${SCHEMATIC_FILE}" ]; then
    SCHEMATIC_FILE="schematic-${BASE_FILE_NAME}.pdf"
fi

if [ ! "${BOM_FILE}" ]; then
    BOM_FILE="bom-${BASE_FILE_NAME}.csv"
fi

if [ ! "${CAD_FILE}" ]; then
    CAD_FILE="3D-${BASE_FILE_NAME}"
fi

if [ ! "${CAD_FILE_GLB}" ]; then
    CAD_FILE_GLB="${CAD_FILE}.glb"
fi

if [ ! "${CAD_FILE_STEP}" ]; then
    CAD_FILE_STEP="${CAD_FILE}.step"
fi

if [ ! "${CAD_FILE_VRML}" ]; then
    CAD_FILE_VRML="${CAD_FILE}.vrml"
fi

if [ ! "${CASE_FILE}" ]; then
    CASE_FILE="case-${BASE_FILE_NAME}.scad"
fi

if [ ! "${GERBER_DIR}" ]; then
    GERBER_DIR="gerber-${BASE_FILE_NAME}"
fi

if [ ! "${ARTIFACTS_DIR}" ]; then
    ARTIFACTS_DIR=${DATETIME}-${PROJECT_NAME}
    if [ "${CI_COMMIT_SHORT_SHA}" ]; then
       ARTIFACTS_DIR="${ARTIFACTS_DIR}-${CI_COMMIT_SHORT_SHA}"
    fi
fi

echo "##############################################"
echo "DATETIME:       $DATETIME"
echo "DIR:            $(pwd)"
echo "KICAD_CLI:      $KICAD_CLI"
echo "BASE_FILE_NAME: $BASE_FILE_NAME"
echo "KICAD_SCH_FILE: $KICAD_SCH_FILE"
echo "KICAD_PCB_FILE: $KICAD_PCB_FILE"
echo "SCHEMATIC_FILE: $SCHEMATIC_FILE"
echo "BOM_FILE:       $BOM_FILE"
echo "CAD_FILE:       $CAD_FILE"
echo "CAD_FILE_GLB:   $CAD_FILE_GLB"
echo "CAD_FILE_STEP:  $CAD_FILE_STEP"
echo "CAD_FILE_VRML:  $CAD_FILE_VRML"
echo "CASE_FILE:      $CASE_FILE"
echo "GERBER_DIR:     $GERBER_DIR"
echo "ARTIFACTS_DIR:  $ARTIFACTS_DIR"
echo " "
echo "Project content:"
ls -lh
echo "##############################################"

#
# Print command (GREEN)
#
# $1 string to print
#
print_command() {
    #Black        0;30     Dark Gray     1;30
    #Red          0;31     Light Red     1;31
    #Green        0;32     Light Green   1;32
    #Brown/Orange 0;33     Yellow        1;33
    #Blue         0;34     Light Blue    1;34
    #Purple       0;35     Light Purple  1;35
    #Cyan         0;36     Light Cyan    1;36
    #Light Gray   0;37     White         1;37
    GREEN='\033[1;32m'
    NC='\033[0m' # No Color
    printf "${GREEN}$1${NC}\n"
}

#
# Print blue
#
# $1 string to print
#
print_blue() {
    #Black        0;30     Dark Gray     1;30
    #Red          0;31     Light Red     1;31
    #Green        0;32     Light Green   1;32
    #Brown/Orange 0;33     Yellow        1;33
    #Blue         0;34     Light Blue    1;34
    #Purple       0;35     Light Purple  1;35
    #Cyan         0;36     Light Cyan    1;36
    #Light Gray   0;37     White         1;37
    BLUE='\033[1;34m'
    NC='\033[0m' # No Color
    printf "${BLUE}$1${NC}\n"
}

#
# Print error (RED)
#
# $1 string to print
#
print_error() {
    #Black        0;30     Dark Gray     1;30
    #Red          0;31     Light Red     1;31
    #Green        0;32     Light Green   1;32
    #Brown/Orange 0;33     Yellow        1;33
    #Blue         0;34     Light Blue    1;34
    #Purple       0;35     Light Purple  1;35
    #Cyan         0;36     Light Cyan    1;36
    #Light Gray   0;37     White         1;37
    RED='\033[1;31m'
    NC='\033[0m' # No Color
    printf "${RED}$1${NC}\n"
}

#
# Display error
#
# $1 Error
#
exit_with_error() {
    print_error " "
    print_error "##########################################"
    print_error "## Error: $1"
    print_error "##########################################"
    print_error " "
    exit 1
}

#
# Display new section
#
# $1 Section name
#
display_section() {
    print_blue " "
    print_blue "##########################################"
    print_blue "## $1"
    print_blue "##########################################"
    print_blue " "
}


prepare() {
  mkdir -p ./${ARTIFACTS_DIR} || true
  chmod -R 777 ./${ARTIFACTS_DIR} || true
  mkdir -p ./${ARTIFACTS_DIR}/$GERBER_DIR || true
  chmod -R 777 ./${ARTIFACTS_DIR}/$GERBER_DIR || true
  if [ $(command -v apt-get) ]; then
     sudo apt update && sudo apt install python3-pip virtualenv -yq
     if [ ! $(command -v kicad-cli) ]; then
         sudo add-apt-repository --yes ppa:kicad/kicad-9.0-releases
         sudo apt update
         sudo apt install --install-recommends kicad -yq
         KICAD_CLI=$(which kicad-cli)
     fi
  fi
  virtualenv -p python3 .python3env
  source .python3env/bin/activate
  pip3 install --upgrade pip
  pip3 install turbocase
  deactivate
  return 0
}

schematic() {
    echo "Working directory: $(pwd)"
    print_command "$KICAD_CLI sch export pdf -o ./${ARTIFACTS_DIR}/${SCHEMATIC_FILE} ${KICAD_SCH_FILE}"
    $KICAD_CLI sch export pdf -o ./${ARTIFACTS_DIR}/${SCHEMATIC_FILE} ${KICAD_SCH_FILE}
}

bom() {
    echo "Working directory: $(pwd)"
    print_command "$KICAD_CLI sch export bom -o ./${ARTIFACTS_DIR}/${BOM_FILE} ${KICAD_SCH_FILE}"
    $KICAD_CLI sch export bom -o ./${ARTIFACTS_DIR}/${BOM_FILE} ${KICAD_SCH_FILE}
}

gerber() {
    echo "Working directory: $(pwd)"
    print_command "pcb drc --severity-error --exit-code-violations ${KICAD_PCB_FILE}"
    $KICAD_CLI pcb drc --severity-error --exit-code-violations ${KICAD_PCB_FILE}
    res="$?"
    if [ "$res" != "0" ]; then
        return $res
    fi
    print_command "$KICAD_CLI pcb export drill -o ./${ARTIFACTS_DIR}/$GERBER_DIR/ ${KICAD_PCB_FILE}"
    $KICAD_CLI pcb export drill -o ./${ARTIFACTS_DIR}/$GERBER_DIR/ ${KICAD_PCB_FILE}
    print_command "$KICAD_CLI pcb export gerbers -o ./${ARTIFACTS_DIR}/$GERBER_DIR/ ${KICAD_PCB_FILE}"
    $KICAD_CLI pcb export gerbers -o ./${ARTIFACTS_DIR}/$GERBER_DIR/ ${KICAD_PCB_FILE}
}

housing() {
    echo "Working directory: $(pwd)"
    source .python3env/bin/activate
    print_command "python3 -m turbocase ${KICAD_PCB_FILE} ./${ARTIFACTS_DIR}/${CASE_FILE}"
    python3 -m turbocase ${KICAD_PCB_FILE} ./${ARTIFACTS_DIR}/${CASE_FILE}
    deactivate
}

cad() {
    $KICAD_CLI pcb export glb --output  ./${ARTIFACTS_DIR}/${CAD_FILE_GLB} ${KICAD_PCB_FILE}  
    $KICAD_CLI pcb export step --output ./${ARTIFACTS_DIR}/${CAD_FILE_STEP} ${KICAD_PCB_FILE}  
    $KICAD_CLI pcb export vrml --output ./${ARTIFACTS_DIR}/${CAD_FILE_VRML} ${KICAD_PCB_FILE} 
}

case $1 in

  "prepare")
    display_section "Prepare Stage"
    prepare
    exit $?
    ;;

  "schematic")
    display_section "Schematic Stage"
    schematic
    ;;

  "bom")
    display_section "BOM Stage"
    bom
    ;;

  "gerber")
    display_section "Gerber Stage"
    gerber
    ;;

  "cad")
    display_section "CAD Stage"
    cad
    ;;

  "housing")
    display_section "Housing Stage"
    housing
    ;;

  "docker")
    display_section "Build using docker"
    docker compose up
    ;;

  "")
    prepare
    res="$?"; if [ "$res" != "0" ]; then exit $res; fi
    schematic
    res="$?"; if [ "$res" != "0" ]; then exit $res; fi
    bom
    res="$?"; if [ "$res" != "0" ]; then exit $res; fi
    gerber
    res="$?"; if [ "$res" != "0" ]; then exit $res; fi
    cad
    res="$?"; if [ "$res" != "0" ]; then exit $res; fi
    housing
    res="$?"; if [ "$res" != "0" ]; then exit $res; fi
    ;;

  *)
    print_error "Error: Unknown option $@"
    echo "Usage:"
    echo $0 prepare      - Prepare for build
    echo $0 schematic    - Build schematic artifacts only
    echo $0 bom          - Build bill of materials artifacts only
    echo $0 gerber       - Build gerber artifacts only
    echo $0 cad          - Build 3D files only
    echo $0 housing      - Build housing files only 
    echo $0 docker       - build all using docker
    echo $0              - build all
    ;;
esac