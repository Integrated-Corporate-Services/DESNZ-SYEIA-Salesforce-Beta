#!/bin/bash

# Exit immediately if any command fails
set -e

# Variables
PMD_VERSION="6.55.0"
PMD_DIR="pmd-bin-${PMD_VERSION}"
PMD_ZIP="${PMD_DIR}.zip"
PMD_URL="https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/${PMD_ZIP}"

# Download PMD if not already downloaded
if [ ! -d "$PMD_DIR" ]; then
  echo "Downloading PMD ${PMD_VERSION}..."
  curl -sL -o "$PMD_ZIP" "$PMD_URL"
  unzip -q "$PMD_ZIP"
fi

# Run PMD on the force-app directory
echo "Running PMD on force-app..."
./${PMD_DIR}/bin/run.sh pmd \
  -d force-app \
  -R category/apex/design.xml \
  -f text \
  -language apex

# Optional: output report to file
# -f xml -r pmd-report.xml
