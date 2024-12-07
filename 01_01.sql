create table T (row text);
.import 01_input.txt T
.load ./regex0.so

-- P contains the problem input
--
-- a is the first value of the row
-- b is the second value of the row
with P(a, b) as (
	select
		regex_capture(captures, 1),
		regex_capture(captures, 2)
	from
		regex_captures(
			'(\d+)\s+(\d+)',
			T.row
		)
	join T
)

select sum(abs(a-b))
from (
	select a from P order by a
) as P1
join (
	select b from P order by b
) as P2
on P1.rowid = P2.rowid;
