#!/bin/bash

duration_in_seconds=$1

interrupted()
{
   echo "Do you want continue [Y/n]?"
   read  run_flag
   if [ -z "$run_flag" ]
   then
      run_flag="Y"
   else
      run_flag=$(echo $run_flag | tr '[a-z]'  '[A-Z]')
   fi

}

trap "interrupted" SIGINT


i=0
run_flag=Y
while [ "$run_flag" = "Y" ]
do
    i=$(expr $i \+ 1)
    j=$(expr $i \% 1000)
    [ -n "$j" ] && [ $j -eq 0 ] && echo $(expr $i \/ 1000)
done

