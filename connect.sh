#!/bin/bash

#默认服务器配置项
#    "服务器名称 服务器标识 端口号 IP地址 登录用户名 登录密码/秘钥文件Key 秘钥文件地址"
SERVERS=(
    #"服务器名称 hk 22 220.181.57.217 root passphrase key ~/private_key.pem"
    "服务器名称 hk 22 10.10.10.1 root passphrase"
	"阿里云 bj 22 10.10.10.1 root password"
	"阿里云 as 22 10.10.10.1 root password"
	"腾讯云 sz 22 10.10.10.2 root password"
	"腾讯云1 hh 22 10.10.10.3 root password"
	"腾讯云1 as 22 10.10.10.4 root password"
)

#读取自定义服务器配置文件（server_config）列表，合并服务器配置列表
if [ -f server_config ]; then
	while read line
	do
		SERVERS+=("$line")
	done < server_config
fi

#服务器配置数
SERVER_LENGTH=${#SERVERS[*]}  #配置站点个数

if [[ $SERVER_LENGTH -le 0 ]] ;
then
	echo "未检测到服务器配置项!"
	echo "请在脚本SERVERS变量中配置或单独创建一个server_config文件并配置"
	exit ;
fi

#初始化
function Init() {
	terminalRow=`tput cols`	
	terminalLine=`tput lines`
	#清空屏幕
	printf "\ec"

	#默认行最大输出100字符
	if [ $terminalRow -gt 80 ]
	then
		terminalRow=100;
	fi
}

#服务器配置菜单
function ConfigList(){
	unset leftOutput;
	OutputFirst;
	for ((i=0;i<${SERVER_LENGTH};i++));
	do
		SERVER=(${SERVERS[$i]}) #将一维sites字符串赋值到数组
		serverNum=$(($i+1))
		mean=$(($terminalRow / 2));

		leftOutput="# \033[31m${serverNum}\033[0m (\033[31m${SERVER[1]}\033[0m) : \033[32m${SERVER[0]}[${SERVER[3]}]\033[0m\c"
		echo -e $leftOutput;

		stringLenght=`echo -n "${leftOutput}"| iconv -f UTF-8 -t gb18030 -c  | wc -c`
		stringLenght=$(($stringLenght-2-45));

		if [ $(($i%2)) == 1 ]
		then
			repairNum=`expr $mean - $stringLenght - 1`
			repair=$(printf "%-${repairNum}s" ' ')
			echo -e "${repair// / }#"
		else
			repairNum=`expr $mean - $stringLenght`
			repair=$(printf "%-${repairNum}s" ' ')
			echo -e "${repair// / }\c"

			if [ $(($i+1)) == $SERVER_LENGTH ]
			then
				repair=$(printf "%-48s" ' ')
				echo -e "#${repair// / }#"
			fi
		fi
	done
	OutputLast
}

#输出第一行
function OutputFirst() {
	leftNum=$((($terminalRow-22)/2))
	leftOutput=$(printf "%-${leftNum}s" '#')
	leftOutput="${leftOutput// /#}\033[32m请输入服务器序号或标识\033[0m"
	rightNum=$(($terminalRow-$leftNum-22))
	rightOutput=$(printf "%-${rightNum}s" '#')
	echo -e "$leftOutput${rightOutput// /#}"
}

#输出末行
function OutputLast() {
	rowOutput=$(printf "%-${terminalRow}s" '#')
	echo "${rowOutput// /#}"
}

#登录菜单
function LoginMenu(){
	if [  ! -n $1 ]; then
		AutoLogin $1
	else
		ConfigList
		echo "请输入服务器序号或标识"
	fi
}

#查找服务器编号
function FindServerNum() {
	unset serverNum;
	for ((i=0;i<${SERVER_LENGTH};i++));
	do
		SERVER=(${SERVERS[$i]}) #将一维sites字符串赋值到数组
		if [[ $serverMark = ${SERVER[1]} ]]
		then
			serverNum=$(($i+1));
			break
		fi
	done

	if [ -z $serverNum ]
	then
		if [[ $serverMark =~ ^-?[0-9]+$ ]];
		then
			serverNum=$serverMark;
		else
			serverNum='';
		fi
	fi
}

#选择登录的服务器
function ChooseServer(){
	read serverMark
	FindServerNum

	if [[ $serverNum -gt $SERVER_LENGTH ]] ;
	then
		echo "序号或标识错误，请重新输入:"
		ChooseServer ;
		return ;
	fi
	if [[ $serverNum -lt 1 ]] ;
	then
		echo "序号或标识错误，请重新输入:"
		ChooseServer ;
		return ;
	fi

	AutoLogin $serverNum;
}

#自动登录
function AutoLogin(){

	num=$(($1-1))
	SERVER=(${SERVERS[$num]})
	echo "正在登录【${SERVER[0]}】"

	command="
	expect {
	\"*assword\" {set timeout 6000; send \"${SERVER[5]}\n\"; exp_continue ; sleep 3; }
	\"*passphrase\" {set timeout 6000; send \"${SERVER[5]}\r\n\"; exp_continue ; sleep 3; }
	\"yes/no\" {send \"yes\n\"; exp_continue;}
	\"Last*\" {  send_user \"\n登录【${SERVER[0]}】\n\";}
	}
	interact
	";
	pem=${SERVER[6]}
	if [ -n "$pem" ]
	then
		expect -c "
		spawn ssh -p ${SERVER[2]} -i ${SERVER[6]} ${SERVER[4]}@${SERVER[3]}
		${command}
		"
	else
		expect -c "
		spawn ssh -p ${SERVER[2]} ${SERVER[4]}@${SERVER[3]}
		${command}
		"
	fi
	echo "您已退出【${SERVER[0]}】"

}

# 程序入口
Init;
if [ 1 == $# ]; then
	if [ 'list' == $1 ]; then
		ConfigList
	else
		AutoLogin $1
	fi
else
	LoginMenu 
	ChooseServer 
fi
