/*
 * INFo2120 / INFO2820
 * Database Systems I
 *
 * Reference Schema for INFO2120/2820 Assignment - Treasure Hunt Database
 * version 1.2
 *
 * PostgreSQL version
 *
 * IMPORTANT!
 * You need to replace 'your_login' with your PostgreSQL user name in line 240
 * of this file (the ALTER USER  command)
 */
-- delete eventually already existing tables
-- ignore the errors if you execute this script the first time
BEGIN TRANSACTION;
   DROP SCHEMA IF EXISTS TreasureHunt CASCADE;
   DROP DOMAIN IF EXISTS RatingDomain CASCADE;
   DROP DOMAIN IF EXISTS DurationDomain;
COMMIT;

BEGIN TRANSACTION;
/* a user domain can be defined inside the CREATE SCHEMA block as used below */
CREATE DOMAIN RatingDomain   AS SMALLINT CHECK ( VALUE BETWEEN 1 AND 5 );
CREATE DOMAIN DurationDomain AS INT      CHECK ( VALUE >= 0 );
COMMENT ON DOMAIN RatingDomain   IS 'A rating between 1 and 5';
COMMENT ON DOMAIN DurationDomain IS 'Duration in full minutes';

/* all tables and views are part of one 'TreasureHunt' schema */
CREATE SCHEMA TreasureHunt
CREATE TABLE Hunt (
    id           SERIAL,                      -- surrogate key (INT) with auto-increment
    title        VARCHAR(40) UNIQUE NOT NULL, -- title is a candidate key, hence UNIQUE
    description  TEXT,                        -- this is new here, helpful for GUI
    distance     INT,
    numWayPoints INT,
    startTime    TIMESTAMP,                   -- just DATE would be not precise enough
    status       VARCHAR(20) NOT NULL DEFAULT 'under construction',
    CONSTRAINT Hunt_PK     PRIMARY KEY (id),
    CONSTRAINT Hunt_Status CHECK ( status IN ('under construction','open','active','finished') )
)
-- advanced part
CREATE TABLE Location (
    name   VARCHAR(40),
    parent VARCHAR(40) NULL,
    type   VARCHAR(10) NOT NULL,
    CONSTRAINT Location_PK        PRIMARY KEY (name),
    CONSTRAINT Location_Parent_FK FOREIGN KEY (parent) REFERENCES Location ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT Location_CHK CHECK (type IN ('suburb','area','region','city','state','country'))
)
--
-- WayPoint ISA mapped to 2 distinct tables plus a view on top
--
CREATE TABLE PhysicalWayPoint (
    hunt   INT,
    num    SMALLINT,
    name   VARCHAR(40) NOT NULL,
    verification_code   INT,
    clue   TEXT,
    gpsLat FLOAT,
    gpsLon FLOAT,
    isAt   VARCHAR(40),   -- advanced part
    CONSTRAINT PhysicalWayPoint_PK      PRIMARY KEY (hunt, num),
    CONSTRAINT PhysicalWayPoint_Name_UN UNIQUE      (hunt, name),
    CONSTRAINT PhysicalWayPoint_Hunt_FK FOREIGN KEY (hunt) REFERENCES Hunt ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT PhysicalWayPoint_Loc_FK  FOREIGN KEY (isAt) REFERENCES Location ON DELETE RESTRICT ON UPDATE CASCADE
)
CREATE TABLE VirtualWayPoint (
    hunt   INT,
    num    SMALLINT,
    name   VARCHAR(40) NOT NULL,
    verification_code   INT,
    clue   TEXT,
    url    VARCHAR(200),
    CONSTRAINT VirtualWayPoint_PK      PRIMARY KEY (hunt, num),
    CONSTRAINT VirtualWayPoint_Name_UN UNIQUE      (hunt, name),
    CONSTRAINT VirtualWayPoint_Hunt_FK FOREIGN KEY (hunt) REFERENCES Hunt ON DELETE CASCADE ON UPDATE RESTRICT
)
CREATE VIEW WayPoint AS
    SELECT hunt, num, name, verification_code, clue, 'LOC'
      FROM PhysicalWayPoint
     UNION
    SELECT hunt, num, name, verification_code, clue, 'WWW'
      FROM VirtualWayPoint
