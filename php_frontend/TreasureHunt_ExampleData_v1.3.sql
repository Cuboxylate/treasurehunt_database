/*
 *  Demo Data for Assignment 3 - DB Programming (INFO2120/2820)
 *  PostgreSQL Version 1.3
 *
 *  The following SQL script loads five example treasure hunts into your database.
 *  In order to avoid clashes with potentially existing data, we start our IDs at 11
 *  and then set the ID counters to 100 for the inserts of your own hunts & reviews etc.
 *  Contents:
 *    'The Goonies / One-Eyed Willies Hunt' by Callan
 *    'Pokemon Hunt' by Sasha
 *    'Return of the Jedi' by Scott
 *    'Find One Piece' by Blake
 *    'Shpoorenzoohe' by Uwe
 *    'QR-Test Hunt'
 *
 *  While the first four contain sythetic data, the last two are based on real virtual
 *  and physical locations in Sydney. So you can plot those GPS coordinates for example,
 *  especially of hunt #15 ('Shpoorenzoohe').
 *  The QR test has the idea that you can put up QR signs inside the SIT building which
 *  encode URLs to your web-based application with the given verification code as parameter
 *  so that you could visit those waypoints with a normal QR-reader app on a smartphone.
 *
 *  Changes:
 *   v1.3  fixed two Participates entries for hunts #11 and #16
 *   v1.2  fixed the visit times of the 'Pokemon' and the 'Find One Piece' hunts
 *   v1.1  included Blake's hunt too which accidentally was forgotten in initial release
 *         also fixed the Goonies hunt so that each player is only in a single team
 *   v1.0b same data as v1.0, but with portable DATE and TIMESTAMP syntax, and fixed typos
 *   v1.0  initial release
 */

/* First we need to make a few updates to the original schema */
BEGIN TRANSACTION;
  -- there are a few more location types than originally anticipated
  ALTER TABLE TreasureHunt.Location DROP CONSTRAINT IF EXISTS Location_CHK;
  ALTER TABLE TreasureHunt.Location ADD  CONSTRAINT Location_CHK CHECK (type IN ('locality','precinct','suburb','lga','area','city','region','state','country','planet','starsystem','galaxy','universe'));
  INSERT INTO TreasureHunt.Location (name, parent, type)
   VALUES ('Our Universe',     NULL,                 'universe'),
          ('Milky Way',        'Our Universe',       'galaxy'),
          ('Solar System',     'Milky Way',          'starsystem'),
          ('Earth',            'Solar System',       'planet');

  -- ISO/IEC 5218  defines three possible values for gender + NULL (http://en.wikipedia.org/wiki/ISO/IEC_5218)
  ALTER TABLE TreasureHunt.Player DROP CONSTRAINT IF EXISTS Player_Gender;
  ALTER TABLE TreasureHunt.Player ALTER COLUMN gender SET DATA TYPE VARCHAR(3);
  ALTER TABLE TreasureHunt.Player ADD  CONSTRAINT Player_Gender CHECK ( gender IN ('m','f','n/a') );

  -- introduce some badges which will be used by different hunts
  INSERT INTO TreasureHunt.Badge (name, description, condition)
   VALUES ('Novice Player', 'Welcome to the game!', 'finished_hunts = 0'),
          ('Adventurer',    'You already played at least three hunts.', 'finished_hunts > 2'),
          ('Treasure Hunter','You already played ten or more hunts.', 'finished_hunts >= 10'),
          ('High Roller',   'You scored already 100 points.', 'point_score > 99'),
          ('Trial-And-Error','Made 10 wrong attempts or visits.', 'wrong_visits > 9'),
          ('Sprinter',      'Congratulations - your average finishing time per hunt is 60 minutes or less.', 'avg_hunting_time <= 60');

COMMIT;

/*
 * The Goonies: One-Eyed Willies Treasure Hunt (thanks to Callan)
 */
BEGIN TRANSACTION;

INSERT INTO TreasureHunt.Hunt (id, title,description,distance,numWayPoints,startTime,status)
   VALUES (11, 'Find One-Eyed Willies Treasure', 'Find One-Eyed Willies', 500, 6, TIMESTAMP '1985-06-07 12:00:00', 'finished');

INSERT INTO TreasureHunt.PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon, isAt)
VALUES (11, 1, 'Walshes attic', 55371, 'Try to find the treasure map to One-Eyed Willies treasure!', 41.15850,174.47210, NULL),
       (11, 2, 'Fratellis Hideout', 55372, 'Avoid the Fratellis while you try to find the cave.', 41.17050,174.0010, NULL),
       (11, 3, 'Caverns', 55373, 'Escape the Fratellis in the hidden cavern. Watch out for traps!', 42.06050,175.00105, NULL),
       (11, 4, 'Underground Lagoon', 55374, 'Can you spot Willies Ship?', 44.06050,174.90101, NULL),
       (11, 5, 'Willies Ship', 55375, 'Get as much treasure off as possible and escape! Watch out for the Fratellis...', 40.89520,152.88406, NULL),
       (11, 6, 'Fratellis Hideout 2', 55376, 'You made it out alive! Now go save your neighbourhood.', 38.33210,150.0010, NULL);

INSERT INTO TreasureHunt.Player (name, password, pw_salt, gender, addr)
VALUES ('chunk', 'truffle', 'g#m#g#m#', 'm', 'Goon Docks'),
       ('mikey', 'goon4life', 't#s#y#w#r#', 'm', 'Goon Docks'),
       ('data',  'dataizcool', 'h#n#e#2', 'm', 'Goon Docks'),
       ('sloth', 'friend', 's#w#o#e#', 'm', 'Fratellis Hideout'),
       ('stef',  'treasure', 'p#e#m#n#', 'f', 'Goon Docks'),
       ('andy',  'plank',  'h#o#h#u#', 'f', 'Goon Docks');

INSERT INTO TreasureHunt.PlayerStats (player, stat_name, stat_value)
VALUES ('chunk', 'truffles_shuffled', '100'),
       ('mikey', 'treasure_found', '1'),
       ('chunk', 'friends_made', '1'),
       ('chunk', 'finished_hunts', '1'),
       ('chunk', 'point_score', '6'),
       ('mikey', 'finished_hunts', '1'),
       ('mikey', 'point_score', '9'),
       ('data',  'finished_hunts', '1'),
       ('data',  'point_score', '6'),
       ('data',  'wrong_visits', '1'),
       ('sloth', 'finished_hunts', '1'),
       ('sloth', 'point_score', '6'),
       ('stef',  'finished_hunts', '0'),
       ('stef',  'point_score', '0'),
       ('andy',  'finished_hunts', '1'),
       ('andy',  'point_score', '6'),
       ('andy',  'wrong_visits', '1');

INSERT INTO TreasureHunt.Team (name, created)
VALUES ('Shufflers',  DATE '1985-05-01'),
       ('GoonSelect', DATE '1985-02-21'),
	   ('Couple',     DATE '1985-01-04');

INSERT INTO TreasureHunt.MemberOf (player, team, since, current)
VALUES ('chunk', 'Shufflers',  DATE '1985-05-01', true),
       ('sloth', 'Shufflers',  DATE '1985-05-01', true),
       ('andy',  'GoonSelect', DATE '1985-02-21', true),
       ('data',  'GoonSelect', DATE '1985-02-21', true),
       ('stef',  'GoonSelect', DATE '1985-01-01', false),
	   ('mikey', 'Couple',     DATE '1985-01-04', true),
       ('stef',  'Couple',     DATE '1985-01-04', true);

INSERT INTO TreasureHunt.Badge (name, description, condition)
  VALUES ('Home Saver', 'You managed to save the day and your home!', 'treasure_found > 0');

INSERT INTO TreasureHunt.Achievements (player, badge, whenReceived)
VALUES ('chunk', 'Home Saver', DATE '1985-06-07'),
       ('mikey', 'Home Saver', DATE '1985-06-07'),
       ('data',  'Home Saver', DATE '1985-06-07'),
       ('stef',  'Home Saver', DATE '1985-06-07'),
       ('andy',  'Novice Player', DATE '1985-06-07');

