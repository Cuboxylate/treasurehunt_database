<?php
/**
 * Connect to database
 * This function does not need to be edited - just update config.ini with your own 
 * database connection details. 
 * @param string $file Location of configuration data
 * @return PDO database object
 * @throws exception
 */
function connect($file = 'config.ini') {
	// read database seetings from config file
    if ( !$settings = parse_ini_file($file, TRUE) ) 
        throw new exception('Unable to open ' . $file);
    
    // parse contents of config.ini
    $dns = $settings['database']['driver'] . ':' .
            'host=' . $settings['database']['host'] .
            ((!empty($settings['database']['port'])) ? (';port=' . $settings['database']['port']) : '') .
            ';dbname=' . $settings['database']['schema'];
    $user= $settings['db_user']['username'];
    $pw  = $settings['db_user']['password'];

	// create new database connection
    try {
        $dbh=new PDO($dns, $user, $pw);
        $dbh->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        print "Error Connecting to Database: " . $e->getMessage() . "<br/>";
        die();
    }
    return $dbh;
}

/**
 * Check login details
 * @param string $name Login name
 * @param string $pass Password
 * @return boolean True is login details are correct
 */
function checkLogin($name,$pass) {

    $db = connect();
    try {
        $db->beginTransaction();
        $stmt = $db->prepare('SELECT * FROM login(:name, :password)');
        $stmt->bindValue(':name', $name);
        $stmt->bindValue(':password', $pass);
        $stmt->execute();
        $result = $stmt->fetchColumn();
        $stmt->closeCursor();
        $db->commit();      
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error checking login ";// . $e->getMessage(); 
        return FALSE;
    }
    return ($result==1);
}

/**
 * Get details of the current user
 * @param string $user login name user
 * @return array Details of user - see index.php
 */
function getUserDetails($user) {

    $db = connect();
    try {
        $db->beginTransaction();
        /* Retrieve player info */
        $stmt = $db->prepare('SELECT * FROM get_user_details(:name)');
        $stmt->bindValue(':name', $user);
        $stmt->execute();
        $result = $stmt->fetch();
        $stmt->closeCursor();

        /* Retieve player statistics as array */
        $stmt2 = $db->prepare('SELECT * FROM get_user_stats(:name)');
        $stmt2->bindValue(':name', $user);
        $stmt2->execute();
        $stats = $stmt2->fetchAll();

        /*Retrieve player badges as array */
        $stmt3 = $db->prepare('SELECT * FROM get_user_badges(:name)');
        $stmt3->bindValue(':name', $user);
        $stmt3->execute();
        $badges = $stmt3->fetchAll();
        $db->commit();      
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error retrieving player information ";// . $e->getMessage(); 
        return FALSE;
    }

    $results = array();
    $results['name'] = $result['name'];
    $results['address'] = $result['addr'];
    $results['team'] = $result['team'];
    $results['stats'] = $stats;
    $results['badges'] = $badges;
    
    return $results;
}

/**
 * List hunts that are currently available
 * @return array Various details of for available hunts - see hunts.php
 * @throws Exception 
 */
function getAvailableHunts() {

    $db = connect();
    try {
        $db->beginTransaction();
        $stmt = $db->prepare('SELECT * FROM get_available_hunts()');
        $stmt->execute();
        $result = $stmt->fetchAll();
        $stmt->closeCursor();
        $db->commit();
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error retrieving hunt information ";// . $e->getMessage(); 
        return FALSE;
    }
    return $result;
}

/**
 * Get details for a specific hunt
 * @param integer $hunt ID of hunt
 * @return array Various details of current hunt - see huntdetails.php
 * @throws Exception 
 */
function getHuntDetails($hunt) {
    
    $db = connect();
    try {
        $db->beginTransaction();
        $stmt = $db->prepare('SELECT * FROM get_hunt_details(:hunt_id)');
        $stmt->bindValue(':hunt_id', $hunt);
        $stmt->execute();
        $result = $stmt->fetchAll();
        $stmt->closeCursor();
        $db->commit();
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error retrieving hunt information: ";// . $e->getMessage(); 
        return FALSE;
    }
    return $result;
}

