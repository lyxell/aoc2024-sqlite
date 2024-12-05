create table T (c1 text) strict;
.import 02_input.txt T
.load ./regex0.so

with

-- parse input
L(row, discard, col, curr, prev) as (
	select
		T.rowid,
		D.value,
		M.rowid,
		cast(M.match as integer),
		-- lag value by 1
		lag(cast(M.match as integer)) over (partition by T.rowid, D.value)
	from
		T,
		regex_find_all("\d+", T.c1) as M
	-- generate index of columns to discard
	join generate_series(0, 7) as D
	where D.value != M.rowid
),

-- find all (row, discard) pairs with rule violations
-- where discard is the index of the discarded column
I as (
	select row, discard from L where (abs(prev - curr) > 3)
	union
	select * from (
		select row, discard from L where (prev <= curr)
		intersect
		select row, discard from L where (prev >= curr)
	)
),

-- the idea here is that if we can count 8 distinct
-- pairs for one row, the row has rule violations no matter
-- which column we discard
V as (
	select
		row,
		count(distinct discard) as violating
	from I group by row
)

select count (*)
from (
	select row from L
	except
	select row from V where violating == 8
);