INSERT INTO TreasureHunt.Visit (team, num, time, submitted_code, is_correct, visited_hunt, visited_wp)
VALUES ('Shufflers', 1, TIMESTAMP '1985-06-07 12:00:00', 61371, true, 11, 1),
       ('Shufflers', 2, TIMESTAMP '1985-06-07 13:00:00', 61372, true, 11, 2),
       ('Shufflers', 3, TIMESTAMP '1985-06-07 14:00:00', 61373, true, 11, 3),
       ('Shufflers', 4, TIMESTAMP '1985-06-07 15:00:00', 61374, true, 11, 4),
       ('Shufflers', 5, TIMESTAMP '1985-06-07 16:00:00', 61375, true, 11, 5),
	   ('Shufflers', 6, TIMESTAMP '1985-06-07 17:00:00', 61376, true, 11, 6),
       ('GoonSelect', 1, TIMESTAMP '1985-06-07 12:01:00', 66371, true, 11, 1),
       ('GoonSelect', 2, TIMESTAMP '1985-06-07 12:45:00', 66372, true, 11, 2),
       ('GoonSelect', 3, TIMESTAMP '1985-06-07 13:15:00',  6699,false, NULL, NULL),
	   ('GoonSelect', 4, TIMESTAMP '1985-06-07 13:20:00', 66995, true, 11, 3),
	   ('GoonSelect', 5, TIMESTAMP '1985-06-07 14:00:00', 67374, true, 11, 4),
       ('GoonSelect', 6, TIMESTAMP '1985-06-07 14:30:00', 67375, true, 11, 5),
	   ('GoonSelect', 7, TIMESTAMP '1985-06-07 15:05:05', 67376, true, 11, 6);

INSERT INTO TreasureHunt.Participates (team, hunt, currentWP, score, rank, duration)
VALUES ('Shufflers',  11, NULL, 6, 2, 5*60),
       ('GoonSelect', 11, NULL, 6, 1, 3*60+5);

INSERT INTO TreasureHunt.Review (id, hunt, player, whenDone, rating, description)
VALUES (11, 11, 'sloth', TIMESTAMP '1985-06-07 20:00:00', 1, 'Made friend.'),
       (12, 11, 'mikey', TIMESTAMP '1985-06-07 20:05:00', 5, 'Great hunt, very well timed. Would do again! A+++++++++');

INSERT INTO TreasureHunt.Likes (review, player, whenDone, usefulness)
VALUES (11, 'chunk', TIMESTAMP '1985-06-08 14:00:00', 5);

COMMIT;


/*
 * Pokemon Hunt (thanks to Sasha)
 */
BEGIN TRANSACTION;

INSERT INTO TreasureHunt.Hunt (id,title,description,distance,numWayPoints,startTime,status)
  VALUES (12, 'Kanto Pokemon Hunt', 'Pokemons rule!', 20000, 10, TIMESTAMP '2012-07-18 13:05:00', 'active');

INSERT INTO TreasureHunt.Location (name, parent, type)
VALUES ('Kanto', NULL, 'region'),
       ('Pallet Town', 'Kanto', 'city'),
       ('Pewter City', 'Kanto', 'city'),
       ('Cerulean City', 'Kanto', 'city'),
       ('Vermilion City', 'Kanto', 'city'),
       ('Celadon City', 'Kanto', 'city'),
       ('Fuschia City', 'Kanto', 'city'),
       ('Saffron City', 'Kanto', 'city'),
       ('Cinnabar Island', 'Kanto', 'city'),
       ('Viridian City', 'Kanto', 'city'),
       ('Indigo Plateau', 'Kanto', 'area'),
       ('Ash''s House', 'Pallet Town', 'suburb'),
       ('Gary''s House', 'Pallet Town', 'suburb'),
       ('Johto', NULL, 'region'),
       ('New Bark Town', 'Johto', 'city');

INSERT INTO TreasureHunt.PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon, isAt)
VALUES (12, 1, 'Starting House', 10, 'Receive your first Pokemon at the lab.', -34.034453,151.11969, 'Pallet Town'),
       (12, 2, 'Stone Gym', 30, 'Brock uses Rock-type Pokemon.', -33.92513,151.086731, 'Pewter City'),
       (12, 3, 'Water Gym', 32, 'Misty uses Water-type Pokemon.',  -33.785996,150.89447, 'Cerulean City'),
       (12, 4, 'Electric Gym', 29, 'Lt Surge uses Electric-type Pokemon.', -33.763165,151.210327, 'Vermilion City'),
       (12, 5, 'Grass Gym', 82, 'Erika uses Grass-type Pokemon.',  -33.824794,151.083984, 'Celadon City'),
       (12, 6, 'Poison Gym', 85, 'Koga uses Poison-type Pokemon.',  -33.683211,150.825806, 'Fuschia City'),
       (12, 7, 'Psychic Gym', 15, 'Sabrina uses Psychic-type Pokemon.', -33.815666,150.671997, 'Saffron City'),
       (12, 8, 'Fire Gym', 25, 'Blaine uses Fire-type Pokemon.', -33.904616,150.823059, 'Cinnabar Island'),
       (12, 9, 'Ground Gym', 342, 'Giovanni uses Ground-type Pokemon.',  -33.378706,151.281738, 'Viridian City'),
       (12, 10, 'The Elite 4', 12, 'The ultimate Pokemon Master challenge.', -33.607757,151.427307, 'Indigo Plateau');

INSERT INTO TreasureHunt.Player (name, password, pw_salt, gender, addr)
VALUES ('Ash', 'garyoak', 'oak', 'm', 'Ash''s House'),
       ('Misty', 'waterpkmn', 'gym', 'f', 'Cerulean City'),
       ('Brock', 'rockpkmn', 'gym', 'm', 'Pewter City'),
       ('Gary Oak', 'iwillwin', 'cheat', 'm', 'Gary''s House'),
       ('???', 'iwillwin', 'cheat', 'm', 'New Bark Town'),
       ('Jesse', 'double', 'trouble', 'm', 'Kanto'),
       ('James', 'capture', 'pkmn', 'm', 'Kanto');

INSERT INTO TreasureHunt.PlayerStats (player, stat_name, stat_value)
   VALUES ('Ash',   'finished_hunts', '1'),
          ('Ash',   'point_score',   '16'),
          ('Ash',   'wrong_visits',   '2'),
          ('Misty', 'finished_hunts', '2'),
          ('Misty', 'point_score',   '26'),
          ('Misty', 'wrong_visits',   '2'),
          ('Brock', 'finished_hunts', '2'),
          ('Brock', 'point_score',   '16'),
          ('Brock', 'wrong_visits',   '2'),
          ('Gary Oak','finished_hunts','2'),
          ('Gary Oak','point_score', '30'),
          ('???',   'finished_hunts', '1'),
          ('???',   'point_score',   '20'),
          ('Jesse', 'finished_hunts', '1'),
          ('Jesse', 'point_score',   '20'),
          ('James', 'finished_hunts','10'),
          ('James', 'point_score',  '110');

INSERT INTO TreasureHunt.Team (name, created)
VALUES ('CatchEmAll', DATE '2011-07-18'),
       ('Rival', DATE '2009-07-18'),
       ('Rocket', DATE '2008-07-18');

INSERT INTO TreasureHunt.MemberOf (player, team, since)
VALUES ('Ash', 'CatchEmAll', DATE '2011-07-18'),
       ('Misty', 'CatchEmAll', DATE '2011-07-20'),
       ('Brock', 'CatchEmAll', DATE '2011-08-18'),
       ('Gary Oak', 'Rival', DATE '2008-07-18'),
       ('???', 'Rival', DATE '2009-07-18'),
       ('Jesse', 'Rocket', DATE '2008-07-18'),
       ('James', 'Rocket', DATE '2008-07-18');

INSERT INTO TreasureHunt.Participates (team, hunt, currentWP, score, rank, duration)
VALUES ('CatchEmAll', 12,  7, 6, NULL, NULL),
       ('Rival',      12,NULL,10, 1, (29-18)*24*60+20 ),
       ('Rocket',     12,  1, 0, NULL, NULL);

