create table T (c1 text) strict;
.import 06_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

-- M is the parsed map
--
-- mx is the column index
-- my is the row index
-- mc is the char at (x, y)
M(mx, my, mc) as materialized (
	select
		R.start,
		T.rowid - 1,
		R.match
	from regex_find_all("(.)", T.c1) as R
	join T
),

-- solve

-- S is the initial walk for the guard
-- we use this to calculate where to put
-- obstacles
--
-- x, y is the current position of the guard
-- dx, dy is the direction vector of the guard
S(x, y, dx, dy) as (
	-- case: base case, guard is walking in direction (0, -1)
	select mx, my, 0, -1 from M where mc = '^'

	-- case: the next tile is walkable
	union
	select x+dx, y+dy, dx, dy from S
	where
		((x+dx, y+dy, '.') in M or
		 (x+dx, y+dy, '^') in M)

	-- case: the next tile is blocked, perform rotation (dx, dy) => (-dy, dx)
	union
	select x, y, -dy, dx from S
	where (x+dx, y+dy, '#') in M
),

-- O contains the tiles where we will place obstacles
O(ox, oy) as (
	select distinct x, y from S
	except select mx, my from M where mc = '^'
),

-- N is the recursive solver for the guard walks with
-- placed obstacles
--
-- ox, oy is where the obstacle is placed
-- x, y is the position of the guard
-- dx, dy is the direction vector of the guard
N(ox, oy, x, y, dx, dy) as (
	-- case: base case, guard is walking in direction (0, -1)
	select ox, oy, mx, my, 0, -1 from M join O where mc = '^'

	-- case: the next tile is walkable
	union
	select ox, oy, x+dx, y+dy, dx, dy from N
	where
	    not (x+dx, y+dy) = (ox, oy)
		and
		((x+dx, y+dy, '.') in M or
		 (x+dx, y+dy, '^') in M)

	-- case: the next tile is blocked by #, perform rotation (dx, dy) => (-dy, dx)
	union
	select ox, oy, x, y, -dy, dx from N
	where (x+dx, y+dy, '#') in M

	-- case: the next tile is blocked by O, perform rotation (dx, dy) => (-dy, dx)
	union
	select ox, oy, x, y, -dy, dx from N
	where (x+dx, y+dy) = (ox, oy)
),

-- B is the map bounds
B(x, y) as (
	select mx, my from M
)

select (
	-- count the number of placed obstacles
	select count(*) from O
) - (
	-- find number of guards that walked off the map
	select count(*) from N where (x+dx, y+dy) not in B
) as result;
