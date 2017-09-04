for xspectest in *.xspec; 
    do /tmp/xspec/bin/xspec.sh $xspectest &> result.log; 
    if grep -q ".*failed:\s[1-9]" result.log || grep -q "*\sError\srunning\sthe\stest\ssuite" result.log; 
	    then echo "$xspectest failed" && exit 1; 
	    else echo "ok $xspectest";
    fi	
done