INSERT INTO TreasureHunt.Visit (team, num, time, submitted_code, is_correct, visited_hunt, visited_wp)
VALUES ('CatchEmAll', 1, TIMESTAMP '2012-07-18 13:05:30', 10, true, 12, 1),
       ('CatchEmAll', 2, TIMESTAMP '2012-07-19 08:00:00', 15,false, NULL, NULL),
       ('CatchEmAll', 3, TIMESTAMP '2012-07-20 09:00:00', 30, true, 12, 2),
       ('CatchEmAll', 4, TIMESTAMP '2012-07-21 09:00:00', 32, true, 12, 3),
       ('CatchEmAll', 5, TIMESTAMP '2012-07-22 10:00:00', 29, true, 12, 4),
       ('CatchEmAll', 6, TIMESTAMP '2012-07-23 09:01:00', 82, true, 12, 5),
       ('CatchEmAll', 7, TIMESTAMP '2012-07-24 10:24:00', 82,false, NULL, NULL),
       ('CatchEmAll', 8, TIMESTAMP '2012-07-24 11:45:00', 85, true, 12, 6),
       ('Rival', 1, TIMESTAMP '2012-07-18 13:05:30', 10, true, 12, 1),
       ('Rival', 2, TIMESTAMP '2012-07-20 01:00:00', 30, true, 12, 2),
       ('Rival', 3, TIMESTAMP '2012-07-21 08:00:00', 32, true, 12, 3),
       ('Rival', 4, TIMESTAMP '2012-07-22 04:00:00', 29, true, 12, 4),
       ('Rival', 5, TIMESTAMP '2012-07-23 09:20:00', 82, true, 12, 5),
       ('Rival', 6, TIMESTAMP '2012-07-25 01:01:00', 85, true, 12, 6),
       ('Rival', 7, TIMESTAMP '2012-07-26 23:59:00', 15, true, 12, 7),
       ('Rival', 8, TIMESTAMP '2012-07-27 15:18:00', 25, true, 12, 8),
       ('Rival', 9, TIMESTAMP '2012-07-28 12:45:00', 342, true, 12, 9),
       ('Rival', 10, TIMESTAMP '2012-07-29 12:25:30', 12, true, 12, 10);

INSERT INTO TreasureHunt.Achievements (player, badge, whenReceived)
   VALUES ('James', 'Adventurer',      DATE '2008-11-18'),
          ('James', 'Treasure Hunter', DATE '2012-02-11'),
          ('James', 'High Roller',     DATE '2013-01-01');

COMMIT;


/*
 * 'Return of the Jedi' hunt (thanks to Scott)
 */
BEGIN TRANSACTION;

INSERT INTO TreasureHunt.Hunt
VALUES (13, 'Return of the Jedi', 'Use the force, Luke!', 327327327, 8, TIMESTAMP '2013-05-16 16:00:00', 'active');

INSERT INTO TreasureHunt.PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon, isAt)
VALUES (13, 1, 'Tatooine', 11381, 'The first planet in the binary Tatoo star system', 41.15850, 174.47210, 'Milky Way'),
       (13, 2, 'Cloud City', 11382, 'An outpost and a tibanna gas mining colony on the planet Bespin', 41.17050, 174.0010, 'Milky Way'),
       (13, 3, 'Dagobah', 11383, 'A remote world of swamps and forests, it served as a refuge for Jedi Grand Master Yoda during his exile', 42.06050, 175.00105, 'Milky Way'),
       (13, 4, 'Sullust', 11384, 'The primary planet of the Sullust system, located in the Outer Rim at the conjuncture of the Rimma Trade Route and the Silvestri Trace', 44.06050, 174.90101, 'Milky Way'),
       (13, 5, 'Endor', 11385, 'An enchanted world, notable for being the native home of the Ewoks', 40.89520, 152.88406, 'Milky Way'),
       (13, 6, 'Death Star', 11386, 'A moon-sized Imperial military battlestation armed with a planet-destroying superlaser',  38.33210, 150.0010, 'Milky Way'),
       (13, 7, 'Coruscant', 11387, 'Also known as Imperial Center or the Queen of the Core, a planet located in the Galactic Core', 38.35210, 150.0310, 'Milky Way'),
       (13, 8, 'Naboo', 11388, ' A largely unspoiled world with large plains, swamps and seas', 38.38210, 150.0950, 'Milky Way');

INSERT INTO TreasureHunt.Player (name, password, pw_salt, gender, addr)
VALUES ('Luke Skywalker', 'usetheforce1', 'u#e#h#f#r#', 'm', 'Tatooine'),
       ('Princess Leia', 'twinsister2', 't#i#s#s#e#', 'f', 'Alderann'),
       ('Han Solo', 'shootfirst3', 's#o#t#i#s#', 'm', 'Coreilla'),
       ('Chewbacca', 'hairydog4', 'h#i#y#o#4#', 'm', 'Kashyyyk'),
       ('Darth Vader', 'mask5', 'm#s#5#', 'm', 'Tatooine'),
       ('Emperor Palpatine', 'lightning6', 'l#g#t#i#g#', 'm', 'Naboo'),
       ('Lando Calrissian', 'survivor7', 's#r#i#o#7#', 'm', 'Socorro'),
       ('Jabba the Hutt', 'obese8', 'o#e#s#8', 'm', 'Nal Hutta'),
       ('Boba Fett', 'bountyhunter9', 'b#u#t#h#n#', 'm', 'Kamino'),
       ('R2D2', 'beepbeep10', 'b#e#p#e#p#', 'n/a', 'Naboo'),
       ('C-3PO', 'chatterbox11', 'c#a#t#r#o#', 'n/a', 'Tatooine'),
       ('Yoda', 'wiseone12', 'w#s#o#e#2', 'm', 'Unknown'),
       ('Admiral Piett', 'swedishhouse13', 's#e#i#h#o#', 'm', 'Axxila'),
       ('Admiral Ackbar', 'itsatrap14', 'i#s#t#a#1#', 'm', 'Mon Calamari');

INSERT INTO TreasureHunt.PlayerStats (player, stat_name, stat_value)
VALUES ('Luke Skywalker',  'finished_hunts',   '0'),
       ('Luke Skywalker',  'point_score',      '6'),
       ('Luke Skywalker',  'wrong_visits',     '1'),
       ('Luke Skywalker',  'only_force_powers','true'),
       ('Princess Leia',   'finished_hunts',   '1'),
       ('Princess Leia',   'point_score',     '16'),
       ('Princess Leia',   'wrong_visits',     '1'),
       ('Han Solo',        'finished_hunts',  '12'),
       ('Han Solo',        'wrong_visits',    '33'),
       ('Han Solo',        'point_score',    '103'),
       ('Chewbacca',       'finished_hunts',  '12'),
       ('Chewbacca',       'point_score',    '124'),
       ('Darth Vader',     'finished_hunts',   '1'),
       ('Darth Vader',     'point_score',     '16'),
       ('Emperor Palpatine','finished_hunts',  '2'),
       ('Emperor Palpatine','point_score',    '26'),
       ('Lando Calrissian','finished_hunts',   '5'),
       ('Lando Calrissian','wrong_visits',     '5'),
       ('Lando Calrissian','point_score',     '57'),
       ('Jabba the Hutt',  'finished_hunts',   '0'),
       ('Jabba the Hutt',  'point_score',      '1'),
       ('Boba Fett',       'finished_hunts',   '0'),
       ('Boba Fett',       'point_score',      '1'),
       ('R2D2',            'finished_hunts',  '16'),
       ('R2D2',            'point_score',    '164'),
       ('C-3PO',           'finished_hunts',   '4'),
       ('C-3PO',           'point_score',     '44'),
       ('Yoda',            'finished_hunts',  '99'),
       ('Yoda',            'point_score',    '996'),
       ('Yoda',            'wrong_visits',     '1'),
       ('Admiral Piett',   'finished_hunts',   '1'),
       ('Admiral Piett',   'point_score',     '16'),
       ('Admiral Ackbar',  'finished_hunts',   '1'),
       ('Admiral Ackbar',  'wrong_visits',     '5'),
       ('Admiral Ackbar',  'point_score',      '17'),
       ('Admiral Ackbar',  'battle_above_endor','true');

