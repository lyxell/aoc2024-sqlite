create table T (c1 text) strict;
.import 04_input.txt T
.load ./regex0.so
.mode box

-- parse input
create table MAT (row integer, col integer, value text) strict;
insert into MAT
select
	T.rowid - 1,
	start,
	match
from regex_find_all("(.)", T.c1)
join T;
create table X (row integer, col integer) strict;
create table M (row integer, col integer) strict;
create table A (row integer, col integer) strict;
create table S (row integer, col integer) strict;
insert into X select row, col from MAT where value = "X";
insert into M select row, col from MAT where value = "M";
insert into A select row, col from MAT where value = "A";
insert into S select row, col from MAT where value = "S";

-- solve
select count(*) from (
	-- horizontal/vertical
	select *
		from X
		join M
		join A
		join S
		join (values (1), (-1)) as D
		join (values (0), (1)) as E
	where (
		M.col = X.col + 1 * D.column1 * E.column1 and
		A.col = X.col + 2 * D.column1 * E.column1 and
		S.col = X.col + 3 * D.column1 * E.column1 and
		--
		M.row = X.row + 1 * D.column1 * (1 - E.column1) and
		A.row = X.row + 2 * D.column1 * (1 - E.column1) and
		S.row = X.row + 3 * D.column1 * (1 - E.column1)
	)
	union all
	-- diagonal
	select *
		from X
		join M
		join A
		join S
		join (values (1), (-1)) as D1
		join (values (1), (-1)) as D2
	where (
		M.row = X.row - 1 * D1.column1 and
		A.row = X.row - 2 * D1.column1 and
		S.row = X.row - 3 * D1.column1 and
		--
		M.col = X.col + 1 * D2.column1 and
		A.col = X.col + 2 * D2.column1 and
		S.col = X.col + 3 * D2.column1
	)
);
