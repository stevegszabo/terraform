# attestation

```
GCLOUD_PROJECT_ID=project-01-xxxxxx
GCLOUD_REGION=northamerica-northeast2
GCLOUD_REGISTRY=northamerica-northeast2-docker.pkg.dev
GCLOUD_REPOSITORY=gar-01
GCLOUD_IMAGE=webapp@sha256:18fa2ec16e378d9f84ef98bd48f588bba067dae70e0dbe6605f141ab7fbf172d
GCLOUD_KEYRING=kms-01
GCLOUD_KEY=kms-01-attestor
GCLOUD_ATTESTOR=gke-01
GCLOUD_PAYLOAD=/tmp/payload.json
GCLOUD_SIGNATURE=/tmp/signature

GCLOUD_HEADER="Authorization: Bearer $(gcloud auth print-access-token)"
GCLOUD_ARTIFACT=$GCLOUD_REGISTRY/$GCLOUD_PROJECT_ID/$GCLOUD_REPOSITORY/$GCLOUD_IMAGE
GCLOUD_PUBLIC_KEY_ID=$(gcloud container binauthz attestors describe --project=$GCLOUD_PROJECT_ID $GCLOUD_ATTESTOR --format=json | jq -r .userOwnedGrafeasNote.publicKeys[0].id)
GCLOUD_OCCURRENCE=$(gcloud container binauthz attestations list --attestor-project=$GCLOUD_PROJECT_ID --attestor=$GCLOUD_ATTESTOR --format=json | jq -r .[0].name)
GCLOUD_OCCURRENCE_URL=https://containeranalysis.googleapis.com/v1beta1/$GCLOUD_OCCURRENCE

[ $GCLOUD_OCCURRENCE != null ] && curl -H "$GCLOUD_HEADER" -X DELETE $GCLOUD_OCCURRENCE_URL

gcloud container binauthz create-signature-payload \
--artifact-url=$GCLOUD_ARTIFACT > $GCLOUD_PAYLOAD

gcloud kms asymmetric-sign \
--project=$GCLOUD_PROJECT_ID \
--location=$GCLOUD_REGION \
--keyring=$GCLOUD_KEYRING \
--key=$GCLOUD_KEY \
--version=1 \
--digest-algorithm=sha512 \
--input-file=$GCLOUD_PAYLOAD \
--signature-file=$GCLOUD_SIGNATURE

gcloud container binauthz attestations create \
--project=$GCLOUD_PROJECT_ID \
--attestor=projects/$GCLOUD_PROJECT_ID/attestors/$GCLOUD_ATTESTOR \
--artifact-url=$GCLOUD_ARTIFACT \
--public-key-id=$GCLOUD_PUBLIC_KEY_ID \
--signature-file=$GCLOUD_SIGNATURE \
--validate

gcloud container binauthz attestations list \
--attestor-project=$GCLOUD_PROJECT_ID \
--attestor=$GCLOUD_ATTESTOR
```