/**
 * Show status of user in their current hunt
 * @param string $user
 * @return array Various details of current hunt - see current.php
 * @throws Exception 
 */
function getHuntStatus($user) {

    $db = connect();
    try {
        $db->beginTransaction();
        /* Selects the current hunt, if any */
        $stmt = $db->prepare("SELECT * FROM get_active_hunt(:name)");
        $stmt->bindValue(':name', $user);
        $stmt->execute();
        $active = $stmt->fetch();
        $stmt->closeCursor();
        /* Selects the last finished hunt, if any */
        $stmt2 = $db->prepare("SELECT * FROM get_recent_hunt(:name)");
        $stmt2->bindValue(':name', $user);
        $stmt2->execute();
        $finished = $stmt2->fetch();
        $stmt2->closeCursor();
        $db->commit();      
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error retrieving hunt information: ";// . $e->getMessage(); 
        return FALSE;
    }

    $results = array();
    $results['active'] = $active;
    $results['finished'] = $finished;
    
    return $results;
}

/**
 * Check validation code is for user's next expected waypoint 
 * @param string $user
 * @param integer $code Validation code (e.g. from QR)
 * @return array Various details of current visit - see validate.php
 * @throws Exception 
 */
function validateVisit($user,$code) {
    $db = connect();
    try {
        /* First, select the correct ver code and some key values 
         * for later transactions */
        $db->beginTransaction();
        $check_code = $db->prepare('SELECT * FROM get_ver_code(:name)');
        $check_code->bindValue(':name', $user);
        $check_code->execute();
        $ver_code = $check_code->fetch();
        $check_code->closeCursor();

	    /* Retrieve hunt id and team name to use later*/
	    $hunt_id = $ver_code['hunt_id'];
        $team = $ver_code['pteam'];
        $current_wp = $ver_code['wp_num'];

        if ($ver_code['ver_code'] == $code) {

		/*If the waypoint code is right, check first if it's the last waypoint*/
            $get_hunt_wp = $db->prepare("SELECT * FROM get_hunt_wp_num(:hunt)");
            $get_hunt_wp->bindValue(':hunt', $hunt_id);
            $get_hunt_wp->execute();
            $hunt_wpnum = $get_hunt_wp->fetch();
            $get_hunt_wp->closeCursor();

            if ($hunt_wpnum[0] == $current_wp) {
		/* If final waypoint, we need to update stats. First check
		 * there is a finished hunt stat and retrive the points_score */		
		        $check_fin_hunts = $db->prepare("SELECT * FROM get_fin_hunts(:name)");
	    	    $check_fin_hunts->bindValue(':name', $user);
		        $check_fin_hunts->execute();
		        $fin_hunts = $check_fin_hunts->fetchAll();
		        $check_fin_hunts->closeCursor();
		
                /* The stats are returned in alphabetical order, so finished_hunts should be first */
		        if ($fin_hunts[0]['statname'] != 'finished_hunts') {
			/* If no finished_hunts stat available, make one */
			        $make_fin_hunts = $db->prepare("SELECT * FROM make_fin_hunts(:name)");
				    $make_fin_hunts->bindValue(':name', $user);
			        $make_fin_hunts->execute();

                    $curr_score = $fin_hunts[0]['statvalue'];
		        }
		        else {
			/* If there are finished hunts, increase the value */;
			        $incr_fin_hunts = $db->prepare("SELECT * FROM incr_fin_hunts(:name)");
			        $incr_fin_hunts->bindValue(':name', $user);
			        $incr_fin_hunts->execute();

                    $curr_score = $fin_hunts[1]['statvalue'];
		        }
                /*Now to update player score and the participates table */
		        $update_score = $db->prepare("SELECT * FROM update_score(:curr_score, :hunt, :team, :name)");
                $update_score->bindValue(':curr_score', $curr_score);
                $update_score->bindValue(':hunt', $hunt_id);
                $update_score->bindValue(':team', $team);
                $update_score->bindValue(':name', $user);
				$update_score->execute();
				
				$update_participates = $db->prepare("SELECT * FROM update_participates(:hunt, :team)");
                $update_participates->bindValue(':hunt', $hunt_id);
                $update_participates->bindValue(':team', $team);
                $update_participates->execute();

                $results['status'] = 'complete';
        }
	    else {
            /* If just a correct vist, update the currentWP and score
             * and return the clue for the next waypoint */
            $update_current_hunt = $db->prepare("SELECT * FROM update_current_hunt(:hunt_id, :team)");
            $update_current_hunt->bindValue(':hunt_id', $hunt_id);
            $update_current_hunt->bindValue(':team', $team);
            $update_current_hunt->execute();
         
			$get_clue = $db->prepare("SELECT * FROM get_clue(:hunt, :curr_wp)");
			$get_clue->bindValue(':hunt', $hunt_id);
            $get_clue->bindValue(':curr_wp', $current_wp + 1);
			$get_clue->execute();
			$clue = $get_clue->fetch();
            $get_clue->closeCursor();
			
            $results['status'] = 'correct';
            $results['clue'] = $clue;
        }
        /* Save a variable to show it's a correct visit */
        $is_correct = 't';
    }
	else {
	    $results['status'] = 'incorrect';
        $is_correct = 'f';
    }
    /* Whether correct or not, we need to save a visit in the visit table and return the score */
        $save_visit = $db->prepare("SELECT * FROM save_visit(:team, :code, :correct, :hunt, :wp)");
        $save_visit->bindValue(':team', $team);
        $save_visit->bindValue(':code', $code);
        $save_visit->bindValue(':correct', $is_correct);
        $save_visit->bindValue(':hunt', $hunt_id);
        $save_visit->bindValue(':wp', $current_wp);
		$save_visit->execute();
		
		$get_score = $db->prepare("SELECT * FROM get_score(:team, :hunt)");
        $get_score->bindValue(':team', $team);
        $get_score->bindValue(':hunt', $hunt_id);
        $get_score->execute();
        $score = $get_score->fetch();
        $get_score->closeCursor();

        $results['score'] = $score;

    $db->commit();
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error handling WP visit: ";// . $e->getMessage(); 
        return FALSE;
    }
    return $results;

   }

