create table T (row text) strict;
.import 06_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

-- M is the parsed map
--
-- x is the column index
-- y is the row index
-- v is the char at (x, y)
M(x, y, v) as materialized (
	select
		R.start,
		T.rowid - 1,
		R.match
	from regex_find_all(".", T.row) as R
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
	select x, y, 0, -1 from M where v = '^'

	-- case: the next tile is walkable
	union
	select x+dx, y+dy, dx, dy from S
	where
		((x+dx, y+dy, '.') in M or
		 (x+dx, y+dy, '^') in M)

	-- case: the next tile is blocked
	-- perform rotation (dx, dy) -> (-dy, dx)
	union
	select x, y, -dy, dx from S
	where (x+dx, y+dy, '#') in M
),

-- O contains the tiles where we will place obstacles
O(ox, oy) as (
	select distinct x, y from S
	except select x, y from M where v = '^'
),

-- N is the recursive solver for the guard walks with
-- placed obstacles
--
-- ox, oy is where the obstacle is placed
-- x, y is the position of the guard
-- dx, dy is the direction vector of the guard
N(ox, oy, x, y, dx, dy) as (
	-- case: base case, guard is walking in direction (0, -1)
	select ox, oy, x, y, 0, -1 from M join O where v = '^'

	-- case: the next tile is walkable
	union
	select ox, oy, x+dx, y+dy, dx, dy from N
	where
		(x+dx, y+dy) != (ox, oy)
		and
		((x+dx, y+dy, '.') in M or
		 (x+dx, y+dy, '^') in M)

	-- case: the next tile is blocked by #
	-- perform rotation (dx, dy) -> (-dy, dx)
	union
	select ox, oy, x, y, -dy, dx from N
	where (x+dx, y+dy, '#') in M

	-- case: the next tile is blocked by O
	-- perform rotation (dx, dy) -> (-dy, dx)
	union
	select ox, oy, x, y, -dy, dx from N
	where (x+dx, y+dy) = (ox, oy)
)

select (
	-- count the number of placed obstacles
	select count(*) from O
) - (
	-- find number of guards that walked off the map
	select count(*) from N
	where (x+dx, y+dy) not in (select x, y from M)
) as result;
