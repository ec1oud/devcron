<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0;" />
<link rel="apple-touch-icon" href="images/webclip.png"/> 
<title>Earll home automation: All Known Devices</title>
</head>
<body>
<div style="float: right;">
<a href="index.php"><img src="images/switches.png" border="0" width="46" height="48"><br/>Switches</a><br/><br/>
</div>
<table>
<?php
$switches = scandir('/mnt/x10');
foreach($switches as $switch)
{
	if (strpos($switch, ".") === false)
	{
		$switchReadable = ucwords(str_replace("-", " ", $switch));
		echo "<tr><td align=right>$switchReadable</td>";
		$path = "/mnt/x10/" . $switch;
		if (is_link($path))
		{
			$dest = readlink($path);
			if (strpos($dest, "x10"))
				$dest = "X10 code " . strtoupper(substr($dest, strrpos($dest, "/") + 1));
			else if (strpos($dest, "ow0"))
			{
				$pieces = explode("/", $dest);
				$dest = "OneWire <a href=http://" . $_SERVER[SERVER_ADDR] . ":4380/" . $pieces[3] . ">serial " . $pieces[3];
			}
			echo "<td><code>$dest</code></td></tr>\n";
		}
		else
    			echo "<td></td></tr>\n";
	}
}
?>
</table>
</body>
</html>
