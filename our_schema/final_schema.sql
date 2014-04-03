/* Treasure Hunt Schema for INFO2120 Group Assignment 2. 
	Sebastian Dunn
	Jenna Bermeister
	Eric Lam
*/

BEGIN TRANSACTION;
	DROP SCHEMA IF EXISTS TreasureHunt CASCADE;
	DROP TABLE IF EXISTS Hunt;
   	DROP TABLE IF EXISTS Player;
	DROP TABLE IF EXISTS Team;
   	DROP TABLE IF EXISTS Badge;
	DROP TABLE IF EXISTS Review 	CASCADE;
   	DROP TABLE IF EXISTS Likes 	CASCADE;
   	DROP TABLE IF EXISTS Statistics CASCADE;
   	DROP TABLE IF EXISTS Achieves	CASCADE;
   	DROP TABLE IF EXISTS MemberOf 	CASCADE;
   	DROP TABLE IF EXISTS Waypoint 	CASCADE;
   	DROP TABLE IF EXISTS Visit 	CASCADE;
   	DROP TABLE IF EXISTS Participate CASCADE;
	DROP TABLE IF EXISTS Challenge	CASCADE;

   	DROP DOMAIN IF EXISTS GEO_LOC;
   	DROP TYPE IF EXISTS hunt_status;

	DROP FUNCTION IF EXISTS AbortWaypointDelete();
	DROP FUNCTION IF EXISTS AbortTeamInsert();
COMMIT;

BEGIN TRANSACTION;

CREATE SCHEMA TreasureHunt;

--Created a domain for geographic location data. Float with 10 sf, 6 of which may be after the decimal point
CREATE DOMAIN GEO_LOC NUMERIC(10, 6);

--Enum for the status of a hunt
CREATE TYPE hunt_status AS ENUM ('under construction', 'open for registrations', 'in progress', 'complete');

/* Treasure hunt table. Distance and startTime may be null while hunt is under construction */
CREATE TABLE TreasureHunt.Hunt (
  	title		VARCHAR(50) 	PRIMARY KEY,
  	distance      	INTEGER,
  	numWaypoints	INTEGER		NOT NULL,
  	startTime	TIMESTAMP,
  	status		hunt_status	NOT NULL,

	CONSTRAINT number_hunt_waypoints CHECK (numWaypoints >= 2)
);

/* Player table. May elect not to give address, and gender can be Male, Female or Other */
CREATE TABLE TreasureHunt.Player (
  	name          	VARCHAR(30) 	PRIMARY KEY,
  	password      	VARCHAR(10) 	NOT NULL,
  	address       	VARCHAR(50),
  	gender		CHAR	 	NOT NULL,

	CONSTRAINT approve_gender CHECK (gender IN ('F','M','O'))  
);

/* Team table. time_created will be a CURRENT_TIMESTAMP when the team tuple is created */
CREATE TABLE TreasureHunt.Team (
	name 		VARCHAR(50),
	time_created	TIMESTAMP	NOT NULL,

	CONSTRAINT Team_PK PRIMARY KEY (name)
);

/* Badge table. Description is what the player sees, condition is more details on win condition
 * or possibly a small script testing win condition and awarding badge if met by player */
CREATE TABLE TreasureHunt.Badge	(
	name 		VARCHAR(30)	NOT NULL,
	description 	VARCHAR(150)	NOT NULL,
	condition 	VARCHAR(150) 	NOT NULL,

	CONSTRAINT Badge_PK PRIMARY KEY (name)
);

/* Review table. Identified by player_name and hunt_title - each player may only review a hunt
 * once. A rating is between 1 and 5. WhenDone will be a CURRENT_TIMESTAMP on tuple creation. */
CREATE TABLE TreasureHunt.Review (
  	player_name	VARCHAR(30),
  	hunt_title    	VARCHAR(50),
  	rating   	INTEGER 	NOT NULL,
  	whenDone      	TIMESTAMP 	NOT NULL,
  	description   	VARCHAR(150),
  
  	CONSTRAINT Review_pk PRIMARY KEY (player_name,hunt_title),
    
  	CONSTRAINT review_player_name_fk FOREIGN KEY (player_name) REFERENCES TreasureHunt.Player(name)
   						ON UPDATE CASCADE
    						ON DELETE CASCADE,

  	CONSTRAINT review_hunt_title_fk FOREIGN KEY (hunt_title) REFERENCES TreasureHunt.Hunt(title)
   						ON UPDATE CASCADE
    						ON DELETE CASCADE,

	CONSTRAINT rating_range CHECK (rating BETWEEN 1 and 5)
);

