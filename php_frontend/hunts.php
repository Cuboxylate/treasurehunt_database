<?php 
/**
 * Web page to display all available hunts
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Browse Hunts</h1>
<?php 
try {
    $hunts = getAvailableHunts();
    echo '<table>';
    echo '<thead>';
    echo '<tr><th>Name</th><th>Starts</th><th>Distance</th><th>Waypoints</th><th>Reviews</th></tr>';
    echo '</thead>';
    echo '<tbody>';
    /* For each hunt returned, display the details in table */
    foreach($hunts as $hunt) {
        echo '<tr><td><a href="huntdetails.php?id='.$hunt['hunt_id'].'">',$hunt['htitle'],'</a></td>',
                '<td>',$hunt['stime'],'</td><td>',$hunt['dist'],'</td>',
                '<td>',$hunt['num_wp'],'</td>',
                '<td><a href="reviews.php?id='.$hunt['hunt_id'].'&name='.$hunt['htitle'].'">','Reviews for hunt &raquo;','</a></tr>';

    }
    echo '</tbody>';
    echo '</table>';
} catch (Exception $e) {
        echo 'Cannot get available hunts';
}
htmlFoot();
?>
