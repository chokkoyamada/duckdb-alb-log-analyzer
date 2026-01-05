#!/bin/bash
# Helper script to load AWS credentials from a named profile
# Usage: source scripts/load_profile.sh <profile-name>

if [ -z "$1" ]; then
    echo "Usage: source $0 <profile-name>"
    echo ""
    echo "Available profiles:"
    aws configure list-profiles 2>/dev/null || echo "  (aws CLI not configured)"
    return 1 2>/dev/null || exit 1
fi

PROFILE_NAME="$1"

# Check if profile exists
if ! aws configure get aws_access_key_id --profile "$PROFILE_NAME" >/dev/null 2>&1; then
    echo "Error: Profile '$PROFILE_NAME' not found"
    echo ""
    echo "Available profiles:"
    aws configure list-profiles
    return 1 2>/dev/null || exit 1
fi

# Export credentials from profile
export AWS_PROFILE="$PROFILE_NAME"
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$PROFILE_NAME")
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$PROFILE_NAME")
export AWS_DEFAULT_REGION=$(aws configure get region --profile "$PROFILE_NAME")

echo "✅ Loaded credentials from profile: $PROFILE_NAME"
echo "   AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:10}..."
echo "   AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"
echo ""
echo "You can now run:"
echo "  ./scripts/analyze.sh setup-env"
echo "  ./scripts/analyze.sh load 's3://bucket/path/**/*.log.gz'"
