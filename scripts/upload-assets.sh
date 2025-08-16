#!/usr/bin/env bash

# ==============================================================================
# INNERWORLD MOBILE APP - ASSET UPLOAD SCRIPT
# ==============================================================================
# Upload assets to S3 bucket for mobile app with proper organization
# Supports multiple environments and automatic CloudFront invalidation
# ==============================================================================

set -e  # Exit on any error

# Ensure we're using bash for associative array support
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Please run with: bash $0 $*"
    exit 1
fi

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# AWS region
AWS_REGION="us-west-2"

# Function to get S3 bucket name for environment
get_bucket_name() {
    local env=$1
    case "$env" in
        prod) echo "innerworld-prod-app-assets" ;;
        *) echo "" ;;
    esac
}

# Function to get CloudFront distribution ID for environment
get_cloudfront_id() {
    local env=$1
    case "$env" in
        dev) echo "" ;;  # Dev uses direct S3 access
        staging) echo "" ;;  # Staging uses direct S3 access
        prod) 
            # Get CloudFront distribution ID from Terraform output or set manually
            # To get ID: terraform output -json | jq -r '.s3.value.cloudfront_distribution_id'
            echo "YOUR_PROD_CLOUDFRONT_DISTRIBUTION_ID" ;;
        *) echo "" ;;
    esac
}

# Default AWS profile (can be overridden)
AWS_PROFILE="${AWS_PROFILE:-default}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

print_usage() {
    echo -e "${BLUE}📱 InnerWorld Asset Upload Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] <directory_path>"
    echo ""
    echo "Options:"
    echo "  -e, --env ENV        Environment (only 'prod' available) [default: prod]"
    echo "  -p, --profile PROF   AWS CLI profile [default: \$AWS_PROFILE or 'default']"
    echo "  -t, --target PATH    Target S3 path prefix [default: assets/]"
    echo "  -c, --invalidate     Invalidate CloudFront cache after upload (production only)"
    echo "  -d, --dry-run        Show what would be uploaded without actually uploading"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ./mobile-assets/                    # Upload to dev environment"
    echo "  $0 -e prod -c ./assets/                # Upload to prod and invalidate cache"
    echo "  $0 -e staging -t images/ ./icons/      # Upload to staging under 'images/' prefix"
    echo "  $0 -d ./assets/                        # Dry run to see what would be uploaded"
    echo ""
    echo "S3 Bucket:"
    echo "  production: $(get_bucket_name prod)"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first:"
        echo "  macOS: brew install awscli"
        echo "  Linux: sudo apt install awscli"
        echo "  Or visit: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        log_error "AWS credentials not configured or invalid for profile '$AWS_PROFILE'"
        echo "Run: aws configure --profile $AWS_PROFILE"
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

validate_environment() {
    local env=$1
    local bucket=$(get_bucket_name "$env")
    if [[ -z "$bucket" ]]; then
        log_error "Invalid environment: $env"
        echo "Only 'prod' environment is available"
        exit 1
    fi
}

validate_directory() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        log_error "Directory does not exist: $dir"
        exit 1
    fi
    
    if [[ ! -r "$dir" ]]; then
        log_error "Directory is not readable: $dir"
        exit 1
    fi
}

get_content_type() {
    local file=$1
    local extension="${file##*.}"
    # Convert to lowercase for case-insensitive matching
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    case "$extension" in
        jpg|jpeg) echo "image/jpeg" ;;
        png) echo "image/png" ;;
        gif) echo "image/gif" ;;
        webp) echo "image/webp" ;;
        svg) echo "image/svg+xml" ;;
        mp4) echo "video/mp4" ;;
        mov) echo "video/quicktime" ;;
        avi) echo "video/x-msvideo" ;;
        webm) echo "video/webm" ;;
        mp3) echo "audio/mpeg" ;;
        wav) echo "audio/wav" ;;
        ogg) echo "audio/ogg" ;;
        pdf) echo "application/pdf" ;;
        json) echo "application/json" ;;
        xml) echo "application/xml" ;;
        css) echo "text/css" ;;
        js) echo "application/javascript" ;;
        html) echo "text/html" ;;
        txt) echo "text/plain" ;;
        *) echo "application/octet-stream" ;;
    esac
}

upload_file() {
    local local_file=$1
    local s3_key=$2
    local bucket=$3
    local content_type=$4
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would upload: $local_file → s3://$bucket/$s3_key"
        return 0
    fi
    
    local upload_cmd="aws s3 cp \"$local_file\" \"s3://$bucket/$s3_key\""
    upload_cmd+=" --content-type \"$content_type\""
    upload_cmd+=" --profile \"$AWS_PROFILE\""
    
    if [[ "$VERBOSE" == "true" ]]; then
        upload_cmd+=" --cli-write-timeout 0 --cli-read-timeout 0"
        log_info "Uploading: $local_file → s3://$bucket/$s3_key"
    fi
    
    if eval "$upload_cmd"; then
        if [[ "$VERBOSE" == "true" ]]; then
            log_success "Uploaded: $s3_key"
        fi
        return 0
    else
        log_error "Failed to upload: $local_file"
        return 1
    fi
}

