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

E(c, start, end, type) as materialized (
	select
		c,
		lag (end, 1, 0) over (order by c) as start,
		end,
		case c % 2 when 0 then 'data' else 'empty' end as type
	from (
		select c, sum(v) over (order by c) as end from M
	)
),

-- space blocks
S(sc, start, end, size, type) as (
	select (c-1)/2, start, end, end - start, type from E where type == 'empty'
),

-- data blocks
D(dc, start, end, size, type) as (
	select c/2, start, end, end - start, type from E where type == 'data' order by c desc
),

-- data blocks divided by sizes
D9(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 9),
D8(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 8),
D7(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 7),
D6(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 6),
D5(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 5),
D4(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 4),
D3(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 3),
D2(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 2),
D1(idx, dc) as (select row_number() over (order by dc desc)-1, dc from D where size = 1),

-- To assign the data to free slots we need to create a recursive CTE
-- where all branches are mutually exclusive. This is kind of messy but
-- I don't really see any other solution.
--
-- At least this gives us a linear time algorithm.
X(space_left, offset, sc, p9, p8, p7, p6, p5, p4, p3, p2, p1, dc) as (
	select size, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL from S where sc = 0

	-- case: pick the next data block of size 1
	union all
	select space_left-1, offset+1, sc, p9, p8, p7, p6, p5, p4, p3, p2, p1+1, D1.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D1.dc > D9.dc) and
		(D8.dc is null or D1.dc > D8.dc) and
		(D7.dc is null or D1.dc > D7.dc) and
		(D6.dc is null or D1.dc > D6.dc) and
		(D5.dc is null or D1.dc > D5.dc) and
		(D4.dc is null or D1.dc > D4.dc) and
		(D3.dc is null or D1.dc > D3.dc) and
		(D2.dc is null or D1.dc > D2.dc) and
		(D1.dc is not null)

	-- case: pick the next data block of size 2
	union all
	select space_left-2, offset+2, sc, p9, p8, p7, p6, p5, p4, p3, p2+1, p1, D2.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D2.dc > D9.dc) and
		(D8.dc is null or D2.dc > D8.dc) and
		(D7.dc is null or D2.dc > D7.dc) and
		(D6.dc is null or D2.dc > D6.dc) and
		(D5.dc is null or D2.dc > D5.dc) and
		(D4.dc is null or D2.dc > D4.dc) and
		(D3.dc is null or D2.dc > D3.dc) and
		(D2.dc is not null) and
		(D1.dc is null or D2.dc > D1.dc)

	-- case: pick the next data block of size 3
	union all
	select space_left-3, offset+3, sc, p9, p8, p7, p6, p5, p4, p3+1, p2, p1, D3.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D3.dc > D9.dc) and
		(D8.dc is null or D3.dc > D8.dc) and
		(D7.dc is null or D3.dc > D7.dc) and
		(D6.dc is null or D3.dc > D6.dc) and
		(D5.dc is null or D3.dc > D5.dc) and
		(D4.dc is null or D3.dc > D4.dc) and
		(D3.dc is not null) and
		(D2.dc is null or D3.dc > D2.dc) and
		(D1.dc is null or D3.dc > D1.dc)

	-- case: pick the next data block of size 4
	union all
	select space_left-4, offset+4, sc, p9, p8, p7, p6, p5, p4+1, p3, p2, p1, D4.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D4.dc > D9.dc) and
		(D8.dc is null or D4.dc > D8.dc) and
		(D7.dc is null or D4.dc > D7.dc) and
		(D6.dc is null or D4.dc > D6.dc) and
		(D5.dc is null or D4.dc > D5.dc) and
		(D4.dc is not null) and
		(D3.dc is null or D4.dc > D3.dc) and
		(D2.dc is null or D4.dc > D2.dc) and
		(D1.dc is null or D4.dc > D1.dc)

	-- case: pick the next data block of size 5
	union all
	select space_left-5, offset+5, sc, p9, p8, p7, p6, p5+1, p4, p3, p2, p1, D5.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D5.dc > D9.dc) and
		(D8.dc is null or D5.dc > D8.dc) and
		(D7.dc is null or D5.dc > D7.dc) and
		(D6.dc is null or D5.dc > D6.dc) and
		(D5.dc is not null) and
		(D4.dc is null or D5.dc > D4.dc) and
		(D3.dc is null or D5.dc > D3.dc) and
		(D2.dc is null or D5.dc > D2.dc) and
		(D1.dc is null or D5.dc > D1.dc)

	-- case: pick the next data block of size 6
	union all
	select space_left-6, offset+6, sc, p9, p8, p7, p6+1, p5, p4, p3, p2, p1, D6.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D6.dc > D9.dc) and
		(D8.dc is null or D6.dc > D8.dc) and
		(D7.dc is null or D6.dc > D7.dc) and
		(D6.dc is not null) and
		(D5.dc is null or D6.dc > D5.dc) and
		(D4.dc is null or D6.dc > D4.dc) and
		(D3.dc is null or D6.dc > D3.dc) and
		(D2.dc is null or D6.dc > D2.dc) and
		(D1.dc is null or D6.dc > D1.dc)

	-- case: pick the next data block of size 7
	union all
	select space_left-7, offset+7, sc, p9, p8, p7+1, p6, p5, p4, p3, p2, p1, D7.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D7.dc > D9.dc) and
		(D8.dc is null or D7.dc > D8.dc) and
		(D7.dc is not null) and
		(D6.dc is null or D7.dc > D6.dc) and
		(D5.dc is null or D7.dc > D5.dc) and
		(D4.dc is null or D7.dc > D4.dc) and
		(D3.dc is null or D7.dc > D3.dc) and
		(D2.dc is null or D7.dc > D2.dc) and
		(D1.dc is null or D7.dc > D1.dc)

	-- case: pick the next data block of size 8
	union all
	select space_left-8, offset+8, sc, p9, p8+1, p7, p6, p5, p4, p3, p2, p1, D8.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is null or D8.dc > D9.dc) and
		(D8.dc is not null) and
		(D7.dc is null or D8.dc > D7.dc) and
		(D6.dc is null or D8.dc > D6.dc) and
		(D5.dc is null or D8.dc > D5.dc) and
		(D4.dc is null or D8.dc > D4.dc) and
		(D3.dc is null or D8.dc > D3.dc) and
		(D2.dc is null or D8.dc > D2.dc) and
		(D1.dc is null or D8.dc > D1.dc)

	-- case: pick the next data block of size 9
	union all
	select space_left-9, offset+9, sc, p9+1, p8, p7, p6, p5, p4, p3, p2, p1, D9.dc as c from X
	left join D9 on D9.dc > sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > sc and D1.idx = X.p1 and space_left >= 1
	where
		(D9.dc is not null) and
		(D8.dc is null or D9.dc > D8.dc) and
		(D7.dc is null or D9.dc > D7.dc) and
		(D6.dc is null or D9.dc > D6.dc) and
		(D5.dc is null or D9.dc > D5.dc) and
		(D4.dc is null or D9.dc > D4.dc) and
		(D3.dc is null or D9.dc > D3.dc) and
		(D2.dc is null or D9.dc > D2.dc) and
		(D1.dc is null or D9.dc > D1.dc)

	-- case: move on to the next space block
	union all
	select S.size, 0, S.sc, p9, p8, p7, p6, p5, p4, p3, p2, p1, NULL from X
	left join D9 on D9.dc > X.sc and D9.idx = X.p9 and space_left >= 9
	left join D8 on D8.dc > X.sc and D8.idx = X.p8 and space_left >= 8
	left join D7 on D7.dc > X.sc and D7.idx = X.p7 and space_left >= 7
	left join D6 on D6.dc > X.sc and D6.idx = X.p6 and space_left >= 6
	left join D5 on D5.dc > X.sc and D5.idx = X.p5 and space_left >= 5
	left join D4 on D4.dc > X.sc and D4.idx = X.p4 and space_left >= 4
	left join D3 on D3.dc > X.sc and D3.idx = X.p3 and space_left >= 3
	left join D2 on D2.dc > X.sc and D2.idx = X.p2 and space_left >= 2
	left join D1 on D1.dc > X.sc and D1.idx = X.p1 and space_left >= 1
	join S where
		(S.sc = X.sc + 1) and
		(D9.dc is null) and
		(D8.dc is null) and
		(D7.dc is null) and
		(D6.dc is null) and
		(D5.dc is null) and
		(D4.dc is null) and
		(D3.dc is null) and
		(D2.dc is null) and
		(D1.dc is null)
),

F as (
	select	
		D.dc,
		coalesce(S.start + X.offset - D.size, D.start) as start,
		coalesce(S.start + X.offset, D.end)	as end
	from D
	left join X on D.dc = X.dc
	left join S on S.sc = X.sc
	order by start
)

select sum(value * dc) from F
join generate_series(F.start, F.end-1);
