#!/bin/bash -e
set -o pipefail
source env.sh

echo ">>> Import Census into PostgreSQL database '$PGDATABASE'"
psql -v ON_ERROR_STOP=1 --single-transaction <<EOF
DROP TABLE IF EXISTS census_germany;
CREATE TABLE census_germany (
    id char(30),
    x int8,
    y int8,
    population int8
);
\COPY census_germany FROM data/Zensus2022_Bevoelkerungszahl_100m-Gitter.csv (FORMAT CSV, DELIMITER ';', NULL '', HEADER)

EOF
