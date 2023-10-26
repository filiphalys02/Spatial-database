CREATE DATABASE bazadanychprzestrzennych3;

CREATE EXTENSION postgis;

-- 1. Zaimportuj nastepujące pliki shapefile do bazy, przyjmij wszedzie uklad WGS84:
--	  T2018_KAR_BUILDINGS
--    T2019_KAR_BUILDINGS
--	  Pliki te przedstawiaja zabudowe miasta Karlsruhe w latach 2018 i 2019.
--    Znajdz budynki, ktore zostaly wybudowane lub wyremontowane na przestrzeni roku (zmiana 
--	  pomiedzy 2018 a 2019).

SELECT COUNT(*) FROM t2018_kar_buildings;
SELECT COUNT(*) FROM t2019_kar_buildings;

CREATE TABLE NewBuildings AS
SELECT b19.gid, b19.polygon_id, b19.name, b19.type, b19.height, b19.geom FROM t2019_kar_buildings b19 
LEFT OUTER JOIN t2018_kar_buildings b18 ON b19.geom=b18.geom
WHERE b18.geom IS NULL; 

SELECT * FROM NewBuildings;

-- 2. Zaimportuj dane dotyczące POIs (Points of Interest) z obu lat:
--   	 - T2018_KAR_POI_TABLE
--   	 - T2019_KAR_POI_TABLE
-- 	  Znajdz ile nowych POI pojawilo sie w promieniu 500 m od wyremontowanych lub 
--	  wybudowanych budynkow, ktore znalezione zostaly w zadaniu 1. Policz je wg ich kategorii.

CREATE TABLE NewPoints AS
SELECT pt19.gid, pt19.poi_id, pt19.link_id, pt19.type, pt19.poi_name, pt19.st_name, pt19.lat, pt19.lon, pt19.geom 
FROM t2019_kar_poi_table pt19
LEFT OUTER JOIN t2018_kar_poi_table pt18 
ON pt19.geom=pt18.geom 
WHERE pt18.geom IS NULL;

SELECT * FROM NewPoints;

WITH OnePolygon AS (
    SELECT ST_Union(ST_Buffer(geom,500)) AS geom
    FROM NewBuildings
)
SELECT p.type, COUNT(*) AS liczba_punktow
FROM OnePolygon g
LEFT JOIN NewPoints p
ON ST_Within(p.geom, g.geom)
GROUP BY p.type;

-- 3. Utworz nowa tabele o nazwie ‘streets_reprojected’, ktora zawierac bedzie dane z tabeli 
--	  T2019_KAR_STREETS przetransformowane do ukladu wspolrzednych DHDN.Berlin/Cassini.

SELECT * FROM T2019_KAR_STREETS;

CREATE TABLE streets_reprojected AS
SELECT gid,link_id,st_name,ref_in_id,nref_in_id,func_class,speed_cat, fr_speed_l,to_speed_l,dir_travel,
	ST_Transform(geom, 3068) AS geom
FROM T2019_KAR_STREETS;

SELECT * FROM streets_reprojected;
SELECT ST_SRID(geom) FROM streets_reprojected;

-- 4. Stworz tabele o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej. 
-- 	  Uzyj nastepujących wspolrzednych:
--	  	X	 	Y
--	  8.36093 49.03174
--	  8.39876 49.00644
-- 	  Przyjmij uklad wspolrzednych GPS.

CREATE TABLE input_points (
	id INT,
	geom GEOMETRY(point, 4326)
);

INSERT INTO input_points VALUES (0, ST_GeomFromText('POINT(8.36093 49.03174)'));
INSERT INTO input_points VALUES (1, ST_GeomFromText('POINT(8.39876 49.00644)'));

SELECT ST_Srid(geom) FROM input_points;
SELECT id, ST_AsText(geom) FROM input_points;

-- 5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te byly w ukladzie wspolrzednych 
--	  DHDN.Berlin/Cassini. Wyswietl wspolrzedne za pomoca funkcji ST_AsText().

ALTER TABLE input_points
ALTER COLUMN geom
TYPE GEOMETRY(Point, 3068)
USING ST_Transform(geom, 3068);

SELECT ST_Srid(geom) FROM input_points;

-- 6. Znajdz wszystkie skrzyzowania, ktore znajduja sie w odleglosci 200 m od linii zbudowanej 
--    z punktów w tabeli ‘input_points’. Wykorzystaj tabele T2019_STREET_NODE. Dokonaj 
-- 	  reprojekcji geometrii, aby byla zgodna z reszta tabel.

SELECT count(*) FROM t2019_kar_street_node;

SELECT * FROM t2019_kar_street_node  
WHERE ST_Within(
	    		geom,
	   			ST_Transform(
				 ST_Buffer(
	 	 		  ST_MakeLine( 
		  		   (SELECT geom FROM input_points WHERE id=0),			  
		  		   (SELECT geom FROM input_points WHERE id=1)
		 		  ), 200
				 ), 4326
	   			)
	  );							
									
-- 7. Policz jak wiele sklepow sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje sie 
--	  w odleglosci 300 m od parkow (LAND_USE_A).

SELECT * FROM t2019_kar_land_use_a
SELECT ST_Srid(geom) FROM t2019_kar_land_use_a;

SELECT COUNT(*)
FROM t2019_kar_poi_table p
WHERE ST_Within(p.geom, (SELECT ST_union(ST_buffer(geom,300)) FROM t2019_kar_land_use_a WHERE type='Park (City/County)'))
AND p.type='Sporting Goods Store';

-- 8. Znajdz punkty przeciecia torow kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz 
--	  znaleziona geometrie do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’

SELECT * FROM t2019_kar_railways;
SELECT * FROM t2019_kar_water_lines;

CREATE TABLE T2019_KAR_BRIDGES AS
SELECT DISTINCT(ST_Intersection(r.geom, w.geom)) AS geom
FROM t2019_kar_railways r, t2019_kar_water_lines w;

SELECT * FROM T2019_KAR_BRIDGES;

