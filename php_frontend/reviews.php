<?php 
/**
 * Web page to display reviews of a hunt
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<?php 
try {
    /* Retrieves reviews for a hunt and displays them */
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

/* This is a form for a user to submit their own review */
echo '<h1>Write a review</h1>';
echo 'Select a rating: ';
echo '<form method="post" action=""><select name="rating">
<option value="5">5</option>
<option value="4">4</option>
<option value="3">3</option>
<option value="2">2</option>
<option value="1">1</option>
</select><br><br>';
echo 'Write your review here: <br>';
echo '<textarea row="5" col="10" name="reviewdesc"></textarea><br>';
echo '<input type=submit name="submit_button" value="Submit!"/></form>';

/* If the form has been submitted, executes the make_review function */
if(isset($_POST["rating"]) && isset($_POST["reviewdesc"])) {
    try {
        make_review($_GET["id"], $_SESSION['player'], $_POST['rating'], $_POST['reviewdesc']);
        echo '<a href="reviews_viewonly.php?id='.$_GET["id"].'&name='.$_GET["name"].'">','Click here to view updated reviews.','</a>';
    } catch (Exception $e) {
        echo 'Cannot make new review!';
    }
}
htmlFoot();
?>
