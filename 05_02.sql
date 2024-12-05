create table T (c1 text) strict;
.separator "$"
.import 05_input.txt T
.load ./regex0.so
.mode box
with

-- parse input

-- this table contains all the (pred, succ)
-- rules stating that (pred) should be a
-- predecessor of (succ)
O(r, pred, succ) as (
	select
		T.rowid,
		cast(regex_capture(captures, 1) as integer),
		cast(regex_capture(captures, 2) as integer)
	from
		regex_captures(
			'(\d+)\|(\d+)',
			T.c1
		)
	join T
),

-- this table contains all the integer
-- sequences
--
-- r is the row number, c is the column and
-- v is the value of the column
R(r, c, v) as (
	select
		T.rowid,
		M.rowid,
		cast(match as integer)
	from regex_find_all('\d+', T.c1) as M
	join T
	where T.rowid not in (select r from O)
),

-- this table contains the index of the
-- middle element for each row
M(r, mid) as (
	select
		R.r, 
		count(*)/2
	from R
	group by R.r
),


-- solve

-- this table contains the ids
-- of all rows with violations
V(r) as (
	-- here we take the cross product
	-- of R and itself and checks,
	-- for each column, if there is
	-- a succeeding column that should
	-- be a preceeding column according
	-- to the rules
	select distinct R1.r
	from R as R1
	join R as R2
	join O
	where
		R1.r = R2.r and
		R1.c < R2.c and
		O.pred = R2.v and O.succ = R1.v
),

-- for each (row, col) pair we compute
-- how many values on the row should
-- precede the value in the col according
-- to the rules
P(r, c, v, npred) as (
	select
		R1.r,
		R1.c,
		R1.v,
		count(O.pred)
	from
		R as R1
	left join R as R2 on
		R1.r = R2.r
	left join O on
		O.pred = R2.v and
		O.succ = R1.v 
	group by R1.r, R1.v
)

select sum(P.v)
from P
join M
where
	P.r = M.r and
	-- here we exploit the fact that
	-- the problem description of part 2
	-- forces the sequence to be
	-- a totally ordered set, since otherwise
	-- the middle element would not be
	-- defined. it follows that, when sorted,
	-- the new column index is equal to
	-- the number of predecessors the column
	-- should have according to the rules.
	M.mid = P.npred and
	P.r in V;
