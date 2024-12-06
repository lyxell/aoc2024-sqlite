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

-- solve recursively
--
-- x, y is the position of the guard
-- dx, dy is the direction vector for the guard
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
)

select count(*) as result from (
	select distinct x, y from S
);
