#!/bin/bash

# Usage: ./print-markdown.sh filename.md
# Converts a Markdown file to PDF and sends it to the default printer.

set -e

# Check for input file
if [ $# -ne 1 ]; then
  echo "Usage: $0 filename.md"
  exit 1
fi

MD_FILE="$1"
PDF_FILE="${MD_FILE%.md}.pdf"

# Install pandoc and wkhtmltopdf if not present
if ! command -v pandoc &> /dev/null; then
  echo "Installing pandoc..."
  sudo apt-get update && sudo apt-get install -y pandoc
fi

if ! command -v wkhtmltopdf &> /dev/null; then
  echo "Installing wkhtmltopdf..."
  sudo apt-get update && sudo apt-get install -y wkhtmltopdf
fi

# Convert Markdown to PDF
pandoc "$MD_FILE" -o "$PDF_FILE" --pdf-engine=wkhtmltopdf


echo "Printed $PDF_FILE"
