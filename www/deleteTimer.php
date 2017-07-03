<?php
include 'functions.inc';
$timer = htmlspecialchars($_GET["timer"]);
unlink("timers/$timer");
Header('Location: timers.php');
?>
