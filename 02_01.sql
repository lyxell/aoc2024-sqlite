create table T (c1 text) strict;
.import 02_input.txt T
.load ./regex0.so

with

-- parse input
L(row, col, curr, prev) as (
	select
		T.rowid,
		M.rowid,
		cast(M.match as integer),
		-- lag value by 1
		lag(cast(M.match as integer)) over (partition by T.rowid)
	from
		T,
		regex_find_all("\d+", T.c1) as M
),

-- find all rows with rule violations
V as (
	select row from L where (abs(prev - curr) > 3)
	union
	select * from (
		select row from L where (prev <= curr)
		intersect
		select row from L where (prev >= curr)
	)
)

select count (*)
from (
	select row from L
	except
	select row from V
);
