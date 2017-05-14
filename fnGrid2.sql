-- FUNCTION: public.ig_polygon_with_grid(geometry, int)

DROP FUNCTION IF EXISTS public.ig_polygon_with_grid(geometry, int);

/*Function return multiline for polygon geomentry with grid.
	Parameters:
		poly - is polygon geometry.
		meters - size tiles in meters.
	NOTE:
		Use postgis. Use espg 4326. Use geometry only polygon not multi polygon.
*/

CREATE OR REPLACE FUNCTION public.ig_polygon_with_grid(
	poly geometry,
	meters int
	)
	RETURNS geometry
	LANGUAGE 'plpgsql'
AS $$
	DECLARE

		Ymin numeric :=  ST_YMin(poly);
		Ymax numeric := ST_YMax(poly);
		Xmin numeric :=  ST_XMin(poly);
		Xmax numeric := ST_XMax(poly);
		Y numeric;
		X numeric;
		srid int := 4326;
		poinXmYm geometry := ST_SetSRID(ST_MakePoint(Xmin,Ymin),srid);
		poinXmYx geometry := ST_SetSRID(ST_MakePoint(Xmin,Ymax),srid);
		poinXxYm geometry := ST_SetSRID(ST_MakePoint(Xmax,Ymin),srid);
		distY FLOAT := ST_Distance(poinXmYm, poinXmYx, true);
		distX FLOAT := ST_Distance(poinXmYm, poinXxYm, true);
		countRows int := distY / meters;
		countCols int := distX / meters;
		delta numeric := (Xmax - Xmin) / countCols;
		i int := -1;
		sectors geometry[];
		profiles geometry[];
		profile geometry;
		net geometry;

	BEGIN

		Y := Ymin;

		<<yloop>>
		LOOP
			IF (Y > Ymax) THEN
				EXIT;
			END IF;

			i := i + 1;
			sectors[i] := ST_Intersection(ST_GeomFromText('LINESTRING('||Xmin||' '||Y||', '||Xmax||' '||Y||')', srid), poly) ;

			Y := Y + delta;
		END LOOP yloop;

		X := Xmin;

		<<xloop>>
		LOOP
			IF (X > Xmax) THEN
				EXIT;
			END IF;

			i := i + 1;
			sectors[i] := ST_Intersection(ST_GeomFromText('LINESTRING('||X||' '||Ymin||', '||X||' '||Ymax||')', srid), poly) ;

			X := X + delta;
		END LOOP xloop;

		net := ST_Union(sectors);

		profiles := ARRAY(SELECT ST_ExteriorRing((ST_DumpRings(poly)).geom));
		profile := ST_Union(profiles);

		RETURN ST_Union(profile,net);

	END;

$$;

ALTER FUNCTION public.ig_grid_geom(geometry, int)
	OWNER TO postgres;
