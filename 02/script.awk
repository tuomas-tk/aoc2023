BEGIN {
	FS = ":"
	sum1 = 0
	sum2 = 0
}

{
	n        = split($2, a, "[;,]")
	maxRed   = 0
	maxGreen = 0
	maxBlue  = 0
	for (i=1; i<=n; i++) {
		split(a[i], b, " ")
		cubes = int(b[1])
		if (b[2] == "red"   && cubes > maxRed)   maxRed   = cubes;
		if (b[2] == "green" && cubes > maxGreen) maxGreen = cubes;
		if (b[2] == "blue"  && cubes > maxBlue)  maxBlue  = cubes;
	}
	if (maxRed <= 12 && maxGreen <= 13 && maxBlue <= 14) sum1 += int(substr($1, 6))
	sum2 += maxRed * maxGreen * maxBlue
}

END {
	print "Part 1:", sum1
	print "Part 2:", sum2
}