<?php 
/**
 * Web page to display details of a user's current hunt (if any) 
 * and their last finished hunt. 
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Hunt Status</h1>
<?php 
try {
    $hunt = getHuntStatus($_SESSION['player']);

    /* If there is a current hunt, display it */
    if($hunt['active']!=NULL) {
        $active=$hunt['active'];
        echo '<h2>Hunt Name</h2> ', $active['hunt_title'];
        echo '<h2>Playing in team</h2> ',$active['pteam'];
        echo '<h2>Started</h2> ',$active['stime'];
        echo '<h2>Time elapsed</h2> ',$active['elapsed'];
        echo '<h2>Current score</h2> ',$active['pscore'];
        echo '<h2>Completed waypoints</h2> ',$active['waypoint_count'];  
        echo '<h2>Next Waypoint\'s clue</h2> <quote>',$active['clue'],'</quote>';
        echo '<form action="validate.php" id="verify" method="post"><br />
            <label>Verification code <input type=text name="vcode" /></label><br />
               <input type=submit value="Verify"/>
        </form>';
    } else {
        echo "You are not currently on a hunt! :("; 
    }
    echo'<br />';

    /* If there is a completed hunt, display it */
    if ($hunt['finished']!=NULL) {
        $finished=$hunt['finished'];
        echo '<h1>Previous Hunt</h1>';
        echo '<h2>Hunt Name</h2> ', $finished['hunt_title'];
        echo '<h2>Played in team</h2> ',$finished['pteam'];
        echo '<h2>Started</h2> ',$finished['stime'];
        echo '<h2>Time Taken</h2> ',$finished['elapsed'];
        echo '<h2>Final score</h2> ',$finished['pscore'];
        echo '<h2>Rank</h2> ',$finished['trank'];
    } else {
        echo 'No hunt history.';
    }
} catch (Exception $e) {
    echo 'Cannot get current hunt status';
}
htmlFoot();
?>
