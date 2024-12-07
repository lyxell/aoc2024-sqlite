create table T (row text);
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
D(r, c) as (
	values
		-- horizontal/vertical
		( 1,  0),
		(-1,  0),
		( 0,  1),
		( 0, -1),
		-- diagonal
		( 1,  1),
		( 1, -1),
		(-1,  1),
		(-1, -1)
)

select count(*)
	from X
	join M
	join A
	join S
	join D
where (
	M.r = X.r + 1 * D.c and M.c = X.c + 1 * D.r and
	A.r = X.r + 2 * D.c and A.c = X.c + 2 * D.r and
	S.r = X.r + 3 * D.c and S.c = X.c + 3 * D.r
)

