create table T (c1 text) strict;
.import 01_input.txt T
.load ./regex0.so
-- parse input
with P(c1, c2) as (
	select
		regex_capture(captures, 1),
		regex_capture(captures, 2)
	from
		regex_captures(
			'(\d+)\s+(\d+)',
			T.c1
		)
	join T
)
-- solution
select sum(abs(P1.c1-P2.c2))
from (
	select c1 from P order by c1
) P1
join (
	select c2 from P order by c2
) P2
on P1.rowid = P2.rowid;
