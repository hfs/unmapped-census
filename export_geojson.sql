SELECT json_build_object(
    'type', 'FeatureCollection',
    'features', json_agg(ST_AsGeoJSON(u.*)::json)
)
FROM (
	SELECT
		id,
		population,
		ST_ForceRHR(ST_Transform(geom, 4326)) AS geom
	FROM census_unmapped 
) u
;
