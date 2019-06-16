#!/bin/bash
bugrev=3eb6091d69
EXECUTABLE=$( dirname $1 )
TEST_ID=$2
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


run_test()
{
    cd $DIR/src
        $DIR/limit /usr/bin/perl $DIR/gzip-run-tests.pl $1
    RESULT=$?

    cd ..
    return 0
}
case $TEST_ID in
    p1) run_test 1 && exit 0 ;; 
    p2) run_test 3 && exit 0 ;; 
    p3) run_test 4 && exit 0 ;; 
    p4) run_test 5 && exit 0 ;; 
    p5) run_test 7 && exit 0 ;; 
    p6) run_test 8 && exit 0 ;; 
    p7) run_test 9 && exit 0 ;; 
    p8) run_test 12 && exit 0 ;; 
    n1) run_test 6 && exit 0 ;; 
esac
exit 1
