#!/bin/sh
################ Version Info ##################
# Create Date: 2019-11-11
# Version:     0.0.1
# Description: 自动重签名脚本
################################################

# 静态常量
VERSION="0.0.1"
HELP_DESCRIPTION="你可以输入 \"-h\" 或者 \"--help\" 查看可用命令。"

# 常用方法

# help 帮助命令查看
printHelpLog(){
  echo ""
  echo "支持以下命令：";
  echo ""
  echo " 必选命令："
  echo " -path                            待重签名的iPA包地址"
  echo " -amb|--appmobileprovision        重签名所需要的应用描述文件"
  echo ""
  echo " 可选命令:"
  echo " -dt|--developteam                输入开发者团队名称，注意：团队名称可能存在空格，建议名称加上双引号";
  echo " -appname                         新的app名称"
  echo " -appversion                      新的app版本号"
  echo " -appexmb|--appexmobileprovision  新的拓展应用重签名所需要的描述文件，注意：该描述文件的名称前缀需要和拓展应用的名称保持一致，例如：拓展应用名\"CallIdentification\",新的描述文件则为\"CallIdentification.mobileprovision\""
  echo " -output                          重签名后的iPA包输出目录";
  echo " -h|--help                        查看帮助信息";
  echo " -v|--version                     查看版本信息";
  echo ""
}

# 打印版本信息
printVersionLog(){
    echo "工具名称：Epoint快速重签名"
    echo "当前版本：${VERSION}"
}

# 检查当前环境是否可以进行重签名
checkCurrentEnviroment(){
  #  security
  command -v security >/dev/null 2>&1 || { echo >&2 "security 命令不存在，请确认当前系统是否存在该命令"; exit 1; }
  #  /usr/libexec/PlistBuddy
  command -v /usr/libexec/PlistBuddy >/dev/null 2>&1 || { echo >&2 "/usr/libexec/PlistBuddy 命令不存在，请确认当前系统是否存在该命令"; exit 1; }
  #  codesign
  command -v codesign >/dev/null 2>&1 || { echo >&2 "codesign 命令不存在，请确认当前系统是否存在该命令"; exit 1; }
  #  zip
  command -v zip >/dev/null 2>&1 || { echo >&2 "zip 命令不存在，请确认当前系统是否存在该命令"; exit 1; }
  #  unzip
  command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip 命令不存在，请确认当前系统是否存在该命令"; exit 1; }
}

# 参数
PARAM_DEVELOPTEAM="" # 开发团队名称
PARAM_IPA_PATH="" # 原始IPA包地址
PARAM_APPMOBILEPROVISION="" # 应用重签名所需要的描述文件
PARAM_OUTPUT=$(pwd) # 签名成功后的输出目录

APPEXMBP_INDEX=0
APPEXMBP_TMP_PATH=""
PARAM_APPEXMOBILEPROVISION=() # 拓展应用重签名所需要的描述文件

PARAM_APPNAME=""; # 重签名后App的名称
PARAM_APPVERSION=""; # 重签名后App的版本号

# 检查环境
checkCurrentEnviroment

# 解析命令条件
while [ -n "$1" ]
do
	case "$1" in
    -h|--help)
      printHelpLog
      exit 1
      shift;;
    -v|--version)
      printVersionLog
      exit 1
      shift;;
    -dt|--developteam) PARAM_DEVELOPTEAM="$2"
      shift;;
    -path) PARAM_IPA_PATH="$2"
      shift;;
    -amb|--appmobileprovision) PARAM_APPMOBILEPROVISION="$2"
      shift;;
    -appexmb|--appexmobileprovision) APPEXMBP_TMP_PATH="$2"
      PARAM_APPEXMOBILEPROVISION[APPEXMBP_INDEX]=$APPEXMBP_TMP_PATH;
      APPEXMBP_INDEX=`expr $APPEXMBP_INDEX+1`;
      shift;;
    -output) PARAM_OUTPUT="$2"
      shift;;
    -appname) PARAM_APPNAME="$2"
      shift;;
    -appversion) PARAM_APPVERSION="$2"
      shift;;
    *) echo "$1 无法识别指令，${HELP_DESCRIPTION}"
      # 识别到未知命令退出脚本
      exit 1
      ;;
    esac
	shift
done


# 创建临时目录
ROOT_PATH=$(pwd)
DIR_TMP_PATH="${ROOT_PATH}/temp"
DIR_ENTITLEMENTS_TMP_PATH="${ROOT_PATH}/entitlementsTemp"


# 删除旧目录并创建临时目录
rm -rf $DIR_ENTITLEMENTS_TMP_PATH
mkdir $DIR_ENTITLEMENTS_TMP_PATH

rm -rf $DIR_TMP_PATH
mkdir $DIR_TMP_PATH



# 检查必选参数
if [[ $PARAM_IPA_PATH == "" ]]
  then
    rm -rf $DIR_ENTITLEMENTS_TMP_PATH
    rm -rf $DIR_TMP_PATH
    echo "--path 待重签名的iPA地址必须指明！${HELP_DESCRIPTION}"
    exit 1
fi

if [[ $PARAM_APPMOBILEPROVISION == "" ]]
  then
    rm -rf $DIR_ENTITLEMENTS_TMP_PATH
    rm -rf $DIR_TMP_PATH
    echo "--appmobileprovision 新的描述地址必须指明！${HELP_DESCRIPTION}"
    exit 1
