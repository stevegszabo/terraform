# cloud run

```
GCLOUD_WEBAPP_SERVICE=https://webapp-xxxxxxxxxx-pd.a.run.app/
GCLOUD_ACCESS_TOKEN=$(gcloud auth print-identity-token --audiences=$GCLOUD_WEBAPP_SERVICE)

curl -H "Authorization: Bearer $GCLOUD_ACCESS_TOKEN" $GCLOUD_WEBAPP_SERVICE
```
