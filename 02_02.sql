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
)

-- group by row and find all rows without rule violations
select count(distinct row) from (
	select
		L.row,
		-- we construct these values to be able to do boolean aggregation
		-- this let's us express statements that should hold true for all
		-- elements
		case when (abs(prev - curr) > 3) then 1 else 0 end as diff,
		case when (prev <= curr) then 1 else 0 end as incr,
		case when (prev >= curr) then 1 else 0 end as decr
	from L
	group by L.row, L.discard
	having
		sum(diff) == 0 and
		(sum(incr) == 0 or sum(decr) == 0)
);
