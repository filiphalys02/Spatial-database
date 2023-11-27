CREATE DATABASE bazadanychprzestrzennych6;

CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

CREATE SCHEMA halys;
--CREATE SCHEMA public;
CREATE SCHEMA rasters;
CREATE SCHEMA vectors;


-- TWORZENIE RASTROW Z ISTNIEJACYCH RASTROW I INTERAKCJA Z WEKTORAMI

	-- Przyklad 1 - ST_Intersects
	-- Przyciecie rastra z wektorem
CREATE TABLE halys.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';
SELECT * FROM schema_Halys.intersects;

	-- dodanie serial primary key
ALTER TABLE halys.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

	-- utworzenie indeksu przestrzennego
CREATE INDEX idx_intersects_rast_gist ON schema_Halys.intersects
USING gist (ST_ConvexHull(rast));

	--  dodanie raster constraints
SELECT AddRasterConstraints('halys'::name,
'intersects'::name,'rast'::name);


	-- Przyklad 2 - ST_Clip
	-- obcinanie rastra na podstawie wektora.
CREATE TABLE halys.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

	-- Przyklad 3 - ST_Union
	-- polaczenie wielu kafelkow w jeden raster.
CREATE TABLE halys.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


-- TWORZENIE RASTROW Z WEKTOROW (RASTROWANIE)

	-- PrzykLad 1 - ST_AsRaster
	-- przyklad pokazuje uzycie funkcji ST_AsRaster w celu rastrowania tabeli z parafiami o takiej
	-- samej charakterystyce przestrzennej tj.: wielkosc piksela, zakresy itp.
DROP TABLE halys.porto_parishes;
CREATE TABLE halys.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';
SELECT * FROM halys.porto_parishes;

	-- Przyklad 2 - ST_Union
	-- wynikowy raster z poprzedniego zadania to jedna parafia na rekord, na wiersz tabeli. Uzyj QGIS lub
	-- ArcGIS do wizualizacji wyników.
	-- drugi przyklad laczy rekordy z poprzedniego przykladu przy uzyciu funkcji ST_UNION w pojedynczy raster
DROP TABLE halys.porto_parishes2;
CREATE TABLE halys.porto_parishes2 AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';
SELECT * FROM halys.porto_parishes2;


	-- Przyklad 3 - ST_Tile
	-- po uzyskaniu pojedynczego rastra mozna generowac kafelki za pomoca funkcji ST_Tile.
CREATE TABLE halys.porto_parishes3 AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';
SELECT * FROM halys.porto_parishes3;


-- KONWERTOWANIE RASTROW NA WEKTORY (WEKTORYZOWANIE)

	-- Przyklad 1 - ST_Intersection
CREATE TABLE halys.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

	-- Przyklad 2 - ST_DumpAsPolygons
	-- ST_DumpAsPolygons konwertuje rastry w wektory (poligony).
CREATE TABLE halys.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,
	(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


-- ANALIZA RASTROW

	-- Przyklad 1 - ST_Band
	-- funkcja ST_Band słuzy do wyodrebniania pasm z rastra
CREATE TABLE halys.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

	-- Przyklad 2 - ST_Clip
	-- ST_Clip moze byc uzyty do wyciecia rastra z innego rastra. Ponizszy przyklad wycina jedna parafie
	-- z tabeli vectors.porto_parishes. Wynik bedzie potrzebny do wykonania kolejnych przykladow.
CREATE TABLE halys.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

	-- Przyklad 3 - ST_Slope
	-- ponizszy przyklad uzycia funkcji ST_Slope wygeneruje nachylenie przy uzyciu
	-- poprzednio wygenerowanej tabeli (wzniesienie).
CREATE TABLE halys.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM halys.paranhos_dem AS a;

	-- Przyklad 4 - ST_Reclass
	-- Aby zreklasyfikowac raster nalezy uzyc funkcji ST_Reclass
CREATE TABLE halys.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM halys.paranhos_slope AS a;

	-- Przyklad 5 - ST_SummaryStats
	-- aby obliczyc statystyki rastra mozna uzyc funkcji ST_SummaryStats. Ponizszy przyklad wygeneruje statystyki dla kafelka.
SELECT st_summarystats(a.rast) AS stats
FROM halys.paranhos_dem AS a;

	-- Przyklad 6 - ST_SummaryStats oraz Union
	-- Przy uzyciu UNION mozna wygenerowac jedna statystyke wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM halys.paranhos_dem AS a;

	-- Przyklad 7 - ST_SummaryStats z lepsza kontrola zlozonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM halys.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

	-- Przyklad 8 - ST_SummaryStats w polaczeniu z GROUP BY
	-- aby wyswietlic statystyke dla kazdego poligonu "parish" mozna uzyc polecenia GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

	-- Przyklad 9 - ST_Value
	-- funkcja ST_Value pozwala wyodrebnic wartosc piksela z punktu lub zestawu punktow.
	-- Ponizszy przyklad wyodrebnia punkty znajdujace sie w tabeli vectors.places.
	-- Poniewaz geometria punktow jest wielopunktowa, a funkcja ST_Value wymaga geometrii
	-- jednopunktowej, nalezy przekonwertowac geometrie wielopunktową na geometrię
	-- jednopunktowa za pomoca funkcji (ST_Dump(b.geom)).geom.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


-- TOPOGRAPHIC POSITION INDEX (TPI)
	-- Przyklad 10 - ST_TPI
CREATE TABLE halys.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON halys.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('halys'::name,
'tpi30'::name,'rast'::name);


-- ALGEBRA MAP 
-- NDVI=(NIR-Red)/(NIR+Red)

	-- Przyklad 1 - Wyrażenie Algebry Map
CREATE TABLE halys.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] +
		[rast1.val])::float','32BF'
	) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON halys.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('halys'::name,
'porto_ndvi'::name,'rast'::name);

	-- Przyklad 2 – Funkcja zwrotna
	-- tworzenie funkcji
