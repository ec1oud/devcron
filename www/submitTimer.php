<?php
include 'functions.inc';
$timer = htmlspecialchars($_GET["timer"]);
if (!$timer)
	$timer = htmlspecialchars($_GET["description"]);
if (!$timer)
{
	echo "Description is a required field.  Please hit the back button and try again.";
	exit(0);
}
$days = $_GET["days"];
if (empty($days))
	$days = array("daily");
$startHour = htmlspecialchars($_GET["startHour"]);
$startMinute = htmlspecialchars($_GET["startMinute"]);
if ($startMinute == 0) $startMinute = "00";
if (strstr($startHour, "sun"))
	$startMinute = "";
else
	$startMinute = ":" . $startMinute;
$startRand = $_GET["startRand"];
$endHour = htmlspecialchars($_GET["endHour"]);
$endMinute = htmlspecialchars($_GET["endMinute"]);
if ($endMinute == 0) $endMinute = "00";
if (strstr($endHour, "sun"))
	$endMinute = "";
else if (strstr($endHour, "pool"))
	$endMinute = "";
else
	$endMinute = ":" . $endMinute;
$endRand = $_GET["endRand"];
$fd = fopen("timers/$timer", "w");
fputs($fd, $startHour . $startMinute);
if ($startRand)
	fputs($fd, " + rand($startRand)");
fputs($fd, "\n");
fputs($fd, $endHour . $endMinute);
if ($endRand)
	fputs($fd, " + rand($endRand)");
fputs($fd, "\n");
foreach($days as $day)
	fputs($fd, $day . " ");
fputs($fd, "\n");
fputs($fd, $_GET["device"] . "\n");
if ($_GET["babysit-on"])
	fputs($fd, "babysit-on ");
if ($_GET["babysit-off"])
	fputs($fd, "babysit-off ");
fputs($fd, "\n");
fclose($fd);
Header('Location: timers.php');
?>
