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
	select 0, v from P

	-- case: v = 0
	union
	select i+1, 1 from S
	where v = 0 and i < 25

	-- case: even length
	union
	select i+1, cast(substr(v, 0,length(v)/2+1) as integer) from S
	where length(v) % 2 = 0 and i < 25

	union
	select i+1, cast(substr(v, length(v)/2+1) as integer) from S
	where length(v) % 2 = 0 and i < 25

	-- case: otherwise
	union
	select i+1, v*2024 from S
	where v != 0 and length(v) % 2 != 0 and i < 25

),

-- here we need to simulate a for-loop
-- since SQLite doesn't support aggregate recursive queries
-- nor recursive queries that do multiple self-references
-- in a single select
Q(n, i, v) as (
	select row_number() over (order by i asc), S.i, S.v from S
),

K(n, j) as (
	-- base case
	select 0, jsonb_object('0', jsonb_group_object(S.v, 1))
	from S
	where S.i = 0

	-- case: v = 0
	union all
	select
		K.n+1,
		jsonb_set(
			K.j,
			printf('$.%d.%d', Q.i+1, 1),
			coalesce(K.j ->> printf('$.%d.%d', Q.i+1, 1), 0)
				+ (K.j ->> printf('$.%d.%d', Q.i, 0))
		)
	from K join Q on K.n+1 = Q.n
	where v = 0

	-- case: even length
	union all
	select
		K.n+1,
		jsonb_set(
			jsonb_set(
				K.j,
				printf('$.%d.%d', Q.i+1, substr(v, length(v)/2+1)),
				coalesce(K.j ->> printf('$.%d.%d', Q.i+1, substr(v, length(v)/2+1)), 0)
					+ (K.j ->> printf('$.%d.%d', Q.i, v))
			),
			printf('$.%d.%d', Q.i+1, substr(v, 0,length(v)/2+1)),
			coalesce(K.j ->> printf('$.%d.%d', Q.i+1, substr(v, 0,length(v)/2+1)), 0)
			+ (K.j ->> printf('$.%d.%d', Q.i, v) * (case when substr(v, 0,length(v)/2+1) = substr(v, length(v)/2+1) then 2 else 1 end))
		)
	from K join Q on K.n+1 = Q.n
	where v != 0 and length(v) % 2 = 0

	-- case: otherwise
	union all
	select
		K.n+1,
		jsonb_set(
			K.j,
			printf('$.%d.%d', Q.i+1, v*2024),
			coalesce(K.j ->> printf('$.%d.%d', Q.i+1, v*2024), 0)
				+ (K.j ->> printf('$.%d.%d', Q.i, v))
		)
	from K join Q on K.n+1 = Q.n
	where v != 0 and length(v) % 2 != 0

),

R as (
	select * from K order by n desc limit 1 
)

select K.value, sum(json_each.value) from R join json_each(R.j ->> printf('$.%d',K.value))
join generate_series(0, 25) as K
group by K.value;
