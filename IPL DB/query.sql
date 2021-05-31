--1--
select match_id, player_name, team_name, count(*) as num_wickets from player, (select bowler, team_bowling, wicket_taken.match_id as match_id from wicket_taken join ball_by_ball on (wicket_taken.match_id = ball_by_ball.match_id and wicket_taken.over_id = ball_by_ball.over_id and wicket_taken.ball_id = ball_by_ball.ball_id and wicket_taken.innings_no = ball_by_ball.innings_no and wicket_taken.kind_out in (1, 2, 4 ,6, 7, 8))) as p, team t where p.bowler = player.player_id and team_bowling = t.team_id  group by player_name, team_name, match_id having count(*) >= 5 order by count(*) desc, player_name asc, team_name asc, match_id;

--2--
select player.player_name as Player_name, count(*) as num_matches from player,  (select player_match.player_id from player_match join match on (player_match.match_id = match.match_id and player_match.player_id = match.man_of_the_match and player_match.team_id <> match.match_winner) ) as p where player.player_id = p.player_id group by player.player_id order by count(*) desc, player.player_name limit 3;

--3--
select player_name from player,  (select fielders from wicket_taken,(select match_id from match join season on season.season_id = match.season_id where season_year = 2012 ) as p1 where wicket_taken.match_id = p1.match_id and wicket_taken.kind_out = 1 and fielders is not null) as p2 where p2.fielders = player_id  group by player_id order by count(*) desc limit 1;

--4--
select q2.season_year, player_name, count(*) as num_matches from player, (select q1.purple_cap, q1.season_year from player_match, (select  match_id, purple_cap, season.season_id, season.season_year from season join match on season.season_id = match.season_id )as q1 where player_id = q1.purple_cap and q1.match_id = player_match.match_id) as q2 where player_id = q2.purple_cap group by q2.season_year, player_name order by q2.season_year;

--5--
select distinct player_name from player, (select match.match_id, player_id, runs_scored from match, (select player_match.match_id, player_match.player_id, player_match.team_id, runs_scored from player_match, (select bb.match_id, bb.striker, sum(runs_scored) as runs_scored from batsman_scored as bs join ball_by_ball as bb on bs.match_id = bb.match_id and bs.over_id = bb.over_id and bs.ball_id = bb.ball_id and bs.innings_no = bb.innings_no group by bb.match_id, bb.striker having sum(runs_scored) > 50) as q1 where player_match.player_id = q1.striker and player_match.match_id = q1.match_id ) as q2 where match.match_id = q2.match_id and match.match_winner <> q2.team_id ) as q3 where q3.player_id = player.player_id order by player_name;

--6--
with res as( select q2.season_year, q2.team_name, row_number() over (partition by q2.season_year order by count desc, team_name ) as rank from
(select q1.season_year, q1.team_name, count(*) from player p, (select s.season_year, pm.player_id, t.team_name from player_match pm, match m, team t, season s 
where pm.match_id = m.match_id and pm.team_id = t.team_id and m.season_id = s.season_id
group by s.season_year, pm.player_id, t.team_name) as q1 where p.player_id = q1.player_id and p.batting_hand = 1 and p.country_id <> 1 group by q1.team_name, q1.season_year) as q2)
select res.season_year, res.team_name, res.rank from res where res.rank in (1, 2, 3, 4, 5) order by res.season_year, rank, team_name;

--7--
select team_name  from team, (select match_winner from match, (select season_id from season where season_year = 2009 ) as q1 where match.season_id = q1.season_id) as q2 where q2.match_winner = team.team_id group by team_id order by count(*) desc, team_name ;

--8--
with result as (select team_name, player_name, sum, row_number() over (partition by team_name order by sum desc) as rk from 
(select player.player_name, q5.team_name, q5.sum  from 
(select * from 
(select q3.striker, sum(runs_scored), q3.team_batting from 
(select * from batsman_scored where batsman_scored.match_id in 
(select match_id from match where season_id in (select season_id from season where season_year = 2010))) as q2, 
(select * from ball_by_ball where ball_by_ball.match_id in 
(select match_id from match where season_id in (select season_id from season where season_year = 2010))) as q3 
where q2.match_id = q3.match_id and q2.over_id = q3.over_id and q2.ball_id = q3.ball_id and q2.innings_no = q3.innings_no and q2.innings_no in (1, 2)
group by q3.striker, q3.team_batting ) as q4 join team 
on q4.team_batting = team.team_id) as q5 join player on q5.striker = player.player_id) as final_table)
select result.team_name, result.player_name, sum as runs from result where result.rk = 1 order by result.team_name, result.player_name;

