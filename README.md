# Python Script on AWS Batch (Fargate)

This project runs `main.py` as an on-demand AWS Batch job on Fargate.

The script itself is intentionally simple. High CPU/RAM behavior is treated as an infrastructure sizing concern (Batch/Fargate job resources), not something we simulate in the code.

## 1) Validate locally before deploy

Build and run locally:

```bash
cd python_script_project
docker build -t python-script:v1.0 .
docker run --rm python-script:v1.0
```

## 2) Push image to ECR

Set shared variables:

```bash
REGION=eu-central-1
ACCOUNT_ID=436081123286
IMAGE=python-script
TAG=v1.0
ECR_URI=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:${TAG}
```

Create or update a repository creation template so ECR can auto-create repos on first push. The snippet below is idempotent – it will create the template if it doesn’t exist, or update it otherwise:

```bash
aws ecr create-repository-creation-template \
  --region ${REGION} \
  --prefix ROOT \
  --applied-for CREATE_ON_PUSH \
  --description "Auto-create ECR repos on push" \
|| aws ecr update-repository-creation-template \
  --region ${REGION} \
  --prefix ROOT \
  --applied-for CREATE_ON_PUSH \
  --description "Auto-create ECR repos on push"
```
Build, login, and push:

```bash
python_script_project/scripts/build_ecr_image.sh v1.0
aws ecr get-login-password --region ${REGION} \
  | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
docker push ${ECR_URI}
```

## 3) Deploy with Terragrunt

1. Use the image from env (preferred) or change the default in `tg/dev/batch/python_script/terragrunt.hcl`.
2. Export `IMAGE_URI` before deploy (optional, overrides default):
   `export IMAGE_URI=${ECR_URI}`
3. Deploy Batch resources:

```bash
cd tg/dev/batch/python_script
terragrunt init
terragrunt apply
```

This creates:
- Batch compute environment (`FARGATE_SPOT`)
- Batch job queue
- Batch job definition
- CloudWatch log group `/aws/batch/job/<name>`
- IAM roles

## 4) Trigger on demand

Submit a normal job:

```bash
aws batch submit-job \
  --job-name python-script-run-$(date +%s) \
  --job-queue python-script-queue \
  --job-definition python-script
```

Submit another job (parallel demo):

```bash
aws batch submit-job \
  --job-name python-script-run-2-$(date +%s) \
  --job-queue python-script-queue \
  --job-definition python-script
```

## 5) Observe status and failure reason

Get status:

```bash
aws batch describe-jobs --jobs <job-id>
```

Useful fields:
- `status` (`SUBMITTED`, `RUNNABLE`, `STARTING`, `RUNNING`, `SUCCEEDED`, `FAILED`)
- `statusReason`
- `attempts[].container.exitCode`
- `attempts[].container.reason`
- `attempts[].container.logStreamName`

Read logs:

```bash
aws logs tail /aws/batch/job/python-script --follow
```

## 6) User access for on-demand execution


Provide a minimal IAM policy that allows users to submit and inspect jobs only for this queue and definition.

Example permissions:
- `batch:SubmitJob`
- `batch:DescribeJobs`
- `batch:ListJobs`
- `logs:GetLogEvents`
- `logs:DescribeLogStreams`

Scope resources to:
- `arn:aws:batch:<region>:<account-id>:job-queue/python-script-queue`
- `arn:aws:batch:<region>:<account-id>:job-definition/python-script:*`
- `/aws/batch/job/python-script` log group

## Demo flow (screen share)

1. Show local Docker run success.
2. Show ECR template setup and successful `docker push`.
3. Show `terragrunt apply` output and created Batch resources.
4. Submit two jobs in parallel.
5. Show Batch job statuses and CloudWatch logs.
6. Show IAM policy used by an end-user role for on-demand execution.

## 7) GitHub Actions (Build + Deploy)

Workflows added:
- `.github/workflows/build-ecr-image.yml`
- `.github/workflows/deploy-terragrunt.yml`

Repository configuration needed:
- Secret: `AWS_GHA_ROLE_ARN` (IAM role for GitHub OIDC)
- Variable: `AWS_ACCOUNT_ID`
- Variable: `AWS_REGION` (for example `eu-central-1`)
- Variable: `ECR_REPOSITORY` (for example `python-script`)

Pipeline behavior:
- Push to `main` builds and pushes an image tagged with commit SHA.
- Deploy workflow runs after a successful build and executes `terragrunt apply`.
- Manual deploy is also available via `workflow_dispatch` with optional `image_tag`.
