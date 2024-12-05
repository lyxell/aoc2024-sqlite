create table T (c1 text) strict;
.import 04_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

W(row, col, value) as materialized (
	select
		T.rowid - 1,
		start,
		match
	from regex_find_all("(.)", T.c1)
	join T
),
X as materialized (select row, col from W where value = "X"),
M as materialized (select row, col from W where value = "M"),
A as materialized (select row, col from W where value = "A"),
S as materialized (select row, col from W where value = "S")

-- solve
select count(*) from (
	select *
		from A
		join M as M1
		join M as M2
		join S as S1
		join S as S2
		join (values (1), (-1)) as D1
		join (values (1), (-1)) as D2
	where (
		--
		M1.col = A.col + D1.column1 and
		M1.row = A.row + D1.column1 and
		--
		S1.col = A.col - D1.column1 and
		S1.row = A.row - D1.column1 and
		--
		M2.col = A.col + D2.column1 and
		M2.row = A.row - D2.column1 and
		--
		S2.col = A.col - D2.column1 and
		S2.row = A.row + D2.column1
	)
);
