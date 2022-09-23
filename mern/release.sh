###Shared

echo Choose project:
ls ~/dev

read projectName

. ~/dev/$projectName/release.config

ssh $remote "rm -rf ~/domains/$domain/public_nodejs/*"

ssh $remote "mkdir ~/domains/$domain/public_nodejs/client"

###Frontend

cd ~/dev/$projectName/$projectName-frontend

rm ~/dev/$projectName/$projectName-frontend/.env

cp ~/dev/$projectName/envs/frontend/remoteDev/.env ~/dev/$projectName/$projectName-frontend/

npm run build

rm ~/dev/$projectName/$projectName-frontend/.env

cp ~/dev/$projectName/envs/frontend/localDev/.env ~/dev/$projectName/$projectName-frontend/

cd ~/scripts/mern

scp -r ~/dev/$projectName/$projectName-frontend/build/* $remote:~/domains/$domain/public_nodejs/client

###Backend

mv ~/dev/$projectName/$projectName-backend/node_modules ~/dev/$projectName/tempContainer

mv ~/dev/$projectName/$projectName-backend/.gitignore ~/dev/$projectName/tempContainer

mv ~/dev/$projectName/$projectName-backend/package-lock.json ~/dev/$projectName/tempContainer

scp -r ~/dev/$projectName/$projectName-backend/* $remote:~/domains/$domain/public_nodejs

scp -r ~/dev/$projectName/envs/backend/dev/.env $remote:~/domains/$domain/public_nodejs

mv ~/dev/$projectName/tempContainer/* ~/dev/$projectName/$projectName-backend

mv ~/dev/$projectName/tempContainer/.gitignore ~/dev/$projectName/$projectName-backend

###Shared

ssh $remote "cd ~/domains/$domain/public_nodejs && npm install"

ssh $remote "devil www restart $domain"
