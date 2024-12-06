create table T (c1 text) strict;
.import 06_input.txt T
.load ./regex0.so
.mode box

-- parse input
with recursive

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
	from regex_find_all("(.)", T.c1) as R
	join T
),

-- solve recursively
--
-- x, y is the position of the guard
-- dx, dy is the direction vector for the guard
S(x, y, dx, dy) as (
	-- case: base case, guard is walking in direction (0, -1)
	select x, y, 0, -1 from M where v = '^'

	-- case: the next tile is walkable
	union
	select S.x+S.dx, S.y+S.dy, S.dx, S.dy from S
	join M on (M.v = '.' or M.v = '^') and (M.x = S.x+dx and M.y = S.y+S.dy)

	-- case: the next tile is blocked, perform rotation (dx, dy) => (-dy, dx)
	union
	select S.x, S.y, -S.dy, S.dx from S
	join M on M.v = '#' and (M.x = S.x+dx and M.y = S.y+S.dy)
)

select count(*) from (
	select distinct x, y from S
);
