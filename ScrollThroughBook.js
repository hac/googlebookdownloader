scrolly = document.getElementById("viewport").children[0];
scrollComplete = false;
yInterval = 50;
tInterval = 2;

function scrollDown()
{
	original = scrolly.scrollTop;
	scrolly.scrollTop += yInterval;
	
	if (original < scrolly.scrollTop)
	{
		setTimeout("scrollDown()", tInterval);
	}
	else
	{
		scrollComplete = true;
	}
}

scrollDown();