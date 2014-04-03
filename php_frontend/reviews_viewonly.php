<?php 
/**
 * Web page to only display the reviews of a hunt. Users are directed here
 * after submitting a new review to avoid resending the submit form 
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<?php 
try {
    $reviews = getReviews($_GET["id"]);
    echo '<h1>Reviews of '.$_GET["name"].'</h1>';
    echo '<table>';
    echo '<thead>';
    echo '<tr><th>Player</th><th>Reviewed</th><th>Rating</th><th>Comment</th></tr>';
    echo '</thead>';
    echo '<tbody>';
    foreach($reviews as $review) {
        echo '<tr><td>',$review['pname'],'</td>',
                '<td>',$review['whenmade'],'</td><td>',$review['rate'],'</td>',
                '<td>',$review['comm'],'</td></tr>';
    }
    echo '</tbody>';
    echo '</table><br>';
} catch (Exception $e) {
        echo 'Cannot get hunt reviews';
}

htmlFoot();
?>
