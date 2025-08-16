#!/usr/bin/env bash

# ==============================================================================
# INNERWORLD ASSET MANAGEMENT - ONE-STOP-SHOP SCRIPT
# ==============================================================================
# Comprehensive asset management for mobile app development
# Upload, download, sync, and browse assets across environments
# ==============================================================================

set -e

# Ensure we're using bash for associative array support
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Please run with: bash $0 $*"
    exit 1
fi

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# AWS region
AWS_REGION="us-east-1"

# Default AWS profile (can be overridden)
AWS_PROFILE="${AWS_PROFILE:-default}"

# Script version
VERSION="1.0.0"

# Function to get S3 bucket name for environment
get_bucket_name() {
    local env=$1
    case "$env" in
        dev) echo "innerworld-dev-app-assets" ;;
        staging) echo "innerworld-staging-app-assets" ;;
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "${PURPLE}🎯 $1${NC}"; }

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    📱 InnerWorld Asset Management v$VERSION                    ║"
    echo "║                         One-Stop-Shop for Mobile Assets                     ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    print_banner
    echo ""
    echo -e "${BLUE}Usage: $0 <command> [options] [arguments]${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  upload    Upload assets to S3 bucket"
    echo "  download  Download assets from S3 bucket"
    echo "  list      List/browse assets in S3 bucket"
    echo "  sync      Sync assets between environments or local/remote"
    echo "  compare   Compare assets between environments"
    echo "  clean     Clean up old/unused assets"
    echo "  info      Show bucket and environment information"
    echo "  help      Show detailed help for a command"
    echo ""
    echo -e "${YELLOW}Global Options:${NC}"
    echo "  -e, --env ENV        Environment (dev, staging, prod) [default: dev]"
    echo "  -p, --profile PROF   AWS CLI profile [default: \$AWS_PROFILE or 'default']"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help           Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 upload ./my-assets/              # Upload to dev environment"
    echo "  $0 download -e prod images/         # Download images from production"
    echo "  $0 list -e staging                  # List staging assets"
    echo "  $0 sync dev staging                 # Sync from dev to staging"
    echo "  $0 compare dev prod                 # Compare dev vs prod assets"
    echo ""
    echo -e "${YELLOW}For detailed help on any command:${NC}"
    echo "  $0 help <command>"
    echo ""
    echo -e "${BLUE}S3 Buckets:${NC}"
    echo "  dev:     $(get_bucket_name dev)"
    echo "  staging: $(get_bucket_name staging)" 
    echo "  prod:    $(get_bucket_name prod)"
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
        echo "Valid environments: dev, staging, prod"
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

format_size() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while (( bytes >= 1024 && unit < 4 )); do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done
    
    echo "${bytes}${units[$unit]}"
}

format_date() {
    local date_str=$1
    if command -v gdate &> /dev/null; then
        # macOS with GNU date (brew install coreutils)
        gdate -d "$date_str" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$date_str"
    elif date --version 2>/dev/null | grep -q GNU; then
        # GNU date (Linux)
        date -d "$date_str" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$date_str"
    else
        # BSD date (macOS default) - limited parsing
        echo "$date_str"
    fi
}

# ==============================================================================
# UPLOAD COMMAND
# ==============================================================================

cmd_upload_help() {
    echo -e "${BLUE}Upload assets to S3 bucket${NC}"
    echo ""
    echo "Usage: $0 upload [options] <source_path>"
    echo ""
    echo "Options:"
    echo "  -e, --env ENV        Environment (dev, staging, prod) [default: dev]"
    echo "  -t, --target PATH    Target S3 path prefix [default: assets/]"
    echo "  -c, --invalidate     Invalidate CloudFront cache after upload (production only)"
    echo "  -d, --dry-run        Show what would be uploaded without actually uploading"
    echo "  --delete             Delete extraneous files from destination"
    echo ""
    echo "Examples:"
    echo "  $0 upload ./my-images/                    # Upload to dev/assets/"
    echo "  $0 upload -e prod -c ./icons/             # Upload to prod with cache invalidation"
    echo "  $0 upload -t images/ ./new-images/        # Upload to dev/images/"
    echo "  $0 upload -d ./assets/                    # Dry run to preview changes"
}

