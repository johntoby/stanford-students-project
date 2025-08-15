# Docker Registry Setup for CI/CD

## Issue
The CI pipeline is failing with "denied: requested access to the resource is denied" because it's trying to push to Docker Hub without proper authentication or repository ownership.

## Solutions

### Option 1: Use Your Docker Hub Account (Recommended)

1. **Create Docker Hub Repository:**
   - Go to [Docker Hub](https://hub.docker.com)
   - Create a new repository: `your-username/stanford-students-api`
   - Make it public or private as needed

2. **Set GitHub Secrets:**
   ```
   DOCKER_USERNAME = your-dockerhub-username
   DOCKER_PASSWORD = your-dockerhub-password-or-token
   ```

3. **Image will be pushed as:**
   ```
   your-username/stanford-students-api:latest
   your-username/stanford-students-api:commit-sha
   ```

### Option 2: Use GitHub Container Registry

Update `.github/workflows/ci.yml`:

```yaml
env:
  DOCKER_REGISTRY: ghcr.io
  DOCKER_IMAGE: ghcr.io/${{ github.repository_owner }}/stanford-students-api
  DOCKER_TAG: ${{ github.sha }}

- name: Docker Login
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### Option 3: Use AWS ECR

Update `.github/workflows/ci.yml`:

```yaml
env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: stanford-students-api

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}

- name: Login to Amazon ECR
  uses: aws-actions/amazon-ecr-login@v1

- name: Build and Push to ECR
  run: |
    docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$DOCKER_TAG .
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$DOCKER_TAG
```

## Current Setup
The pipeline is configured for **Option 1** (Docker Hub). You need to:

1. Set the GitHub secrets: `DOCKER_USERNAME` and `DOCKER_PASSWORD`
2. Ensure you have a Docker Hub repository with the same name
3. The image will be pushed as: `your-username/stanford-students-api`

## Testing Locally
```bash
# Test Docker login
docker login

# Test build and push
docker build -t your-username/stanford-students-api:test .
docker push your-username/stanford-students-api:test
```