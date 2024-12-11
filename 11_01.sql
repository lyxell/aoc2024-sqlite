create table T (row text) strict;
.import 11_input.txt T
.load ./regex0.so
.mode box

-- parse input
with

-- P contains the problem input
P(v) as materialized (
	select
		cast(R.match as integer)
	from regex_find_all('\d+', T.row) as R
	join T
),

S(i, v) as (
	select 0, * from P

	-- case: v = 0
	union all
	select i+1,1 from S
	where v = 0 and i < 25

	-- case: even length
	union all
	select i+1, cast(substr(v, 0,length(v)/2+1) as integer) from S
	where length(v) % 2 = 0 and i < 25
	union all
	select i+1, cast(substr(v, length(v)/2+1) as integer) from S
	where length(v) % 2 = 0 and i < 25

	-- case: otherwise
	union all
	select i+1, v*2024 from S
	where v != 0 and length(v) % 2 != 0 and i < 25
)

select K.value, count(*) as n from S
join generate_series(0, 25) as K
where S.i = K.value
group by K.value
