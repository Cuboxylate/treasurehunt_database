<?php 
/**
 * Home page giving details of a specific user
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Home</h1>
<?php 
try {
    /* First, retrieve all the relevent details from the database */
    $details = getUserDetails($_SESSION['player']);

    /* Print out the static details */
    echo '<h2>Name</h2> ',$details['name'];
    echo '<h2>Address</h2>',$details['address'];
    echo '<h2>Current team</h2>',$details['team'];
    if ($details['team'] == NULL) {
        echo 'You are not currently in a team';
    }
    echo '<h2>Statistics</h2>';
    /* Print the statistics in a table */
    echo '<table>';
    foreach($details['stats'] as $stats) {
        echo '<tr><td>',$stats['statname'];
        echo '</td><td>',$stats['statvalue'];
        echo '</td></tr>';
    }
    echo '</table>';

    /* Print badges as badge elements */
    echo '<h2>Badges</h2>';
    foreach($details['badges'] as $badge) {
        echo '<span class="badge" title="',$badge['badgedescription'],'">',$badge['badgename'],'</span><br />';
    }
} catch (Exception $e) {
    echo 'Cannot get user details';
}
htmlFoot();
?>
