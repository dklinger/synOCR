#!/bin/bash
# ./recursive_inputdir_workflow.sh
# Tutorial: https://www.synology-forum.de/threads/synocr-gui-fuer-ocrmypdf.99647/post-879535
# Dieses Skript hilft dabei, einmalig OCR auf eine hirachische Verzeichnisstrucktur mit PDF-Dateien anzuwenden

# hier sind die absoluten Pfade (beginnen meist mit /volume… ) zwischen den Anführungszeichen anzugeben
# Quellverzeichnisstruktur:
    SOURCEPARENTDIR=""
# Eingangsverzeichnis für synOCR:
    SYNOCR_INPUT=""
# Ausgabeverzeichnis für synOCR:
    SYNOCR_OUTPUT=""

# – ab hier nichts mehr ändern –
#----------------------------------------------------------------------

#                               HOW TO

#   ! ! ! BITTE ZUNÄCHST EIN BACKUP DEINES QUELLORDNERS ANLEGEN ! ! !
#   ! ! ! es empfiehlt sich ein Test mit einer Beispielverzeichnisstruktur ! ! !

#   1.)
#   Dieses Skript (die 3 Ordnervariablen [Zeile 8, 10, 12] müssen angepasst werden)
#   ➜ durchsucht alle Verzeichnisse des angegebenen Ordners nach PDF-Dateien
#   ➜ verschiebt diese in den angegebenen synOCR-INPUT-Ordner
#   ➜ versieht diese mit einer ID
#   ➜ und erstellt eine Indexdatei in den gleichen Ordner, wo dieses Skript gespeichert ist

#   2.)
#   Nach dem ersten Aufruf dieses Skripts lässt man einmal synOCR seine Arbeit machen, d. h. automatisch 
#   über die Ordnerüberwachung / Zeitplan oder durch einen manuellen Aufruf.
#   WICHTIG: synOCR-Profil ohne Umbenennungssyntax und Einsortierung in regeldefinierte 
#   Ordner, d.h. alle fertigen PDFs liegen im synOCR OUTPUT-Ordner

#   3.)
#   Das Skript muss jetzt erneut aufgerufen werden
#   ➜ es erkennt die vorhandene Indexdatei
#   ➜ verschiebt die fertigen PDFs an ihren Urspungsort
#   ➜ entfernt die ID aus dem Dateinamen
#   ➜ und benennt die Indexdatei um

#   4.)
#   be happy :-)


#----------------------------------------------------------------------
#                   ab hier nichts mehr ändern                        |
#----------------------------------------------------------------------

preprocess() {
# verschiebe Quelldateien nach SYNOCR_INPUT:
    while IFS= read -r -d '' i ; do
        FILEPATH="${i%/*}"
        FILENAME="${i##*/}"
        ID="$(date +%s%N)_"
    
    # erstelle Indexeintrag:
        echo "${ID}§_§${FILEPATH}§_§${FILENAME}" >> "${INDEXFILE}"
    
    # verschiebe Quelldatei:
        mv "${i}" "${SYNOCR_INPUT}${ID}${FILENAME}"
    done <   <(find "${SOURCEPARENTDIR}" -iname "*.pdf" -type f -print0)
}

postprocess() {
# verarbeitete Dateien zurücksortieren:
    while IFS= read -r line; do 
        FILEPATH=$(echo "${line}" | awk -F'§_§' '{print $2}')
        FILENAME=$(echo "${line}" | awk -F'§_§' '{print $3}')
        ID=$(echo "${line}" | awk -F'§_§' '{print $1}')
        
        FILEHOME="${FILEPATH}/${FILENAME}"
        OCRFILE=$( find "${SYNOCR_OUTPUT}" -iname "${ID}*.pdf" )
        mv "${OCRFILE}" "${FILEHOME}"
    done < "${INDEXFILE}"
    
    mv "${INDEXFILE}" "${INDEXFILE}_finish"
}


##  APPDIR=$(cd $(dirname "$0");pwd)

if [ ! -d "${SOURCEPARENTDIR}" ] || [ ! -d "${SYNOCR_INPUT}" ] || [ ! -d "${SYNOCR_OUTPUT}" ] ; then
    echo "FEHLER! Pfad ungültig!"
    exit 1
fi

if [ ! -d "${0%/*}" ]; then
    echo "FEHLER! Der eigene Pfad des Skripts konnte nicht ausgelesen werden!"
    echo "Bitte rufe es mit vollständigen Pfad oder wenn du dich bereits im Ordner des Skripts befindest mit \"./recursive_inputdir_workflow.sh\" auf."
    exit 1
fi

SOURCEPARENTDIR="${SOURCEPARENTDIR%/}/"
SYNOCR_INPUT="${SYNOCR_INPUT%/}/"
SYNOCR_OUTPUT="${SYNOCR_OUTPUT%/}/"

INDEXFILE="${0%/*}/multidir_workflow_INDEX.txt"

if [ ! -f "${INDEXFILE}" ] ; then
    # backup, damit durch erneutes Starten nicht die bisherigen IDs gelöscht werden
    touch "${INDEXFILE}"
    echo "Index wird erstellt ➜ verschiebe Dateien in den Arbeitsordner"
    preprocess
else
    echo "Index bereits vorhanden ➜ sortiere verarbeitete Dateien zurück"
    postprocess
fi

