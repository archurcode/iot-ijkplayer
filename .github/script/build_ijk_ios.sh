#!/bin/sh
#set -eo pipefail
set -e

#rtt=$GIT_BRANCH_IMAGE_VERSION
#rb=$(git rev-parse --abbrev-ref HEAD)
rc=$(git rev-parse --short HEAD)
currtag=$(git describe --tags `git rev-list --tags --max-count=1`)
echo 000---$currtag

./init-ios.sh
./init-ios-openssl.sh

# 1.准备编译
cd ios

#2. 开始编译支持https
./compile-openssl.sh clean
./compile-ffmpeg.sh clean

./compile-openssl.sh arm64
./compile-ffmpeg.sh arm64

cd IJKMediaPlayer


# 2.编译iOS平台工程配置
xcodebuild build -project IJKMediaPlayer.xcodeproj -scheme IJKMediaFramework -configuration Release -sdk iphoneos -derivedDataPath ./build



#3.将编译的结果pod发布
git clone https://$GIT_ACCESS_TOKEN@github.com/tencentyun/iot-thirdparty-ios.git
cd iot-thirdparty-ios


rm -rf Source/IJKPlayer-iOS/IJKMediaFramework.framework
mv ../build/Build/Products/Release-iphoneos/IJKMediaFramework.framework  Source/IJKPlayer-iOS


poddatetime=$(date '+%Y%m%d%H%M')
echo $poddatetime

git add .
git commit -m "tencentyun/iot-ijkplayer@$rc"
git push https://$GIT_ACCESS_TOKEN@github.com/tencentyun/iot-thirdparty-ios.git

# ==========此处添加版本自增逻辑，如果是持续集成发snapshot，最新tag+1；如果是发布就发branch

temptag=$(git describe --tags `git rev-list --tags --max-count=1`)
vtaglist=(${temptag//-/ })
beta=${vtaglist[1]}
version=${vtaglist[0]}
resultvv=${version#*v}
echo "-->>$resultvv"

if [ $1 == 'Debug' ]; then
    git tag "$resultvv-beta.$poddatetime"
else
    vtag=${currtag#*v}
    git tag "$vtag"
fi
# ==========此处添加版本自增逻辑，如果是持续集成发snapshot，最新tag+1；如果是发布就发branch

git push https://$GIT_ACCESS_TOKEN@github.com/tencentyun/iot-thirdparty-ios.git --tags
