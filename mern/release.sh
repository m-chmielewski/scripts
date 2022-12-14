###Shared
echo Choose project:
ls ~/dev

read projectName

echo Choose destination env:
echo dev'\t'prod

read destinationEnv

. ~/dev/$projectName/release.config

if [ $destinationEnv = 'dev' ]
then
 domain=$devDomain
 backendDotEnvFolder=dev
 frontendDotEnvFolder=remoteDev
else
 domain=$prodDomain
 backendDotEnvFolder=prod
 frontendDotEnvFolder=prod
fi


ssh $remote "rm -rf ~/domains/$domain/public_nodejs/*"

ssh $remote "mkdir ~/domains/$domain/public_nodejs/client"

###Frontend

cd ~/dev/$projectName/$projectName-frontend

rm ~/dev/$projectName/$projectName-frontend/.env

cp ~/dev/$projectName/envs/frontend/$frontendDotEnvFolder/.env ~/dev/$projectName/$projectName-frontend/

npm run build

scp -r ~/dev/$projectName/$projectName-frontend/build/* $remote:~/domains/$domain/public_nodejs/client

rm -rf ~/dev/$projectName/$projectName-frontend/build

rm ~/dev/$projectName/$projectName-frontend/.env

cp ~/dev/$projectName/envs/frontend/localDev/.env ~/dev/$projectName/$projectName-frontend/

###Backend

mv ~/dev/$projectName/$projectName-backend/node_modules ~/dev/$projectName/tempContainer

mv ~/dev/$projectName/$projectName-backend/package-lock.json ~/dev/$projectName/tempContainer

scp -r ~/dev/$projectName/$projectName-backend/* $remote:~/domains/$domain/public_nodejs

###I should try to use -al flag in previous step and get rid of this one
scp -r ~/dev/$projectName/envs/backend/$backendDotEnvFolder/.env $remote:~/domains/$domain/public_nodejs

mv ~/dev/$projectName/tempContainer/* ~/dev/$projectName/$projectName-backend

###Shared

ssh $remote "cd ~/domains/$domain/public_nodejs && npm install"

ssh $remote "devil www restart $domain"
