<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0;" />
<link rel="apple-touch-icon" href="images/webclip.png"/> 
<title>Earll home automation - Timers</title>
</head>
<body>
<form action="/cgi-bin/onoff" method="GET">
<div style="float: right;">
<a href="index.php"><img src="images/switches.png" border="0" width="46" height="48"><br/>Switches</a><br/><br/>
</div>
<table border=1>
<tr align="left"><th>Start</th><th>End</th><th>Days</th><th>Options</th><th>Description</th><th>Delete</th></tr>
<?php
$timers = scandir('timers');
foreach($timers as $timer)
{
	if (!strstr($timer, "."))
	{
		$fd = fopen("timers/$timer", "r");
		$startTime = fgets($fd);
		$endTime = fgets($fd);
		$days = trim(fgets($fd));
		$device = trim(fgets($fd));
		$options = trim(fgets($fd));
		if (!$days)
			$days = "daily";
		if ($days == "sunday monday tuesday wednesday thursday friday saturday")
			$days = "daily";
		if ($days == "monday tuesday wednesday thursday friday")
			$days = "weekdays";
		if ($days == "sunday saturday")
			$days = "weekends";
		fclose($fd);
		echo "<tr><td>$startTime</td><td>$endTime</td><td>$days</td><td>$options</td><td><a href=\"editTimer.php?timer=$timer\">$timer</a></td><td align=\"center\"><a href=\"deleteTimer.php?timer=$timer\">X</a></tr>";
	}
}
?>
<tr><td colspan="6"><b>The following timers are non-editable, but may be overridden by timers above:</b></td></tr>
<?php
$timers = scandir('timers-ro');
foreach($timers as $timer)
{
	if (!strstr($timer, "."))
	{
		$fd = fopen("timers-ro/$timer", "r");
		$startTime = fgets($fd);
		$endTime = fgets($fd);
		$days = trim(fgets($fd));
		$device = trim(fgets($fd));
		$options = trim(fgets($fd));
		if (!$days)
			$days = "daily";
		if ($days == "sunday monday tuesday wednesday thursday friday saturday")
			$days = "daily";
		if ($days == "monday tuesday wednesday thursday friday")
			$days = "weekdays";
		if ($days == "sunday saturday")
			$days = "weekends";
		fclose($fd);
		echo "<tr><td>$startTime</td><td>$endTime</td><td>$days</td><td>$options</td><td>$timer</td><td></td></tr>";
	}
}
?>
</table>
<hr/>
<a href="editTimer.php">Add a timer</a>
</body>
</html>
