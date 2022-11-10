#!/bin/sh

mkdir -p "$HOME"/.kube
echo "$INPUT_KUBECONFIG" | base64 -d > "$HOME"/.kube/config

kubectl config view --minify
kubectl config current-context

cd deployment || exit 1

# Creating namespace if necessary
kubectl create namespace "$HELM_K8S_NAMESPACE" || true

# Setup our helm args
export HELM_EXTRA_ARGS="$HELM_EXTRA_ARGS \
  --set image.tag=$HELM_IMAGE_TAG \
  --set global.image.tag=$HELM_IMAGE_TAG \
  --set global.namespace=$HELM_K8S_NAMESPACE";

# Iterate through all our deployments
for CURRENT_HELM_CHART in $(ls -d */ | grep -Evi "helm_value_files|templates" | tr '/' ' '); do

  echo "Update our helm chart dependencies"
  helm dependency update "$CURRENT_HELM_CHART" || true

  # Discover values files
  VALUES_ENV_FILE=`find $CURRENT_HELM_CHART -name values-${HELM_ENVIRONMENT_SLUG}.yaml`
  VALUES_FILE_ARGS="-f $CURRENT_HELM_CHART/values.yaml${VALUES_ENV_FILE:+ -f $VALUES_ENV_FILE}"

  echo "--- HELM DIFF ---"
  helm diff upgrade --allow-unreleased --namespace "$HELM_K8S_NAMESPACE" "$HELM_UPDIFF_EXTRA_ARGS" "$CURRENT_HELM_CHART" ./"$CURRENT_HELM_CHART" \
    "$VALUES_FILE_ARGS" \
    "$HELM_EXTRA_ARGS"

  if [ "$HELM_DRY_RUN" = "false" ]; then
    echo "--- HELM UPGRADE ---"
    helm upgrade --install --atomic --namespace "$HELM_K8S_NAMESPACE" "$CURRENT_HELM_CHART" ./"$CURRENT_HELM_CHART" \
      "$VALUES_FILE_ARGS" \
      "$HELM_EXTRA_ARGS"
  fi
done
