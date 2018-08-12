#!/bin/bash
NO_PAGES_TO_CHECK=10
if [ $# -lt 1 ]; then
    echo "[-] $0 <id> [no-dork-pages-to-get] [out-file]"
    echo "id: "
    echo "sensitive-dirs = 3"
    exit
fi
id="$1"
no_dork_pages_to_get="$2"
out_file="$3"

[ -z $no_dork_pages_to_get ] && no_dork_pages_to_get=10

[ -z "$out_file" ] && out_file="out-latest-dorks-$id.txt"
echo "[+] out_file = $out_file"

echo "[*] Removing the out_file if it already exists"
[ -f "$out_file" ] && rm $out_file 2>/dev/null

echo "[*] Installing tools"
set -x
sudo apt-get -y install curl
set +x

echo "[*] Get the sensitive directories"
for pg in `seq 1 $no_dork_pages_to_get`; do

    echo "[*] Getting page $pg"
    set -x
    curl --compressed --http1.1 -s "https://www.exploit-db.com/google-hacking-database/$id/?pg=$pg" -A "Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0" > /tmp/index.html
    #wget --user-agent "Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0" -O /tmp/index.html "https://www.exploit-db.com/google-hacking-database/$id/" 

    set +x
    
    echo "[*] Parsing page for dork links"
    links=`cat /tmp/index.html | egrep -io "https://www.exploit-db.com/ghdb/[0-9]+/"`

    echo "[*] Running searches via dorks"
    IFS=$'\n'
    for link in $links; do
        echo "[*] Getting page at '$link'"
        set -x
        curl --http1.1 -s "$link" -A "Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0" > /tmp/index2.html
        set +x
    
        echo "[*] Grabbing the dork from the page"
        set -x
        cat /tmp/index2.html   | egrep -io 'href="https://www\.google\.com.*"' | cut -d'"' -f2 | sed -r 's/&quot;/"/g' | tee -a $out_file
        set +x
    done
    
done