--9--
with q1 as (select team_name, team_bowling, number_of_sixes from team as t, 
(select team_batting,  team_bowling, count(runs_scored) as number_of_sixes  from season as s,                                             match as m, batsman_scored as bs, ball_by_ball as bb where 
s.season_year = 2008 and m.season_id = s.season_id and m.match_id = bs.match_id and bs.match_id = bb.match_id and 
bs.over_id = bb.over_id and bs.innings_no = bb.innings_no and bs.innings_no in (1, 2) and bs.ball_id = bb.ball_id and bs.runs_scored = 6 
group by bs.innings_no, bs.match_id, bb.team_batting, bb.team_bowling ) as q where t.team_id = q.team_batting)
select q1.team_name, tt.team_name as opponent_team_name, number_of_sixes from team as tt, q1 
where team_bowling = tt.team_id order by number_of_sixes desc, team_name limit 3;

--10--
with avg_bow as (select round(sum(wickets)/count(*)) as avg_wk from (select bowler, count(*) as wickets from wicket_taken wk, ball_by_ball bb where wk.match_id = bb.match_id
and wk.over_id = bb.over_id and wk.ball_id = bb.ball_id and wk.innings_no = bb.innings_no and wk.innings_no in (1, 2) group by bowler) as q1),
avg_bat as (select striker, round(sum(sum)/count(*), 2) as avg from (select striker, sum(runs_scored) from batsman_scored bs, ball_by_ball bb where bs.match_id = bb.match_id
and bs.over_id = bb.over_id and bs.ball_id = bb.ball_id and bs.innings_no = bb.innings_no and bs.innings_no in (1, 2) group by striker, bs.match_id) as q2 group by striker),
bat_wk as (select striker, avg, q1.wickets from avg_bat,avg_bow, (select bowler, count(*) as wickets from wicket_taken wk, ball_by_ball bb where wk.match_id = bb.match_id
and wk.over_id = bb.over_id and wk.ball_id = bb.ball_id and wk.innings_no = bb.innings_no and wk.innings_no in (1, 2) group by bowler) as q1 where avg_bat.striker = q1.bowler and q1.wickets > avg_bow.avg_wk),
final as (select player_name, bs.bowling_skill, avg, row_number() over (partition by bs.bowling_skill order by avg desc, player_name) as rk from bat_wk , player p, bowling_style bs where bat_wk.striker = p.player_id and p.bowling_skill = bs.bowling_id)
select bowling_skill as bowling_category, player_name, avg as batting_average from final where rk = 1;

--11--
select  season_year, player_name, wickets_taken as num_wickets, runs_scored as runs from season, 
(select p1.season_id, p1.player_id, p1.player_name, p1.runs_scored, p2.wickets_taken from  
(select season_id, player_id, m1.player_name, runs_scored from player as m1, 
(select season_id, striker, sum(runs_scored) as runs_scored from match as m,
(select bb.match_id, striker, sum(runs_scored) as runs_scored from batsman_scored as bs, ball_by_ball as bb 
where bb.match_id = bs.match_id and 
bb.over_id = bs.over_id and 
bb.ball_id = bs.ball_id and 
bb.innings_no = bs.innings_no and bb.innings_no in (1, 2)
group by bb.match_id, striker ) as q1 where m.match_id = q1.match_id group by season_id, striker) as q2 where 
q2.striker = m1.player_id and m1.batting_hand = 1 and runs_scored >= 150 ) as p1,
(select season_id, player_id, player_name, bowler, wickets_taken from player, (select season_id, bowler,  sum(wickets_taken) as wickets_taken from match as m, 
(select bb.match_id, bb.bowler, count(*) as wickets_taken from wicket_taken as wk, ball_by_ball as bb 
where wk.match_id = bb.match_id and 
wk.over_id = bb.over_id and 
bb.ball_id = wk.ball_id and 
bb.innings_no = wk.innings_no and bb.innings_no in (1, 2) and
wk.kind_out in (1, 2, 4, 6, 7, 8) 
group by bb.match_id, bowler ) as q3 where m.match_id = q3.match_id group by season_id, bowler) as q4 
where q4.bowler = player.player_id and wickets_taken >= 5 ) as p2,
(select season_id, player_id from player_match as pm, match as m where 
pm.match_id = m.match_id group by season_id, player_id having count(*) >= 10 ) as p3
where p1.season_id = p2.season_id and p2.season_id = p3.season_id and p1.player_id = p2.player_id and p2.player_id = p3.player_id) as p4
where p4.season_id = season.season_id
order by num_wickets desc, runs desc, player_name;

