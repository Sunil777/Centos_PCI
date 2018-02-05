## This file is managed by Ansible Server ## 

########running Card scan tool############

for dir in "/usr" "/var"  "/home" "/run" "/tmp" "/opt"
do

/opt/CCSearchX64 --input="$dir" --excludelist="/boot" --output="/tmp/reportCDD.xml"  --xml --selective --resume --p=low --minlen=15 --maxlen=16 --trial=false --sep=":#:#*#:#|#:# #:#.#:#-" --searchopt=txt,csv,text,xml,dat,htm,tsv,cfg,xsd,out,in,bkd,crd,f05,lst,odt,rpt,bak,bkp,bk,old,plb,temp,tmp,lck,lok,sql,msb,dbf,mdb,accdb,idx,nlb,trn,pdf,bck,arc,trc,enr,bit,aud,cdx,ds,dcr,dcn,rdf,err,log,01300,bkl,doc,docx,xls,xlsx,rtf,mht,one,msg,zip,noext > /tmp/log 2>&1
cat /tmp/reportCDD.xml >> /tmp/CDDreport.`hostname`_`date +%m-%Y`.xml

done
########## for sending the mail with attachment############

echo "PFA" | nail -s "Card Scan Report" -a /tmp/CDDreport.`hostname`_`date +%m-%Y`.xml -a /tmp/skipped_files.txt noc@payu.in