CREATE OR REPLACE FUNCTION halys.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

	-- wywolanie funkcji
CREATE TABLE halys.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, ARRAY[1,4],
		'halys.ndvi(double precision[],
		integer[],text[])'::regprocedure, --> This is the function!
		'32BF'::text
	) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON halys.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('halys'::name,
'porto_ndvi2'::name,'rast'::name);


-- EKSPORT DANYCH
	-- Przyklad 0 - Użycie QGIS
	-- po zaladowaniu tabeli/widoku z danymi rastrowymi do QGIS, mozliwe jest zapisanie/wyeksportowanie 
	-- warstwy rastrowej do dowolnego formatu obslugiwanego przez GDAL za pomoca interfejsu QGIS

	-- Przykład 1 - ST_AsTiff
	-- funkcja ST_AsTiff tworzy dane wyjsciowe jako binarna reprezentacje pliku tiff, moze to byc przydatne 
	-- na stronach internetowych, skryptach itp., w ktorych programista moze kontrolowac, cozrobić z plikiem 
	-- binarnym, na przyklad zapisac go na dysku lub po prostu wyświetlic.
SELECT ST_AsTiff(ST_Union(rast))
FROM halys.porto_ndvi;

	-- Przyklad 2 - ST_AsGDALRaster
	-- podobnie do funkcji ST_AsTiff, ST_AsGDALRaster nie zapisuje danych wyjsciowych bezposrednio na dysku, 
	-- natomiast dane wyjsciowe sa reprezentacja binarna dowolnego formatu GDAL.
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
FROM halys.porto_ndvi;

SELECT ST_GDALDrivers();

	-- Przyklad 3 - Zapisywanie danych na dysku za pomoca duzego obiektu (large object,lo)
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])) AS loid
FROM halys.porto_ndvi;

SELECT lo_export(loid, 'C:\Bazy-danych-przestrzennych\Ex_6_PostGis_Raster\myraster.tiff')
FROM tmp_out;

SELECT lo_unlink(loid)
FROM tmp_out;

	-- Przyklad 4 - Użycie Gdal
	-- Gdal obsluguje rastry z PostGISa. Polecenie gdal_translate eksportuje raster do dowolnego formatu
	-- obslugiwanego przez GDAL.
	
-- PUBLIKOWANIE DANYCH ZA POMOCA MAPSERVER
	
	-- Przyklad 1 - Mapfile
MAP
	NAME 'map'
	SIZE 800 650
	STATUS ON
	EXTENT -58968 145487 30916 206234
	UNITS METERS
	WEB
		METADATA
			'wms_title' 'Terrain wms'
			'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
			'wms_enable_request' '*'
			'wms_onlineresource'
'http://54.37.13.53/mapservices/srtm'
		END
	END
	PROJECTION
		'init=epsg:3763'
	END
	LAYER
		NAME srtm
		TYPE raster
		STATUS OFF
DATA "PG:host=localhost port=5432 dbname='postgis_raster' user='sasig'
			password='postgis' schema='rasters' table='dem' mode='2'" PROCESSING
			"SCALE=AUTO"
		PROCESSING "NODATA=-32767"
		OFFSITE 0 0 0
		METADATA
			'wms_title' 'srtm'
		END
	END
END
