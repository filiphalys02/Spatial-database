-- 1. Zainstaluj rozszerzenie PosGIS dla bazy danych PostgreSQL (sprawdz, czy najnowsza
--    dostepna wersja oprogramowania wspiera PostGIS).


-- 2. Utworz pusta baze danych
CREATE DATABASE BazaDanychPrzestrzennych;

-- 3. Dodaj funkcjonalnosci PostGIS’a do bazy poleceniem CREATE EXTENSION postgis;
CREATE EXTENSION postgis;

-- 4. Na podstawie ponizszej mapy utworz trzy tabele: budynki (id, geometria, nazwa), drogi
--    (id, geometria, nazwa), punkty_informacyjne (id, geometria, nazwa).
CREATE TABLE budynki (
	id INT NOT NULL, 
	geometria GEOMETRY NOT NULL, 
	nazwa VARCHAR(50) NOT NULL);

CREATE TABLE drogi (
	id INT NOT NULL, 
	geometria GEOMETRY NOT NULL, 
	nazwa VARCHAR(50) NOT NULL);
	
CREATE TABLE punkty_informacyjne (
	id INT NOT NULL, 
	geometria GEOMETRY NOT NULL, 
	nazwa VARCHAR(1) NOT NULL);

-- 5. Wspolrzedne obiektow oraz nazwy (np. BuildingA) nalezy odczytac z mapki umieszczonej
--	  ponizej. Uklad wspolrzednych ustaw jako niezdefiniowany.
INSERT INTO punkty_informacyjne VALUES (0, ST_GeomFromText('POINT(1.0 3.5)'), 'G');
INSERT INTO punkty_informacyjne VALUES (1, ST_GeomFromText('POINT(5.5 1.5)'), 'H');
INSERT INTO punkty_informacyjne VALUES (2, ST_GeomFromText('POINT(9.5 6.0)'), 'I');
INSERT INTO punkty_informacyjne VALUES (3, ST_GeomFromText('POINT(6.5 6.0)'), 'J');
INSERT INTO punkty_informacyjne VALUES (4, ST_GeomFromText('POINT(6.0 9.5)'), 'K');
SELECT id, ST_AsText(geometria), nazwa FROM punkty_informacyjne;
--DELETE FROM punkty_informacyjne

INSERT INTO drogi VALUES (0, ST_GeomFromText('LINESTRING(0.0 4.5, 12.0 4.5)'), 'RoadX');
INSERT INTO drogi VALUES (1, ST_GeomFromText('LINESTRING(7.5 0.0, 7.5 10.5)'), 'RoadY');
SELECT id, ST_AsText(geometria), nazwa FROM drogi;
--DELETE FROM drogi 

INSERT INTO budynki VALUES (0, ST_GeomFromText('POLYGON((8.0 1.5,8.0 4.0,10.5 4.0,10.5 1.5,8.0 1.5))'), 'BuildingA');
INSERT INTO budynki VALUES (1, ST_GeomFromText('POLYGON((4.0 5.0,4.0 7.0, 6.0 7.0, 6.0 5.0,4.0 5.0))'), 'BuildingB');
INSERT INTO budynki VALUES (2, ST_GeomFromText('POLYGON((3.0 6.0,3.0 8.0, 5.0 8.0, 5.0 6.0,3.0 6.0))'), 'BuildingC');
INSERT INTO budynki VALUES (3, ST_GeomFromText('POLYGON((9.0 8.0,9.0 9.0,10.0 9.0,10.0 8.0,9.0 8.0))'), 'BuildingD');
INSERT INTO budynki VALUES (4, ST_GeomFromText('POLYGON((1.0 1.0,1.0 2.0, 2.0 2.0, 2.0 1.0,1.0 1.0))'), 'BuildingE');
SELECT id, ST_AsText(geometria), nazwa FROM budynki;

-- 6. Na podstawie przygotowanych tabel wykonaj ponizsze polecenia:
-- a) Wyznacz calkowita dlugosc drog w analizowanym miescie.

SELECT SUM(ST_Length(geometria)) FROM drogi;

-- b) Wypisz geometrie (WKT), pole powierzchni oraz obwod poligonu reprezentujacego budynek o nazwie BuildingA.

SELECT ST_Area(geometria) AS Pole_powierzchni, ST_Perimeter(geometria) AS Obwod, ST_AsText(geometria) AS Geometria_WKT;
FROM budynki WHERE id=0

-- c) Wypisz nazwy i pola powierzchni wszystkich poligonow w warstwie budynki wyniki posortuj alfabetycznie.

SELECT nazwa, ST_Area(geometria) AS pole_powierzchni FROM budynki ORDER BY nazwa;

-- d) Wypisz nazwy i obwody 2 budynkow o najwiekszej powierzchni.

SELECT nazwa, ST_Area(geometria) AS pole_powierzchni FROM budynki ORDER BY pole_powierzchni DESC LIMIT 2;
--LIMIT wypisuje dana ilosc rekordow

-- e) Wyznacz najkrotsza odleglosc miedzy budynkiem C a punktem G.

--SELECT ST_Distance(SELECT geometria FROM punkty_informacyjne WHERE nazwa='G'
--,SELECT geometria FROM budynki WHERE nazwa='BuildingC'
--) AS odleglosc 
--FROM punkty_informacyjne, budynki

SELECT ST_Distance(punkty_informacyjne.geometria, budynki.geometria) AS Odleglosc
FROM punkty_informacyjne, budynki
WHERE punkty_informacyjne.nazwa = 'G' AND budynki.nazwa = 'BuildingC';

-- f) Wypisz pole powierzchnitej czesci budynku BuildingC, ktora znajduje sie
--    w odleglosci wiekszej niz 0.5 od budynku BuildingB.

SELECT ST_Area(C.geometria)-ST_Area(ST_Intersection(ST_Buffer(B.geometria, 0.5), C.geometria)) AS pole 
FROM budynki B, budynki C
WHERE B.nazwa='BuildingB' AND C.nazwa='BuildingC';

-- g) Wybierz te budynki, ktorych centroid (ST_Centroid) znajduje sie powyzej drogi o nazwie RoadX.

SELECT nazwa 
FROM budynki 
WHERE ST_Y(ST_Centroid(geometria))>(SELECT ST_Y(ST_PointN(geometria,1)) FROM drogi WHERE nazwa='RoadX');

-- h) Oblicz pole powierzchni tych czesci budynku BuildingC i poligonu o wspolrzednych 
--	  (4 7,6 7,6 8,4 8, 4 7), ktore nie sa wspolne dla tych dwoch obiektow.

SELECT ST_Area(C.geometria)+
	ST_Area(ST_GeomFromText('POLYGON((4 7,6 7,6 8,4 8, 4 7))'))
	-2*ST_Area((ST_Intersection(C.geometria, ST_GeomFromText('POLYGON((4 7,6 7,6 8,4 8, 4 7))'))))
AS pole 
FROM budynki C
WHERE C.nazwa='BuildingC';

