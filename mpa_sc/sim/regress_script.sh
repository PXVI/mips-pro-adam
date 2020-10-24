# -----------------------------------------------------------------------------------
# Module Name  :
# Date Created : 02:40:34 IST, 25 October, 2020 [ Sunday ]
#
# Author       : pxvi
# Description  : Simple multi core regression script
# -----------------------------------------------------------------------------------
#
# MIT License
#
# Copyright (c) 2020 k-sva
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the Software), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ----------------------------------------------------------------------------------- */

# Regression Test Running Script
# ------------------------------
# 0
runTests(){

    if [ $# -eq 5 ]
    then
        if [ -f $1 ]
        then
            i=1;
            pass_num=0;
            fail_num=0;
            reg_list_num=`cat $1 | wc -l`;
            mc_count=$5;
            regress_start_time=`date "+%s"`;
            echo "=====================================================";
            echo -n " TOTAL NUMBER OF TESTS IN REGRESSION LIST: ";
            echo "$reg_list_num";
            echo "=====================================================";
            echo -n " RANDOMIZATION MODE : ";
            if [ $3 -eq "0" ]
            then
                echo "Common Seed"
            else
                echo "Random Seed"
            fi
            echo "=====================================================";

            # Getting the Process ID
            echo " Process ID: $$";

            if [ $reg_list_num -ne 0 ]
            then
                echo "-----------------------------------------------------";
                if [ $mc_count -le 1 ]
                then
                    echo " CORES : DEFAULT ( 1 )                           ";
                else
                    echo " CORES : $mc_count                               ";
                fi
                echo "-----------------------------------------------------";
                echo " REGRESSION STATUS :-                                ";
                echo "-----------------------------------------------------";

                if [ $mc_count -le 1 ]
                then
                    while [ $i -le $reg_list_num ]
                    do
                        testName=`head -$i $1 | tail -1`;
                        testAbsName=`basename ${testName}`;
                        echo "$testAbsName running..."
                        sleep 1;

                        if [ $3 -ne "0" ]
                        then
                            rand_seed=`date "+%N"`;
                            make sim SB=1 TDEBUG=1 IMFILE=$testName SEED=$rand_seed >> regression.log;
                        else
                            make sim SB=1 TDEBUG=1 IMFILE=$testName SEED=$2 >> regression.log;
                        fi

                        testRes=`grep "\[ RESULT \] Clean_Run\|\[ RESULT \] Error_Run\|\[ RESULT \] Warning" $testAbsName.log`;

                        #echo " $testRes";

                        temp_res=`grep "\[ RESULT \] Clean_Run" $testAbsName.log`;
                        if [ "$temp_res" != "" ]
                        then
                            pass_num=`expr $pass_num + 1`;
                        fi
                        
                        temp_res=`grep "\[ RESULT \] Error_Run\|\[ RESULT \] Warning" $testAbsName.log`;
                        if [ "$temp_res" != "" ]
                        then
                            fail_num=`expr $fail_num + 1`;
                        fi

                        i=`expr $i + 1`;
                    done
                    total_pass_fail_sum=`expr $pass_num + $fail_num`;

                    echo ""
                    echo "-----------------------------------------------------";
                    echo -n " TOTAL   TESTS : ";
                    echo "$total_pass_fail_sum";
                    echo -n " PASSING TESTS : ";
                    echo "$pass_num";
                    echo -n " FAILING TESTS : ";
                    echo "$fail_num";
                    echo "-----------------------------------------------------";

                    regress_end_time=`date "+%s"`;
                    time_eval_sec=`expr $regress_end_time - $regress_start_time`;
                    if [ $time_eval_sec -ge 60 ]
                    then
                        time_eval_min=`expr $time_eval_sec / 60`;
                        if [ $time_eval_min -ge 60 ]
                        then
                            time_eval_hr=`expr $time_eval_min / 60`;
                            temp_val=`expr $time_eval_hr "*" 60`;
                            time_eval_min=`expr $time_eval_min - $temp_val_1`;
                            temp_val_2=`expr $time_eval_min "*" 60`;
                            time_eval_sec=`expr $time_eval_sec - $temp_val_2`;
                            echo " Run Time : ${time_eval_hr}h ${time_eval_min}m ${time_eval_sec}s"
                        else
                            temp_val=`expr $time_eval_min "*" 60`;
                            time_eval_sec=`expr $time_eval_sec - $temp_val`;
                            echo " Run Time : ${time_eval_min}m ${time_eval_sec}s"
                        fi
                    else
                        echo " Run Time : ${time_eval_sec}s"
                    fi

                    echo "-----------------------------------------------------";
                    echo "REGRESSION Complete! [S]"
                else
                    
                    # This will keep track of the number of test cases that are running in parallel
                    running_test_count=0;

                    while [ $i -le $reg_list_num ]
                    do
                        testName=`head -$i $1 | tail -1`;
                        testAbsName=`basename ${testName}`;
                        #echo "$testAbsName running..."

                        # Firing the Simulations on Different Cores
                        if [ $3 -ne "0" ]
                        then
                            rand_seed=`date "+%N"`;
                            make sim SB=1 TDEBUG=1 IMFILE=$testAbsName SEED=$rand_seed > /dev/null &
                            echo "$testAbsName fired..."
                        else
                            make sim SB=1 TDEBUG=1 IMFILE=$testAbsName SEED=$2 > /dev/null &
                            echo "$testAbsName fired..."
                        fi

                        sleep 0.5;
                        running_test_count=`ps --ppid $$ | grep -c 'make'`;
                        running_test_count=`expr $running_test_count`;

                        while [ $running_test_count -ge $mc_count ]
                        do
                            sleep 0.5;
                            running_test_count=`ps --ppid $$ | grep -c 'make'`;
                            running_test_count=`expr $running_test_count`;
                        done
                        
                        i=`expr $i + 1`;
                    done

                    sleep 0.5;
                    running_test_count=`ps --ppid $$ | grep -c 'make'`;
                    running_test_count=`expr $running_test_count`;

                    while [ $running_test_count -ne 0 ]
                    do
                        sleep 0.5;
                        running_test_count=`ps --ppid $$ | grep -c 'make'`;
                        running_test_count=`expr $running_test_count`;
                    done

                    pass_num=`grep '\[ RESULT \] Clean_Run' ./*.bin.log | wc -l`;
                    fail_num=`grep '\[ RESULT \] Error_Run\|\[ RESULT \] Warning' ./*.bin.log | wc -l`;

                    total_pass_fail_sum=`expr $pass_num + $fail_num`;

                    echo ""
                    echo "-----------------------------------------------------";
                    echo -n " TOTAL   TESTS : ";
                    echo "$total_pass_fail_sum";
                    echo -n " PASSING TESTS : ";
                    echo "$pass_num";
                    echo -n " FAILING TESTS : ";
                    echo "$fail_num";
                    echo "-----------------------------------------------------";

                    regress_end_time=`date "+%s"`;
                    time_eval_sec=`expr $regress_end_time - $regress_start_time`;
                    if [ $time_eval_sec -ge 60 ]
                    then
                        time_eval_min=`expr $time_eval_sec / 60`;
                        if [ $time_eval_min -ge 60 ]
                        then
                            time_eval_hr=`expr $time_eval_min / 60`;
                            temp_val=`expr $time_eval_hr "*" 60`;
                            time_eval_min=`expr $time_eval_min - $temp_val_1`;
                            temp_val_2=`expr $time_eval_min "*" 60`;
                            time_eval_sec=`expr $time_eval_sec - $temp_val_2`;
                            echo " Run Time : ${time_eval_hr}h ${time_eval_min}m ${time_eval_sec}s"
                        else
                            temp_val=`expr $time_eval_min "*" 60`;
                            time_eval_sec=`expr $time_eval_sec - $temp_val`;
                            echo " Run Time : ${time_eval_min}m ${time_eval_sec}s"
                        fi
                    else
                        echo " Run Time : ${time_eval_sec}s"
                    fi

                    echo "-----------------------------------------------------";
                    echo "REGRESSION Complete! [S]"
                fi
            else
                echo "No Tests Provided in the Regression List! [S] Regression Script Completed!"
            fi

        else
            echo "Not a valid file! [F] Regress Script Failed!"
        fi
    else
        echo "Please pass only one file as an argument! [F] Regress Script Failed!"
    fi

}

if [ $# -eq 5 -a -f $1 ]
then
    runTests $@;   
else
  echo "Invalid Regression Command Execution! [F] Regress Script Failed!";
fi