INSERT INTO TreasureHunt.Team (name, created)
VALUES ('Jedi', DATE '2013-05-12'),
       ('Rebels', DATE '2013-05-12'),
       ('Empire', DATE '2013-05-12'),
       ('Outlaws', DATE '2013-05-12'),
       ('Sidekicks', DATE '2013-05-12');

INSERT INTO TreasureHunt.MemberOf (player, team, since, current)
VALUES ('Yoda', 'Jedi', DATE '2013-05-12', true),
       ('Darth Vader', 'Jedi', DATE '2011-02-12', false),
       ('Luke Skywalker', 'Jedi', DATE '2013-05-12', true),
       ('Princess Leia', 'Jedi', DATE '2013-05-12', true),

       ('Han Solo', 'Rebels', DATE '2013-05-12', true),
       ('Admiral Ackbar', 'Rebels', DATE '2013-05-12', true),
       ('Lando Calrissian', 'Rebels', DATE '2013-05-12', true),

       ('Darth Vader', 'Empire', DATE '2013-05-12', true),
       ('Admiral Piett', 'Empire', DATE '2013-05-12', true),
       ('Emperor Palpatine', 'Empire', DATE '2013-05-12', true),

       ('Boba Fett', 'Outlaws', DATE '2013-05-12', true),
       ('Jabba the Hutt', 'Outlaws', DATE '2013-05-12', true),

       ('R2D2', 'Sidekicks', DATE '2013-05-12', true),
       ('C-3PO', 'Sidekicks', DATE '2013-05-12', true),
       ('Chewbacca', 'Sidekicks', DATE '2013-05-12', true);

INSERT INTO TreasureHunt.Badge (name, description, condition)
VALUES ('It''s a trap!', 'Given to those who battle over Endor against the Empire', 'battle_above_endor = true'),
       ('Use the Force, Luke', 'Given to those who reach a waypoint using only Force Powers', 'only_force_powers = true');

INSERT INTO TreasureHunt.Achievements (player, badge, whenReceived)
VALUES ('Admiral Ackbar', 'It''s a trap!',   DATE '2013-05-16'),
       ('Luke Skywalker', 'Use the Force, Luke', DATE '2013-05-16'),
       ('Luke Skywalker', 'Novice Player',  DATE '2013-04-30'),
       ('Jabba the Hutt', 'Novice Player',  DATE '2013-04-30'),
       ('Boba Fett',      'Novice Player',  DATE '2013-04-30'),
       ('Han Solo',       'Adventurer',     DATE '1990-02-03'),
       ('Han Solo',       'Treasure Hunter',DATE '2000-05-30'),
       ('Han Solo',       'Trial-And-Error',DATE '1995-05-30'),
       ('Han Solo',       'High Roller',    DATE '1999-09-09'),
       ('Chewbacca',      'Adventurer',     DATE '1999-02-03'),
       ('Chewbacca',      'Treasure Hunter',DATE '2000-05-30'),
       ('Chewbacca',      'High Roller',    DATE '1999-05-30'),
       ('Lando Calrissian','Adventurer',    DATE '2012-10-22'),
       ('R2D2',           'Adventurer',     DATE '2011-02-03'),
       ('R2D2',           'Treasure Hunter',DATE '2013-02-06'),
       ('R2D2',           'High Roller',    DATE '2012-07-11'),
       ('Yoda',           'Adventurer',     DATE '1978-04-05'),
       ('Yoda',           'Treasure Hunter',DATE '1983-09-16'),
       ('Yoda',           'High Roller',    DATE '1985-12-24');

INSERT INTO TreasureHunt.Visit (team, num, time, submitted_code, is_correct, visited_hunt, visited_wp)
VALUES ('Jedi',      1, TIMESTAMP '2013-05-16 16:00:00', 11381, true, 13, 1),
       ('Outlaws',   1, TIMESTAMP '2013-05-16 16:10:00', 11381, true, 13, 1),
       ('Rebels',    1, TIMESTAMP '2013-05-16 16:20:00', 18311,false, NULL, NULL),
       ('Rebels',    2, TIMESTAMP '2013-05-16 16:30:00', 11381, true, 13, 1),
       ('Sidekicks', 1, TIMESTAMP '2013-05-16 16:40:00', 11381, true, 13, 1),
       ('Empire',    1, TIMESTAMP '2013-05-16 16:50:00', 11381, true, 13, 1),

       ('Rebels',    3, TIMESTAMP '2013-05-18 09:10:00', 28311,false, NULL, NULL),
       ('Sidekicks', 2, TIMESTAMP '2013-05-18 09:20:00', 11382, true, 13, 2),
       ('Jedi',      2, TIMESTAMP '2013-05-18 09:30:00', 11832,false, NULL, NULL),
       ('Rebels',    4, TIMESTAMP '2013-05-18 09:40:00', 11382, true, 13, 2),
       ('Empire',    2, TIMESTAMP '2013-05-18 09:50:00', 11382, true, 13, 2),
       ('Jedi',      3, TIMESTAMP '2013-05-18 10:00:00', 11382, true, 13, 2),

       ('Rebels',    5, TIMESTAMP '2013-05-20 10:01:00', 58311,false, NULL,NULL),
       ('Empire',    3, TIMESTAMP '2013-05-20 10:02:00', 11383, true, 13, 3),
       ('Jedi',      4, TIMESTAMP '2013-05-20 10:03:00', 11383, true, 13, 3),
       ('Sidekicks', 3, TIMESTAMP '2013-05-20 10:04:00', 11383, true, 13, 3),
       ('Rebels',    6, TIMESTAMP '2013-05-20 10:05:00', 11383, true, 13, 3),

       ('Rebels',    7, TIMESTAMP '2013-05-22 11:01:00', 48311,false, NULL, NULL),
       ('Empire',    4, TIMESTAMP '2013-05-22 11:11:00', 11384, true, 13, 4),
       ('Rebels',    8, TIMESTAMP '2013-05-22 11:21:00', 11384, true, 13, 4),
       ('Jedi',      5, TIMESTAMP '2013-05-22 11:31:00', 11384, true, 13, 4),
       ('Sidekicks', 4, TIMESTAMP '2013-05-22 11:41:00', 11384,false,NULL,NULL),
       ('Sidekicks', 5, TIMESTAMP '2013-05-22 11:51:00', 11384, true, 13, 4),

       ('Empire',    5, TIMESTAMP '2013-05-24 15:15:00', 11385, true, 13, 5),
       ('Jedi',      6, TIMESTAMP '2013-05-24 15:16:00', 13183,false, NULL, NULL),
       ('Rebels',    9, TIMESTAMP '2013-05-24 15:17:00', 83113,false, NULL, NULL),
       ('Sidekicks', 6, TIMESTAMP '2013-05-24 15:18:00', 11385, true, 13, 5),
       ('Jedi',      7, TIMESTAMP '2013-05-24 15:19:00', 11385, true, 13, 5),

       ('Jedi',      8, TIMESTAMP '2013-05-25 12:01:00', 11386, true, 13, 6),
       ('Empire',    6, TIMESTAMP '2013-05-25 12:22:00', 11386, true, 13, 6);

INSERT INTO TreasureHunt.Participates (hunt, team, currentWP, score, rank, duration)
VALUES (13, 'Jedi',      7, 6, NULL, NULL),
       (13, 'Rebels',    5, 4, NULL, NULL),
       (13, 'Sidekicks', 6, 5, NULL, NULL),
       (13, 'Empire',    7, 6, NULL, NULL),
       (13, 'Outlaws',   2, 1, NULL, NULL);

INSERT INTO TreasureHunt.Review (id, hunt, player, whenDone, rating, description)
VALUES (13, 13, 'Admiral Ackbar', TIMESTAMP '2013-05-18 12:01:00', 5, 'The Shield is down! Commence attack on the Death star''s main reactor'),
       (14, 13, 'Lando Calrissian', TIMESTAMP '2013-05-19 14:00:00', 5, 'We''re on our way, Red group, Gold group, all fighters follow me. Ha ha ha, I told you they''d do it!');

INSERT INTO TreasureHunt.Likes (review, player, whenDone, usefulness)
VALUES (13, 'Lando Calrissian', TIMESTAMP '2013-05-20 15:35:00', 5),
       (13, 'Chewbacca',        TIMESTAMP '2013-05-20 15:36:00', 4);