cmd_upload() {
    local source_path=""
    local target_prefix="assets/"
    local environment="dev"
    local invalidate_cache="false"
    local dry_run="false"
    local delete_extra="false"
    
    # Parse upload-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env) environment="$2"; shift 2 ;;
            -t|--target) target_prefix="$2"; [[ "$target_prefix" != */ ]] && target_prefix="${target_prefix}/"; shift 2 ;;
            -c|--invalidate) invalidate_cache="true"; shift ;;
            -d|--dry-run) dry_run="true"; shift ;;
            --delete) delete_extra="true"; shift ;;
            -h|--help) cmd_upload_help; exit 0 ;;
            -*) log_error "Unknown upload option: $1"; exit 1 ;;
            *) source_path="$1"; shift ;;
        esac
    done
    
    if [[ -z "$source_path" ]]; then
        log_error "Source path is required for upload"
        cmd_upload_help
        exit 1
    fi
    
    if [[ ! -d "$source_path" && ! -f "$source_path" ]]; then
        log_error "Source path does not exist: $source_path"
        exit 1
    fi
    
    validate_environment "$environment"
    local bucket=$(get_bucket_name "$environment")
    
    log_header "Uploading Assets"
    echo "  Source: $source_path"
    echo "  Target: s3://$bucket/$target_prefix"
    echo "  Environment: $environment"
    echo "  AWS Profile: $AWS_PROFILE"
    echo ""
    
    # Confirmation for production
    if [[ "$environment" == "prod" && "$dry_run" != "true" ]]; then
        log_warning "You are uploading to PRODUCTION environment!"
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Upload cancelled"
            exit 0
        fi
    fi
    
    # Build AWS S3 sync command
    local sync_cmd="aws s3 sync \"$source_path\" \"s3://$bucket/$target_prefix\""
    sync_cmd+=" --profile \"$AWS_PROFILE\""
    
    if [[ "$delete_extra" == "true" ]]; then
        sync_cmd+=" --delete"
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        sync_cmd+=" --dryrun"
        log_info "DRY RUN - No files will actually be uploaded"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        sync_cmd+=" --cli-write-timeout 0 --cli-read-timeout 0"
    fi
    
    # Execute upload
    log_info "Starting upload..."
    if eval "$sync_cmd"; then
        if [[ "$dry_run" != "true" ]]; then
            log_success "Upload completed successfully!"
            
            # CloudFront invalidation if requested
            if [[ "$invalidate_cache" == "true" && "$environment" == "prod" ]]; then
                invalidate_cloudfront_cache "$target_prefix"
            fi
        else
            log_success "Dry run completed - no files were actually uploaded"
        fi
    else
        log_error "Upload failed"
        exit 1
    fi
}

invalidate_cloudfront_cache() {
    local path_prefix=$1
    local distribution_id=$(get_cloudfront_id "prod")
    
    if [[ -z "$distribution_id" ]]; then
        log_warning "CloudFront distribution ID not configured for production!"
        log_warning "Assets uploaded but cache not invalidated. Users may see old content."
        return 0
    fi
    
    log_info "Invalidating CloudFront cache for /$path_prefix*"
    
    if aws cloudfront create-invalidation \
        --distribution-id "$distribution_id" \
        --paths "/$path_prefix*" \
        --profile "$AWS_PROFILE" > /dev/null; then
        log_success "CloudFront invalidation initiated"
    else
        log_error "Failed to invalidate CloudFront cache"
        return 1
    fi
}

# ==============================================================================
# DOWNLOAD COMMAND
# ==============================================================================

cmd_download_help() {
    echo -e "${BLUE}Download assets from S3 bucket${NC}"
    echo ""
    echo "Usage: $0 download [options] [remote_path] [local_path]"
    echo ""
    echo "Options:"
    echo "  -e, --env ENV        Environment (dev, staging, prod) [default: dev]"
    echo "  -d, --dry-run        Show what would be downloaded without actually downloading"
    echo "  --delete             Delete extraneous files from local destination"
    echo ""
    echo "Arguments:"
    echo "  remote_path          S3 path to download (optional, defaults to entire bucket)"
    echo "  local_path           Local destination path [default: ./downloaded-assets/]"
    echo ""
    echo "Examples:"
    echo "  $0 download                               # Download all dev assets"
    echo "  $0 download -e prod                       # Download all prod assets"
    echo "  $0 download images/ ./local-images/       # Download specific folder"
    echo "  $0 download assets/logo.png ./            # Download specific file"
}

