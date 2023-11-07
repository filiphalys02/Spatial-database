-- Pobierz dane https://qgis.org/downloads/data/qgis_sample_data.zip i zaladuj odpowiednie warstwy do bazy 
-- (PostGIS). Następnie nawiaz polaczenie z baza danych i rozwiaz ponizsze zadania za pomocą narzedzi QGIS.

CREATE DATABASE bazadanychprzestrzennych4;

CREATE EXTENSION postgis;

-- 1. Dla warstwy trees zmien ustawienia tak, aby lasy lisciaste, iglaste i mieszane wyswietlane byly innymi kolorami. 
--	  Podaj pole powierzchni wszystkich lasow o charakterze mieszanym. 

	-- trees -> wlasciwosci -> styl -> wartosc unikalna -> wartosc (vegdesc) -> klasyfikuj -> zastosuj -> ok

SELECT ST_Area(ST_Union(t.geom)) 
FROM trees t 
WHERE t.vegdesc='Mixed Trees';

SELECT * FROM trees

-- 2. Podziel warstwe trees na trzy warstwy. Na kazdej z nich umiesc inny typ lasu. Zapisz wyniki do osobnych tabel. 
--	  Wyeksportuj je do bazy

	-- przegladarka -> trees -> PPM -> wykonaj SQL 
CREATE TABLE trees_deciduous AS
SELECT * FROM "public"."trees"
WHERE "public"."trees"."vegdesc"='Deciduous'

CREATE TABLE trees_evergreen AS
SELECT * FROM "public"."trees"
WHERE "public"."trees"."vegdesc"='Evergreen'

CREATE TABLE trees_evergreen AS
SELECT * FROM "public"."trees"
WHERE "public"."trees"."vegdesc"='Mixed Trees'

-- 3. Oblicz dlugosc linii kolejowych dla regionu Matanuska-Susitna. 

	-- przegladarka -> railroads -> PPM -> wykonaj SQL 
SELECT SUM(ST_Length(rail.geom))
FROM "public"."railroads" rail, "public"."regions" reg
WHERE ST_Within(rail.geom, 
			   (SELECT reg.geom 
				FROM "public"."regions" reg
				WHERE reg.name_2='Matanuska-Susitna'))
			
	-- Within nie jest dobrym narzedziem w tym przypadku
SELECT SUM(
	    ST_Length(
		 ST_Intersection( rail.geom, 
						  (SELECT reg.geom FROM "public"."regions" reg WHERE reg.name_2='Matanuska-Susitna')
		 )
		) 
	   )
FROM "public"."railroads" rail


-- 4. Oblicz, na jakiej sredniej wysokosci nad poziomem morza polozone są lotniska o charakterze militarnym. Ile 
--	  jest takich lotnisk? Usun z warstwy airports lotniska o charakterze militarnym, ktore sa dodatkowo polozone 
--	  powyzej 1400 m n.p.m. Ile bylo takich lotnisk? Sprawdz, czy zmiany sa widoczne w tabeli bazy danych.

	-- przegladarka -> airports -> PPM -> wykonaj SQL 
SELECT COUNT(*) AS liczba, AVG(air.elev) AS srednia_wysokosci 
FROM "public"."airports" air
WHERE air.use='Military';

	-- jedno lotnisko
SELECT COUNT(*)
FROM "public"."airports" air
WHERE air.use='Military'
AND air.elev>'1400';

SELECT COUNT(*) FROM airports
	-- Tabela airports ma 76 rekordow
DELETE FROM "public"."airports" air
WHERE air.use = 'Military'
AND air.elev > 1400;

SELECT COUNT(*) FROM airports
	-- Tabela airports ma 75 rekordow

-- 5. Utworz warstwe (tabele), na ktorej znajdowac sie beda jedynie budynki polozone w regionie Bristol Bay 
--	  (wykorzystaj warstwe popp). Podaj liczbe budynkow.

	-- przegladarka -> popp -> PPM -> wykonaj SQL 
CREATE TABLE Buildings_BristolBay AS
SELECT * FROM "public"."popp" bud
WHERE ST_Within(bud.geom,
				(SELECT reg.geom FROM "public"."regions" reg
				 WHERE reg.name_2='Bristol Bay'))
AND bud.f_codedesc = 'Building';

SELECT COUNT(*) FROM "public"."buildings_bristolbay";
	-- 5 budynkow


-- 6. W tabeli wynikowej z poprzedniego zadania zostaw tylko te budynki, ktore sa polozone nie dalej niż 100 km od 
--	  rzek (rivers). Ile jest takich budynkow? 

	-- przegladarka -> buildings_bristolbay -> PPM -> wykonaj SQL 
SELECT COUNT(*) FROM "public"."buildings_bristolbay" bud
WHERE NOT ST_Within(bud.geom,
				(SELECT ST_union(ST_buffer(rze.geom,100000)) FROM "public"."rivers" rze ));
	--0

DELETE FROM "public"."buildings_bristolbay" bud
WHERE NOT ST_Within(bud.geom,
				(SELECT ST_union(ST_buffer(rze.geom,100000)) FROM "public"."rivers" rze ));
 
-- 7. Sprawdz w ilu miejscach przecinaja sie rzeki (majrivers) z liniami kolejowymi (railroads).

	-- Wektor -> narzedzia analizy -> przeciecia linii 
	-- przegladarka -> railroads -> PPM -> wykonaj SQL 
SELECT COUNT(*)
FROM (
    SELECT ST_DumpPoints(ST_Intersection(rze.geom, tor.geom))
    FROM "public"."majrivers" rze, "public"."railroads" tor
    WHERE ST_Intersects(rze.geom, tor.geom)
) AS subquery;

-- 8. Wydobadz wezly dla warstwy railroads. Ile jest takich wezlow? Zapisz wynik w postaci osobnej tabeli w bazie danych.

	-- Wektor -> narzedzia analizy -> przeciecia linii 
	-- Wektor -> narzedzia geometrii -> wydobadz wierzcholki

-- 9.  Wyszukaj najlepsze lokalizacje do budowy hotelu. Hotel powinien byc oddalony od lotniska nie wiecej niz 100 
--	   km i nie mniej niz 50 km od linii kolejowych. Powinien lezec takze w poblizu sieci drogowej.
	
	-- Dla warstwy airports i railroads:
	-- wektor -> narzedzia geoprocessoringu -> bufor -> (agreguj) 
	-- wektor -> narzedzia geoprocessoringu -> iloczyn 

-- 10. Uprosc geometrie warstwy przedstawiajacej bagna (swamps). Ustaw tolerancje na 100. Ile wierzcholkow 
--	   zostalo zredukowanych? Czy zmienilo sie pole powierzchni calkowitej poligonów? 

	-- wektor -> narzedzia geometrii -> uprosc geometrie -> tolerancja 100
	-- warstwa swamp -> PPM -> otworz tabele atrybutow -> kalkulator pol -> wyrazenie: num_points($geometry)
	-- wynik 315
	-- warstwa swamp_uproszczonageometria -> PPM -> otworz tabele atrybutow -> kalkulator pol -> wyrazenie: num_points($geometry)
	-- wynik 298

SELECT SUM(ST_Area(sw.geom)) - SUM(ST_Area(ug.geom)) FROM swamp sw, swamp_uproszczonageometria ug
