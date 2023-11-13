CREATE DATABASE bazadanychprzestrzennych5;

CREATE EXTENSION postgis;

-- 0. Utworz tabele obiekty. W tabeli umiesc nazwy i geometrie obiektow przedstawionych ponizej. Uklad odniesienia
--	  ustal jako niezdefiniowany. Definicja geometrii powinna odbyc sie za pomoca typow zlozonych, wlasciwych dla EWKT.

CREATE TABLE obiekty (
	nazwa VARCHAR(7) NOT NULL,
	geom GEOMETRY NOT NULL
);

	--DROP TABLE obiekty;

	-- obiekt 1
INSERT INTO obiekty VALUES ('obiekt1', ST_GeomFromEWKT( 'COMPOUNDCURVE( 
	LINESTRING(0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), LINESTRING(5 1, 6 1))' ));
	-- obiekt 2
INSERT INTO obiekty 
VALUES ('obiekt2', ST_GeomFromEWKT('CURVEPOLYGON(
                     COMPOUNDCURVE( 
					   LINESTRING(10 2, 10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2)),
                     COMPOUNDCURVE( 
					   CIRCULARSTRING(11 2,12 3, 13 2), CIRCULARSTRING(13 2, 12 1, 11 2) ) )'
		));
	-- obiekt 3
INSERT INTO obiekty VALUES('obiekt3', ST_GeomFromEWKT( 'TRIANGLE((7 15, 10 17, 12 13, 7 15))' ));
	-- obiekt 4
INSERT INTO obiekty VALUES('obiekt4', ST_GeomFromEWKT( 'MULTILINESTRING((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))' ));
	-- obiekt 5
INSERT INTO obiekty VALUES('obiekt5', ST_GeomFromEWKT( 'MULTIPOINT Z ((30 30 59),(38 32 234))' ));
	-- obiekt 6
INSERT INTO obiekty VALUES('obiekt6', ST_GeomFromEWKT( 'GEOMETRYCOLLECTION ( POINT(4 2), LINESTRING(1 1, 3 2))' ));

SELECT o.nazwa, ST_AsText(o.geom), ST_CurveToLine(o.geom) FROM obiekty o ORDER BY o.nazwa;

-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, ktory zostal utworzony wokol najkrotszej linii laczacej
--    obiekt 3 i 4

SELECT DISTINCT ST_Area(ST_Buffer(ST_ShortestLine( 
	(SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),
	(SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')), 5)) 
FROM obiekty

-- 2. Zamien obiekt4 na poligon. Jaki warunek musi byc spelniony, aby mozna bylo wykonac to zadanie? Zapewnij te warunki.

UPDATE obiekty
SET geom = (SELECT ST_Polygonize(ST_Union(geom, ST_MakeLine((ST_MakePoint(20,20)), ST_MakePoint(20.5,19.5)))) 
			FROM obiekty 
			WHERE nazwa='obiekt4');

-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt zlozony z obiektu 3 i obiektu 4.

INSERT INTO obiekty 
VALUES ('obiekt7', ST_Union((SELECT geom FROM obiekty WHERE nazwa = 'obiekt4'), 
							(SELECT geom FROM obiekty WHERE nazwa = 'obiekt3')));

-- 4. Wyznacz pole powierzchni wszystkich buforow o wielkosci 5 jednostek, ktore zostaly utworzone wokol obiektow nie
-- 	  zawierajacych lukow.

SELECT SUM(ST_Area(ST_Buffer(geom,5)))
FROM obiekty
WHERE ST_HasArc(geom)=FALSE;

select st_area(st_buffer(geom,5)) from obiekty 

-- workspace
DELETE FROM probne
INSERT INTO probne VALUES('obiekt4', ST_GeomFromEWKT( 'MULTILINESTRING((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))' ));

UPDATE probne
SET geom = (SELECT ST_MakePolygon(ST_Union(geom, ST_MakeLine((SELECT ST_StartPoint(ST_AsText(geom)) 
															 FROM probne WHERE nazwa='obiekt4'), 
															(SELECT ST_EndPoint(ST_AsText(geom)) 
															 FROM probne WHERE nazwa='obiekt4')))) 
			FROM probne WHERE nazwa='obiekt4')
WHERE nazwa='obiekt4';

Select * from probne W


SELECT * FROM probne