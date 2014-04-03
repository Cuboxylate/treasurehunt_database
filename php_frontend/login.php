<?php 
/**
 * Login page
 * Users visiting the site via index.php are redirected to this login page, where
 * they must enter their username and password. Successful login starts a new session and
 * redirection to main content in index.php. Query parameters are preserved so that a user 
 * can use QR codes to go to confirmation page after logging in. 
 */
require_once('include/database.php');
/**
 * Clean up after user logs out 
 */
function log_out() {
    $_SESSION['player'] = '';
    $_SESSION['logged_in'] = false;
}

/**
 * Process a user's login details
 * @param string $name username
 * @param string $pass password
 * @return boolean true if login details are correct, else false 
 */
function log_in($name, $pass) {
    $is_valid = checkLogin($name,$pass);
    if ($is_valid) {
        $_SESSION['logged_in'] = true;
        $_SESSION['player'] = $name;
    }
    return $is_valid;
}

// Start session from scratch
session_start();
log_out();

// Messages to display to user if returning to page
$message = '';

// Query string parameters to preserve across login process
$qstring = http_build_query($_GET);
if (!empty($qstring)) {
    $qstring = '?'.$qstring;
}

//
// Process login details (must be POST data) and redirect to main site if correct
//
if(!isset($_POST['user']) || !isset($_POST['pass'])) {
    // Invalid data supplied, so don't return any message (maybe log the event though)
} else if (log_in($_POST['user'], $_POST['pass'])) {
    // Success so redirect to desired page
    $target = 'index.php'.$qstring; // Pass on query parameters
    header('Location:'.$target);
    exit;
} else {
    $message='Login details incorrect. Please try again.';
}

//
// If user hasn't submitted login details, or if they are incorrect, they will see
// the following page.
//

?>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Treasure Hunt Login</title>
    <link rel="stylesheet" type="text/css" href="css/main.css" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body>
    <div id="wrapper">
    <div id="content">
    <ul id="nav">
        <li><a href="login.php">Login</a></li>
    </ul>
    <h1>Treasure Hunt</h1>
    <div id="login">
        <form action="<?php echo 'login.php',$qstring; ?>" id="loginform" method="post">
            <label><h3>Name </h3><input type=text name="user" /></label><br />
            <label><h3>Password </h3><input type=password name="pass" /></label><br />
            <input type=submit value="Log in"/>
        </form>
    <div id="message">
    <?php echo $message; ?>
    </div>
    </div>
    </div>
    </div>
    <div id="footer">
</div>
</body>
</html>
