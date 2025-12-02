#!/bin/bash

#script for marking P-arrival using template matching
#cd to the directory with event folders 

for event in Event_2006_142_11_12_00
do

cd $event


echo "Working on $event"


rm *.corr *txt *.temp *picked *sacro
#Read sac files

sac <<!
r *.z
qdp off
ppk p 10
w append .temp
!

#Remove unnecessary temp files

for file in *.z
do

filename=$file.temp

echo "Working on $file"
t1=`sac <<! |grep "t1" | awk '{ print $3 }'
r ${file}
lh t1
q
!`

T1=`sac <<! |grep "t1" | awk '{ print $3 }'
r ${filename}
lh t1
q
!`

echo "Checking if t1 is the same"

if [ $t1 == $T1 ] ; then
rm ${filename}
else
echo "${file} is the template"
fi


done

echo "correlation with the template"


template=`ls *.temp`
echo $template

sac <<!
r *.z
correlate master ${template}
w append .corr
q
!

echo "marking new P-arrival"

rm chheader.sacro
for file in *.z
do

net=`echo $file | awk -F_ '{print $1}' | awk -F. '{print $1}'`
sta=`echo $file | awk -F_ '{print $1}' | awk -F. '{print $2}'`
num=`echo $file | awk -F_ '{print $2}' | awk -F. '{print $1"."$2"."$3}'`

rfile=`echo ${net}.${sta}_${num}.r`
/depot/jdelph/apps/sacdump/sacdump $file.corr > $file.corr.txt #converting correlation files to txt format

max_value=`awk '{if($1>=-5 && $1<=5) print $0}' $file.corr.txt | sort -k 2n | tail -n 1 | awk '{print $2}'`
delay_time=`awk '{if($1>=-5 && $1<=5) print $0}' $file.corr.txt | sort -k 2n | tail -n 1 | awk '{print $1}'`

temp_t1=`saclst t1 f $template | awk '{print $2}'`
file_t1=`saclst t1 f $file | awk '{print $2}'`
echo $temp_t1 $file_t1
echo $delay_time

#temp_t1=`sac <<! |grep "t1" | awk '{ print $3 }'
#r ${template}
#lh t1
#q
#!`

#file_t1=`sac <<! |grep "t1" | awk '{ print $3 }'
#r ${file}
#lh t1
#q
#!`

t1=`echo "($temp_t1) + ($delay_time)" | bc -l`

echo $t1

cat >> chheader.sacro <<+
r ${file} ${rfile}
ch t1 ${t1} t2 -12345
w append .picked
+

done

cat >> chheader.sacro <<+
q
+

sac chheader.sacro

cd ..

done

