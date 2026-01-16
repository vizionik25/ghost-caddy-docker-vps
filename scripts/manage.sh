#!/bin/bash
# Ghost Management Script
# Provides common management commands for the Ghost + Caddy Docker setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}==========================================="
    echo -e "  👻 Ghost Blog Management (with Caddy SSL)"
    echo -e "===========================================${NC}"
    echo ""
}

print_usage() {
    print_header
    echo "Usage: $0 <command>"
    echo ""
    echo -e "${BLUE}Container Commands:${NC}"
    echo "  start          Start Ghost + Caddy containers"
    echo "  stop           Stop all containers"
    echo "  restart        Restart all containers"
    echo "  status         Show container status"
    echo "  logs           Show Ghost logs (follow mode)"
    echo "  logs-caddy     Show Caddy logs (follow mode)"
    echo "  logs-tail      Show last 100 log lines"
    echo "  shell          Open shell in Ghost container"
    echo "  shell-caddy    Open shell in Caddy container"
    echo ""
    echo -e "${BLUE}Content Commands:${NC}"
    echo "  backup         Create a backup of Ghost content"
    echo "  restore        Restore from a backup file"
    echo "  export         Export content as JSON"
    echo ""
    echo -e "${BLUE}Maintenance Commands:${NC}"
    echo "  update         Update Ghost and Caddy to latest version"
    echo "  cleanup        Remove all data and start fresh"
    echo "  health         Check Ghost health status"
    echo "  reload-caddy   Reload Caddy configuration"
    echo ""
    echo -e "${BLUE}Info Commands:${NC}"
    echo "  info           Show Ghost instance information"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs"
    echo "  $0 backup"
    echo ""
}

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

GHOST_URL="${GHOST_URL:-https://localhost}"
DOMAIN="${DOMAIN:-localhost}"

case "$1" in
    start)
        echo -e "${GREEN}Starting Ghost + Caddy...${NC}"
        docker compose up -d
        echo ""
        echo -e "${GREEN}✓ Services started!${NC}"
        echo ""
        echo -e "  Blog:  ${CYAN}${GHOST_URL}${NC}"
        echo -e "  Admin: ${CYAN}${GHOST_URL}/ghost${NC}"
        echo ""
        echo -e "${YELLOW}Note: SSL certificate will be obtained automatically.${NC}"
        echo -e "      First request may take a few seconds."
        echo ""
        ;;
    stop)
        echo -e "${YELLOW}Stopping all containers...${NC}"
        docker compose stop
        echo -e "${GREEN}✓ All containers stopped${NC}"
        ;;
    restart)
        echo -e "${YELLOW}Restarting all containers...${NC}"
        docker compose restart
        echo -e "${GREEN}✓ All containers restarted${NC}"
        ;;
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f ghost
        ;;
    logs-caddy)
        docker compose logs -f caddy
        ;;
    logs-all)
        docker compose logs -f
        ;;
    logs-tail)
        docker compose logs --tail=100
        ;;
    shell)
        docker compose exec ghost sh
        ;;
    shell-caddy)
        docker compose exec caddy sh
        ;;
    backup)
        BACKUP_DIR="backups"
        BACKUP_NAME="ghost_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        echo -e "${BLUE}Creating backup...${NC}"
        
        # Copy content from Docker volume
        docker compose exec ghost tar -czf /tmp/backup.tar.gz -C /var/lib/ghost/content .
        docker compose cp ghost:/tmp/backup.tar.gz "$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
        docker compose exec ghost rm /tmp/backup.tar.gz
        
        echo -e "${GREEN}✓ Backup created: $BACKUP_DIR/${BACKUP_NAME}.tar.gz${NC}"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Backup file required${NC}"
            echo "Usage: $0 restore <backup-file>"
            exit 1
        fi
        
        if [ ! -f "$2" ]; then
            echo -e "${RED}Error: Backup file not found: $2${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}WARNING: This will overwrite existing content!${NC}"
        read -p "Are you sure? (y/N) " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo -e "${BLUE}Restoring backup...${NC}"
            docker compose cp "$2" ghost:/tmp/backup.tar.gz
            docker compose exec ghost sh -c "cd /var/lib/ghost/content && tar -xzf /tmp/backup.tar.gz"
            docker compose exec ghost rm /tmp/backup.tar.gz
            docker compose restart ghost
            echo -e "${GREEN}✓ Backup restored${NC}"
        fi
        ;;
    export)
        echo -e "${BLUE}To export content:${NC}"
        echo "1. Go to ${GHOST_URL}/ghost/#/settings/labs"
        echo "2. Click 'Export your content'"
        echo ""
        echo "This will download a JSON file with all your posts and settings."
        ;;
    update)
        echo -e "${BLUE}Updating Ghost + Caddy...${NC}"
        docker compose pull
        docker compose up -d
        echo -e "${GREEN}✓ All containers updated to latest versions${NC}"
        ;;
    cleanup)
        echo -e "${RED}WARNING: This will remove ALL data including:${NC}"
        echo "  - All posts and pages"
        echo "  - All images and uploads"
        echo "  - All members and subscriptions"
        echo "  - All settings"
        echo "  - SSL certificates (will be re-obtained)"
        echo ""
        read -p "Are you sure? Type 'DELETE' to confirm: " confirm
        if [ "$confirm" = "DELETE" ]; then
            docker compose down -v
            rm -rf content/images/* content/themes/*
            echo -e "${GREEN}✓ Cleanup complete. Run '$0 start' to create fresh instance.${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    health)
        echo -e "${BLUE}Checking service health...${NC}"
        echo ""
        
        # Check Ghost
        echo -n "Ghost: "
        if docker compose exec ghost wget -q --spider http://localhost:2368 2>/dev/null; then
            echo -e "${GREEN}✓ Healthy${NC}"
        else
            echo -e "${RED}✗ Not responding${NC}"
        fi
        
        # Check Caddy
        echo -n "Caddy: "
        if docker compose exec caddy caddy version >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Running${NC}"
        else
            echo -e "${RED}✗ Not running${NC}"
        fi
        
        echo ""
        echo -e "${BLUE}Container Status:${NC}"
        docker compose ps --format "table {{.Name}}\t{{.Status}}"
        ;;
    reload-caddy)
        echo -e "${BLUE}Reloading Caddy configuration...${NC}"
        docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
        echo -e "${GREEN}✓ Caddy configuration reloaded${NC}"
        ;;
    info)
        print_header
        echo -e "${BLUE}Container Status:${NC}"
        docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo -e "${BLUE}Access URLs:${NC}"
        echo -e "  Blog:      ${CYAN}${GHOST_URL}${NC}"
        echo -e "  Admin:     ${CYAN}${GHOST_URL}/ghost${NC}"
        echo ""
        echo -e "${BLUE}Domain:${NC} ${DOMAIN}"
        echo ""
        echo -e "${BLUE}First-time Setup:${NC}"
        echo "  1. Ensure DNS points to this server"
        echo "  2. Visit ${GHOST_URL}/ghost"
        echo "  3. Create your admin account"
        echo "  4. Start creating content!"
        echo ""
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
