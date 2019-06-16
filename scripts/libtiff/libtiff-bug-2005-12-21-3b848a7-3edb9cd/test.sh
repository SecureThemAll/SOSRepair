#!/bin/bash
bugrev=3b848a7
dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#Check if coverage is being run. If so, don't use time limit.
if [ `basename $1` = "coverage" ] ; then
    cov=0
else
    cov=1
fi

run_test()
{
    cd $dir/src
    if [ $cov -eq 0 ] ; then
        /usr/bin/perl $dir/libtiff-run-tests.pl $1
    else
        $dir/limit /usr/bin/perl $dir/libtiff-run-tests.pl $1
    fi
    RESULT=$?
    
    cd ..
    return 0
}

run_test1()
{
    pushd $dir/src/test > /dev/null
    test_script=$(sed "$1q;d" $dir/TESTS)
    test_script_log="$test_script.log"
    rm -f $test_script_log
    timeout $timeout make $test_script_log
    #timeout $timeout ./$test_script
    return $?
}

case $2 in
    p1) run_test 2 && exit 0 ;; 
    p2) run_test 3 && exit 0 ;; 
    p3) run_test 4 && exit 0 ;; 
    p4) run_test 5 && exit 0 ;; 
    p5) run_test 6 && exit 0 ;; 
    p6) run_test 7 && exit 0 ;; 
    p7) run_test 8 && exit 0 ;; 
    p8) run_test 10 && exit 0 ;; 
    p9) run_test 11 && exit 0 ;; 
    p10) run_test 12 && exit 0 ;; 
    p11) run_test 13 && exit 0 ;; 
    p12) run_test 14 && exit 0 ;; 
    p13) run_test 15 && exit 0 ;; 
    p14) run_test 16 && exit 0 ;; 
    p15) run_test 17 && exit 0 ;; 
    p16) run_test 19 && exit 0 ;; 
    p17) run_test 20 && exit 0 ;; 
    p18) run_test 21 && exit 0 ;; 
    p19) run_test 24 && exit 0 ;; 
    p20) run_test 25 && exit 0 ;; 
    p21) run_test 26 && exit 0 ;; 
    p22) run_test 27 && exit 0 ;; 
    p23) run_test 28 && exit 0 ;; 
    p24) run_test 69 && exit 0 ;; 
    p25) run_test 70 && exit 0 ;; 
    p26) run_test 71 && exit 0 ;; 
    p27) run_test 72 && exit 0 ;; 
    p28) run_test 73 && exit 0 ;; 
    p29) run_test 74 && exit 0 ;; 
    p30) run_test 75 && exit 0 ;; 
    p31) run_test 76 && exit 0 ;; 
    p32) run_test 77 && exit 0 ;; 
    p33) run_test 78 && exit 0 ;; 
    n1) run_test 22 && exit 0 ;; 
    n2) run_test 23 && exit 0 ;; 
esac
exit 1