--
-- example for an assertion to ensure that each hunt has at least two waypoints
-- and at the same time also checking that num_way_points matches the atual number of WPs
-- CREATE ASSERTION HuntsMinTwoWaypoints CHECK (
--   NOT EXISTS ( SELECT hunt
--                  FROM WayPoint JOIN Hunt ON (hunt=id)
--                 GROUP BY hunt
--                HAVING COUNT(num) < 2 OR COUNT(num) != numWayPoints )
-- )
--
CREATE TABLE Player (
   name     VARCHAR(40),
   password VARCHAR(20) NOT NULL,
   pw_salt  VARCHAR(10) NOT NULL,
   gender   CHAR,
   addr     VARCHAR(100),
   CONSTRAINT Player_PK     PRIMARY KEY (name),
   CONSTRAINT Player_Gender CHECK ( gender IN ('m','f') )
)
CREATE TABLE PlayerStats (
   player     VARCHAR(40),
   stat_name  VARCHAR(20),
   stat_value VARCHAR(20) NOT NULL,
   CONSTRAINT PlayerStats_PK PRIMARY KEY (player, stat_name),
   CONSTRAINT PlayerStats_FK FOREIGN KEY (player) REFERENCES Player
)
CREATE TABLE Team (
    name    VARCHAR(40),
    created DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT Team_PK PRIMARY KEY (name)
)
CREATE TABLE MemberOf (
    player VARCHAR(40),
    team   VARCHAR(40),
    since  DATE NOT NULL DEFAULT CURRENT_DATE,
    current BOOLEAN NOT NULL DEFAULT TRUE, -- ADDED: identifies current team of a player
    CONSTRAINT TeamMembers_PK        PRIMARY KEY (team,player),
    CONSTRAINT TeamMembers_Player_FK FOREIGN KEY (player) REFERENCES Player,
    CONSTRAINT TeamMembers_Team_FK   FOREIGN KEY (team)   REFERENCES Team ON DELETE CASCADE ON UPDATE CASCADE
)
--
-- Example for an assertion to ensure that each team has 2-3 members:
-- CREATE ASSERTION TeamSizeBetween2and3 CHECK (
--   NOT EXISTS ( SELECT team
--                  FROM MemberOf
--                 GROUP BY team
--                HAVING COUNT(player) < 2 OR COUNT(player) > 3 )
-- )
-- Another, perhaps more elegant option is to check for this at the point in time
-- when a team tries to enrol for a hunt using a trigger...
-- For the latter approach, see the two triggers at the end of this file
--
CREATE TABLE Participates (
    team      VARCHAR(40),
    hunt      INT,
    currentWP SMALLINT NULL, -- ADDED: identifies current waypoint of team during active hunt
                             --        doubles as a flag for a team's current hunt, as otherwise it is NULL
    score     INT NULL,      -- progressively increases during a hunt
    rank      INT NULL,
    duration DurationDomain NULL, -- in minutes
    CONSTRAINT Participates_PK PRIMARY KEY (team,hunt),
    CONSTRAINT Participates_Hunt_FK FOREIGN KEY (hunt) REFERENCES Hunt ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Participates_Team_FK FOREIGN KEY (team) REFERENCES Team ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Participates_Rank    CHECK ( rank > 0 ),
    CONSTRAINT Participates_Score   CHECK ( score >= 0 )
)
-- Example for an assertion to ensure that teams participate in at most one active hunt
-- CREATE ASSERTION TeamsMaxOneActiveHunt CHECK (
--   NOT EXISTS ( SELECT team
--                  FROM Participates JOIN Hunt ON (hunt=id)
--                 WHERE status = 'active'
--                 GROUP BY team
--                HAVING COUNT(hunt) > 1 )
-- )
CREATE TABLE Visit (
    team           VARCHAR(40),
    num            SMALLINT,
    submitted_code INT       NOT NULL,
    time           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_correct     BOOLEAN   NOT NULL,
    visited_hunt   INT       NULL,
    visited_wp     SMALLINT  NULL,
    CONSTRAINT Visit_PK PRIMARY KEY (team,num),
    CONSTRAINT Visit_Team_FK     FOREIGN KEY (team) REFERENCES Team ON DELETE CASCADE ON UPDATE CASCADE
-- one big disadvantage of having WayPoints as a view is that we cannot use foreign key here...
--    CONSTRAINT Visit_WayPoint_FK FOREIGN KEY (visited_hunt,visited_wp) REFERENCES WayPoint ON DELETE RESTRICT ON UPDATE CASCADE
)
CREATE TABLE Badge (
    name        VARCHAR(40),
    description TEXT          NOT NULL,
    condition   VARCHAR(200)  NOT NULL,
    CONSTRAINT Badge_PK PRIMARY KEY (name)
)
CREATE TABLE Achievements (
    player  VARCHAR(40),
    badge   VARCHAR(40),
    whenReceived DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT Wins_PK        PRIMARY KEY (player, badge),
    CONSTRAINT Wins_Player_FK FOREIGN KEY (player) REFERENCES Player ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Wins_Badge_FK  FOREIGN KEY (badge)  REFERENCES Badge  ON DELETE CASCADE ON UPDATE CASCADE
)
CREATE TABLE Review (
    id          SERIAL,       -- surrogate ID (INT) with auto-increment
    hunt        INT           NOT NULL,
    player      VARCHAR(40)   NOT NULL,
    whenDone    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rating      RatingDomain  NOT NULL,
    description TEXT          NULL,
    CONSTRAINT Review_PK PRIMARY KEY (id),
    CONSTRAINT Review_CK UNIQUE (hunt,player),
    CONSTRAINT Review_Hunt_FK   FOREIGN KEY (hunt)   REFERENCES Hunt ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Review_Player_FK FOREIGN KEY (player) REFERENCES Player ON DELETE CASCADE ON UPDATE CASCADE
)
CREATE TABLE Likes (
    review     INT,
    player     VARCHAR(40),
    whenDone   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usefulness RatingDomain,
    CONSTRAINT Likes_PK PRIMARY KEY (review,player),
    CONSTRAINT Likes_Review_FK FOREIGN KEY (review) REFERENCES Review ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Likes_Player_FK FOREIGN KEY (player) REFERENCES Player ON DELETE CASCADE ON UPDATE CASCADE
);


