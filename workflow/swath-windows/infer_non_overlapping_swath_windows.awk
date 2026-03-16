BEGIN {OFS="	"}
function max(a,b){
    if(a > b)
	return a
    return b
}
NR==1 {
    # we start with the special case that the boundary for the first entry
    # should be unchanged
    prev_upper=$1
    # and we add the column names
    print "LowerOffset","HigherOffset"
}
{
    if (prev_upper > $2)
    {
	print "There is a a window thats a subwindow of the previous window"
	exit 1
    }
    print(max($1,prev_upper),$2)
    prev_upper=$2
}
