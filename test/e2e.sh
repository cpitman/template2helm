#!/usr/bin/env bash

failures=0

for test in $(find ./examples/ -maxdepth 1 -mindepth 1 -type f); do
  echo "Testing $test"
  # create staging director for results
  ARTIFACT_DIR=/tmp/test/$test
  mkdir -p $ARTIFACT_DIR
  # get output of the template
  oc process --local -f $test -o yaml | yq -S .items[] > $ARTIFACT_DIR/oc-process-sorted.yaml
  # convert template to chart
  template2helm convert --template $test --chart $ARTIFACT_DIR/charts > /dev/null
  # find newly created chart
  chart=$(ls -td $ARTIFACT_DIR/charts/*/ | head -1)
  echo "Resulting chart: $chart"
  # get output of chart
  helm template $chart | yq -S . > $ARTIFACT_DIR/helm-process-sorted.yaml
  # compare resources produced
  gap=$(diff $ARTIFACT_DIR/oc-process-sorted.yaml $ARTIFACT_DIR/helm-process-sorted.yaml)
  if [[ "${gap}x" != "x" ]]; then
    >&2 echo "Test Failed!"
    >&2 echo "${gap}"
    failures=$((failures+1))
  else
    echo "Passed!"
  fi

  echo
  echo
done

if [[ $failures > 0 ]]; then
  echo "$failures Tests Failed"
  exit $failures
fi
