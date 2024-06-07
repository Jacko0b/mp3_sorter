#!/bin/bash

# Konfiguracja skryptu
VERSION="1.0.0"
REPO_URL="https://github.com/Jacko0b/mp3_sorter"
RC_FILE="$HOME/mp3_sorter/.mp3_sorter_rc"

# Funkcja wyświetlająca pomoc
function show_help {
    echo "Użycie: $0 -s [kryterium_sortowania] [ścieżki_do_plików_mp3...]"
    echo "Kryteria sortowania: title, artist, album, year"
    echo "Opcje:"
    echo "  -v  Wyświetl wersję skryptu"
    echo "  -u  Zaktualizuj skrypt do najnowszej wersji z repozytorium"
}

# Funkcja wyświetlająca wersję skryptu
function show_version {
    echo "mp3_sorter version $VERSION"
}

# Funkcja aktualizująca skrypt do najnowszej wersji
function update_script {
    echo "Aktualizowanie skryptu z repozytorium..."
    curl -s "$REPO_URL/raw/main/mp3_sorter.sh" -o "$0"
    if [ $? -eq 0 ]; then
        echo "Skrypt został pomyślnie zaktualizowany."
        chmod +x "$0"
    else
        echo "Nie udało się zaktualizować skryptu."
    fi
}

# Wczytywanie pliku rc
if [ -f "$RC_FILE" ]; then
    source "$RC_FILE"
fi

# Domyślne wartości
DEFAULT_SORT_CRITERIA=${DEFAULT_SORT_CRITERIA:-"artist"}
DESTINATION_DIR=${DESTINATION_DIR:-"$HOME/mp3_sorted"}

# Kryterium sortowania ustawione na domyślne
sort_criteria=$DEFAULT_SORT_CRITERIA

# Parsowanie opcji
while getopts ":s:vu" opt; do
    case $opt in
        s)
            sort_criteria=$OPTARG
            ;;
        v)
            show_version
            exit 0
            ;;
        u)
            update_script
            exit 0
            ;;
        \?)
            echo "Nieznana opcja: -$OPTARG"
            show_help
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

# Sprawdzenie poprawności kryterium sortowania
if [[ "$sort_criteria" != "title" && "$sort_criteria" != "artist" && "$sort_criteria" != "album" && "$sort_criteria" != "year" ]]; then
    echo "Błędne kryterium sortowania: $sort_criteria"
    show_help
    exit 1
fi

# Sprawdzenie, czy podano co najmniej jeden plik
if [ $# -lt 1 ]; then
    echo "Brak podanych ścieżek do plików MP3"
    show_help
    exit 1
fi

# Funkcja do wyciągania metadanych z plików MP3
function extract_metadata {
    local file="$1"
    local metadata_key="$2"
    ffmpeg -i "$file" 2>&1 | grep -i "$metadata_key" | head -n 1 | sed -e "s/.*: //"
}

# Licznik przetworzonych plików
processed_count=0

# Przetwarzanie plików MP3
for file in "$@"; do
    if [ -d "$file" ]; then
        mp3_files=$(find "$file" -type f -name "*.mp3")
        cd $file
        
    else
        mp3_files=$file
    fi

    echo "${mp3_files[1]}"

    for mp3 in $mp3_files; do
        if [ ! -f "$mp3" ]; then
            echo "Plik nie istnieje: $mp3" 
            continue
        fi

        case $sort_criteria in
            title)
                metadata=$(extract_metadata "$mp3" "title")
                ;;
            artist)
                metadata=$(extract_metadata "$mp3" "artist")
                ;;
            album)
                metadata=$(extract_metadata "$mp3" "album")
                ;;
            year)
                metadata=$(extract_metadata "$mp3" "date")
                ;;
        esac

        if [ -z "$metadata" ]; then
            echo "Brak metadanych $sort_criteria dla pliku: $mp3"
            metadata="inne"
        fi

        # Tworzenie odpowiedniego folderu
        folder="$DESTINATION_DIR/$sort_criteria/$metadata"
        mkdir -p "$folder"

        # Przenoszenie pliku do odpowiedniego folderu
        mv "$mp3" "$folder/"
        if [ $? -eq 0 ]; then
            echo "Przeniesiono $mp3 do $folder/"
            ((processed_count++))
        else
            echo "Błąd podczas przenoszenia $mp3 do $folder/"
        fi
    done
done

# Wyświetlenie liczby przetworzonych plików
echo "Przetworzono $processed_count utworów."