/* some utility functions for the CHECK clause of the following triggers */
CREATE OR REPLACE FUNCTION TreasureHunt.getTeamSize( team VARCHAR ) RETURNS BIGINT AS
       'SELECT COUNT(*) FROM TreasureHunt.MemberOf WHERE team = $1'
       LANGUAGE sql;

/* generic trigger function that just stops the execution of the current statement      */
/* note that this gives a silent stop without error message; result is '0 row affected' */
/* if you want an explicit error message, include a  RAISE EXCEPTION 'error msg'        */
CREATE OR REPLACE FUNCTION TreasureHunt.Noop() RETURNS trigger AS
$body$
BEGIN
   RETURN NULL; -- a return value of NULL silently stops the current statement
END
$body$ LANGUAGE plpgsql;

/* trigger to ensure that a team can have a maximum of 3 members */
DROP TRIGGER IF EXISTS TeamMaxThreeMembers_Trigger ON TreasureHunt.MemberOf;
CREATE TRIGGER TeamMaxThreeMembers_Trigger
       BEFORE UPDATE OR INSERT ON TreasureHunt.MemberOf
       FOR EACH ROW 
       WHEN ( TreasureHunt.getTeamSize(NEW.team) = 3 )
       EXECUTE PROCEDURE TreasureHunt.Noop();

/* trigger to ensure that a team must have at least 2 member when signing up to a hunt */
DROP TRIGGER IF EXISTS TeamMin2Members_Trigger ON TreasureHunt.Participates;
CREATE TRIGGER TeamMin2Members_Trigger
       BEFORE UPDATE OR INSERT ON TreasureHunt.Participates
       FOR EACH ROW
       WHEN ( TreasureHunt.getTeamSize(NEW.team) < 2 )
       EXECUTE PROCEDURE TreasureHunt.Noop();

/* Stored function to check login of user */
CREATE OR REPLACE FUNCTION login ( username VARCHAR, pword VARCHAR ) RETURNS BIGINT AS $$ 
	BEGIN
		RETURN (SELECT COUNT(*) FROM TreasureHunt.Player 
		WHERE name=username AND password=pword);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve details of user */
CREATE OR REPLACE FUNCTION get_user_details ( username VARCHAR ) RETURNS TABLE(name VARCHAR, addr VARCHAR, team VARCHAR) AS $$ 
	BEGIN
		RETURN QUERY(SELECT p.name, p.addr, m.team FROM treasurehunt.player p 
		LEFT OUTER JOIN  treasurehunt.memberof m  ON p.name=m.player
            	WHERE p.name=username);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve all stats of user */