fi

# 从新描述文件中获取团队名称
if [[ $PARAM_DEVELOPTEAM == "" ]]
   then
       _tmp="${DIR_ENTITLEMENTS_TMP_PATH}/info.plist"
       security cms -D -i "${PARAM_APPMOBILEPROVISION}" > "${_tmp}"
       PARAM_DEVELOPTEAM=$(/usr/libexec/PlistBuddy -c 'Print :TeamName' "${_tmp}")
fi


# 解压ipa到temp目录
unzip -d $DIR_TMP_PATH $PARAM_IPA_PATH
#
## 获取应用名称
APP_ORIGIN_PATH="${DIR_TMP_PATH}/Payload"
APP_NAME=$(ls $APP_ORIGIN_PATH)

# 递归遍历目录
recursivePath(){
  local _path=$1;
  for item in $(ls "$_path")
  do
    local subPath="${_path}/${item}";


    if [[ ${item} =~ '.appex' ]];
        then
          # 对应用拓展进行重签名
          reSignAppex "${subPath}" $item
#    elif [[ ${item} =~ '.framework' ]];
#        then
#          # 对framework进行重签名
#          echo $item
    else
        if [ -d "$subPath" ];
          then
            recursivePath $subPath
        fi
    fi
  done
}

# 从描述文件中提取完整plist文件
_getPlistFile(){
  local _path=$1
  local _name=$2
  local originMobileprovisionPath="${_path}/embedded.mobileprovision"
  local tempEntitle="${DIR_ENTITLEMENTS_TMP_PATH}/${_name}_temp.plist"
  local entitle="${DIR_ENTITLEMENTS_TMP_PATH}/${_name}.plist"
  security cms -D -i "$originMobileprovisionPath" > "${tempEntitle}"
  # 提取 Entitlements 字段
  /usr/libexec/PlistBuddy -x -c 'Print:Entitlements' $tempEntitle > $entitle
}

# 重签名拓展应用
reSignAppex(){
  local _path=$1
  local _appexName=$2
  local _tmpMbArray=(${_appexName/./ })
  local _tmpMbName=${_tmpMbArray[0]}

  # 把新的描述文件替换旧版描述文件
  local _mbPath="${_path}/embedded.mobileprovision";
  rm -rf _mbPath

  for index in $(seq 0 ${#PARAM_APPEXMOBILEPROVISION[@]})
  do
      local appexMb=${PARAM_APPEXMOBILEPROVISION[index]}
      local _tmpStrArray=(${appexMb//// })
      local last=${#_tmpStrArray[@]}
      ((last-=1))
      if [ $last -ge 0 ]
      then
        local _newAppexMb=${_tmpStrArray[last]}
        if [[ $_newAppexMb =~ $_tmpMbName ]];
        then
            # 复制新的文件到目标目录
            cp $appexMb $_mbPath
            break
        fi
      fi
    done

  _getPlistFile $_path $_tmpMbName
  local _plistPath="${DIR_ENTITLEMENTS_TMP_PATH}/${_tmpMbName}.plist";
  echo $PARAM_DEVELOPTEAM
  echo $_plistPath
  echo $_path
  codesign -f -s "${PARAM_DEVELOPTEAM}" --entitlements "${_plistPath}" "${_path}"
}


# 重签名
recursivePath "${APP_ORIGIN_PATH}/${APP_NAME}"

# 对整体App进行重签名
# 删除旧文件，并移动新的描述文件
_ombpath="${APP_ORIGIN_PATH}/${APP_NAME}/embedded.mobileprovision"
rm -rf $_ombpath
cp $PARAM_APPMOBILEPROVISION $_ombpath

# 提取字段
_getPlistFile "${APP_ORIGIN_PATH}/${APP_NAME}" "${APP_NAME}"
_NewPlistPath="${DIR_ENTITLEMENTS_TMP_PATH}/${APP_NAME}.plist";

# 修改App名称
APP_PLIST_PATH="${APP_ORIGIN_PATH}/${APP_NAME}/info.plist"
if [[ $PARAM_APPNAME != ""  ]]
then
    /usr/libexec/PlistBuddy -c "Set CFBundleDisplayName $PARAM_APPNAME" "$APP_PLIST_PATH"
fi

# 修改版本号
if [[ $PARAM_APPVERSION != "" ]]
then
    /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $PARAM_APPVERSION" "$APP_PLIST_PATH"
fi


# 重签名
codesign -f -s "${PARAM_DEVELOPTEAM}" --entitlements "${_NewPlistPath}" "${APP_ORIGIN_PATH}/${APP_NAME}"

# 压缩成新的iPA
cd $APP_ORIGIN_PATH
cd ../
zip -r "New.ipa" ./Payload

_appNameArray=(${APP_NAME/./ })
NOW_DATE_TIME=$(date "+%Y%m%d%H%M%S")
APP_NAME="${_appNameArray[0]}-${NOW_DATE_TIME}.ipa"

# 移动新的iPA
mv "./New.ipa" "${PARAM_OUTPUT}/${APP_NAME}"

# 输出
echo "签名成功..."
echo "目标地址："
echo "${PARAM_OUTPUT}/${APP_NAME}"

# 移除垃圾文件
rm -rf $DIR_ENTITLEMENTS_TMP_PATH
rm -rf $DIR_TMP_PATH

