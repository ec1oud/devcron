<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0;" />
<link rel="apple-touch-icon" href="images/webclip.png"/> 
<title>Earll home automation - Timers</title>
</head>
<body>
<form action="submitTimer.php" method="GET">
<?php
include 'functions.inc';
$timer = htmlspecialchars($_GET["timer"]);
$fd = fopen("timers/$timer", "r");
$startTime = fgets($fd);
$endTime = fgets($fd);
$days = trim(fgets($fd));
$device = trim(fgets($fd));
$options = trim(fgets($fd));
fclose($fd);
echo '<input type="hidden" name="timer" value="' . $timer . '"/>';
?>

<table>
<tr><td align="right">Description</td><td><input type="text" name="description" value="<?php echo $timer ?>"/></td></tr>

<tr><td align="right">Start Time</td><td>
<select name="startHour">
<?php
$sel = timeHour($startTime);
for ($i = 0; $i <= 24; $i++)
{
	echo '<option value="' . $i . '"';
	if ($i == $sel)
		echo ' selected="selected"';
	echo '>';
	if ($i == 0)
		echo "Midnight";
	else if ($i == 12)
		echo "Noon";
	else if ($i < 12)
		echo $i . " AM";
	else
		echo ($i - 12) . " PM";
	echo "</option>\n";
}
?>
<option value="sunrise"<?php if (strstr($startTime, 'sunrise')) echo ' selected="selected"'; ?>>Sunrise</option>
<option value="sunset"<?php if (strstr($startTime, 'sunset')) echo ' selected="selected"'; ?>>Sunset</option>
</select>

<?php
	echo '<select name="startMinute">';
	$sel = timeMinute($startTime);
	for ($i = 0; $i < 60; $i += 15)
	{
		echo '<option value="' . $i . '"';
		if ($i <= $sel && $i + 15 > $sel)
			echo ' selected="selected"';
		echo '>';
		if ($i == 0)
			echo ":00";
		else
			echo ":$i";
		echo "</option>\n";
	}
	echo "</select>\n";
?>&nbsp;+&nbsp;random&nbsp;<=&nbsp;<input type="text" name="startRand" size="2"
<?php
	$rand = timeRandom($startTime);
	if ($rand)
		echo "value=\"$rand\"";
?>
/>&nbsp;minutes</td></tr>

<tr><td align="right">End Time</td><td>
<select name="endHour">
<?php
$sel = timeHour($endTime);
for ($i = 0; $i <= 24; $i++)
{
	echo '<option value="' . $i . '"';
	if ($i == $sel)
		echo ' selected="selected"';
	echo '>';
	if ($i == 0)
		echo "Midnight";
	else if ($i == 12)
		echo "Noon";
	else if ($i < 12)
		echo $i . " AM";
	else
		echo ($i - 12) . " PM";
	echo "</option>\n";
}
?>
<option value="sunrise"<?php if (strstr($endTime, 'sunrise')) echo ' selected="selected"'; ?>>Sunrise</option>
<option value="sunset"<?php if (strstr($endTime, 'sunset')) echo ' selected="selected"'; ?>>Sunset</option>
<option value="pool-calc"<?php if (strstr($endTime, 'pool-calc')) echo ' selected="selected"'; ?>>Pool pump time calculator</option>
</select>

<?php
	echo '<select name="endMinute">';
	$sel = timeMinute($endTime);
	for ($i = 0; $i < 60; $i += 15)
	{
		echo '<option value="' . $i . '"';
		if ($i <= $sel && $i + 15 > $sel)
			echo ' selected="selected"';
		echo '>';
		if ($i == 0)
			echo ":00";
		else
			echo ":$i";
		echo "</option>\n";
	}
	echo "</select>\n";
?>&nbsp;+&nbsp;random&nbsp;<=&nbsp;<input type="text" name="endRand" size="2"
<?php
	$rand = timeRandom($endTime);
	if ($rand)
		echo "value=\"$rand\"";
?>
/>&nbsp;minutes</td></tr>
<tr><td align="right">Days</td><td>
<?php
$allDays = array("sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday");
foreach ($allDays as $d => $dName)
{
	echo "<input type=\"checkbox\" name=\"days[]\" value=\"$dName\"";
	if ($days == "daily" || strstr($days, $dName))
		echo ' checked="true"';
	echo ">" . ucfirst(substr($dName, 0, 3)) . "</input>\n";
}
?>
</td></tr>
<tr><td align="right">Device</td><td>
<select name="device">
<?php
$devs = scandir('/mnt/x10');
foreach($devs as $dev)
{
        if (!strstr($dev, "."))
        {
		echo "<option value=\"$dev\"";
		if (strcmp($device, $dev) == 0)
			echo " selected=\"selected\"";
		echo ">$dev</option>\n";
	}
}
?>
</select></td></tr>
<tr><td align="right">Babysitting</td><td>
<input type="checkbox" name="babysit-on" value="babysit-on"
<?php
	if (strstr($options, "babysit-on"))
		echo ' checked="true"';
?>
>Make sure it stays on</input>
<input type="checkbox" name="babysit-off" value="babysit-off"
<?php
	if (strstr($options, "babysit-off"))
		echo ' checked="true"';
?>
>Make sure it stays off</input>
</td></tr>
</table>
<input type="submit" />
</form>
</body>
</html>
