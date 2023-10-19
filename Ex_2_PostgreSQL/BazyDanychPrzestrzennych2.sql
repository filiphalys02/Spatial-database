CREATE EXTENSION postgis;

-- 3. Zaimportuj pliki shapefile do bazy danych wykorzystujac wtyczke PostGIS DBF Loader

-- 4. Wyznacz liczbe budynkow (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
--	  polozonych w odleglosci mniejszej niż 1000 jednostek od glownych rzek. Budynki spelniajace
--	  to kryterium zapisz do osobnej tabeli tableB.

CREATE TABLE tableB AS
SELECT p.gid, p.cat, p.f_codedesc, p.f_code, p.type, p.geom
FROM popp p, majrivers m 
WHERE p.f_codedesc='Building' 
AND ST_Distance(p.geom, m.geom) < 1000;

SELECT * FROM tableB;

SELECT COUNT(*) FROM tableB;

-- 5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
--	  geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

CREATE TABLE airportsNew AS
SELECT air.name, air.geom, air.elev 
FROM airports air

SELECT * FROM airportsNew;

-- a) Znajdz lotnisko, ktore polozone jest najbardziej na zachod i najbardziej na wschod.

SELECT an.name, ST_X(an.geom) AS wspolrzedna_pozioma, an.elev
FROM airportsNew an
WHERE ST_X(an.geom) = (SELECT MAX(ST_X(geom)) FROM airportsNew)
OR ST_X(an.geom) = (SELECT MIN(ST_X(geom)) FROM airportsNew);

-- b)  Do tabeli airportsNew dodaj nowy obiekt - lotnisko, ktore polozone jest w punkcie
--	   srodkowym drogi pomiedzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
--	   Wysokosc n.p.m. przyjmij dowolna.

INSERT INTO airportsNew 
VALUES ('airportB', 
		(SELECT ST_Centroid(ST_MakeLine( (SELECT geom FROM airportsNew WHERE ST_X(geom) = (SELECT MAX(ST_X(geom)) FROM airportsNew)),
										 (SELECT geom FROM airportsNew WHERE ST_X(geom) = (SELECT MIN(ST_X(geom)) FROM airportsNew) )))), 
		10.000);

SELECT * FROM airportsNew an WHERE an.name = 'airportB';

-- 6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od 
--    najkrotszej linii laczacej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”.

SELECT ST_Area(ST_Buffer(ST_ShortestLine((SELECT ST_Centroid(geom) FROM lakes l WHERE l.names = 'Iliamna Lake'),
	    		   (SELECT geom FROM airports air WHERE air.name = 'AMBLER')), 1000));

SELECT * FROM lakes WHERE names = 'Iliamna Lake';
SELECT * FROM airports WHERE name = 'AMBLER';


-- 7. Napisz zapytanie, ktore zwroci sumaryczne pole powierzchni poligonów reprezentujacych
--	  poszczegolne typy drzew znajdujacych sie na obszarze tundry i bagien (swamps)

-- tundra + bagna
SELECT t.vegdesc AS typy_drzew, SUM(ST_Area(t.geom)) AS pole_powierzchni
FROM trees t, tundra tun, swamp s
WHERE ST_Within(t.geom, tun.geom)
OR ST_Within(t.geom, s.geom)
GROUP BY t.vegdesc; 

-- tundra
SELECT t.vegdesc AS typy_drzew, SUM(ST_Area(t.geom)) AS pole_powierzchni
FROM trees t, tundra tun
WHERE ST_Within(t.geom, tun.geom)
GROUP BY t.vegdesc; 

-- bagna
SELECT t.vegdesc AS typy_drzew, SUM(ST_Area(t.geom)) AS pole_powierzchni
FROM trees t, swamp s
WHERE ST_Within(t.geom, s.geom)
GROUP BY t.vegdesc; 

SELECT * FROM swamp;
SELECT * FROM tundra;
SELECT * FROM trees;
