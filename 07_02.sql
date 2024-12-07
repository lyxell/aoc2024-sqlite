create table T (c1 text) strict;
.import 07_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

-- P contains the problem input
--
-- pr is the row index
-- pc is the column index of the number after the ':'
-- pv is the value at (r, c)
-- ps is the expected sum (i.e. the value before the ':')
P(pr, pc, pv, ps) as materialized (
	select
		T.rowid - 1,
		R.rowid,
		cast(R.match as integer),
		cast(regex_capture(captures, 1) as integer)
	from regex_find_all("\d+", regex_capture(captures, 2)) as R
	join regex_captures("(\d+): (.*)", T.c1)
	join T
),

-- N is the number of columns for each row
N(nr, nc) as (
	select pr, count(*) from P group by pr
),

-- S is the wanted sum for each row
S(sr, ss) as (
	select pr, ps from P group by pr
),

-- C is the solver for the calculations
--
-- r is the row
-- c is the current col
-- s is the current sum
C(r, c, s) as (
	-- base case
	select pr, 0, pv from P where pc = 0
	-- add
	union
	select r, c+1, s+pv from C
	join P on pc = c+1 and pr = r
	-- mul
	union
	select r, c+1, s*pv from C
	join P on pc = c+1 and pr = r
	-- concat
	union
	select r, c+1, cast(s||pv as int) from C
	join P on pc = c+1 and pr = r
)

select sum(s) from C
join N on nr = r and c = nc-1
join S on sr = r and s = ss;