COMMIT;


/*
 * Shpoorenzoohe hunt
 * inspired by the same-named project of the German Department of Sydney Uni
 * The name "Shpoorenzoohe" is derived from the phonetic spelling of the German word
 *  "Spurensuche", which means 'to follow clues'.
 */
BEGIN TRANSACTION;

  /* manually advance the hunt's PK sequence */
  SELECT setval('TreasureHunt.Hunt_id_seq', 14, false);

  INSERT INTO TreasureHunt.Hunt (title,description,distance,numWayPoints,startTime,status)
    VALUES ('Shpoorenzoohe', 'Find out about Australian-German links in Sydney. This hunt is inspired by the original "Shpoorenzoohe" research project of the Department of Germanic Studies at University of Sydney, which was initiated by Dr Jaeger in 2007. The name "Shpoorenzoohe" is derived from the phonetic spelling of the German word "Spurensuche", which means "to follow clues".', 5700, 15, TIMESTAMP '2013-05-18 10:00:00', 'active');

  -- list of Sydney locations; assumes the improved location type list
  INSERT INTO TreasureHunt.Location (name, parent, type)
  VALUES ('Australia',        'Earth',              'country'),
       ('ACT',              'Australia',          'state'),
       ('New South Wales',  'Australia',          'state'),
       ('Northern Territory','Australia',         'state'),
       ('Queensland',       'Australia',          'state'),
       ('South Australia',  'Australia',          'state'),
       ('Tasmania',         'Australia',          'state'),
       ('Western Australia','Australia',          'state'),
       ('Victoria',         'Australia',          'state'),
       ('IOT',              'Australia',          'state'),
       ('Sydney',           'New South Wales',    'city' ),
       ('Brisbane',         'Queensland',         'city' ),
       ('Melbourne',        'Victoria',           'city' ),
       ('Perth',            'Western Australia',  'city'),
       ('Adelaide',         'South Australia',    'city'),
       ('Hobart',           'Tasmania',           'city' ),
       ('Parramatta',       'New South Wales',    'city' ),
       ('North Shore',      'Sydney',             'region'),
       ('Lower North Shore','North Shore',        'area'),
       ('Upper North Shore','North Shore',        'area'),
       ('Sydney Center',    'Sydney',             'area'),
       ('Eastern Suburbs',  'Sydney',             'area'),
       ('Inner West',       'Sydney',             'area'),
       ('Northern Beaches', 'Sydney',             'area'),
       ('Northern Suburbs', 'Sydney',             'area'),
       ('Botany Bay',       'Sydney',             'area'),
       ('City of Sydney', 'Sydney Center',               'lga'),
       ('Haymarket',      'City of Sydney',              'suburb'),
       ('Pyrmont',        'City of Sydney',              'suburb'),
       ('The Rocks',      'City of Sydney',              'suburb'),
       ('Millers Point',  'City of Sydney',              'suburb'),
       ('Woolloomooloo',  'City of Sydney',              'suburb'),
       ('Alexandria',     'City of Sydney',              'suburb'),
       ('Chippendale',    'City of Sydney',              'suburb'),
       ('Darlington',     'City of Sydney',              'suburb'),
       ('Darlinghurst',   'City of Sydney',              'suburb'),
       ('Erskineville',   'City of Sydney',              'suburb'),
       ('Redfern',        'City of Sydney',              'suburb'),
       ('Surry Hills',    'City of Sydney',              'suburb'),
       ('Sydney CBD',     'City of Sydney',              'suburb'),
       ('Ultimo',         'City of Sydney',              'suburb'),
       ('Waterloo',       'City of Sydney',              'suburb'),
       ('Zetland',        'City of Sydney',              'suburb'),
       ('Darling Harbour','City of Sydney',              'precinct'),
       ('Kings Cross',    'Darlinghurst',                'precinct'),
       ('Municipality of Ashfield',   'Inner West',     'lga'),
       ('Municipality of Burwood',    'Inner West',     'lga'),
       ('City of Canada Bay',         'Inner West',     'lga'),
       ('Municipality of Leichhardt', 'Inner West',     'lga'),
       ('Marrickville Council',       'Inner West',     'lga'),
       ('Municipality of Strathfield','Inner West',     'lga'),
       ('Glebe',          'Municipality of Leichhardt', 'suburb'), -- actually belongs to Sydney council
       ('Forest Lodge',   'Municipality of Leichhardt', 'suburb'), -- actually belongs to Sydney council
       ('Annandale',      'Municipality of Leichhardt', 'suburb'),
       ('Balmain',        'Municipality of Leichhardt', 'suburb'),
       ('Birchgrove',     'Municipality of Leichhardt', 'suburb'),
       ('Cockatoo Island','Municipality of Leichhardt', 'suburb'),
       ('Leichhardt',     'Municipality of Leichhardt', 'suburb'),
       ('Lilyfield',      'Municipality of Leichhardt', 'suburb'),
       ('Rozelle',        'Municipality of Leichhardt', 'suburb'),
       ('Camperdown',     'Marrickville Council',       'suburb'),
       ('Dulwich Hill',   'Marrickville Council',       'suburb'),
       ('Enmore',         'Marrickville Council',       'suburb'),
       ('Lewisham',       'Marrickville Council',       'suburb'),
       ('Marrickville',   'Marrickville Council',       'suburb'),
       ('Newtown',        'Marrickville Council',       'suburb'),
       ('Petersham',      'Marrickville Council',       'suburb'),
       ('St Peters',      'Marrickville Council',       'suburb'),
       ('Stanmore',       'Marrickville Council',       'suburb'),
       ('Sydenham',       'Marrickville Council',       'suburb'),
       ('Tempe',          'Marrickville Council',       'suburb'),
       ('University of Sydney/Camperdown','Camperdown', 'precinct'),
       ('University of Sydney/Darlington','Darlington', 'precinct'),
       ('Concord',        'City of Canada Bay',         'suburb'),
       ('Drummoyne',      'City of Canada Bay',         'suburb'),
       ('Ashfield',       'Municipality of Ashfield',   'suburb'),
       ('Dobroyd Point',  'Municipality of Ashfield',   'suburb'),
       ('Haberfield',     'Municipality of Ashfield',   'suburb'),
       ('Summer Hill',    'Municipality of Ashfield',   'suburb'),
       ('Burwood',        'Municipality of Burwood',    'suburb'),
       ('Burwood Heights','Municipality of Burwood',    'suburb'),
       ('Enfield',        'Municipality of Burwood',    'suburb'),
       ('Enfield South',  'Municipality of Burwood',    'suburb'),
       ('Strathfield',    'Municipality of Strathfield','suburb'),
       ('Homebush',       'Municipality of Strathfield','suburb'),
       ('Flemington',     'Municipality of Strathfield','suburb');
       -- ok., let's stop here ;)

