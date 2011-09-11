// http://stackoverflow.com/questions/288699/get-the-position-of-a-div-span-tag
function getPos(el)
{
    // yay readability
    for (var lx=0, ly=0;
         el != null;
         lx += el.offsetLeft, ly += el.offsetTop, el = el.offsetParent);
    return {x: lx,y: ly};
}

function getIdPos(id)
{
	pos = getPos(document.getElementById(id));
	return "{" + pos.x + "," + pos.y + "}";
}