/* Likes table, for players 'liking' player reviews. Each like has a usefulness rating between 
 * 1 and 5, a CURRENT_TIMESTAMP of when the like happened, and details of the review. */
CREATE TABLE TreasureHunt.Likes (
  	usefulness  		INTEGER		NOT NULL,
  	whenDone    		TIMESTAMP	NOT NULL,
  	player_name 		VARCHAR(30),
  	review_player_name 	VARCHAR(30),
  	review_hunt_title 	VARCHAR(50),
  
  	CONSTRAINT likes_PK PRIMARY KEY (review_player_name, review_hunt_title, player_name),

  	CONSTRAINT likes_player_name_fk FOREIGN KEY (player_name) REFERENCES TreasureHunt.Player(name)
    						ON UPDATE CASCADE
    						ON DELETE CASCADE,

  	CONSTRAINT likes_review_fk FOREIGN KEY (review_player_name, review_hunt_title) 
						REFERENCES TreasureHunt.Review(player_name, hunt_title)
   						ON UPDATE CASCADE
   						ON DELETE CASCADE,

	CONSTRAINT usefulness_range CHECK (usefulness BETWEEN 1 and 5)
);

/* Statistics table. Stores player_name with the associated stat and an int value for the stat. */
CREATE TABLE TreasureHunt.Statistics	(
	name 		VARCHAR(30),
	player_name	VARCHAR(30),
	value 		INTEGER,
	
	CONSTRAINT stat_PK PRIMARY KEY (name, player_name),

	CONSTRAINT stat_play_name_FK FOREIGN KEY (player_name) REFERENCES TreasureHunt.Player(name)
		ON UPDATE CASCADE 
		ON DELETE CASCADE
);

/* Table for when a player Achieves a badge. Only stores date of achievement - badges are long 
 * term rewards. */
CREATE TABLE TreasureHunt.Achieves	(
	recieved 	DATE 		NOT NULL,
	player_name	VARCHAR(30),
	badge_name	VARCHAR(30),

	CONSTRAINT achieves_player_FK FOREIGN KEY (player_name) REFERENCES TreasureHunt.Player(name)
		ON UPDATE CASCADE 
		ON DELETE CASCADE,

	CONSTRAINT achieves_badge_FK FOREIGN KEY (badge_name) REFERENCES TreasureHunt.Badge(name) 
		ON UPDATE CASCADE 
		ON DELETE CASCADE
);

/* MemberOf table. Stores player, their current team and the CURRENT_TIMESTAMP of the tuple 
 * creation. */
CREATE TABLE TreasureHunt.MemberOf (
	player_name	VARCHAR(30),
	team_name	VARCHAR(50),
	since		TIMESTAMP	NOT NULL,

	CONSTRAINT MemberOf_PK 		PRIMARY KEY (player_name, team_name),

	CONSTRAINT MemberOf_Team_FK 	FOREIGN KEY (team_name) 
					REFERENCES TreasureHunt.Team(name) 
					ON UPDATE CASCADE
					ON DELETE CASCADE,

	CONSTRAINT MemberOf_Player_FK 	FOREIGN KEY (player_name) 
					REFERENCES TreasureHunt.Player(name) 
					ON UPDATE CASCADE
					ON DELETE NO ACTION
);

/* Waypoint table. Stores the hunt, sequential number of the waypoint, a verification code needed
 * to gain the clue to the next waypoint, its own clue, and either geographic location data (if
 * a physical waypoint) or a URL (if a virtual waypoint).
 */
CREATE TABLE TreasureHunt.Waypoint (
	hunt_title	VARCHAR(50),
	number		INT,
	name		VARCHAR(30),
	ver_code	VARCHAR(50)	NOT NULL,
	clue		VARCHAR(150)	NOT NULL,
	longitude	GEO_LOC,
	latitude	GEO_LOC,
	url		VARCHAR(100),

	CONSTRAINT Waypoint_PK 		PRIMARY KEY (hunt_title, number),

	CONSTRAINT Waypoint_Hunt_FK 	FOREIGN KEY (hunt_title) 	
					REFERENCES TreasureHunt.Hunt(title) 
					ON UPDATE CASCADE
					ON DELETE CASCADE,

	--This constraint enforces that a waypoint has EITHER a geographic location OR a URL
	CONSTRAINT virtual_physical 	CHECK ((longitude IS NULL AND latitude IS NULL AND url IS NOT NULL) 
					OR (longitude IS NOT NULL AND latitude IS NOT NULL AND url IS NULL))
);

