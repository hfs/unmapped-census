#!/bin/bash -e
set -o pipefail

source env.sh

cd data
echo ">>> Downloading Census 2022 data"
wget 'https://www.zensus2022.de/static/Zensus_Veroeffentlichung/Zensus2022_Bevoelkerungszahl.zip' \
    --timestamping
unzip -o Zensus2022_Bevoelkerungszahl.zip

echo ">>> Downloading OpenStreetMap dump for Germany"
wget "http://download.geofabrik.de/europe/$REGION-latest.osm.pbf" \
    --timestamping