/**
 * Retrieves reviews for a given hunt
 * @param int $hunt_id
 * @throws Exception 
 */
function getReviews($hunt_id) {

    $db = connect();
    try {
        $db->beginTransaction();
        $get_reviews = $db->prepare("SELECT * FROM get_reviews(:hunt_id)");
        $get_reviews->bindValue(':hunt_id', $hunt_id);
        $get_reviews->execute();
        $reviews = $get_reviews->fetchAll();
        $get_reviews->closeCursor();
        $db->commit();      
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error retrieving reviews: ";// . $e->getMessage(); 
        return FALSE;
    }
    return $reviews;
}

/**
 * Makes a review for a given hunt 
 * @param int $hunt_id
 * @param string $player
 * @param int $rating
 * @param text $description
 * @throws Exception 
 */
function make_review($hunt_id, $player, $rating, $description) {

    $db = connect();
    try {
        $db->beginTransaction();
        $make_review = $db->prepare("SELECT * FROM make_review(:hunt_id, :user, :rating, :desc)");
        $make_review->bindValue(':hunt_id', $hunt_id);
        $make_review->bindValue(':user', $player);
        $make_review->bindValue(':rating', $rating);
        $make_review->bindValue(':desc', $description);
        $make_review->execute();
        $db->commit();      
    } catch (PDOException $e) { 
        $db->rollBack();
        print "Error making review ";// . $e->getMessage(); 
        return FALSE;
    }
}


?>