/* Table storing deatils of a team's visit to a waypoint. Has the visit_num (the number that this
 * visit is for them in the hunt - may be different from waypoint_number), foreign keys to 
 * waypoint and team tables, a boolean to show if the visit was correct (in order), points 
 * awarded for the visit, the code_submitted to the waypoint (may not be correct verification 
 * code) and the timestamp of the visit.
 */
CREATE TABLE TreasureHunt.Visit (
	visit_num	INT,
	team_name	VARCHAR(50),
	waypoint_num	INT		NOT NULL,
	hunt_title	VARCHAR(50)	NOT NULL,
	correct		BOOLEAN		NOT NULL,
	points		INT		NOT NULL,
	submitted_code	VARCHAR(50)	NOT NULL,
	time		TIMESTAMP	NOT NULL,

	CONSTRAINT Visit_PK 		PRIMARY KEY (visit_num, team_name),

	CONSTRAINT visit_waypoint_FK	FOREIGN KEY (hunt_title, waypoint_num)
					REFERENCES TreasureHunt.Waypoint(hunt_title, number)
					ON UPDATE CASCADE
					ON DELETE SET NULL, --this is so the points still exist for the team score

	CONSTRAINT Visit_Team_FK 	FOREIGN KEY (team_name) 
					REFERENCES TreasureHunt.Team(name)
					ON UPDATE CASCADE
					ON DELETE CASCADE
);

/* Challenge table. Any hunt waypoint may be a challenge waypoint - when a team reaches it they
 * are given the choice to either take the normal clue and proceed to the next waypoint or to 
 * take the challenge to try and speed their progress. If taking the challenge, they are directed
 * to a URL (challenge_info) with details of problem/task. After completing the task they will 
 * have worked out or been given a string to enter (return_string). Once they enter this string, 
 * they are given the clue to the 2nd coming waypoint, not the next waypoint, thereby earning
 * a shortcut.
 */
CREATE TABLE TreasureHunt.Challenge (
	hunt_title	VARCHAR(50),
	waypoint_number	INT,
	description	VARCHAR(150),
	challenge_info	VARCHAR(100),
	return_string	VARCHAR(50),

	CONSTRAINT challenge_PK PRIMARY KEY (hunt_title, waypoint_number),

	CONSTRAINT challenge_wp_FK	FOREIGN KEY (hunt_title, waypoint_number)
					REFERENCES TreasureHunt.Waypoint(hunt_title, number)
					ON UPDATE CASCADE
					ON DELETE CASCADE
);

/* Participate table storing information about a team participating in the hunt. Includes the 
 * team's culmulative score so far in the hunt, and their ranking with other teams on the same
 * hunt (based on their relative scores). Duration is the time since they started the hunt.
 */
CREATE TABLE TreasureHunt.Participate (
	rank 		INTEGER		NOT NULL,
	score 		INTEGER		NOT NULL,
	duration 	TIME,
	hunt_title	VARCHAR(50),
	team_name	VARCHAR(50),

	CONSTRAINT participate_PK PRIMARY KEY (hunt_title, team_name),

	CONSTRAINT participate_hunt_FK FOREIGN KEY (hunt_title) REFERENCES TreasureHunt.Hunt(title) 
		ON UPDATE CASCADE 
		ON DELETE CASCADE,

	CONSTRAINT participate_team_FK FOREIGN KEY (team_name) REFERENCES TreasureHunt.Team(name) 
		ON UPDATE CASCADE 
		ON DELETE CASCADE
);

-- This assertion checks that team numbers are between 2 and 3 each time the MemberOf table is modified. It is deferred so the inital team creation can make the first two players without violating this constraint. This is not implemented by any DBMS but needed to be included for the marking rubric. Please see trigger function below for how this will actually be maintained in the database.
--CREATE ASSERTION member_number CHECK
--	( ((SELECT MIN(COUNT(*)) FROM MemberOf GROUP BY team_name)
--		> 1) AND
--	  ((SELECT MAX(COUNT(*)) FROM MemberOf GROUP BY team_name)
--		< 4)
--	) DEFERRABLE INITAILLY DEFERRED;

/* Trigger function maintaining that team must have 2 or 3 members, upon INSERT or UPDATE. This
 * is separate to the function for when DELETE happens because of the reference to NEW tuple.
 */