--12--
with result as (select q2.match_id, p.player_name, t.team_name, q2.num_wickets, q2.season_year, row_number() over (partition by q2.match_id order by num_wickets desc, player_name, match_id) as rk
from player as p, team as t,
(select s.season_year, q1.match_id, q1.bowler, q1.team_bowling, q1.num_wickets from season as s, 
(select wk.match_id, bb.bowler, bb.team_bowling, count(*) as num_wickets from 
wicket_taken as wk, ball_by_ball as bb where 
wk.match_id = bb.match_id and 
wk.over_id = bb.over_id and 
wk.ball_id = bb.ball_id and 
wk.innings_no = bb.innings_no and wk.innings_no in (1, 2) and
wk.kind_out in (1, 2, 4, 6, 7,8) group by wk.match_id, bb.bowler, bb.team_bowling) as q1, match as m
where m.match_id = q1.match_id and s.season_id = m.season_id) as q2
where p.player_id = q2.bowler and q2.team_bowling = t.team_id )
select result.match_id, result.player_name, result.team_name, result.num_wickets, result.season_year from result where result.rk = 1 order by result.num_wickets desc, result.player_name, result.match_id limit 1;

--13--
select player_name from player as p, (select player_id from (select player_id, season_id from 
player_match as pm, match as m where pm.match_id = m.match_id 
group by player_id, season_id) as q1 group by player_id having count(*) = 9) as q2 where p.player_id = q2.player_id 
order by player_name;

--14--
with result as (select q3.match_id, q3.season_year, q3.team_name, q3.count, row_number() 
over (partition by q3.season_year order by q3.count desc, q3.team_name, q3.match_id) as rk from
(select q2.match_id, q2.season_year, q2.team_name, count(*) from
(select m.match_id, s.season_year, t.team_name, q1.runs_scored from match m, season s, team t,
(select bs.match_id, striker, team_batting, sum(runs_scored) as runs_scored from 
batsman_scored as bs, ball_by_ball as bb where 
bs.match_id = bb.match_id and bs.over_id = bb.over_id and 
bs.ball_id = bb.ball_id and bs.innings_no = bb.innings_no and bs.innings_no in (1, 2)
group by bs.match_id, striker, team_batting) as q1 where
q1.match_id = m.match_id and m.outcome_id = 1 and q1.team_batting = m.match_winner and m.match_winner = t.team_id and q1.runs_scored >= 50 and m.season_id = s.season_id) as q2 
group by q2.match_id, q2.season_year, q2.team_name) as q3)
select result.season_year, result.match_id, result.team_name from result where result.rk in (1, 2, 3) order by season_year, rk ;

--15--
with bat as (select q5.season_year, q5.sum, q5.player_name, row_number() over (partition by q5.season_year order by q5.sum desc, q5.player_name ) as rk from
(select s.season_year, sum(q4.sum), q4.player_name from match m, season s, 
(select bs.match_id,player_name, sum(runs_scored) from 
batsman_scored bs, ball_by_ball bb, player p where bs.match_id = bb.match_id and bs.over_id = bb.over_id and 
bs.ball_id = bb.ball_id and bs.innings_no = bb.innings_no and bs.innings_no in (1, 2) and striker = p.player_id group by bs.match_id, player_name) as q4
where q4.match_id = m.match_id and m.season_id = s.season_id group by season_year, player_name) as q5),
bowl as (select q2.season_year, q2.sum, q2.player_name, row_number() over (partition by q2.season_year order by q2.sum desc, q2.player_name ) as rk from
(select q1.player_name, sum(count), s.season_year from match m, season s, 
(select wk.match_id, player_name, count(*) from 
wicket_taken wk, ball_by_ball bb, player p where 
wk.match_id = bb.match_id and wk.over_id = bb.over_id and wk.ball_id = bb.ball_id and wk.innings_no = bb.innings_no and wk.innings_no in (1, 2) and 
kind_out in (1, 2, 4, 6, 7, 8) and bowler = player_id group by player_name, wk.match_id) as q1 where 
m.match_id = q1.match_id and m.season_id = s.season_id group by season_year, player_name) as q2)
select bowl.season_year, bat.player_name as top_batsman, bat.sum as max_runs, bowl.player_name as top_bowler, bowl.sum as max_wickets from bowl, bat where bowl.rk = 2 and bat.rk = 2 and bat.season_year = bowl.season_year;

