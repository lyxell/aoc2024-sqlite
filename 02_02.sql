create table T (row text);
.import 02_input.txt T
.load ./regex0.so

with

-- P contains the problem input
--
-- r is the row index
-- c is the column index
-- v is the value at (r, c)
P(r, c, v) as (
	select
		T.rowid,
		M.rowid,
		cast(M.match as integer)
	from
		T,
		regex_find_all("\d+", T.row) as M
),

-- D contains all the columns indices
-- that we will discard
--
-- dr is the row index
-- dc is the column index to discard
D(dr, dc) as (
	select r, c from P
),

-- L contains all adjacent pairs
-- of values partitioned by the row index
-- and the index of the discarded column
--
-- r is the row index
-- dc is the discarded column
-- pred is the first value of the pair
-- succ is the second value of the pair
L(r, dc, pred, succ) as (
	select
		r,
		dc,
		v,
		lag(v) over (partition by r, dc order by c)
	from P
	join D on r = dr
	where c != dc
)

select count(distinct r)
from (
    select r
    from L
    group by r, dc
    having
        sum(abs(pred - succ) > 3) = 0
        and (sum(pred <= succ) = 0 or sum(pred >= succ) = 0)
);