CREATE FUNCTION TreasureHunt.AbortTeamInsert() RETURNS trigger AS $team_members_ins$
	BEGIN
		IF 	((SELECT COUNT(*)
			FROM TreasureHunt.MemberOf m
			WHERE m.team_name = NEW.team_name)
			NOT BETWEEN 2 AND 3)
		THEN
			RAISE EXCEPTION 'Teams must have 2 or 3 members only';
		END IF;
	RETURN NULL;
	END;
$team_members_ins$ LANGUAGE plpgsql;

/*Trigger is DEFERRABLE INITIALLY DEFERRED so that a hunt may be created with its first two team
 * members without violating the constraint. */
CREATE CONSTRAINT TRIGGER too_many_team_members 
	AFTER INSERT OR UPDATE ON TreasureHunt.MemberOf
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE TreasureHunt.AbortTeamInsert();

/* Trigger function maintaining team number constraint when a DELETE happens. If the number falls
 * to 1, raises exception. However, if it falls to 0 in a single command it will trigger the
 * deletion of the whole team. This second part was included because otherwise team deletion 
 * would always be aborted by this function, even when desirable. */
CREATE FUNCTION TreasureHunt.AbortTeamDelete() RETURNS trigger AS $team_members_del$
	BEGIN
		IF	((SELECT COUNT(*)
			FROM TreasureHunt.MemberOf m
			WHERE m.team_name = OLD.team_name)
			= 0)
		THEN	
			DELETE FROM TreasureHunt.Team 
			WHERE Team.name = OLD.team_name;

		ELSE IF	((SELECT COUNT(*)
			FROM TreasureHunt.MemberOf m
			WHERE m.team_name = OLD.team_name)
			NOT BETWEEN 2 AND 3)
		THEN
			RAISE EXCEPTION 'Teams must have 2 or 3 members only';
		END IF;
		END IF;
	RETURN NULL;
	END;
$team_members_del$ LANGUAGE plpgsql;

/* DEFERRABLE INITIALLY DEFERRED for when a team must be deleted - can delete all team members
 * in a single command without breaching this constraint. */
CREATE CONSTRAINT TRIGGER too_few_team_members
	AFTER DELETE ON TreasureHunt.MemberOf
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE TreasureHunt.AbortTeamDelete();

/* Trigger function to abort waypoint deletion if it would bring the total number of waypoints 
 * in that hunt below 2.
 */
CREATE FUNCTION TreasureHunt.AbortWaypointDelete() RETURNS trigger AS $waypoint_number$
	BEGIN
		IF 	(SELECT COUNT(*)
			FROM  TreasureHunt.Waypoint w
			WHERE w.hunt_title = OLD.hunt_title)
			< 2
		THEN
			RAISE EXCEPTION 'Hunts must always have at least two waypoints!';
		END IF;
	RETURN NULL;
	END;
$waypoint_number$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER enforce_waypoint_number
	AFTER DELETE OR UPDATE ON TreasureHunt.Waypoint 
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE TreasureHunt.AbortWaypointDelete();

/* Trigger function to set the number of waypoints in the Hunt table whenever a tuple is 
 * created, updated or deleted in the waypoint table. Either references the NEW or OLD tuple
 * depending on whether the trigger condition was an INSERT, DELETE or UPDATE. */
CREATE FUNCTION TreasureHunt.SetWaypointNumber() RETURNS trigger AS $set_waypoint_number$
	BEGIN
		IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE')
		THEN
		UPDATE TreasureHunt.Hunt h
		SET numWaypoints = (SELECT COUNT(*)
				   FROM TreasureHunt.Waypoint w
				   WHERE w.hunt_title = NEW.hunt_title)
		WHERE h.title = NEW.hunt_title;
		ELSE IF (TG_OP = 'DELETE')
		THEN
		UPDATE TreasureHunt.Hunt h
		SET numWaypoints = (SELECT COUNT(*)
				   FROM TreasureHunt.Waypoint w
				   WHERE w.hunt_title = OLD.hunt_title)
		WHERE h.title = OLD.hunt_title;
		END IF;
		END IF;
	RETURN NULL;
	END;
$set_waypoint_number$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER update_waypoint_number
	AFTER DELETE OR UPDATE OR INSERT ON TreasureHunt.Waypoint 
	DEFERRABLE INITIALLY DEFERRED
	FOR EACH ROW
	EXECUTE PROCEDURE TreasureHunt.SetWaypointNumber();


COMMIT;
