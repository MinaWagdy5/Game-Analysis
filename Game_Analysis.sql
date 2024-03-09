
-- use game_analysis;

-- Problem Statement - Game Analysis dataset
-- 1) Players play a game divided into 3-levels (L0,L1 and L2)
-- 2) Each level has 3 difficulty levels (Low,Medium,High)
-- 3) At each level,players have to kill the opponents using guns/physical fight
-- 4) Each level has multiple stages at each difficulty level.
-- 5) A player can only play L1 using its system generated L1_code.
-- 6) Only players who have played Level1 can possibly play Level2 
--    using its system generated L2_code.
-- 7) By default a player can play L0.
-- 8) Each player can login to the game using a Dev_ID.
-- 9) Players can earn extra lives at each stage in a level.

-- alter table pd modify L1_Status varchar(30);
-- alter table pd modify L2_Status varchar(30);
-- alter table pd modify P_ID int primary key;
-- alter table pd drop myunknowncolumn;
--
-- alter table ld drop myunknowncolumn;
-- alter table ld change timestamp start_datetime datetime;
-- alter table ld modify Dev_Id varchar(10);
-- alter table ld modify Difficulty varchar(15);
-- alter table ld add primary key(P_ID,Dev_id,start_datetime);

-- pd (P_ID,PName,L1_status,L2_Status,L1_code,L2_Code)
-- ld (P_ID,Dev_ID,start_time,stages_crossed,level,difficulty,kill_count,
-- headshots_count,score,lives_earned)

CREATE TABLE level_details (
  number int,
  P_ID int,
  Dev_ID varchar,
  TimeStamp varchar,
  Stages_crossed int,
  Level int,
  Difficulty varchar,
  Kill_Count int,
  Headshots_Count int,
  Score int,
  Lives_Earned int
);

SELECT *
FROM player_details;

SELECT *
FROM level_details;

CREATE TABLE player_details (
  number int,
  P_ID int,
  PName varchar,
  L1_Status int,
  L2_Status int,
  L1_Code varchar,
  L2_Code varchar
);
-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0
--     CREATE table from player_details.csv DELIMITER ',' CSV HEADER;

SELECT p.P_ID,l.Dev_ID,p.PName,l.Level
FROM player_details AS p
INNER JOIN level_details AS l
ON l.P_ID = p.P_ID
    AND l.level = 0;

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--    3 stages are crossed
SELECT p.L1_Code, AVG(l.Kill_Count)
FROM player_details AS p
INNER JOIN level_details AS l
ON l.P_ID = p.P_ID
    AND l.Lives_Earned = 2
    AND l.Stages_crossed >=3
GROUP BY p.L1_Code;


-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.

SELECT SUM(l.Stages_crossed) AS total_stages_crossed , l.Difficulty
FROM   player_details AS p
INNER JOIN level_details AS l
ON l.P_ID = p.P_ID
    AND l.Level = 2
    AND l.Dev_ID LIKE 'zm%'
group by l.Difficulty
ORDER BY total_stages_crossed DESC;

-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.

SELECT l.P_ID, COUNT(DISTINCT TimeStamp) AS total_number_of_unique_dates
FROM level_details AS l
INNER JOIN player_details AS p
ON l.P_ID = p.P_ID
group by l.P_ID
HAVING COUNT(DISTINCT TimeStamp) > 1;


-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.

SELECT P_ID, level, SUM(kill_count) AS total_kill_count
FROM level_details
WHERE difficulty = 'Medium' AND kill_count > (
    SELECT AVG(kill_count)
    FROM level_details
    WHERE difficulty = 'Medium'
)
GROUP BY P_ID, level;



-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.

SELECT level_details.Level, level_details.P_ID, SUM(level_details.Lives_Earned) AS sum_of_lives_earned
FROM level_details
WHERE Level <> 0
group by level_details.Level, level_details.P_ID
ORDER BY Level;


-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.

SELECT dev_id, score, difficulty,
       ROW_NUMBER() OVER (PARTITION BY dev_id ORDER BY score) AS rank
FROM level_details
ORDER BY dev_id, rank
LIMIT 3;

-- Q8) Find first_login datetime for each device id

SELECT dev_id, MIN(TimeStamp) AS first_login
FROM level_details
GROUP BY dev_id;

-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.

