create table T (c1 text) strict;
.import 08_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

-- M is the parsed map
--
-- x is the column index
-- y is the row index
-- c is the char at (x, y)
M(x, y, c) as materialized (
	select
		R.start,
		T.rowid - 1,
		R.match
	from regex_find_all(".", T.c1) as R
	join T
)

select count(*) from (
	select distinct
		(M1.x + (M1.x - M2.x)) as px,
		(M1.y + (M1.y - M2.y)) as py
	from M as M1
	join M as M2 on
		M1.c = M2.c and
		M1.c != '.' and
		(M1.x != M2.x or M1.y != M2.y)
	where
		(px, py) in (select x, y from M)
)