CREATE OR REPLACE FUNCTION get_user_stats ( username VARCHAR ) RETURNS TABLE(statname VARCHAR, statvalue VARCHAR) AS $$ 
	BEGIN
		RETURN QUERY(SELECT stat_name, stat_value
                    FROM TreasureHunt.PlayerStats
                    WHERE player=username);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve all badges of a user */
CREATE OR REPLACE FUNCTION get_user_badges ( username VARCHAR ) RETURNS TABLE(badgename VARCHAR, badgedescription TEXT) AS $$ 
	BEGIN
		RETURN QUERY(SELECT b.name, b.description
                FROM treasurehunt.badge b JOIN treasurehunt.achievements a ON b.name=a.badge
                WHERE a.player=username);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve all available hunts */
CREATE OR REPLACE FUNCTION get_available_hunts() RETURNS TABLE(hunt_id INT, htitle VARCHAR, stime TIMESTAMP, dist INT, num_wp INT) AS $$ 
	BEGIN
		RETURN QUERY(SELECT id, title, starttime, distance, numwaypoints 
            FROM treasurehunt.hunt
            ORDER BY title);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve information about a specific hunt */
CREATE OR REPLACE FUNCTION get_hunt_details(hunt_id INT) RETURNS TABLE(htitle VARCHAR, hdesc TEXT, stime TIMESTAMP, dist INT) AS $$ 
	BEGIN
		RETURN QUERY(SELECT title, description, starttime, distance 
            FROM treasurehunt.hunt
            WHERE id=hunt_id);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve the active hunt of a user */
CREATE OR REPLACE FUNCTION get_active_hunt ( username VARCHAR ) RETURNS TABLE(hunt_title VARCHAR, pteam VARCHAR, stime TIMESTAMP,
	elapsed INTERVAL, pscore INT, waypoint_count INT, clue TEXT) AS $$ 
	BEGIN
		RETURN QUERY(SELECT h.title, p.team, h.startTime, (CURRENT_TIMESTAMP - h.starttime), 
			p.score, (p.currentWP - 1), 
			(SELECT w.clue FROM treasurehunt.waypoint w WHERE w.num=p.currentWP AND w.hunt=h.id)
            	FROM (treasurehunt.hunt h JOIN treasurehunt.participates p ON h.id = p.hunt)
            	JOIN treasurehunt.memberof m  ON p.team=m.team
            	WHERE h.status='active' AND m.player =username);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve the most recently finished hunt of a user */
CREATE OR REPLACE FUNCTION get_recent_hunt ( username VARCHAR ) RETURNS TABLE(hunt_title VARCHAR, pteam VARCHAR, stime TIMESTAMP,
	elapsed INTERVAL, pscore INT, trank INT) AS $$ 
	BEGIN
		RETURN QUERY(SELECT h.title, p.team, h.startTime, (CURRENT_TIMESTAMP - h.starttime), 
                 p.score, p.rank
            FROM (treasurehunt.hunt h JOIN treasurehunt.participates p ON h.id = p.hunt)
            JOIN treasurehunt.memberof m  ON p.team=m.team
            WHERE h.status='finished' AND m.player=username
            ORDER BY h.starttime DESC LIMIT 1);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve the verification code of the next waypoint in the active hunt of the user, and some stats */
CREATE OR REPLACE FUNCTION get_ver_code ( username VARCHAR ) RETURNS TABLE(ver_code INT, hunt_id INT, pteam VARCHAR,
	wp_num SMALLINT) AS $$ 
	BEGIN
		RETURN QUERY(SELECT w.verification_code, p.hunt, p.team, w.num
            FROM treasurehunt.waypoint w
            JOIN treasurehunt.participates p ON w.hunt = p.hunt
            JOIN treasurehunt.team t ON t.name = p.team
            WHERE p.team = (
            	SELECT team
            	FROM treasurehunt.memberof
            	WHERE player = username)
            AND w.num = p.currentWP);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve the total number of waypoints in a hunt */
CREATE OR REPLACE FUNCTION get_hunt_wp_num ( hunt_id INT ) RETURNS SMALLINT AS $$ 
	BEGIN
		RETURN (SELECT numwaypoints
		        FROM treasurehunt.hunt
                WHERE id=hunt_id);
	END
	$$ language 'plpgsql';

