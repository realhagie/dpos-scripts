#!/bin/bash
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }
APINODE="https://wallet.rise.vision/"
MAXDELEGATES=`curl -s $APINODE/api/delegates?limit=1 | jq .totalCount`
SECRET="<ENTER SEVRET OF PAYING ACCOUNT HERE>"
SECSECRET="<ENTER SECOND SCRET HERE>"
#Amount of transaction * 10^8. Example: to send 1.1234 RISE, use 112340000 as amount */,
#Set to 15 RISE
SENDAMOUNT="1500000000"
OFFSET=0

echo Amount of Delegates on Blockchain: $MAXDELEGATES

# first batch of delegates
echo get delegate $((1+$OFFSET)) up to $((100+$OFFSET)) of $MAXDELEGATES
DELLINES=`curl -s $APINODE/api/delegates?limit=100\&offset=$OFFSET | jq '.delegates[] .address'`
let OFFSET=$OFFSET+100

while [ $OFFSET -le $MAXDELEGATES ]
do
echo get delegate $((1+$OFFSET)) up to $((100+$OFFSET)) of $MAXDELEGATES

DELLINES=$DELLINES"\n"`curl -s $APINODE/api/delegates?limit=100\&offset=$OFFSET | jq '.delegates[] .address'`
DELLINES=`echo -e "$DELLINES"`
let OFFSET=$OFFSET+100
done

echo have `echo "$DELLINES" | wc -l` Delegates in the queue

read -p "Are you sure to send $(($SENDAMOUNT/100000000)) to $MAXDELEGATES Delegates? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit
fi

for VAR in $DELLINES
do
echo "Pay $(($SENDAMOUNT/100000000)) to $VAR"
HEADER="Content-Type: application/json"

if [ -z "$SECSECRET" ]; then 
	BODY="{\"secret\":\"$SECRET\",\"amount\":$SENDAMOUNT,\"recipientId\":"$VAR"}"
else
	BODY="{\"secret\":\"$SECRET\",\"secondSecret\":\"$SECSECRET\",\"amount\":$SENDAMOUNT,\"recipientId\":"$VAR"}"
fi

curl -s -k -H "$HEADER" -X PUT -d "$BODY" "$APINODE/api/transactions" | jq 
sleep 0.5
done
