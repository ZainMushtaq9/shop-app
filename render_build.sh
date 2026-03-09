#!/bin/bash

# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable

# Add flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Configure the project for web (fixes the "not configured for web" error)
flutter create . --platforms web

# Build the web release
flutter build web --release