/* Function to return the finished_hunts and point_score stats of a user */
CREATE OR REPLACE FUNCTION get_fin_hunts ( username VARCHAR ) RETURNS TABLE(statname VARCHAR, statvalue VARCHAR) AS $$ 
	BEGIN
		RETURN QUERY(SELECT stat_name, stat_value 
		FROM treasurehunt.playerstats
		WHERE player=username AND (stat_name='finished_hunts' OR
		stat_name='point_score') ORDER BY stat_name);
	END
	$$ language 'plpgsql';

/* Function to make and increment a finished_hunts stat, if it doesn't exist */
CREATE OR REPLACE FUNCTION make_fin_hunts ( username VARCHAR ) RETURNS VOID AS $$ 
	BEGIN
		INSERT INTO treasurehunt.playerstats
		VALUES(username, 'finished_hunts', 1);
	END
	$$ language 'plpgsql';

/* Function to increment the finished_hunts stat when it exists */
CREATE OR REPLACE FUNCTION incr_fin_hunts ( username VARCHAR ) RETURNS VOID AS $$ 
	BEGIN
		UPDATE treasurehunt.playerstats
		SET stat_value=CAST(stat_value AS INT) + 1
		WHERE player=username AND stat_name='finished_hunts';
	END
	$$ language 'plpgsql';

/* Stored function to update point_score stat for a player on hunt completion */
CREATE OR REPLACE FUNCTION update_score ( curr_score INT, hunt_id INT, pteam VARCHAR, username VARCHAR ) RETURNS VOID AS $$ 
	BEGIN
		UPDATE treasurehunt.playerstats
		SET stat_value = (curr_score + (SELECT p.score 
		FROM participates p 
		WHERE hunt=hunt_id AND team=pteam) + 1)
                WHERE player=username AND stat_name='point_score';
	END
	$$ language 'plpgsql';

/* Stored function to update the participates table for a team on hunt completion */
CREATE OR REPLACE FUNCTION update_participates ( hunt_id INT, pteam VARCHAR ) RETURNS VOID AS $$ 
	BEGIN
		UPDATE treasurehunt.participates
                SET currentWP=NULL, score=score+1,
			duration= ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - 
                (SELECT starttime FROM treasurehunt.hunt WHERE id=hunt_id)))/60),
		rank= 1 + COALESCE((SELECT rank FROM treasurehunt.participates WHERE hunt=hunt_id AND rank IS NOT NULL ORDER BY rank DESC), 0)
                WHERE hunt=hunt_id AND team=pteam;
	END
	$$ language 'plpgsql';

/* Stored function to update the participates table for a team on normal waypoint visit */
CREATE OR REPLACE FUNCTION update_current_hunt ( hunt_id INT, pteam VARCHAR ) RETURNS VOID AS $$ 
	BEGIN
		UPDATE treasurehunt.participates
                SET currentWP=currentWP+1, score=score+1
                WHERE hunt=hunt_id AND team=pteam;
	END
	$$ language 'plpgsql';

/* Stored function to retrieve the next clue in a hunt */
CREATE OR REPLACE FUNCTION get_clue ( hunt_id INT, curr_wp SMALLINT ) RETURNS TEXT AS $$ 
	BEGIN
		RETURN (SELECT clue FROM treasurehunt.waypoint
                WHERE hunt=hunt_id AND num=curr_wp);
	END
	$$ language 'plpgsql';

/* Stored function to save a visit into the visit table, whether correct or not */
CREATE OR REPLACE FUNCTION save_visit ( pteam VARCHAR, code INT, is_correct BOOLEAN, hunt_id INT, current_wp SMALLINT ) RETURNS VOID AS $$ 
	BEGIN
		INSERT INTO treasurehunt.visit
		VALUES(CAST(pteam AS VARCHAR), 1 + COALESCE((SELECT num FROM treasurehunt.visit WHERE team=pteam
		ORDER BY num DESC LIMIT 1), 0), code, CURRENT_TIMESTAMP, is_correct, hunt_id, current_wp);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve a team's score during a hunt */
CREATE OR REPLACE FUNCTION get_score ( pteam VARCHAR, hunt_id INT ) RETURNS INT AS $$ 
	BEGIN
		RETURN( SELECT score FROM treasurehunt.participates WHERE team=pteam AND hunt=hunt_id);
	END
	$$ language 'plpgsql';

