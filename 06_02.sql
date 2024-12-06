create table T (c1 text) strict;
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
	select x, y, 0, -1 from M where v = '^'

	-- case: the next tile is walkable
	union
	select S.x+S.dx, S.y+S.dy, S.dx, S.dy from S
	join M on (M.v = '.' or M.v = '^') and (M.x = S.x+dx and M.y = S.y+S.dy)

	-- case: the next tile is blocked, perform rotation (dx, dy) => (-dy, dx)
	union
	select S.x, S.y, -S.dy, S.dx from S
	join M on M.v = '#' and (M.x = S.x+dx and M.y = S.y+S.dy)
),

-- O contains the tiles where we will place obstacles
O(x, y) as (
	select distinct x, y from S
	except select M.x, M.y from M where M.v = '^'
),

-- B is the map bounds
B(x, y) as (
	select M.x, M.y from M
),

-- N is the recursive solver for the guard walks with
-- placed obstacles
--
-- ox, oy is where the obstacle is placed
-- x, y is the position of the guard
-- dx, dy is the direction vector of the guard
--
-- we use a special value (x, y) = (-1, -1) to encode
-- that the guard fell off the map
N(ox, oy, x, y, dx, dy) as (
	-- case: base case, guard is walking in direction (0, -1)
	select O.x, O.y, M.x, M.y, 0, -1 from M join O where M.v = '^'

	-- case: the next tile is walkable
	union
	select N.ox, N.oy, N.x+N.dx, N.y+N.dy, N.dx, N.dy from N
	join M on (M.v = '.' or M.v = '^') and M.x = N.x+dx and M.y = N.y+N.dy
	where not (N.ox = N.x+dx and N.oy = N.y+dy)

	-- case: the next tile is blocked by #, perform rotation (dx, dy) => (-dy, dx)
	union
	select N.ox, N.oy, N.x, N.y, -N.dy, N.dx from N
	join M on M.v = '#' and M.x = N.x+dx and M.y = N.y+N.dy

	-- case: the next tile is blocked by O, perform rotation (dx, dy) => (-dy, dx)
	union
	select N.ox, N.oy, N.x, N.y, -N.dy, N.dx from N
	where N.ox = N.x+dx and N.oy = N.y+dy

	-- case: guard fell off the map
	union
	select N.ox, N.oy, -1, -1, 0, 0 from N
	where (N.x+N.dx, N.y+N.dy) not in B
)

select (select count(*) from O) - (select count(*) from N where N.x = -1 and N.y = -1);
