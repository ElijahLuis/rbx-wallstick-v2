git fetch origin pull/$PR_NUMBER/head:$BRANCH_NAME
git checkout $BRANCH_NAME
git branch --set-upstream-to=origin/$BRANCH_NAME $BRANCH_NAME || echo "⚠️ Could not set upstream."
rojo serve
