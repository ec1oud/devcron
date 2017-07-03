<?php
function timeHour($timeStr)
{
	return substr($timeStr, 0, strpos($timeStr, ":"));
}
function timeMinute($timeStr)
{
	return substr(strstr($timeStr, ":"), 1);
}
function timeRandom($timeStr)
{
	$inside = substr(strstr($timeStr, "rand("), 5);
	return substr($inside, 0, stripos($inside, ")"));
}
?>
