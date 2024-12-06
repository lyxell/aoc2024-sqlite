create table T (c1 text) strict;
.import 06_input.txt T
.load ./regex0.so
.mode box

-- parse input
with recursive

-- M contains the characters of the map
M(y, x, v) as materialized (
	select
		T.rowid - 1,
		start,
		match
	from regex_find_all('(.)', T.c1)
	join T
),

-- G is the position of the guard
G as materialized (
	select * from M where M.v = '^'
),

-- W contains the first walk of the guard
--
-- we use this to calculate where to put obstacles
W(x, y, dx, dy) as materialized (
	-- base case, guard is walking upwards
	select G.x, G.y, 0, -1 from G
	union
	-- case: walkable
	select W.x+W.dx, W.y+W.dy, W.dx, W.dy from W
	join M on (M.v = '.' or M.v = '^') and M.x = W.x+dx and M.y = W.y+W.dy
	-- case: blocked, 90 deg rotation, (x, y) => (-y, x)
	union
	select W.x, W.y, -W.dy, W.dx from W
	join M on M.v = '#' and M.x = W.x+dx and M.y = W.y+W.dy
),

-- O contains the tiles where we will place obstacles
O as materialized (
	select distinct x, y from W
	except select G.x, G.y from G
),

-- B is the map bounds
B as materialized (
	select M.x, M.y from M
),

-- N is the solver for the guard walks with placed obstacles
--
-- (ox, oy) is where the obstacle is placed
-- (x, y) is the position of the guard
-- (dx, dy) is the direction vector
--
-- we use a special value (x, y) = (-1, -1) to encode
-- that the guard fell off the map
N(ox, oy, x, y, dx, dy) as (
	-- base case, guard is walking upwards
	select O.x, O.y, G.x, G.y, 0, -1 from O join G
	union

	-- case: walkable tile
	select N.ox, N.oy, N.x+N.dx, N.y+N.dy, N.dx, N.dy from N
	join M on ((M.v = '.' or M.v = '^') and M.x = N.x+dx and M.y = N.y+N.dy)
	where not (N.ox = N.x+dx and N.oy = N.y+dy)
	union

	-- case: # tile, 90 deg rotation, (x, y) => (-y, x)
	select N.ox, N.oy, N.x, N.y, -N.dy, N.dx from N
	join M on (M.v = '#' and M.x = N.x+dx and M.y = N.y+N.dy)
	union

	-- case: O tile, 90 deg rotation, (x, y) => (-y, x)
	select N.ox, N.oy, N.x, N.y, -N.dy, N.dx from N
	where (N.ox = N.x+dx and N.oy = N.y+dy)
	union

	-- case: we fell off the map
	select N.ox, N.oy, -1, -1, 0, 0 from N
	where (N.x+dx, N.y+dy) not in B
)

select (select count(*) from O) - (select count(*) from N where N.x = -1 and N.y = -1);