INSERT INTO TreasureHunt.PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon, isAt)
VALUES ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        1, 'Quadrangle', 1927, 'We start at Sydney University''s popular Jacaranda Tree in the South-West corner of its main building. It was planted there by Professor of German E. G. Waterhouse. As verification code enter the year in which this tree was planted.', -33.886195,151.189025, 'University of Sydney/Camperdown'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        2, 'Bosch Portrait', 1929, 'Find the portrait of George Henry Bosch in the main ground level corridor of the University of Sydney''s Anderson Stuart Building. George Henry Bosch was a merchant and philanthropist, born in 1861 at Osborne''s Flat near Yackandandah, Victoria, son of George Bosch, a miner from Bavaria, and his wife Emily, née Spann, of Hamburg. Between 1924 and 1928, Bosch provided the University of Sydney with several donations of over £230,000 for research into cancer and spastic paralysis, and to establish the chairs of histology and embryology, and the chairs of medicine, surgery and bacteriology. As verification code for this waypoint find the year in which his portrait had been painted.', -33.887199,151.189277, 'University of Sydney/Camperdown'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        4, 'GerMANY Innovations Venue', 3, 'Next, find the venue in which in 2007 the "GerMANY Innovations" showcase between the University of Sydney, the Goethe Institute and several German companies and research institutions was held. As a tip: on the closing night of this two-day networking event, the German-French pop duo "Stereo Total" was playing at this venue. If you found that venue, we are interested in how many big theatre rooms are available there. Enter the number of theatres as your next verification code.', -33.888435, 151.193638, 'Darlington'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        5, 'Lüneburger Bakery', 1000, 'At the Henry Deane Plaza near Central, there is an outlet of the Lüneburger Bakery where you can find German bread. How much does their Sunflower Seed Bread weight in grams? Enter the gram value as your next verification code.', -33.884066, 151.203903, 'Chippendale'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        7, 'Queen Victoria Statue', 1987, 'Queen Victoria was queen of the United Kingdom of Great Britain and Ireland from 1837 until her death in 1876. Born in London, she was a descendent of the House of Hanover and when becoming queen, the last monarch from that house to reign Great Britain. Her mother was German-born Princess Victoria of Saxe-Coburg-Saalfeld, and she later maried her first couson, Prince Albert of Saxe-Coburg and Gotha. There is a statue in front of the QVB building that commemorates Queen Victoria. It was originally erected in Dublin in 1904 and re-erected here in Sydney to mark the 200th anniversary of Sydney. The front inscription of the statue states the exact date when it was unveiled in Sydney. Find the statue, read the inscription, and enter the year of its unveiling as your next verification code.', -33.872754, 151.206827, 'Sydney CBD'), -- http://monumentaustralia.org.au/monument_display.php?id=23254
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        8, 'Beers on Kent', 10, 'The next waypoint of our "Shpoorenzoohe" is a bar/cafe/restaurant in York Street, Sydney, that is specialised in German (Bavarian) beers. It is actually owned by the same German-born business man who also runs the Loewenbraeukeller in The Rocks. Find this venue and ask there, as your next verification code, how many Bavarian draught beers are on tap. Here might also be an opportunity for a short break.', -33.868197, 151.206052, 'Sydney CBD'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
       10, 'Hugo Boss King Street', 18, 'Hugo Boss is a German fashion based in Metzingen, Germany. At 97-107 King Street you find one of their Sydney retail stores (BOSS store) in a nicely renovated period building. How many windows does the facade of this building have? Enter this number as your next verification code.', -33.868845, 151.207597, 'Sydney CBD'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
       11, 'Rudi the Audi', 1, 'The next waypoint is the carsharing parking spot ("pod") in the secure car park of 1 Martin Place (entrance is at 159 Pitt Street). GoGet car sharing has several Audi cars available for its members, one of which ("Rudi the Audi") is located at this car pod in Pitt Street/Martin Place. What model of Audi is this? Enter the numerical part of this Audi car model as your next verification code.', -33.868004, 151.208450, 'Sydney CBD'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
       12, 'City Recital Hall', 427, 'On Friday, 17 May 2013, the Australian Brandenburg Orchestra is giving a Mozart concert in the City Recital Hall. The Australian Brandenburg Orchestra is specialized on baroque and classical music which they perform using original edition scores and instruments of the period. At the end of their concert on 17 May  they will play Mozart''s "Great Mass in C minor". As your next verification code enter the KV number (KV - Köchel-Verzeichnis - Köchel catalogue) of this composition of Mozart.', -33.867050, 151.207409, 'Sydney CBD'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
       13, 'Australia Square', 47, 'The next waypoint is at Australia Square. The iconic round tower here was designed by Harry Seidler, an Austrian-born architect who is considered the first architect to fully embrace the principle of the Bauhaus school of design in Australia. In one of the upper floors of the Australia Square Tower is the rotating O bar and dining restaurant. In which floor is this bar? The floor number is your next verification code.', -33.864923, 151.207763, 'Sydney CBD'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
       15, 'Sydney Opera House', 8, 'The final waypoint of our hunt is the Sydney Opera house which was illuminate by the German design collective URBANSCREEN during the 2012 Vivid festival. During this year''s Vivid festival (end of May to mid June), the pioneers of electronic music, the German band legend Kraftwerk will headline and perform in the Sydney Opera House (24-27 May). How many concerts will Kraftwerk perform? Enter the number of performances as the last verification code.', -33.857021, 151.215174, 'Sydney CBD');

INSERT INTO TreasureHunt.VirtualWaypoint (hunt, num, name, verification_code, clue, url)
VALUES ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        3, 'The Art Gallery', 4499, 'This next waypoint is a virtual waypoint on the Internet. Originally an engineer, the German-born Dominik Mersch decided to make his private passion for art his new profession. In 2006, he founded an art gallery for contemporary fine art in Sydney/Waterloo that specialises on works from artists from German speaking countries. Find the home page of his art gallery and as next verification code enter the last four digits of the phone number of that gallery (land line).', 'http://www.dominikmerschgallery.com'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        6, 'Internations', 2007, 'Internations.org is a social networking site that is designed as an online platform connecting people who live and work abroad ("expats"). Internations operates world-wide, and is also quite active down here in Sydney, e.g. with monthly social events that members organise. The web site itself is developed and run by a startup company in Munich, Germany. Since when is the Internations website online? Enter the starting year of that service as your next verification code.', 'http://www.internations.org'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
        9, 'German Opera Award', 53000, 'The Opera Foundation Australia organises several annual awards and scholarships to support young Australians in the field of opera. One of those is the "German Opera Scholarship" for young Australian opera singers which offers the winner a contract as a member of the Cologne Opera Studio for up to twelve months. Navigate to the homepage of the Opera Foundation Australia and find out at how much this award is valued in Australian dollar. This monetary amount is your next verification code.', 'http://www.operafoundationaust.org.au'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
       14, 'The Brothers Grimm and The Wild Girl', 22, 'This month, the 2013 Sydney Writers Festival (SWF) takes place. One of the events is an author talk by Australian novelist Kate Forsyth about her new novel, The Wild Girl, which retells the story of Henriette Dorothea (Dortchen) Wild and Wilhelm Grimm. Both grew up next-door in Germany in Kassel in the late 18th century and later married. When the town was invaded by Napoleon''s army in 1806, the Grimm brothers began collecting fairy tales, wanting to save the old stories from the domination of French culture, and Dortchen became the source of many of the now famous Grimms'' Fairy Tales. On which day of May is Kate Forsyth''s author talk at SWF scheduled? Enter the correct day of the month as your next verification code.', 'http://www.swf.org.au');


INSERT INTO TreasureHunt.Player (name, password, pw_salt, gender, addr)
   VALUES ('goethe',   'faust',    'b#l#a#h#', 'm', 'Am Frauenplan, Weimar'),
          ('schiller', 'glocke',   'b#l#u#b#', 'm', 'Schillerstrasse 12, Weimar'),
          ('nicole',   'kidman',   'a#b#c#d#', 'f', 'Sydney'),
          ('kate',     'blanchett','e#f#g#h#', 'f', 'Hunters Hill, Sydney'),
          ('hugo',     'weaving',  'b#d#f#e#', 'm', 'Sydney'),
          ('geoffrey', 'rush',     'f#o#b#a#', 'm', 'Camberwell, Victoria'),
          ('russell',  'crowe',    'i#h#k#h#', 'm', 'Woolloomooloo, Sydney'),
          ('hugh',     'jackman',  'i#h#k#h#', 'm', 'New York');

INSERT INTO TreasureHunt.PlayerStats (player, stat_name, stat_value)
   VALUES ('goethe',   'finished_hunts',       '3'),
          ('goethe',   'point_score',        '103'),
          ('goethe',   'total_hunting_time','1800'),
          ('goethe',   'avg_hunting_time',   '600'),
          ('schiller', 'finished_hunts',       '1'),
          ('schiller', 'point_score',         '13'),
          ('schiller', 'total_hunting_time', '221'),
          ('schiller', 'avg_hunting_time',   '221'),
          ('nicole',   'finished_hunts',       '0'),
          ('nicole',   'point_score',         '12'),
          ('kate',     'finished_hunts',       '0'),
          ('kate',     'point_score',          '4'),
          ('hugo',     'finished_hunts',       '0'),
          ('hugo',     'point_score',          '4'),
          ('geoffrey', 'finished_hunts',       '0'),
          ('geoffrey', 'point_score',          '4'),
          ('russell',  'finished_hunts',       '0'),
          ('russell',  'point_score',         '12'),
          ('hugh',     'finished_hunts',       '0'),
          ('hugh',     'point_score',         '12');

