startDir=$(pwd)

echo Choose project:
ls ~/dev

read projectName

cd ~/packages/common

curVersion=$(cat package.json | jq -r ".version")

echo CurVersion:$curVersion

patch=$(echo $curVersion | cut -d "." -f 3)

echo patch:$patch

newPatch=$(($patch+1))

echo newPatch:$newPatch

newVersion=0.1.$newPatch

newPackageContent=$(jq '.version = $v' --arg v $newVersion ./package.json)

rm ./package.json

echo $newPackageContent >> ./package.json

npm run build

npm publish --access public

cd ~/dev/$projectName/$projectName-frontend

npm update @mchm/common

cd $startDir