invalidate_cloudfront() {
    local env=$1
    local paths=("${@:2}")  # All arguments except the first
    local distribution_id=$(get_cloudfront_id "$env")
    
    if [[ -z "$distribution_id" ]]; then
        if [[ "$env" == "prod" ]]; then
            log_warning "CloudFront distribution ID not configured for production!"
            log_warning "Assets uploaded but cache not invalidated. Users may see old content."
            log_warning "To fix: Update get_cloudfront_id() function with your distribution ID"
        else
            log_info "$env environment uses direct S3 access (no CloudFront cache to invalidate)"
        fi
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would invalidate CloudFront paths: ${paths[*]}"
        return 0
    fi
    
    log_info "Invalidating CloudFront cache for ${#paths[@]} paths..."
    
    local invalidation_paths=$(printf '"%s" ' "${paths[@]}")
    
    if aws cloudfront create-invalidation \
        --distribution-id "$distribution_id" \
        --paths ${invalidation_paths} \
        --profile "$AWS_PROFILE" > /dev/null; then
        log_success "CloudFront invalidation initiated"
    else
        log_error "Failed to invalidate CloudFront cache"
        return 1
    fi
}

# ==============================================================================
# MAIN UPLOAD FUNCTION
# ==============================================================================

upload_assets() {
    local source_dir=$1
    local environment=$2
    local target_prefix=$3
    local bucket=$(get_bucket_name "$environment")
    
    log_info "Starting asset upload..."
    echo "  Source: $source_dir"
    echo "  Target: s3://$bucket/$target_prefix"
    echo "  Environment: $environment"
    echo "  AWS Profile: $AWS_PROFILE"
    echo ""
    
    # Find all files in the directory
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$source_dir" -type f -print0)
    
    if [[ ${#files[@]} -eq 0 ]]; then
        log_warning "No files found in directory: $source_dir"
        return 0
    fi
    
    log_info "Found ${#files[@]} files to upload"
    
    # Track successful uploads and paths for CloudFront invalidation
    local uploaded_count=0
    local failed_count=0
    local cloudfront_paths=()
    
    # Upload each file
    for file in "${files[@]}"; do
        # Calculate relative path from source directory
        local relative_path="${file#$source_dir/}"
        relative_path="${relative_path#/}"  # Remove leading slash if present
        
        # Build S3 key
        local s3_key="${target_prefix}${relative_path}"
        
        # Get content type
        local content_type=$(get_content_type "$file")
        
        # Upload file
        if upload_file "$file" "$s3_key" "$bucket" "$content_type"; then
            ((uploaded_count++))
            cloudfront_paths+=("/$s3_key")
        else
            ((failed_count++))
        fi
    done
    
    # Summary
    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run completed - no files were actually uploaded"
        log_info "Would upload: ${#files[@]} files"
    else
        log_success "Upload completed: $uploaded_count succeeded, $failed_count failed"
        
        # CloudFront invalidation if requested and there were successful uploads
        if [[ "$INVALIDATE_CACHE" == "true" && $uploaded_count -gt 0 ]]; then
            invalidate_cloudfront "$environment" "${cloudfront_paths[@]}"
        fi
    fi
    
    return $failed_count
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

ENVIRONMENT="prod"
TARGET_PREFIX="assets/"
INVALIDATE_CACHE="false"
DRY_RUN="false"
VERBOSE="false"
SOURCE_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_PREFIX="$2"
            # Ensure target prefix ends with /
            [[ "$TARGET_PREFIX" != */ ]] && TARGET_PREFIX="${TARGET_PREFIX}/"
            shift 2
            ;;
        -c|--invalidate)
            INVALIDATE_CACHE="true"
            shift
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            if [[ -z "$SOURCE_DIR" ]]; then
                SOURCE_DIR="$1"
            else
                log_error "Multiple source directories specified"
                print_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

# Validate arguments
if [[ -z "$SOURCE_DIR" ]]; then
    log_error "Source directory is required"
    print_usage
    exit 1
fi

# Validate inputs
validate_environment "$ENVIRONMENT"
validate_directory "$SOURCE_DIR"

# Check dependencies
check_dependencies

# Convert relative path to absolute
SOURCE_DIR=$(realpath "$SOURCE_DIR")

# Show configuration
echo -e "${BLUE}🚀 InnerWorld Asset Upload${NC}"
echo "=================================="

# Confirmation for production
if [[ "$ENVIRONMENT" == "prod" && "$DRY_RUN" != "true" ]]; then
    echo ""
    log_warning "You are uploading to PRODUCTION environment!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Upload cancelled"
        exit 0
    fi
fi

# Execute upload
if upload_assets "$SOURCE_DIR" "$ENVIRONMENT" "$TARGET_PREFIX"; then
    log_success "Asset upload process completed successfully! 🎉"
    exit 0
else
    log_error "Asset upload process completed with errors"
    exit 1
fi
