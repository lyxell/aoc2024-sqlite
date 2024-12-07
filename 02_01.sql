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

-- L contains all adjacent pairs
-- of values for each row
--
-- r is the row index
-- pred is the first value of the pair
-- succ is the second value of the pair
L(r, pred, succ) as (
	select
		r,
		v,
		lag(v) over (partition by r order by c)
	from P
)

select count(*)
from (
    select r
    from L
    group by r
    having
        sum(abs(pred - succ) > 3) = 0
        and (sum(pred <= succ) = 0 or
			 sum(pred >= succ) = 0)
);
