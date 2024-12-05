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
select sum(P.c1*C.occ) from (
	select c2, count(*) as occ
    from P
    group by c2
) C
join P on C.c2 = P.c1;
