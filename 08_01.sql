create table T (row text) strict;
.import 08_input.txt T
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
)

select count(*) from (
	select distinct
		(M1.x + (M1.x - M2.x)) as px,
		(M1.y + (M1.y - M2.y)) as py
	from M as M1
	join M as M2 on
		M1.v = M2.v and
		M1.v != '.' and
		(M1.x != M2.x or M1.y != M2.y)
	where
		(px, py) in (select x, y from M)
)