cmd_download() {
    local remote_path=""
    local local_path="./downloaded-assets/"
    local environment="dev"
    local dry_run="false"
    local delete_extra="false"
    
    # Parse download-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env) environment="$2"; shift 2 ;;
            -d|--dry-run) dry_run="true"; shift ;;
            --delete) delete_extra="true"; shift ;;
            -h|--help) cmd_download_help; exit 0 ;;
            -*) log_error "Unknown download option: $1"; exit 1 ;;
            *)
                if [[ -z "$remote_path" ]]; then
                    remote_path="$1"
                else
                    local_path="$1"
                fi
                shift
                ;;
        esac
    done
    
    validate_environment "$environment"
    local bucket=$(get_bucket_name "$environment")
    
    log_header "Downloading Assets"
    echo "  Source: s3://$bucket/$remote_path"
    echo "  Target: $local_path"
    echo "  Environment: $environment"
    echo "  AWS Profile: $AWS_PROFILE"
    echo ""
    
    # Create local directory if it doesn't exist
    if [[ "$dry_run" != "true" ]]; then
        mkdir -p "$local_path"
    fi
    
    # Build AWS S3 sync command
    local sync_cmd="aws s3 sync \"s3://$bucket/$remote_path\" \"$local_path\""
    sync_cmd+=" --profile \"$AWS_PROFILE\""
    
    if [[ "$delete_extra" == "true" ]]; then
        sync_cmd+=" --delete"
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        sync_cmd+=" --dryrun"
        log_info "DRY RUN - No files will actually be downloaded"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        sync_cmd+=" --cli-write-timeout 0 --cli-read-timeout 0"
    fi
    
    # Execute download
    log_info "Starting download..."
    if eval "$sync_cmd"; then
        if [[ "$dry_run" != "true" ]]; then
            log_success "Download completed successfully!"
            log_info "Assets saved to: $local_path"
        else
            log_success "Dry run completed - no files were actually downloaded"
        fi
    else
        log_error "Download failed"
        exit 1
    fi
}

# ==============================================================================
# LIST COMMAND
# ==============================================================================

cmd_list_help() {
    echo -e "${BLUE}List/browse assets in S3 bucket${NC}"
    echo ""
    echo "Usage: $0 list [options] [path]"
    echo ""
    echo "Options:"
    echo "  -e, --env ENV        Environment (dev, staging, prod) [default: dev]"
    echo "  -l, --long           Show detailed information (size, date)"
    echo "  -r, --recursive      List all files recursively"
    echo "  --human-readable     Show file sizes in human readable format"
    echo ""
    echo "Arguments:"
    echo "  path                 S3 path to list (optional, defaults to root)"
    echo ""
    echo "Examples:"
    echo "  $0 list                          # List root of dev bucket"
    echo "  $0 list -e prod -l               # Detailed list of prod bucket"
    echo "  $0 list -r images/               # Recursively list images folder"
    echo "  $0 list --human-readable assets/ # List with human readable sizes"
}

