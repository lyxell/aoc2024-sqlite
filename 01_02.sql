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

select sum(a*n)
from (
	select b, count(*) as n
	from P
	group by b
) as C
join P on C.b = P.a;
