create table T (c1 text) strict;
.import 03_input.txt T
.load ./regex0.so

select
	sum(regex_capture(captures, 1) * regex_capture(captures, 2))
from
	regex_captures(
		'mul\(([0-9]{1,3}),([0-9]{1,3})\)',
		T.c1
	)
join T;
