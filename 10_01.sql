create table T (row text) strict;
.import 10_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

-- M is the parsed map
--
-- x is the column index
-- y is the row index
-- v is the char at (x, y)
M(mx, my, mv) as materialized (
	select
		R.start,
		T.rowid - 1,
		R.match
	from regex_find_all(".", T.row) as R
	join T
),

D(dx, dy) as (
	values
		(0,  1),
		(1,  0),
		(0, -1),
		(-1, 0)
),

S(x, y, sx, sy, v) as (
	select mx, my, mx, my, mv from M where mv == 0
	union
	select mx, my, sx, sy, mv from S
	join D
	join M on
		x + dx == mx and y + dy == my and mv = v + 1
)

select sum(n) from (
	select sx, sy, count(*) as n from S where S.v == 9 group by sx, sy
)
