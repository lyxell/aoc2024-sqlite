create table T (row text) strict;
.import 04_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

P(r, c, v) as materialized (
	select
		T.rowid - 1,
		start,
		match
	from regex_find_all('.', T.row)
	join T
),
X as materialized (select r, c from P where v = 'X'),
M as materialized (select r, c from P where v = 'M'),
A as materialized (select r, c from P where v = 'A'),
S as materialized (select r, c from P where v = 'S'),

-- D is the directions for the searches
D(a, b) as (
	values
		( 1,  1),
		( 1, -1),
		(-1, -1),
		(-1,  1)
)

select count(*)
	from A
	join M as M1
	join M as M2
	join S as S1
	join S as S2
	join D
where (
	M1.r = A.r + a and M1.c = A.c + a and
	S1.r = A.r - a and S1.c = A.c - a and

	M2.r = A.r + b and M2.c = A.c - b and
	S2.r = A.r - b and S2.c = A.c + b
)