--16--
with res as (select t1.team_name, t2.team_name, t3.team_name as match_winner from match m, season s, team t1, team t2, team t3 where m.season_id = s.season_id and s.season_year = 2008 and (team_1 = 2 or team_2 = 2) and outcome_id = 1 and match_winner <> 2 and t1.team_id = team_1 and t2.team_id = team_2 and t3.team_id = match_winner)
select match_winner as team_name from res group by match_winner order by count(*) desc, match_winner;

--17--
with res as (select q1.player_name, q1.team_name, count, row_number() over (partition by q1.team_name order by count desc, player_name) as rk from
(select player_name, team_name, count(*) from match m, player_match pm, team t, player p where m.match_id = pm.match_id and
pm.player_id = m.man_of_the_match and pm.player_id = p.player_id and t.team_id = pm.team_id group by player_name, team_name) as q1)
select team_name, player_name, count from res where res.rk = 1 order by team_name;

--18--
select p1.player_name from (select player_name, count(run_conceded) from (select player_name,team_bowling, sum(runs_scored) as run_conceded from ball_by_ball bb , batsman_scored bs, player p where 
bb.match_id = bs.match_id and bb.over_id = bs.over_id and bb.ball_id = bs.ball_id and bb.innings_no = bs.innings_no and 
bb.bowler = p.player_id group by bb.match_id, bb.over_id, team_bowling, player_name) as q1 where q1.run_conceded > 20 group by
player_name) as p1, (select q3.player_name from (select player_name, team_id from player_match pm, player p where p.player_id = pm.player_id group by player_name, team_id) as q3 group by player_name having count(*) > 2) as q4 where q4.player_name = p1.player_name order by count desc, player_name limit 5;

--19--
select team_name, round(sum(sum)/count(*), 2) as avg_runs from (select team_name, sum(runs_scored) from season s, match m, ball_by_ball bb, batsman_scored bs, team t where s.season_year =  2010 and s.season_id = m.season_id
and m.match_id = bb.match_id and bb.match_id = bs.match_id and bb.innings_no not in (3, 4) and bb.innings_no = bs.innings_no and bb.ball_id = bs.ball_id and
bb.over_id = bs.over_id and bb.team_batting = t.team_id group by team_name, bs.match_id) as q1 group by q1.team_name order by team_name;

--sql query 20--
select player_name as player_names from player p, wicket_taken wk, ball_by_ball bb where wk.match_id = bb.match_id and wk.over_id = 1 and wk.over_id = bb.over_id
and wk.ball_id = bb.ball_id and wk.innings_no = bb.innings_no and wk.innings_no in (1, 2) and wk.player_out = p.player_id group by player_name order by count(*) desc, player_name limit 10;

--21--
select q3.match_id , q3.team_1_name, t3.team_name as team_2_name, q3.match_winner_name, q3.number_of_boundaries from 
(select q2.match_id, t2.team_name as team_1_name, q2.team_2, q2.match_winner_name, q2.number_of_boundaries from 
(select m.match_id, m.team_1, m.team_2, t.team_name as match_winner_name, count as number_of_boundaries from (select bb.match_id, bb.team_batting, count(*) from  ball_by_ball bb, batsman_scored bs where bs.runs_scored in (4, 6) and bs.match_id = bb.match_id and
bs.over_id = bb.over_id and bs.ball_id = bb.ball_id and bs.innings_no = bb.innings_no and bb.innings_no = 2 group by bb.match_id, bb.team_batting, bb.innings_no) as q1, match m, team t
where q1.match_id = m.match_id and q1.team_batting = m.match_winner and t.team_id = m.match_winner) as q2 , team t2 where q2.team_1 = t2.team_id) as q3, team t3
where q3.team_2 = t3.team_id  order by number_of_boundaries, match_winner_name, team_1_name, team_2_name limit 3;

--22--
with runs as (select bowler, sum(runs_scored) from batsman_scored bs, ball_by_ball bb where bs.match_id = bb.match_id and bs.over_id = bb.over_id
and bs.ball_id = bb.ball_id and bs.innings_no = bb.innings_no and bs.innings_no in (1, 2) group by bowler),
wick as (select bowler, count(*) from wicket_taken wk, ball_by_ball bb where wk.match_id = bb.match_id and wk.over_id = bb.over_id
and wk.ball_id = bb.ball_id and wk.innings_no = bb.innings_no and wk.innings_no in (1, 2) group by bowler)
select c.country_name from (select player_name, sum, count, round(sum/count, 2), p.country_id from runs r, wick w, player p where r.bowler = w.bowler and r.bowler = p.player_id order by round) as q1, country c where c.country_id = q1.country_id order by round limit 3;
 
