### variables
remote=kuc@s0.small.pl

dbNamePrefix=mo1837_

backendPort=$(cat ~/ports/backend.txt)

rm ~/ports/backend.txt

nextBackendPort=$(($backendPort+1))

cat <<EOF >~/ports/backend.txt
$nextBackendPort
EOF

frontendPort=$(cat ~/ports/frontend.txt)

rm ~/ports/frontend.txt

nextFrontendPort=$(($frontendPort+1))

cat <<EOF >~/ports/frontend.txt
$nextFrontendPort
EOF

echo 'Provide app name'

read appName

echo 'Provide db name [< 8 chars]:'

read dbName

##domain
ssh $remote "devil www add $appName.dev.mchm.pl nodejs /usr/local/bin/node16 development"

ssh $remote "devil www add $appName.mchm.pl nodejs /usr/local/bin/node16 production"

ssh $remote "devil dns add mchm.pl $appName.dev.mchm.pl  A 128.204.218.180 3600"

ssh $remote "devil dns add mchm.pl $appName.mchm.pl  A 128.204.218.180 3600"

ssh $remote "devil ssl www add 128.204.218.180 le le $appName.dev.mchm.pl"

ssh $remote "devil ssl www add 128.204.218.180 le le $appName.mchm.pl"

ssh $remote "devil www options $appName.dev.mchm.pl sslonly on"

ssh $remote "devil www options $appName.mchm.pl sslonly on"

# ##DB
dbDevPass=$(openssl rand -base64 20)

dbProdPass=$(openssl rand -base64 20)

echo "$dbDevPass\n$dbDevPass" | ssh $remote "devil mongo db add $dbName-d"

echo "$dbProdPass\n$dbProdPass" | ssh $remote "devil mongo db add $dbName-p"

### local setup
mkdir ~/dev/$appName

mkdir ~/dev/$appName/$appName-backend

mkdir ~/dev/$appName/tempContainer

mkdir ~/dev/$appName/envs

mkdir ~/dev/$appName/envs/backend

mkdir ~/dev/$appName/envs/backend/prod

mkdir ~/dev/$appName/envs/backend/dev

mkdir ~/dev/$appName/envs/frontend

mkdir ~/dev/$appName/envs/frontend/prod

mkdir ~/dev/$appName/envs/frontend/remoteDev

mkdir ~/dev/$appName/envs/frontend/localDev

cat <<EOF >~/dev/$appName/release.config
remote=$remote
domain=$appName.dev.mchm.pl
EOF

#backend
cd ~/dev/$appName/$appName-backend

npm init -y

#replace default entry point index.js with app.js - hosting accepts only app.js
newPackageContent=$(jq '.main="app.js"' ~/dev/$appName/$appName-backend/package.json)

rm ~/dev/$appName/$appName-backend/package.json

echo $newPackageContent >> ~/dev/$appName/$appName-backend/package.json

npm install express

npm install mongodb

npm install cors

npm install dotenv

cp ~/templates/express/* ~/dev/$appName/$appName-backend/

cp ~/templates/express/.gitignore ~/dev/$appName/$appName-backend/

cat <<EOF >~/dev/$appName/envs/backend/dev/.env
DB_NAME=$dbNamePrefix$dbName-d
DB_HOST=mongo0.small.pl
DB_PASS=$dbDevPass
PORT=$backendPort
EOF

cat <<EOF >~/dev/$appName/envs/backend/prod/.env
DB_NAME=$dbNamePrefix$dbName-p
DB_HOST=mongo0.small.pl
DB_PASS=$dbProdPass
PORT=$backendPort
EOF

cp ~/dev/$appName/envs/backend/dev/.env ~/dev/$appName/$appName-backend/

## Frontend
cd ~/dev/$appName

npx create-react-app $appName-frontend

cd ~/dev/$appName/$appName-frontend

rm ./public/index.html

cp ~/templates/react/index.html ./public

rm ./src/App.css

rm ./src/index.css

rm ./src/logo.svg

npm install react-router-dom

rm ./src/App.js

cp ~/templates/react/App.js ./src

rm ./src/reportWebVitals.js

mkdir ./src/Pages

cp ~/templates/react/Home.js ./src/Pages

cp ~/templates/react/Shared.css ./src

rm ./src/index.js

cp ~/templates/react/index.js ./src

rm ./src/setupTests.js

rm ./src/App.test.js

cat <<EOF >~/dev/$appName/envs/frontend/localDev/.env
PORT=$frontendPort
REACT_APP_BACKEND_URL=http://localhost:$backendPort/backend
EOF

cat <<EOF >~/dev/$appName/envs/frontend/remoteDev/.env
REACT_APP_BACKEND_URL=https://$appName.dev.mchm.pl/backend
EOF

cat <<EOF >~/dev/$appName/envs/frontend/prod/.env
REACT_APP_BACKEND_URL=https://$appName.mchm.pl/backend
EOF

echo ".env" >> ~/dev/$appName/$appName-frontend/.gitignore

cp ~/dev/$appName/envs/frontend/localDev/.env ~/dev/$appName/$appName-frontend/

## GitHub
#frontend
cd ~/dev/$appName/$appName-frontend

gh repo create $appName-frontend --public

git remote add origin git@github.com:m-chmielewski/$appName-frontend.git

git add -A

git commit -m 'Initial commit'

git push --set-upstream origin master

#backend
cd ~/dev/$appName/$appName-backend

git init

gh repo create $appName-backend --public

git remote add origin git@github.com:m-chmielewski/$appName-backend.git

git add -A

git commit -m 'Initial commit'

git push --set-upstream origin master

cd ~/scripts/mern