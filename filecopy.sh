apt list |grep pip3 >>/dev/null
[ $? -ne 0 ] && sudo apt install python3-pip
[ -d $HOME/temp ] || mkdir $HOME/temp 
[ -f $HOME/temp/testfile ]  || dd if=/dev/zero of=$HOME/temp/testfile bs=1M count=1024
[ -f $HOME/temp/log ] && echo '' >$HOME/temp/log || touch $HOME/temp/log
python3<<-EOF
import os
installed_moudles=os.popen('python3-pip list --format=freeze').read()
if 'tqdm' not in installed_moudles:
    os.system('python3 -m pip install tqdm')
EOF

function func_cpcmp(){
python3 <<EOF 
from functools import partial
from hashlib import md5
import os
import time
import tqdm
host=os.popen("hostname").read().split("\n")[0]
logfile="/home/"+host+"/"+"temp/"+"log"
fl=open(logfile,"a")
sourcefile=os.popen("echo -n $1").read()
desc_path=os.popen("echo -n $2").read()
source_path=os.path.dirname(sourcefile)
describe=source_path+"-->"+desc_path
tarfile=os.path.join(desc_path,"testfile")
with open(sourcefile,"rb") as fs:
    with open(tarfile,"wb") as ft:
        record_size=1024
        records=iter(partial(fs.read,record_size),b'')
        #返回源文件的大小（kB）
        size=int(os.path.getsize(os.path.abspath(sourcefile))/record_size)
        for data in tqdm.tqdm(records,total=size,unit="kB",desc=describe,mininterval=1,dynamic_ncols=True):
            ft.write(data)
            ft.flush()
        
#check targetfile md5
source_file="/home/"+host+"/"+"temp/"+"testfile"
with open(source_file,"rb") as fs:
    s_content=fs.read()
    s_md5=md5(s_content).hexdigest()

with open(tarfile,"rb") as f:
    t_content=f.read()
    t_md5=md5(t_content).hexdigest()
    if(t_md5==s_md5):
        fl.write(source_path+"-->"+ desc_path+" copy and compare "+str(size)+"KB"+" testfile pass\n")
    else:
        fl.write(source_path+"-->"+desc_path+" copy and compare "+str(size)+" KB"+" testfile fail\n")
fl.close()
EOF
}

function test(){
    #枚举usb设备挂载点
    disk_num=`lsblk -l |grep -ic "disk"`
    #usb device number
    declare -i count=$disk_num-1 
    #last usb device
    declare -i last_device=$count-1 
    declare -a disk_arr=(`lsblk -l |grep "/media/$user"|sed 's/.*part //g'`)
    if [ $count == 1 ];then
        [ -d ${disk_arr}/temp ] || mkdir  ${disk_arr}/temp 
        sourcefile=$HOME/temp/testfile
        desc_path=${disk_arr}/temp 
        func_cpcmp $sourcefile $desc_path
        copy_back=${disk_arr}/temp/testfile
        local_path=$HOME
        func_cpcmp $copy_back $local_path    
    else
        for ((i=0;i<=$count;i=i+1))
        do  
            
            if [ $i == 0 ];then
                [ -d ${disk_arr}/temp ] || mkdir  ${disk_arr}/temp 
                sourcefile=$HOME/temp/testfile
                desc_path=${disk_arr}/temp 
                func_cpcmp $sourcefile $desc_path 
                
            elif [ $i -gt 0 ] && [ $i -le $last_device ];then
                let n=i-1
                [ -d ${disk_arr[i]}/temp ] || mkdir  ${disk_arr[i]}/temp 
                sourcefile=${disk_arr[n]}/temp/testfile
                desc_path=${disk_arr[i]}/temp
                func_cpcmp $sourcefile $desc_path
            else
                let m=i-1
                sourcefile=${disk_arr[m]}/temp/testfile
                desc_path=$HOME
                func_cpcmp $sourcefile $desc_path
            fi
    done

    fi
}

d=`date +%s`
#设置测试时间，输入参数是小时
#declare -i time_terval
read -p "请输入测试时间，单位是小时(H):" T
let time_terval=T*60*60
let val_time=d+$time_terval
while true
do
	t=`date +%s`
	if [ $t -ge $val_time ];then
		echo "test finishied ,log saved in $HOME/temp"
		exit -1
	else 
        date |tee -a  $HOME/temp/log
		test
        echo -e "\n"
	fi
done
echo "test finishied ,log saved in $HOME/temp"