SELECT dev_id, score, difficulty,
       RANK() OVER (PARTITION BY difficulty ORDER BY score) AS rank
FROM level_details
ORDER BY difficulty, rank
LIMIT 5;

-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.

SELECT P_ID , dev_id , MIN(TimeStamp) AS first_login
FROM level_details
group by dev_id, P_ID;

-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played -- by the player until that date.
-- a) window function
-- b) without window function

-- a
SELECT P_ID, TimeStamp,
       SUM(kill_count) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS total_kill_count
FROM level_details;

-- b
SELECT t1.P_ID, t1.TimeStamp,
       (SELECT SUM(t2.kill_count)
        FROM level_details t2
        WHERE t2.P_ID = t1.P_ID AND t2.TimeStamp <= t1.TimeStamp) AS total_kill_count
FROM level_details t1;


-- Q12) Find the cumulative sum of stages crossed over a start_datetime

SELECT TimeStamp, Stages_crossed,
       SUM(Stages_crossed) OVER (ORDER BY TimeStamp) AS cumulative_sum
FROM level_details;

-- Q13) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime

SELECT P_ID, TimeStamp, Stages_crossed,
       SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS cumulative_sum
FROM level_details;

-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id

SELECT dev_id, P_ID, total_score
FROM (
  SELECT dev_id, P_ID, SUM(score) AS total_score,
         ROW_NUMBER() OVER (PARTITION BY dev_id ORDER BY SUM(score) DESC) AS rank
  FROM level_details
  GROUP BY dev_id, P_ID
) AS subquery
WHERE rank <= 3
LIMIT 3;

-- Q15) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id

WITH player_scores AS (
  SELECT P_ID, SUM(score) AS total_score
  FROM level_details
  GROUP BY P_ID
)
SELECT t.P_ID,t.total_score
FROM player_scores t
JOIN (
  SELECT AVG(total_score) * 0.5 AS threshold
  FROM player_scores
) AS avg_scores ON t.total_score > avg_scores.threshold;

-- Q16) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.

DROP PROCEDURE IF EXISTS find_top_n_headshots_count;
-- Create the function with the desired return type
CREATE OR REPLACE FUNCTION find_top_n_headshots_count(n INT)
RETURNS TABLE (dev_id INT, headshots_count INT, difficulty TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT ranked_results.dev_id, ranked_results.headshots_count, ranked_results.difficulty
  FROM (
    SELECT dev_id, headshots_count, difficulty,
           ROW_NUMBER() OVER (PARTITION BY dev_id ORDER BY headshots_count) AS rank
    FROM level_details
  ) ranked_results
  WHERE ranked_results.rank <= n
  ORDER BY ranked_results.dev_id, ranked_results.rank;
END;
$$;


DO $$BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_proc
        WHERE proname = 'find_top_n_headshots_count'
          AND pronargs = 1
          AND proargtypes[1] = 'integer'::regtype
    ) THEN
        DROP FUNCTION find_top_n_headshots_count(integer);
    END IF;
END$$;

CREATE OR REPLACE FUNCTION find_top_n_headshots_count(n INT)
RETURNS TABLE (dev_id INT, headshots_count INT, difficulty TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT ranked_results.dev_id, ranked_results.headshots_count, ranked_results.difficulty
  FROM (
    SELECT level_details.dev_id, level_details.headshots_count, level_details.difficulty,
           ROW_NUMBER() OVER (PARTITION BY level_details.dev_id ORDER BY level_details.headshots_count) AS rank
    FROM level_details
  ) AS ranked_results
  WHERE ranked_results.rank <= n
  ORDER BY ranked_results.dev_id, ranked_results.rank;
END;
$$;
CALL find_top_n_headshots_count(5);
SELECT * FROM find_top_n_headshots_count(5);


-- Q17) Create a function to return sum of Score for a given player_id.

CREATE OR REPLACE FUNCTION GetPlayerScoreSum(player_id INT)
RETURNS INT
AS $$
DECLARE
  total_score INT;
BEGIN
  SELECT COALESCE(SUM(score), 0)
  INTO total_score
  FROM level_details
  WHERE P_ID = GetPlayerScoreSum.player_id;

  RETURN total_score;
END;
$$
LANGUAGE plpgsql;

-- Calling the function and get results
SELECT GetPlayerScoreSum(558) AS total_score;