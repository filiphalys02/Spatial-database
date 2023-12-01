-- 1. Pobierz dane o nazwie 1:250 000 Scale Colour Raster™ Free OS OpenData ze strony:
-- 	  https://osdatahub.os.uk/downloads/open

-- 2. Zaladuj te dane do tabeli o nazwie uk_250k.	

CREATE DATABASE bazadanychprzestrzennych7;

CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

CREATE SCHEMA rasters;
-- wczytanie_danych_cmd.txt
SELECT * FROM rasters.uk_250k;

-- 3. Polacz te dane (wszystkie kafle) w mozaike, a nastepnie wyeksportuj jako GeoTIFF.
CREATE TABLE rasters.union AS
SELECT ST_Union(uk.rast)
FROM rasters.uk_250k uk;

CREATE TABLE rasters.union_geotiff AS
SELECT ST_AsGDALRaster(ST_Union(u.rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
FROM rasters.union u;

-- 4. Pobierz dane o nazwie OS Open Zoomstack ze strony:
--	  https://osdatahub.os.uk/downloads/open/OpenZoomstack

	SELECT * FROM rasters.national_parks;

-- 5. Zaladuj do bazy danych tabele reprezentujaca granice parkow narodowych.
	
	-- Wektor -> narzedzia geometrii -> poligony na linie
	SELECT * FROM public.national_parks_bound;

-- 6. Utworz nowa tabele o nazwie uk_lake_district, gdzie zaimportujesz mapy rastrowe z
--	  punktu 1, ktore zostana przyciete do granic parku narodowego Lake District.

DROP TABLE rasters.uk_lake_district_raster
CREATE TABLE rasters.uk_lake_district_raster AS 
SELECT ST_Clip(a.rast, b.geom, true) AS rast
FROM rasters.uk_250k a, rasters.national_parks b
WHERE ST_Intersects(a.rast, b.geom) AND b.id=1;

SELECT * FROM rasters.uk_lake_district_raster;

-- 7. Wyeksportuj wyniki do pliku GeoTIFF.

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])) AS loid
FROM rasters.uk_lake_district_raster;

SELECT lo_export(loid, 'C:\Bazy-danych-przestrzennych\Ex_7_PostGis_Raster\uk_lake_district_raster_exported.tiff')
FROM tmp_out;

DROP TABLE tmp_out;

-- 8. Pobierz dane z satelity Sentinel-2 wykorzystujac portal: https://scihub.copernicus.eu Wybierz dowolne zobrazowanie, 
--    ktore pokryje teren parku Lake District oraz gdzie parametr cloud coverage bedzie ponizej 20%.

-- 9. Zaladuj dane z Sentinela-2 do bazy danych.

	-- wczytanie_danych_cmd2.txt

CREATE TABLE nirr AS 
SELECT ST_Union(ST_SetBandNodataValue(rast, NULL), 'MAX') rast
FROM (SELECT rast FROM public.sentinel2_band8_1 UNION ALL SELECT rast FROM public.sentinel2_band8_2) foo;

CREATE TABLE green AS 
SELECT ST_Union(ST_SetBandNodataValue(rast, NULL), 'MAX') rast
FROM (SELECT rast FROM public.sentinel2_band3_1 UNION ALL SELECT rast FROM public.sentinel2_band3_2) foo;


-- 10. Policz indeks NDWI (to inny indeks niż NDVI) oraz przytnij wyniki do granic Lake District.
WITH r1 AS ((SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) as rast
			FROM public.green a, rasters.national_parks b
			WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.id=1)),	
			r2 AS ((SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) as rast
			FROM public.nirr a, rasters.national_parks b
			WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.id=1))
SELECT ST_MapAlgebra(r1.rast, r2.rast, '([rast1.val]-[rast2.val])/([rast1.val]+[rast2.val])::float', '32BF') AS rast
INTO lake_district_ndwi FROM r1, r2;

--11. Wyeksportuj obliczony i przyciety wskaźnik NDWI do GeoTIFF.
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM public.lake_district_ndwi;

SELECT lo_export(loid, 'C:\Bazy-danych-przestrzennych\Ex_7_PostGis_Raster\uk_lake_district_ndwi.tif')
FROM tmp_out;

DROP TABLE tmp_out;
