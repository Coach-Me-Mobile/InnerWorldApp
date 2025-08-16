#!/usr/bin/env bash

# ==============================================================================
# SIMPLE S3 ASSET UPLOAD (NO CLOUDFRONT)
# ==============================================================================
# Simplified version without CloudFront invalidation complexity
# Use this if you don't need cache invalidation
# ==============================================================================

set -e

# Configuration
AWS_REGION="us-west-2"
AWS_PROFILE="${AWS_PROFILE:-default}"
ENVIRONMENT="prod"
TARGET_PREFIX="assets/"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

get_bucket_name() {
    local env=$1
    case "$env" in
        prod) echo "innerworld-prod-app-assets" ;;
        *) echo "" ;;
    esac
}

print_usage() {
    echo -e "${BLUE}📱 Simple S3 Asset Upload${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] <directory_path>"
    echo ""
    echo "Options:"
    echo "  -e, --env ENV        Environment (only 'prod' available) [default: prod]"
    echo "  -t, --target PATH    Target S3 path prefix [default: assets/]"
    echo "  -d, --dry-run        Show what would be uploaded"
    echo "  -h, --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 ./my-assets/                    # Upload to dev"
    echo "  $0 -e prod ./assets/               # Upload to production"
    echo "  $0 -t images/ ./icon-files/        # Upload to 'images/' prefix"
}

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env) ENVIRONMENT="$2"; shift 2 ;;
        -t|--target) TARGET_PREFIX="$2"; shift 2 ;;
        -d|--dry-run) DRY_RUN="true"; shift ;;
        -h|--help) print_usage; exit 0 ;;
        -*) log_error "Unknown option: $1"; exit 1 ;;
        *) SOURCE_DIR="$1"; shift ;;
    esac
done

# Validate
if [[ -z "$SOURCE_DIR" ]]; then
    log_error "Source directory required"
    print_usage
    exit 1
fi

BUCKET=$(get_bucket_name "$ENVIRONMENT")
if [[ -z "$BUCKET" ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

# Upload
log_info "Uploading to s3://$BUCKET/$TARGET_PREFIX"

if [[ "$DRY_RUN" == "true" ]]; then
    aws s3 sync "$SOURCE_DIR" "s3://$BUCKET/$TARGET_PREFIX" \
        --profile "$AWS_PROFILE" \
        --dryrun
else
    aws s3 sync "$SOURCE_DIR" "s3://$BUCKET/$TARGET_PREFIX" \
        --profile "$AWS_PROFILE" \
        --delete
    
    log_success "Upload completed!"
    
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        log_info "Note: Production uses CloudFront CDN"
        log_info "Assets may take up to 24 hours to update globally"
        log_info "For immediate updates, use the full upload script with -c flag"
    fi
fi
