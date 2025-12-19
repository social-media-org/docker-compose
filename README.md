# Docker Compose for Social Media Microservices with Traefik

This project provides a Docker Compose configuration to run all the social media microservices together with Traefik reverse proxy for production deployment.

## Architecture

- **Frontend**: React/Vite application (ui-frontend) served via Nginx
- **Backend Services**: 
  - ui-service: Main orchestration service
  - script-service: Script generation
  - audio-service: Audio generation  
  - video-service: Video generation
  - subtitle-service: Subtitle generation
  - youtube-service: YouTube integration
- **Database**: MongoDB
- **Reverse Proxy**: Traefik (external) for SSL termination and routing

## Services Included

1. **ui-frontend** - React frontend application (exposed via Traefik)
2. **ui-service** - Main UI service that orchestrates other services (exposed via Traefik)
3. **script-service** - Script generation service (internal)
4. **audio-service** - Audio generation service (internal)
5. **video-service** - Video generation service (internal)
6. **subtitle-service** - Subtitle generation service (internal)
7. **youtube-service** - YouTube integration service (exposed via Traefik)
8. **mongodb** - MongoDB database

## Prerequisites

- Docker and Docker Compose installed
- Traefik reverse proxy already running with network `traefik_network`
- GitHub Container Registry access (for pulling images)
- Domain names configured in DNS pointing to your server
- API keys for various services (see Configuration)

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/social-media/docker-compose.git
cd docker-compose
cp .env.example .env
```

### 2. Edit environment variables

Edit the `.env` file:
- Set your domain names:
  ```
  UI_FRONTEND_DOMAIN=frontend.yourdomain.com
  UI_SERVICE_DOMAIN=api.yourdomain.com  
  YOUTUBE_SERVICE_DOMAIN=youtube-api.yourdomain.com
  ```
- Fill in all API keys (DeepSeek, OpenAI, ElevenLabs, Google, AssemblyAI, YouTube)

### 3. Start services

```bash
docker-compose up -d
```

### 4. Verify deployment

```bash
docker-compose ps
docker-compose logs -f
```

## Traefik Configuration

This setup assumes you have Traefik already running. The services are configured with Traefik labels for automatic discovery.

### Required Traefik Setup

1. Ensure Traefik is running with a network named `traefik_network`
2. Configure your Traefik to use the `myhttpchallenge` certresolver (or update the label in docker-compose.yml)
3. Make sure Traefik can access the Docker socket or is configured with Docker provider

### Service Routing

- Frontend: `https://${UI_FRONTEND_DOMAIN}` → ui-frontend:3000
- UI Service: `https://${UI_SERVICE_DOMAIN}` → ui-service:8000  
- YouTube Service: `https://${YOUTUBE_SERVICE_DOMAIN}` → youtube-service:8000

## Configuration

### Environment Variables

Key variables in `.env`:

#### Domain Configuration
- `UI_FRONTEND_DOMAIN` - Domain for the frontend application
- `UI_SERVICE_DOMAIN` - Domain for the UI service API
- `YOUTUBE_SERVICE_DOMAIN` - Domain for YouTube service API

#### API Keys
- `DEEPSEEK_API_KEY` - For script generation
- `OPENAI_API_KEY` - Alternative AI service
- `ELEVENLABS_API_KEY` - For audio generation
- `GOOGLE_API_KEY` - For Google services
- `ASSEMBLYAI_API_KEY` - For transcription
- YouTube API credentials for `youtube-service`

#### Service Communication
Internal service communication uses Docker service names:
- `SCRIPT_SERVICE_URL=http://script-service:8000`
- `AUDIO_SERVICE_URL=http://audio-service:8000`
- `VIDEO_SERVICE_URL=http://video-service:8000`
- `SUBTITLE_SERVICE_URL=http://subtitle-service:8000`
- `YOUTUBE_SERVICE_URL=http://youtube-service:8000`

## Building Images Locally

If you want to build images locally instead of pulling from GitHub Container Registry:

```bash
# For each service
docker build -t ghcr.io/social-media/ui-service:latest ../ui-service
docker build -t ghcr.io/social-media/ui-frontend:latest ../ui-frontend/frontend
# ... repeat for other services
```

## GitHub Workflows

Each service has its own GitHub workflow for building and publishing Docker images to GitHub Container Registry. Workflows are located in `.github/workflows/docker-image.yml` in each service repository.

Run the organization script to move workflows to the correct location:
```powershell
cd ../social-media
.\organize-workflows.ps1
```

## Health Checks

Each service includes a health check endpoint at `/health`. Docker Compose and Traefik use these to determine service health status.

## Volumes

- MongoDB data is persisted in a Docker volume named `mongodb_data`
- To backup or restore data, use standard Docker volume commands

## Networks

- `social-media-network`: Internal network for service communication
- `traefik_network`: External Traefik network (must exist)

## Troubleshooting

### Services not starting
- Check if Traefik network exists: `docker network ls | grep traefik_network`
- Verify API keys in `.env` file
- Check Docker logs: `docker-compose logs [service-name]`

### Traefik routing issues
- Verify domain names are correctly configured in `.env`
- Check Traefik logs: `docker logs [traefik-container]`
- Ensure Traefik has Docker provider enabled

### Frontend cannot connect to backend
- Verify `VITE_API_BASE_URL` and `VITE_YOUTUBE_API_BASE_URL` are correctly set
- Check CORS configuration in backend services
- Verify network connectivity between services

### MongoDB connection issues
- Verify MongoDB is running: `docker-compose ps mongodb`
- Check connection string: `mongodb://mongodb:27017`

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (warning: deletes MongoDB data)
docker-compose down -v
```

## Development

For local development without Traefik:
1. Comment out Traefik labels and networks in docker-compose.yml
2. Uncomment port mappings for services
3. Update frontend environment variables to use localhost URLs

## Security Notes

- Always use HTTPS in production
- Keep API keys secure and never commit `.env` file
- Regularly update Docker images for security patches
- Configure proper firewall rules
- Use strong MongoDB credentials in production

## License

See each service repository for license information.
