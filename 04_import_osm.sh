#!/bin/bash -e
source env.sh

if [ data/$REGION-latest.osm.pbf -nt data/$REGION-filtered.osm.pbf ]; then
    echo ">>> Filter OSM data"
    osmium tags-filter --overwrite data/$REGION-latest.osm.pbf \
        -o data/$REGION-filtered.osm.pbf -e filter_buildings.conf --progress
fi

echo ">>> Import filtered OSM data into PostGIS database"
osm2pgsql --create --slim --cache $MEMORY --number-processes 8 \
    --flat-nodes data/nodes.bin --drop --style residential_and_buildings.lua \
    --output flex data/$REGION-filtered.osm.pbf