cmd_list() {
    local path=""
    local environment="dev"
    local detailed="false"
    local recursive="false"
    local human_readable="false"
    
    # Parse list-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env) environment="$2"; shift 2 ;;
            -l|--long) detailed="true"; shift ;;
            -r|--recursive) recursive="true"; shift ;;
            --human-readable) human_readable="true"; shift ;;
            -h|--help) cmd_list_help; exit 0 ;;
            -*) log_error "Unknown list option: $1"; exit 1 ;;
            *) path="$1"; shift ;;
        esac
    done
    
    validate_environment "$environment"
    local bucket=$(get_bucket_name "$environment")
    
    log_header "Listing Assets"
    echo "  Bucket: s3://$bucket/$path"
    echo "  Environment: $environment"
    echo ""
    
    # Build AWS S3 ls command
    local ls_cmd="aws s3 ls \"s3://$bucket/$path\""
    ls_cmd+=" --profile \"$AWS_PROFILE\""
    
    if [[ "$recursive" == "true" ]]; then
        ls_cmd+=" --recursive"
    fi
    
    if [[ "$human_readable" == "true" ]]; then
        ls_cmd+=" --human-readable"
    fi
    
    # Execute list command
    local output
    if output=$(eval "$ls_cmd" 2>&1); then
        if [[ -z "$output" ]]; then
            log_warning "No assets found in s3://$bucket/$path"
        else
            if [[ "$detailed" == "true" ]]; then
                echo "$output" | while IFS= read -r line; do
                    if [[ "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
                        # File entry
                        local date_part=$(echo "$line" | awk '{print $1" "$2}')
                        local size_part=$(echo "$line" | awk '{print $3}')
                        local file_part=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
                        
                        local formatted_date=$(format_date "$date_part")
                        local formatted_size
                        if [[ "$human_readable" == "true" ]]; then
                            formatted_size="$size_part"
                        else
                            formatted_size=$(format_size "$size_part")
                        fi
                        
                        printf "%-20s %10s  %s\n" "$formatted_date" "$formatted_size" "$file_part"
                    else
                        # Directory entry
                        echo "$line"
                    fi
                done
            else
                echo "$output"
            fi
        fi
    else
        log_error "Failed to list assets: $output"
        exit 1
    fi
}

# ==============================================================================
# SYNC COMMAND
# ==============================================================================

cmd_sync_help() {
    echo -e "${BLUE}Sync assets between environments or local/remote${NC}"
    echo ""
    echo "Usage: $0 sync [options] <source> <destination>"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run        Show what would be synced without actually syncing"
    echo "  --delete             Delete extraneous files from destination"
    echo "  -c, --invalidate     Invalidate CloudFront cache if destination is prod"
    echo ""
    echo "Arguments:"
    echo "  source               Source environment (dev, staging, prod) or local path"
    echo "  destination          Destination environment (dev, staging, prod) or local path"
    echo ""
    echo "Examples:"
    echo "  $0 sync dev staging                      # Sync from dev to staging"
    echo "  $0 sync prod ./backup/                   # Download prod assets to local"
    echo "  $0 sync ./local-assets/ dev              # Upload local assets to dev"
    echo "  $0 sync -d dev prod                      # Dry run sync from dev to prod"
}

cmd_sync() {
    local source=""
    local destination=""
    local dry_run="false"
    local delete_extra="false"
    local invalidate_cache="false"
    
    # Parse sync-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run) dry_run="true"; shift ;;
            --delete) delete_extra="true"; shift ;;
            -c|--invalidate) invalidate_cache="true"; shift ;;
            -h|--help) cmd_sync_help; exit 0 ;;
            -*) log_error "Unknown sync option: $1"; exit 1 ;;
            *)
                if [[ -z "$source" ]]; then
                    source="$1"
                else
                    destination="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$source" || -z "$destination" ]]; then
        log_error "Both source and destination are required for sync"
        cmd_sync_help
        exit 1
    fi
    
    # Determine source and destination paths
    local source_path=""
    local dest_path=""
    
    # Check if source is an environment or local path
    if [[ "$source" =~ ^(dev|staging|prod)$ ]]; then
        validate_environment "$source"
        source_path="s3://$(get_bucket_name "$source")/"
    else
        if [[ ! -d "$source" ]]; then
            log_error "Source directory does not exist: $source"
            exit 1
        fi
        source_path="$source"
    fi
    
    # Check if destination is an environment or local path
    if [[ "$destination" =~ ^(dev|staging|prod)$ ]]; then
        validate_environment "$destination"
        dest_path="s3://$(get_bucket_name "$destination")/"
    else
        dest_path="$destination"
        # Create local directory if it doesn't exist
        if [[ "$dry_run" != "true" ]]; then
            mkdir -p "$dest_path"
        fi
    fi
    
    log_header "Syncing Assets"
    echo "  Source: $source_path"
    echo "  Destination: $dest_path"
    echo "  AWS Profile: $AWS_PROFILE"
    echo ""
    
    # Confirmation for production destination
    if [[ "$destination" == "prod" && "$dry_run" != "true" ]]; then
        log_warning "You are syncing to PRODUCTION environment!"
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Sync cancelled"
            exit 0
        fi
    fi
    
    # Build AWS S3 sync command
    local sync_cmd="aws s3 sync \"$source_path\" \"$dest_path\""
    sync_cmd+=" --profile \"$AWS_PROFILE\""
    
    if [[ "$delete_extra" == "true" ]]; then
        sync_cmd+=" --delete"
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        sync_cmd+=" --dryrun"
        log_info "DRY RUN - No files will actually be synced"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        sync_cmd+=" --cli-write-timeout 0 --cli-read-timeout 0"
    fi
    
    # Execute sync
    log_info "Starting sync..."
    if eval "$sync_cmd"; then
        if [[ "$dry_run" != "true" ]]; then
            log_success "Sync completed successfully!"
            
            # CloudFront invalidation if destination is prod
            if [[ "$invalidate_cache" == "true" && "$destination" == "prod" ]]; then
                invalidate_cloudfront_cache ""
            fi
        else
            log_success "Dry run completed - no files were actually synced"
        fi
    else
        log_error "Sync failed"
        exit 1
    fi
}

