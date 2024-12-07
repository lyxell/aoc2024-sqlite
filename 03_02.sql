create table T (row text);
.import 03_input.txt T
.load ./regex0.so

select
	sum(regex_capture(captures, 1)*regex_capture(captures, 2))
from
	regex_captures(
		'mul\(([0-9]{1,3}),([0-9]{1,3})\)',
		regex_replace_all("don't\(\)(.*?)(do\(\)|$)", program, "")
	)
join (
	-- concatenate the file into a single line
	select group_concat(T.row, '') as program from T
);
