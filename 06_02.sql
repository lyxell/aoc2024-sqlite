create table T (c1 text) strict;
.import 06_input.txt T
.load ./regex0.so
.mode box

-- parse input
with recursive

M(y, x, v) as materialized (
	select
		T.rowid - 1,
		start,
		match
	from regex_find_all('(.)', T.c1)
	join T
),

W(x, y, dx, dy) as (
	-- base case, guard is walking upwards
	select x, y, 0, -1 from M where v = '^'
	union
	-- case: walkable
	select W.x+W.dx, W.y+W.dy, W.dx, W.dy from W
	join M on (M.v = '.' or M.v = '^') and M.x = W.x+dx and M.y = W.y+W.dy
	-- case: blocked, 90 deg rotation, (x, y) => (-y, x)
	union
	select W.x-W.dy, W.y+W.dx, -W.dy, W.dx from W
	join M on M.v = '#' and M.x = W.x+dx and M.y = W.y+W.dy
),

-- px, py is where the block is placed
N(px, py, x, y, dx, dy) as (
	-- base case, guard is walking upwards
	select W.x, W.y, M.x, M.y, 0, -1 from M 
	join W on not (W.x = M.x and W.y = M.y)
	where M.v = '^'
	union
	-- case: walkable
	select N.px, N.py, N.x+N.dx, N.y+N.dy, N.dx, N.dy from N
	join M on (M.v = '.' or M.v = '^') and M.x = N.x+dx and M.y = N.y+N.dy
	-- case: blocked, 90 deg rotation, (x, y) => (-y, x)
	union
	select N.px, N.py, N.x-N.dy, N.y+N.dx, -N.dy, N.dx from N
	join M on M.v = '#' and M.x = N.x+dx and M.y = N.y+N.dy
)

select * from N limit 100000;