# ==============================================================================
# COMPARE COMMAND
# ==============================================================================

cmd_compare_help() {
    echo -e "${BLUE}Compare assets between environments${NC}"
    echo ""
    echo "Usage: $0 compare [options] <env1> <env2>"
    echo ""
    echo "Options:"
    echo "  --summary-only       Show only summary statistics"
    echo ""
    echo "Arguments:"
    echo "  env1                 First environment (dev, staging, prod)"
    echo "  env2                 Second environment (dev, staging, prod)"
    echo ""
    echo "Examples:"
    echo "  $0 compare dev prod                      # Compare dev vs prod"
    echo "  $0 compare --summary-only staging prod   # Show only summary"
}

cmd_compare() {
    local env1=""
    local env2=""
    local summary_only="false"
    
    # Parse compare-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --summary-only) summary_only="true"; shift ;;
            -h|--help) cmd_compare_help; exit 0 ;;
            -*) log_error "Unknown compare option: $1"; exit 1 ;;
            *)
                if [[ -z "$env1" ]]; then
                    env1="$1"
                else
                    env2="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$env1" || -z "$env2" ]]; then
        log_error "Both environments are required for comparison"
        cmd_compare_help
        exit 1
    fi
    
    validate_environment "$env1"
    validate_environment "$env2"
    
    local bucket1=$(get_bucket_name "$env1")
    local bucket2=$(get_bucket_name "$env2")
    
    log_header "Comparing Assets"
    echo "  Environment 1: $env1 (s3://$bucket1/)"
    echo "  Environment 2: $env2 (s3://$bucket2/)"
    echo ""
    
    # Get file lists for both environments
    log_info "Fetching asset lists..."
    
    local list1="/tmp/assets_${env1}_$$.txt"
    local list2="/tmp/assets_${env2}_$$.txt"
    
    aws s3 ls "s3://$bucket1/" --recursive --profile "$AWS_PROFILE" | awk '{print $4}' | sort > "$list1"
    aws s3 ls "s3://$bucket2/" --recursive --profile "$AWS_PROFILE" | awk '{print $4}' | sort > "$list2"
    
    # Find differences
    local only_in_1="/tmp/only_in_${env1}_$$.txt"
    local only_in_2="/tmp/only_in_${env2}_$$.txt"
    local common="/tmp/common_$$.txt"
    
    comm -23 "$list1" "$list2" > "$only_in_1"
    comm -13 "$list1" "$list2" > "$only_in_2"
    comm -12 "$list1" "$list2" > "$common"
    
    local count1=$(wc -l < "$list1")
    local count2=$(wc -l < "$list2")
    local only_count1=$(wc -l < "$only_in_1")
    local only_count2=$(wc -l < "$only_in_2")
    local common_count=$(wc -l < "$common")
    
    # Display results
    echo -e "${YELLOW}Summary:${NC}"
    echo "  Total assets in $env1: $count1"
    echo "  Total assets in $env2: $count2"
    echo "  Common assets: $common_count"
    echo "  Only in $env1: $only_count1"
    echo "  Only in $env2: $only_count2"
    echo ""
    
    if [[ "$summary_only" != "true" ]]; then
        if [[ $only_count1 -gt 0 ]]; then
            echo -e "${BLUE}Assets only in $env1:${NC}"
            head -20 "$only_in_1"
            if [[ $only_count1 -gt 20 ]]; then
                echo "  ... and $((only_count1 - 20)) more"
            fi
            echo ""
        fi
        
        if [[ $only_count2 -gt 0 ]]; then
            echo -e "${BLUE}Assets only in $env2:${NC}"
            head -20 "$only_in_2"
            if [[ $only_count2 -gt 20 ]]; then
                echo "  ... and $((only_count2 - 20)) more"
            fi
            echo ""
        fi
    fi
    
    # Cleanup
    rm -f "$list1" "$list2" "$only_in_1" "$only_in_2" "$common"
    
    log_success "Comparison completed"
}

