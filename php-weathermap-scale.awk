# Copyright (c) 2017 Chase Patterson
#
# Usage: awk -f php-weathermap-scale.awk [var=val] weathermap.conf >mymap.conf
#
# Optionally provide values for the following variables:
#	width	the new width of the map in pixels (default 1440)
#	height	the new height of the map in pixels (default 900)
#	title	a new title for the map (default "My Map")
#	bg	a path to the background image (default "images/mybg.png")
#

# return 0 if $1 is NODE-specific directive, 1 if not
function parse_node_directive() {
	switch ($1) {
	case "ICON":
		if (NF == 4)
			return sprintf("ICON %.0f %.0f %s\n", $2 * xscale, $3 * yscale, $4);
		else
			return sprintf("%s\n", $0);
		break;
	case "LABELOFFSET":
		if (NF == 3)
			return sprintf("LABELOFFSET %%.0f %.0f\n", $2 * xscale, $3 * yscale);
		else
			return sprintf("%s\n", $0);
		break;
	case "POSITION":
		return sprintf("POSITION %.0f %.0f\n", $2 * xscale, $3 * yscale);
		break;
	case "COLOR": case "INFOURL": case "LABEL": case "LABELANGLE":
	case "LABELFONT": case "MAXVALUE": case "NOTES": case "OVERLIBCAPTION":
	case "OVERLIBGRAPH": case "OVERLIBHEIGHT": case "OVERLIBWIDTH":
	case "SET": case "TARGET": case "TEMPLATE": case "USEICONSCALE":
	case "USESCALE": case "ZORDER":
		return sprintf("%s\n", $0);
		break;
	default:
		return 0;
	}
}
function parse_link_node(node,    pi,    x,    y,    r) {
	split(node, a, ":");
	if (3 in a) {
		return sprintf("%s%.0f%s%.0f", a[1] ":", a[2] * xscale, ":", a[3] * yscale);
	} else if (2 in a) {
		if (a[2] ~/[0-9]+r[0-9]+/) {
			split(a[2], noder, "r");
			pi = atan2(0, -1);
			x = noder[2] * cos((noder[1] / 360) * (2 * pi));
			y = noder[2] * sin((noder[1] / 360) * (2 * pi));
			rscaled = sqrt((x * xscale)^2 + (y * yscale)^2);
			return sprintf("%s%.0f", a[1] ":" noder[1] "r", rscaled);
		} else {
			return sprintf("%s", node);
		}
	} else {
		return sprintf("%s", node);
	}
}
# return 0 if $1 is LINK-specific directive, 1 if not
function parse_link_directive() {
	switch ($1) {
	case "BWLABELPOS":
		return sprintf("%s\n", $0);
		break;
	case "NODES":
		return sprintf("NODES %s %s\n", parse_link_node($2), parse_link_node($3));
		break;
	case "VIA":
		return sprintf("VIA %.0f %.0f\n", $2 * xscale, $3 * yscale);
		break;
	case "WIDTH":
		return sprintf("WIDTH %.0f\n", $2 * xscale);
		break;
	case "ARROWSTYLE": case "BANDWIDTH": case "BWFONT": case "BWLABEL":
	case "BWSTYLE": case "COLOR": case "COMMENTFONT": case "COMMENTPOS":
	case "COMMENTSTYLE": case "DUPLEX": case "INBWFORMAT": case "INCOMMENT":
	case "INFOURL": case "INNOTES": case "INOVERLIBCAPTION":
	case "INOVERLIBGRAPH": case "LINKSTYLE": case "NOTES":
	case "OUTBWFORMAT": case "OUTCOMMENT": case "OUTINFOURL":
	case "OUTNOTES": case "OUTOVERLIBCAPTION": case "OUTOVERLIBGRAPH":
	case "OVERLIBCAPTION": case "OVERLIBGRAPH": case "OVERLIBHEIGHT":
	case "OVERLIBWIDTH": case "SET": case "SPLITPOS": case "TARGET":
	case "TEMPLATE": case "USESCALE": case "VIASTYLE": case "ZORDER":
		return sprintf("%s\n", $0);
		break;
	default:
		return 0;
	}
}
BEGIN {
	width = 1440;
	height = 900;
	title = "My Map";
	bg = "images/mybg.png";

	xscale = 0;
	yscale = 0;

	block = "MAIN";

	temp = 0;

	printf "# Scaled by php-weathermap-scale\n\n";
}
block == "NODE" { if (temp = parse_node_directive()) {
			printf "%s", temp;
		  } else {
			block = "MAIN";
		  }
		}
block == "LINK" {
	if (temp = parse_link_directive()) {
		printf "%s", temp;
	} else {
		block = "MAIN";
	}
}
block == "MAIN" { switch ($1) {
	case "BACKGROUND":
		print "BACKGROUND", bg;
		break;
	case "HEIGHT":
		yscale = height / $2;
		print "HEIGHT", height;
		break;
	case "KEYPOS":
		printf "KEYPOS %s %.0f %.0f", $2, $3 * xscale, $4 * yscale;
		$1 = $2 = $3 = $4 = "";
		print $0;
		break;
	case "TITLE":
		print "TITLE", title;
		break;
	case "TIMEPOS":
		printf "TIMEPOS %.0f %.0f", $2 * xscale, $3 * yscale;
		$1 = $2 = $3 = "";
		print $0;
		break;
	case "WIDTH":
		xscale = width / $2;
		print "WIDTH", width;
		break;
	case "NODE":
		print $0;
		block = "NODE";
		break;
	case "LINK":
		print $0;
		block = "LINK";
		break;
	default:
		print $0;
	}
}
END { }
