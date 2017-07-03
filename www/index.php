<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0;" />
<link rel="apple-touch-icon" href="images/webclip.png"/> 
<title>Earll home automation</title>
<SCRIPT Language="JavaScript1.1" SRC="imageSwap.js"></SCRIPT>
<SCRIPT Language="JavaScript">
<!--
fixNetscape4()
toggleState = 'On'   //a required global variable to keep track of if the lights are On or Off.
/**
 * toggle changes source of the imgName image in the current document
 * based on the state ('Normal', 'Over', or 'Down') and the global variable
 * toggleState that contains either 'On' or 'Off.' When a 'Down' state
 * is received the function changes the studio image and changes the
 * toggleState from 'On' to 'Off' or from 'Off' to 'On'. The image to
 * place in the button is a contatentation of:
 * 'images/' + toggleState + state + '.png'
 * for example:
 * 'images/' + 'On' + 'Normal' + '.png'
 * Note the file names in the loadImages list.
 **/
function toggle(imgName, state){
	newState = 0
   if (state == 'Down'){   //swap in the picture and depress the button
      flip(imgName, 'images/' + toggleState + state + '.png')
      if (toggleState == 'On'){
         toggleState = 'Off'
      }
      else{
         toggleState = 'On'
		newState = 1
      }
if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
  xmlhttp=new XMLHttpRequest();
  }
else
  {// code for IE6, IE5
  xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
xmlhttp.open("GET","/cgi-bin/onoff?switch=" + imgName + "&state=" + newState,false);
xmlhttp.send();
   }
   else{                  //change the button image only
      flip(imgName, 'images/' + toggleState + state + '.png')
   }
}

//-->
</SCRIPT>
</head>
<body onLoad="loadImages( 'images/OnNormal.png', 'images/OnDown.png', 'images/OffNormal.png', 'images/OffDown.png')">

<form action="/cgi-bin/onoff" method="GET">
<div style="float: right;">
<a href="timers.php"><img src="images/appliance-timer.png" border="0" width="46" height="48"><br/>Timers</a><br/><br/>
<a href="devices.php"><img src="images/help-icon.png" border="0" width="46" height="48"><br/>Device<br/>Mapping</a><br/>
</div>
<table>
<?php
$switches = scandir('/mnt/x10');
foreach($switches as $switch)
{
	if (strpos($switch, ".") === false)
	{
		$switchReadable = ucwords(str_replace("-", " ", $switch));
		$statefd = fopen("/mnt/x10/$switch", "r");
		$currentState = fread($statefd, 1);
		$stateImage = ($currentState ? "OnNormal.png" : "OffNormal.png");
		fclose($statefd);
		echo "<tr><td align=right>$switchReadable</td>\n";
    		echo "<td><A HREF=\"#\"\n";
		echo "   onMouseDown=\"toggle('$switch', 'Down')\" onMouseUp=\"toggle('$switch', 'Normal')\"\n";
       		echo "><img src=\"images/$stateImage\" width=\"96\" height=\"29\" border=\"0\" Name=\"$switch\"></A>\n";
		echo "</td></tr>\n";
	}
}
?>
</table>
</body>
</html>