# ==============================================================================
# INFO COMMAND
# ==============================================================================

cmd_info() {
    log_header "InnerWorld Asset Management Info"
    echo ""
    
    echo -e "${YELLOW}S3 Buckets:${NC}"
    for env in dev staging prod; do
        local bucket=$(get_bucket_name "$env")
        echo "  $env: $bucket"
        
        # Check if bucket exists and get basic info
        if aws s3 ls "s3://$bucket/" --profile "$AWS_PROFILE" &> /dev/null; then
            local count=$(aws s3 ls "s3://$bucket/" --recursive --profile "$AWS_PROFILE" | wc -l)
            echo "    Status: ✅ Accessible ($count assets)"
        else
            echo "    Status: ❌ Not accessible or doesn't exist"
        fi
    done
    echo ""
    
    echo -e "${YELLOW}CloudFront:${NC}"
    local prod_cf=$(get_cloudfront_id "prod")
    if [[ -n "$prod_cf" && "$prod_cf" != "YOUR_PROD_CLOUDFRONT_DISTRIBUTION_ID" ]]; then
        echo "  Production: ✅ Configured ($prod_cf)"
    else
        echo "  Production: ⚠️  Not configured (update script with distribution ID)"
    fi
    echo "  Dev/Staging: Direct S3 access (no CloudFront)"
    echo ""
    
    echo -e "${YELLOW}AWS Configuration:${NC}"
    echo "  Profile: $AWS_PROFILE"
    echo "  Region: $AWS_REGION"
    
    local identity
    if identity=$(aws sts get-caller-identity --profile "$AWS_PROFILE" 2>/dev/null); then
        local account=$(echo "$identity" | jq -r '.Account')
        local arn=$(echo "$identity" | jq -r '.Arn')
        echo "  Account: $account"
        echo "  Identity: $arn"
        echo "  Status: ✅ Authenticated"
    else
        echo "  Status: ❌ Not authenticated"
    fi
}

# ==============================================================================
# HELP COMMAND
# ==============================================================================

cmd_help() {
    local command=$1
    
    case "$command" in
        upload) cmd_upload_help ;;
        download) cmd_download_help ;;
        list) cmd_list_help ;;
        sync) cmd_sync_help ;;
        compare) cmd_compare_help ;;
        info) echo "Show bucket and environment information" ;;
        *) print_usage ;;
    esac
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

# Global variables
VERBOSE="false"
COMMAND=""

# Parse global arguments first
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            # This will be handled by individual commands
            break
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            if [[ -z "$2" ]]; then
                print_usage
                exit 0
            else
                cmd_help "$2"
                exit 0
            fi
            ;;
        upload|download|list|sync|compare|clean|info|help)
            COMMAND="$1"
            shift
            break
            ;;
        *)
            log_error "Unknown command: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Check if command was provided
if [[ -z "$COMMAND" ]]; then
    print_usage
    exit 1
fi

# Check dependencies before running any command
check_dependencies

# Execute the appropriate command
case "$COMMAND" in
    upload) cmd_upload "$@" ;;
    download) cmd_download "$@" ;;
    list) cmd_list "$@" ;;
    sync) cmd_sync "$@" ;;
    compare) cmd_compare "$@" ;;
    info) cmd_info "$@" ;;
    help) cmd_help "$@" ;;
    clean)
        log_warning "Clean command not yet implemented"
        log_info "Use 'aws s3 rm' manually for now"
        exit 1
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        print_usage
        exit 1
        ;;
esac
