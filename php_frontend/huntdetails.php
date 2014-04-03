<?php 
/**
 * Web page to display information about a specific hunt
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Hunt Details</h1>
<?php 
try {
    $hunt = getHuntDetails($_GET["id"]);
    echo '<h2>Name</h2> ',$hunt[0]['htitle'];
    echo '<h2>Description</h2> ',$hunt[0]['hdesc'];
    echo '<h2>Start Time</h2> ',$hunt[0]['stime'];
    echo '<h2>Distance</h2> ',$hunt[0]['dist'];
} catch (Exception $e) {
    echo 'Cannot get hunt details';
}
htmlFoot();
?>