INSERT INTO TreasureHunt.Team (name, created)
   VALUES ('Dead Poets Society', DATE '1794-06-01'),
          ('The Theatre Gang',   DATE '2013-04-01'),
          ('Les Miserables',     DATE '2013-04-01');

INSERT INTO TreasureHunt.MemberOf (player, team, since, current)
   VALUES ('kate',     'Les Miserables',     DATE '2013-03-31', false),
          ('hugh',     'The Theatre Gang',   DATE '2013-03-31', false);
INSERT INTO TreasureHunt.MemberOf (player, team, since)
   VALUES ('goethe',   'Dead Poets Society', DATE '1794-06-01'),
          ('schiller', 'Dead Poets Society', DATE '1794-06-01'),
          ('kate',     'The Theatre Gang',   DATE '2013-04-01'),
          ('hugo',     'The Theatre Gang',   DATE '2013-04-01'),
          ('geoffrey', 'The Theatre Gang',   DATE '2013-04-01'),
          ('nicole',   'Les Miserables',     DATE '2013-04-01'),
          ('hugh',     'Les Miserables',     DATE '2013-04-01'),
          ('russell',  'Les Miserables',     DATE '2013-04-01');

INSERT INTO TreasureHunt.Participates (team, hunt, currentWP, score, rank, duration)
   VALUES ('Dead Poets Society',(SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 14, 13, NULL, NULL),
          ('The Theatre Gang',  (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),  7,  6, NULL, NULL),
          ('Les Miserables',    (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 12, 11, NULL, NULL),
          ('Shufflers',         (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),  5,  4, NULL, NULL),
          ('GoonSelect',        (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),  6,  5, NULL, NULL);

INSERT INTO TreasureHunt.Visit (team, num, time, submitted_code, is_correct, visited_hunt, visited_wp)
   VALUES ('Dead Poets Society', 1, TIMESTAMP '2013-05-18 10:00:30', 1927, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 1),
          ('The Theatre Gang',   1, TIMESTAMP '2013-05-18 10:01:15', 1927, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 1),
          ('GoonSelect',         8, TIMESTAMP '2013-05-18 10:02:00', 1927, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 1),
          ('Les Miserables',     1, TIMESTAMP '2013-05-18 10:05:00', 1927, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 1),
          ('Shufflers',          7, TIMESTAMP '2013-05-18 10:08:00', 1927, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 1),
          ('Dead Poets Society', 2, TIMESTAMP '2013-05-18 10:15:20', 1929, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 2),
          ('GoonSelect',         9, TIMESTAMP '2013-05-18 10:17:10', 1929, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 2),
          ('The Theatre Gang',   2, TIMESTAMP '2013-05-18 10:18:15', 1929, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 2),
          ('Les Miserables',     2, TIMESTAMP '2013-05-18 10:19:00', 1929, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 2),
          ('The Theatre Gang',   3, TIMESTAMP '2013-05-18 10:19:25', 9698,false, NULL, NULL),
          ('Shufflers',          8, TIMESTAMP '2013-05-18 10:20:00', 1929, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 2),
          ('Dead Poets Society', 3, TIMESTAMP '2013-05-18 10:20:20', 4499, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 3),
          ('Les Miserables',     3, TIMESTAMP '2013-05-18 10:21:00', 4499, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 3),
          ('GoonSelect',        10, TIMESTAMP '2013-05-18 10:21:20', 4499, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 3),
          ('The Theatre Gang',   4, TIMESTAMP '2013-05-18 10:21:40',  802,false, NULL, NULL),
          ('Shufflers',          9, TIMESTAMP '2013-05-18 10:24:04', 4499, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 3),
          ('The Theatre Gang',   5, TIMESTAMP '2013-05-18 10:27:15', 4499, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 3),
          ('Dead Poets Society', 4, TIMESTAMP '2013-05-18 10:31:10',    3, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 4),
          ('Les Miserables',     4, TIMESTAMP '2013-05-18 10:35:00',    3, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 4),
          ('GoonSelect',        11, TIMESTAMP '2013-05-18 10:37:24',    3, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 4),
          ('The Theatre Gang',   6, TIMESTAMP '2013-05-18 10:39:15',    3, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 4),
          ('Shufflers',         10, TIMESTAMP '2013-05-18 10:48:00',    3, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 4),
          ('Dead Poets Society', 5, TIMESTAMP '2013-05-18 10:55:10', 1000, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 5),
          ('Les Miserables',     5, TIMESTAMP '2013-05-18 10:58:43', 1000, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 5),
          ('GoonSelect',        12, TIMESTAMP '2013-05-18 10:59:15', 1000, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 5),
          ('Dead Poets Society', 6, TIMESTAMP '2013-05-18 10:59:24', 2007, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 6),
          ('The Theatre Gang',   7, TIMESTAMP '2013-05-18 11:01:15', 1000, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 5),
          ('Les Miserables',     6, TIMESTAMP '2013-05-18 11:02:23', 2007, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 6),
          ('The Theatre Gang',   8, TIMESTAMP '2013-05-18 11:21:51', 2007, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 6),
          ('Dead Poets Society', 7, TIMESTAMP '2013-05-18 11:35:40', 1987, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 7),
          ('Les Miserables',     7, TIMESTAMP '2013-05-18 11:41:37', 1987, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 7),
          ('Dead Poets Society', 8, TIMESTAMP '2013-05-18 11:52:07',   10, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 8),
          ('Les Miserables',     8, TIMESTAMP '2013-05-18 11:59:59',   10, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 8),
          ('Dead Poets Society', 9, TIMESTAMP '2013-05-18 12:01:01',53000, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 9),
          ('Les Miserables',     9, TIMESTAMP '2013-05-18 12:04:19',53000, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'), 9),
          ('Dead Poets Society',10, TIMESTAMP '2013-05-18 12:40:05',   18, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),10),
          ('Les Miserables',    10, TIMESTAMP '2013-05-18 12:49:43',   18, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),10),
          ('Dead Poets Society',11, TIMESTAMP '2013-05-18 13:09:30',    1, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),11),
          ('Les Miserables',    11, TIMESTAMP '2013-05-18 13:12:50',    1, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),11),
          ('Dead Poets Society',12, TIMESTAMP '2013-05-18 13:19:00',  427, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),12),
          ('Dead Poets Society',13, TIMESTAMP '2013-05-18 13:41:29',   47, true, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),13);

INSERT INTO TreasureHunt.Achievements (player, badge, whenReceived)
   VALUES ('goethe', 'Adventurer',  DATE '1796-04-01'),
          ('goethe', 'High Roller', DATE '1796-04-01'),
          ('schiller','Sprinter',   DATE '1794-07-01'),
          ('nicole', 'Novice Player',DATE '2013-04-01'),
          ('kate',   'Novice Player',DATE '2013-04-01'),
          ('hugo',   'Novice Player',DATE '2013-04-01'),
          ('geoffrey','Novice Player',DATE '2013-04-01'),
          ('russell', 'Novice Player',DATE '2013-04-01'),
          ('hugh',    'Novice Player',DATE '2013-04-01');

INSERT INTO TreasureHunt.Review (id, hunt, player, whenDone, rating, description)
   VALUES (15, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
             'goethe', TIMESTAMP '1796-05-10 09:01:02', 3, 'And here, poor fool, I stand once more - No wiser than I was before.'),
          (16, (SELECT id FROM TreasureHunt.Hunt WHERE title='Shpoorenzoohe'),
             'nicole', TIMESTAMP '2013-05-20 13:09:14', 5, 'I want to be in places I''ve never been before.');

INSERT INTO TreasureHunt.Likes (review, player, whenDone, usefulness)
   VALUES (16, 'russell',  TIMESTAMP '2013-05-20 22:05:00', 4),
          (16, 'schiller', TIMESTAMP '2013-05-21 12:05:00', 2),
          (15, 'schiller', TIMESTAMP '2013-05-21 12:12:00', 5);

COMMIT;