/* Stored function to retrieve the reviews for a given hunt */
CREATE OR REPLACE FUNCTION get_reviews ( hunt_id INT ) RETURNS 
TABLE( pname VARCHAR, whenmade TIMESTAMP, rate ratingdomain, comm TEXT)  AS $$ 
	BEGIN
		RETURN QUERY(SELECT player, whendone, rating, description 
		FROM treasurehunt.review WHERE hunt=hunt_id);
	END
	$$ language 'plpgsql';

/* Stored function to save a review into the reviews table */
CREATE OR REPLACE FUNCTION make_review(hunt_id INT, player VARCHAR, rate RATINGDOMAIN, description TEXT) RETURNS VOID AS $$ 
	BEGIN
		INSERT INTO treasurehunt.review 
		VALUES(DEFAULT, hunt_id, player, CURRENT_TIMESTAMP, rate, description);
	END
	$$ language 'plpgsql';
	
/* IMPORTANT TODO: */
/* please replace 'your_login' with the name of your PostgreSQL login */
/* in the following ALTER USER username SET search_path ... command   */
/* this ensures that the carsharing schema is automatically used when you query one of its tables */
ALTER USER sdun6546 SET search_Path = '$user', public, unidb, TreasureHunt;
COMMIT;

/*Security and user access functions for info2120public. Grants access to db, schema, 
 * select over the tables and use of the stored functions. */
GRANT CONNECT ON DATABASE sdun6546 TO info2120public;

GRANT USAGE ON SCHEMA treasurehunt TO info2120public;

GRANT SELECT ON treasurehunt.hunt TO info2120public; 
GRANT SELECT ON treasurehunt.location TO info2120public;
GRANT SELECT ON treasurehunt.waypoint TO info2120public;
GRANT SELECT ON treasurehunt.player TO info2120public; 
GRANT SELECT ON treasurehunt.playerstats TO info2120public; 
GRANT INSERT ON treasurehunt.playerstats TO info2120public; 
GRANT UPDATE ON treasurehunt.playerstats TO info2120public; 
GRANT SELECT ON treasurehunt.team TO info2120public; 
GRANT SELECT ON treasurehunt.memberof TO info2120public;   
GRANT SELECT ON treasurehunt.participates TO info2120public; 
GRANT UPDATE ON treasurehunt.participates TO info2120public;
GRANT SELECT ON treasurehunt.visit TO info2120public;
GRANT INSERT ON treasurehunt.visit TO info2120public; 
GRANT SELECT ON treasurehunt.badge TO info2120public; 
GRANT SELECT ON treasurehunt.achievements TO info2120public; 
GRANT SELECT ON treasurehunt.review TO info2120public;
GRANT INSERT ON treasurehunt.review TO info2120public; 
GRANT UPDATE ON treasurehunt.review TO info2120public; 
GRANT SELECT ON treasurehunt.likes TO info2120public; 

GRANT EXECUTE ON FUNCTION login(VARCHAR,VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_user_details(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_user_stats(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_user_badges(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_available_hunts() TO info2120public;
GRANT EXECUTE ON FUNCTION get_hunt_details(INT) TO info2120public;
GRANT EXECUTE ON FUNCTION get_active_hunt(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_recent_hunt(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_ver_code(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_hunt_wp_num(INT) TO info2120public;
GRANT EXECUTE ON FUNCTION get_fin_hunts(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION make_fin_hunts(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION incr_fin_hunts(VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION update_score(INT,INT,VARCHAR,VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION update_participates(INT,VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION update_current_hunt(INT,VARCHAR) TO info2120public;
GRANT EXECUTE ON FUNCTION get_clue(INT,SMALLINT) TO info2120public;
GRANT EXECUTE ON FUNCTION save_visit(VARCHAR,INT,BOOLEAN,INT,SMALLINT) TO info2120public;
GRANT EXECUTE ON FUNCTION get_score(VARCHAR,INT) TO info2120public;
GRANT EXECUTE ON FUNCTION get_reviews(INT) TO info2120public;
GRANT EXECUTE ON FUNCTION make_review(INT,VARCHAR,RATINGDOMAIN,TEXT) TO info2120public;
GRANT UPDATE ON SEQUENCE review_id_seq TO info2120public;

