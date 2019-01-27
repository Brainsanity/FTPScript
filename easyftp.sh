#!/bin/sh

IP="0.0.0.0"
cuser=""
pw=""

Help()
{
	echo "usage:"
	echo "	$0 [gf|gd|sf|sd] [src] [dest]"
	echo "	gf	get an ASCII file"
	echo "	gbf	get a binary file"
	echo "	gd	get a directory(binary way)"
	echo "	sf	send an ASCII file"
	echo "	sbf	send a binary file"
	echo "	sd	send a directory(binary way)"
}

GetFile()	#$1:src; $2: dest
{
	ftp -n $IP <<FTP_ARG1
		user $cuser $pw
		get $1 $2
		bye
FTP_ARG1
}

GetBFile()
{
	ftp -n $IP <<FTP_ARG
		user $cuser $pw
		binary
		get $1 $2
		bye
FTP_ARG
}

SendFile()	#$1:src; $2:dest
{
	ftp -n $IP <<FTP_ARG2
		user $cuser $pw
		send $1 $2
		bye
FTP_ARG2
}

SendBFile()
{
	ftp -n $IP <<FTP_ARG
		user $cuser $pw
		binary
		send $1 $2
		bye
FTP_ARG
}

MakeDir()
{
	ftp -n $IP <<FTP_ARG3
		user $cuser $pw
		mkdir $1
		bye
FTP_ARG3
}

LsDir()	#save list to /tmp/dirlist; $1:remote dir
{
	ftp -n $IP <<FTP_ARG3 >/tmp/dirlist1
		user $cuser $pw
		ls $1
		bye
FTP_ARG3
	cat /tmp/dirlist1 | while read line
	do
		if [ ${line:0:1} = "-" ]
		then
			echo -n "f" >> /tmp/dirlist
		else
			echo -n ${line:0:1} >> /tmp/dirlist
		fi
		str=${line#*:}
		str=${str//" "/"_"}	#replace all spaces with underlines
		echo -n ${str:3}" " >> /tmp/dirlist
	done
	rm /tmp/dirlist1
}

GetDir()	#$1:remote dir;	$2:local dir
{
	if [ ! -d $2 ]
	then
		echo "Create folder: "$2
		mkdir $2
	fi
	srcdir=$1
	destdir=$2
	LsDir $1
	set `cat /tmp/dirlist` $srcdir   #make sure that it's not empty after set
	rm /tmp/dirlist
	while [ $# -ne 1 ]
	do
		if [ ${1:0:1} = "d" ]
			then
			#echo "Create folder: "$destdir/${1:1}
			#mkdir "$destdir/${1:1}"
			GetDir "$srcdir/${1:1}" "$destdir/${1:1}"
		else
			echo "Copy "$srcdir/${1:1}" to "$destdir/${1:1}
			GetBFile "$srcdir/${1:1}" "$destdir/${1:1}"
		fi
		shift
	done

}

SendDir()
{
	if [ ! -d $1 ]
		then
		echo "Error: $1 is not a valid local directory"
		exit 0
	fi
	srcdir=$1
	destdir=$2
	MakeDir $2
	set `ls $1` $srcdir   #make sure that it's not empty after set
	while [ $# -ne 1 ]
	do
		if [ ! -d "$srcdir/$1" ]
			then
			SendBFile "$srcdir/$1" "$destdir/$1"
		elif [ "$1" != "." -a "$1" != ".." ]
			then
			SendDir "$srcdir/$1" "$destdir/$1"
			srcdir=`echo ${srcdir%/*}` #cut the last "/*" substring
			destdir=`echo ${destdir%/*}`
		fi
		shift
	done
}


if [ $# -ne 3 ]	#wrong argument list
	then
	Help
	exit 0
fi

arg1="$1"
if [ "$arg1" = "gf" ]	#get file
	then
	GetFile "$2" "$3"
elif [ "$arg1" = "gbf" ]
	then
	GetBFile "$2" "$3"
elif [ "$arg1" = "sf" ]
	then
	SendFile $2 $3
elif [ "$arg1" = "sbf" ]
	then
	SendBFile $2 $3
elif [ "$arg1" = "gd" ]
	then
	echo
	GetDir "$2" "$3"
elif [ "$arg1" = "sd" ]
	then
	SendDir "$2" "$3"
else
	Help
fi

echo
exit 0