/*  QR Code Test Hunt
 *  The idea behind this QR test hunt is that you can put up QR signs inside the SIT
 *  building which encode URLs to your web-based application with the given verification
 *  code as parameter so that you could visit those waypoints with a normal QR-reader
 *  app on a smartphone.
 */
BEGIN TRANSACTION;

INSERT INTO TreasureHunt.Hunt (title,description,distance,numWayPoints,startTime,status)
VALUES ('QR Code Hunt', 'Simple test hunt to play around with QR code links', 100, 3, TIMESTAMP '2013-05-31 18:00:00', 'open');

INSERT INTO TreasureHunt.PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon, isAt)
VALUES ((SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'),
        1, 'SIT Labs', 4711, 'Start the hunt at the QR code sign in the main SIT lab area.', -33.888065,151.194052, 'University of Sydney/Darlington'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'),
        2, 'SIT Foyer', 4712, 'Your next waypoint is the QR sign in the foyer of the SIT building.', -33.888101,151.194175, 'University of Sydney/Darlington'),
       ((SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'),
        3, 'SIT ', 4713, 'The final waypoint is the QR sign at the SIT reception area of the SIT building.', -33.888101,151.194175, 'University of Sydney/Darlington');

INSERT INTO TreasureHunt.Participates (team, hunt, currentWP, score, rank, duration)
   VALUES ('Dead Poets Society', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('The Theatre Gang', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Les Miserables', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Shufflers', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('GoonSelect', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Couple', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('CatchEmAll', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Rival', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Rocket', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Jedi', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Empire', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Rebels', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Sidekicks', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL),
          ('Outlaws', (SELECT id FROM TreasureHunt.Hunt WHERE title='QR Code Hunt'), NULL, NULL, NULL, NULL);

COMMIT;

/*
 * 'Find one Piece' hunt (thanks to Blake)
 */
BEGIN TRANSACTION;

INSERT INTO TreasureHunt.Hunt (id,title,description,distance,numWayPoints,startTime,status)
VALUES (16, 'Find One Piece', 'This is the hunt you will always remember as the hunt in which you almost caught Captain Jack Sparrow!', 350000, 6, TIMESTAMP '2008-10-20 08:00:00', 'active');

INSERT INTO TreasureHunt.PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon)
VALUES (16, 1, 'Foosha Docks', 66371, 'There once was a man named Gold Roger, who was king of the pirates! He left everything he owned... in One Piece.', 41.15850,174.47210),
       (16, 2, 'Kuro Bay', 66372, 'Further east you will find black waters and your next waypoint.', 41.17050,174.0010),
       (16, 3, 'Krieg Caverns', 66373, 'Caves home to the infamous pirate Don Krieg.', 42.06050,175.00105),
       (16, 4, 'Sun Temple', 66374, 'Rumour has it fishmen live at the next waypoint.', 44.06050,174.90101),
       (16, 5, 'Drum Island', 66375, 'North leads to a snowy, percussion island.', 40.89520,152.88406),
       (16, 6, 'Alabasta Docks', 66376, 'Great white kingdom of legend.', 38.33210,150.0010);


INSERT INTO TreasureHunt.Player (name, password, pw_salt, gender, addr)
VALUES ('mdluffy', 'gumgum1', 'g#m#g#m#', 'm', 'Foosha Village'),
       ('rzolo', 'tastysword3', 't#s#y#w#r#', 'm', 'Shimotsuki Village'),
       ('nami', 'hunter2', 'h#n#e#2', 'f', 'Cocoyashi Village'),
       ('arlong', 'sawnose2', 's#w#o#e#', 'm', 'Sun Temple'),
       ('catfish', 'pieuman1', 'p#e#m#n#', 'm', 'Sun Temple');

INSERT INTO TreasureHunt.PlayerStats (player, stat_name, stat_value)
VALUES ('mdluffy', 'finished_hunts', '0'),
       ('mdluffy', 'point_score',    '5'),
       ('rzolo',   'finished_hunts', '0'),
       ('rzolo',   'point_score',    '5'),
       ('nami',    'finished_hunts', '0'),
       ('nami',    'point_score',    '5'),
       ('catfish', 'finished_hunts', '4'),
       ('catfish', 'point_score',   '36'),
       ('arlong',  'finished_hunts', '4'),
       ('arlong',  'point_score',   '36');

INSERT INTO TreasureHunt.Team (name, created)
VALUES ('StrawHats', DATE '2008-11-18'),
       ('Fishmen',   DATE '2007-08-09');

INSERT INTO TreasureHunt.MemberOf (player, team, since)
VALUES ('mdluffy', 'StrawHats', DATE '2008-11-18'),
       ('rzolo',   'StrawHats', DATE '2008-11-18'),
       ('nami',    'StrawHats', DATE '2008-11-26'),
       ('arlong',  'Fishmen',   DATE '2007-08-09'),
       ('catfish', 'Fishmen',   DATE '2007-08-09');

INSERT INTO TreasureHunt.Badge (name, description, condition)
VALUES ('Tide Hunter',   'Given to hunters who crossed an ocean to reach a waypoint.', 'boat_travel_count != 0'),
       ('Night Stalker', 'Given to hunters who reach a waypoint between 12am and 6am on any day.', 'EXISTS discover_time_hour BETWEEN 0 AND 6');

INSERT INTO TreasureHunt.Achievements (player, badge, whenReceived)
VALUES ('mdluffy', 'Novice Player',DATE '2008-12-17'),
       ('mdluffy', 'Tide Hunter',  DATE '2008-12-17'),
       ('rzolo',   'Novice Player',DATE '2008-12-17'),
       ('rzolo',   'Tide Hunter',  DATE '2008-12-17'),
       ('nami',    'Novice Player',DATE '2008-12-17'),
       ('nami',    'Tide Hunter',  DATE '2008-12-17'),
       ('arlong',  'Tide Hunter',  DATE '2007-09-13'),
       ('catfish', 'Tide Hunter',  DATE '2007-09-13'),
       ('arlong',  'Night Stalker',DATE '2009-02-14'),
       ('catfish', 'Night Stalker',DATE '2009-02-14');

INSERT INTO TreasureHunt.Visit (team, num, time, submitted_code, is_correct, visited_hunt, visited_wp)
VALUES ('StrawHats', 1, TIMESTAMP '2008-12-17 12:00:01', 66371, true, 16, 1),
       ('StrawHats', 2, TIMESTAMP '2008-12-18 12:00:02', 66372, true, 16, 2),
       ('StrawHats', 3, TIMESTAMP '2008-12-21 12:00:03', 66373, true, 16, 2),
       ('StrawHats', 4, TIMESTAMP '2008-12-23 12:00:04', 66374, true, 16, 3),
       ('StrawHats', 5, TIMESTAMP '2009-01-01 12:00:05', 66375, true, 16, 4),
       ('Fishmen',   1, TIMESTAMP '2008-11-13 12:00:01', 66371, true, 16, 1),
       ('Fishmen',   2, TIMESTAMP '2008-11-15 12:00:01', 66372, true, 16, 2),
       ('Fishmen',   3, TIMESTAMP '2008-11-16 12:00:03', 66993, false,16, 3);

INSERT INTO TreasureHunt.Participates (hunt, team, currentWP, score, rank, duration)
VALUES (16, 'StrawHats', 5, 4, NULL, NULL),
       (16, 'Fishmen',   3, 2, NULL, NULL);

INSERT INTO TreasureHunt.Review (id, hunt, player, whenDone, rating, description)
VALUES (17, 16, 'mdluffy', TIMESTAMP '2008-12-23 10:00:00', 1, 'Got attacked by fishmen, 1/5 would not do again.'),
       (18, 16, 'arlong',  TIMESTAMP '2009-09-16 11:12:34', 4, 'Sun Temple is a pretty nice place.');

INSERT INTO TreasureHunt.Likes (review, player, whenDone, usefulness)
VALUES (17, 'arlong', TIMESTAMP '2008-12-24 14:00:00', 5);

COMMIT;


/* manually advance the hunt and review PK sequences to clearly separate student hunts from pre-defined hunts */
SELECT setval('TreasureHunt.Hunt_id_seq', 99);
SELECT setval('TreasureHunt.Review_id_seq', 99);

