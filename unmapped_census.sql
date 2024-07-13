\echo >>> Calculate census square for one point of each building

DROP TABLE IF EXISTS building_point;
CREATE TABLE building_point AS
SELECT
    area_id,
    CAST(floor(ST_X(ST_PointN(ST_Exteriorring(geom), 1)) / 100) * 100 + 50 AS int8) AS x,
    CAST(floor(ST_Y(ST_PointN(ST_Exteriorring(geom), 1)) / 100) * 100 + 50 AS int8) AS y,
    geom
FROM building
;

\echo >>> Pass one: DELETE ALL cells touched BY buildings

-- Tried with indexes on x and y but they weren't used anyway
DELETE FROM census_germany c
USING building_point b
WHERE
    c.x = b.x AND
    c.y = b.y
;


\echo >>> Add census square geometries

ALTER TABLE census_germany ADD COLUMN geom geometry(Polygon, 3035);
-- Census uses center point as x, y
UPDATE census_germany SET geom = ST_MakeEnvelope(x - 50, y - 50, x + 50, y + 50,
    3035);
CREATE INDEX ON census_germany USING GIST(geom);

\echo >>> Pass two: DELETE ALL cells intersecting WITH landuse areas

DELETE FROM census_germany c
USING landuse l
WHERE ST_Intersects(c.geom, l.geom)
;
VACUUM ANALYZE census_germany;
VACUUM ANALYZE building;

\echo >>> ADD spatial INDEX ON buildings

CREATE INDEX ON building USING GIST(geom);

\echo >>> Pass three: Delete all cells intersecting with buildings

DELETE FROM census_germany c
USING building b
WHERE
    -- I don't understand why, but without this line, the query is planned
    -- badly (Seq Scan on buildings first) and takes forever
    c.geom && b.geom
    AND ST_Intersects(c.geom, b.geom)
;

\echo >>> Merge clusters of touching census cells into (multi)polygons
-- Cells touching only in corners are ok -- the resulting polygons should be as
-- big as possible
DROP TABLE IF EXISTS census_unmapped;
CREATE TABLE census_unmapped AS
SELECT
    SUM(population) AS population,
    ST_Union(geom) AS geom
FROM
    (
        SELECT
            ST_ClusterDBSCAN(geom, 0, 1) OVER () AS cluster_id,
            *
        FROM
            census_germany
    ) c
GROUP BY
    cluster_id
;


\echo >>> Make the clusters look rounder
-- Merge the square cells together to give them a little softer look.
-- Not too much to use only few vertices.
UPDATE census_unmapped
SET geom = ST_Simplify(ST_Buffer(ST_Buffer(geom, 200), -200), 20)
;

CREATE INDEX ON census_unmapped USING GIST(geom);

-- Create a unique ID based on the centroid of the polygon. If the data is
-- regenerated and the polygon is still the same, the ID should remain the
-- same. If the polygon is different, e.g. because parts are now mapped in
-- OSM, the ID should be different.
\echo >>> Generate polygon IDs based on the centroid
ALTER TABLE census_unmapped
ADD COLUMN centroid geometry(Point, 3035);
UPDATE census_unmapped
SET centroid =
    CASE
        WHEN ST_Contains(geom, ST_Centroid(geom))
        THEN ST_Centroid(geom)
        ELSE ST_PointOnSurface(geom)
    END
;

ALTER TABLE census_unmapped
ADD COLUMN id text;
UPDATE census_unmapped
SET id = round(ST_X(centroid)) || ',' || round(ST_Y(centroid))
;
\echo >>> Done
