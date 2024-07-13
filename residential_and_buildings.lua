local srid = 3035
local tables = {}

tables.landuse = osm2pgsql.define_area_table('landuse', {
    { column = 'geom', type = 'geometry', projection = srid },
})

tables.building = osm2pgsql.define_area_table('building', {
    { column = 'geom', type = 'geometry', projection = srid },
})

create_area = { geom = { create = 'area' } }

local building_tags = { 'building', 'disused:building', 'abandoned:building', 'demolished:building', 'removed:building',
    'razed:building', 'building:part', 'amenity' }

function osm2pgsql.process_way(object)
    if object.tags.landuse then
        tables.landuse:insert({ geom = object.as_polygon():transform(srid) })
    end
    for _, v in ipairs(building_tags) do
        if object.tags[v] then
            tables.building:insert({ geom = object.as_polygon():transform(srid) })
            break
        end
    end
end

function osm2pgsql.process_relation(object)
    if object.tags.type == 'multipolygon' and object.tags.landuse then
        tables.landuse:insert({ geom = object.as_multipolygon():transform(srid) })
    end
    if object.tags.type == 'multipolygon' then
        for _, v in ipairs(building_tags) do
            if object.tags[v] then
                tables.building:insert({ geom = object.as_multipolygon():transform(srid) })
                break
            end
        end
    end
end
