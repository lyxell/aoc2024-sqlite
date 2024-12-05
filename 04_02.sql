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
