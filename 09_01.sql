create table T (row text) strict;
.import 09_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

-- M is the parsed map
--
-- x is the column index
-- y is the row index
-- v is the char at (x, y)
M(c, v) as materialized (
	select
		R.start,
		R.match
	from regex_find_all(".", T.row) as R
	join T
),

E as materialized (
	select
		c,
		lag (end, 1, 0) over (order by c) as start,
		end,
		case c % 2 when 0 then 'data' else 'empty' end as type
	from (
		select c, sum(v) over (order by c) as end from M
	)
),

S(ec, c, type) as materialized (
	select value, c, type from generate_series(0, 110000) as K join E where value >= E.start and value < E.end
),

-- visualize
-- select *
-- from (
-- 	select *, row_number() over (order by ec desc) as r from S where type == 'data' order by ec
-- ) as SD
-- left join (
-- 	select *, row_number() over (order by ec asc) as r from S where type == 'empty' order by ec
-- ) as SE
-- on SD.r = SE.r;

X as materialized (
select
	case SE.ec < SD.ec when 1 then SE.ec else SD.ec end as fc,
	SD.ec,
	SD.c / 2 as c,
	SE.ec as mc
from (
	select *, row_number() over (order by ec desc) as r from S where type == 'data' order by ec
) as SD
left join (
	select *, row_number() over (order by ec asc) as r from S where type == 'empty' order by ec
) as SE
on SD.r = SE.r
order by fc
)

select sum(fc * c) from X;
