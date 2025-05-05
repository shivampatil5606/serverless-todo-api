# Serverless To-Do CRUD API
A simple REST API with endpoints to Create, Read, Update, and Delete “To-Do” items.

We use:
- **API Gateway** (REST API) for the HTTP interface
- **AWS Lambda** for business logic (Python 3.9)
- **DynamoDB** (Pay-per-request) for persistence
- **Terraform** for IaC, with a remote S3/DynamoDB backend for shared state
- **GitHub Actions** for CI/CD.

### Why This Architecture?
- Zero servers to patch or scale: AWS handles the Lambda containers and DynamoDB storage for you.
- Infrastructure-as-code: everything is versioned in Git, reproducible, and templatized across environments (dev/stage/prod).
- Separation of concerns: API Gateway handles routing & authorization, Lambda only cares about business logic, DynamoDB concerns itself with fast, scalable key-value reads/writes.

### The Core Components
1. #### API Gateway “REST API”
    - Exposes a single resource path /todos with a “proxy” ANY method—meaning `GET`, `POST`, `PATCH`, `DELETE` all flow through one integration.
    - Automatically generates an SDK-like interface (you get an invoke_url after deployment).
    - Handles request/response transformation, throttling, and (optionally) API keys or Cognito auth.

2. #### AWS Lambda Function
    - Written in Python 3.9, entrypoint todo_handler.lambda_handler.
    - On each invocation it inspects event `["httpMethod"]` to decide:
        - POST: parse JSON body, generate a UUID, write a new item to DynamoDB.
        - GET: scan the table and return all items (or you could extend for GET /todos/{id} to fetch a single item).
        - PATCH: read an ID and updated fields from the body, call UpdateItem.
        - DELETE: remove the item by ID.
    - Gets its environment variable TABLE from Terraform so it never hard-codes resource names.
    - IAM role grants it exact DynamoDB permissions (no more, no less).

3. #### DynamoDB Table
    - A single table called dev-todos (or prod-todos in prod) with a simple hash key id (string).
    - Billing mode: PAY_PER_REQUEST so you don’t worry about capacity.
    - Auto-scales, highly available, and super low latency for reads/writes.

4. #### Terraform Remote State
    - State file stored in S3 (encrypted + versioned).
    - DynamoDB table for state locking.

4. #### CI/CD with GitHub Actions
    - On every push to main, the workflow:
        - Checks out your code.
        - Packages todo_handler.py into todo.zip.
        - Runs terraform fmt/validate to keep your infra clean.
        - terraform init + terraform apply --auto-approve to create/update API Gateway, Lambda, DynamoDB.
    - If you change just the Lambda code, Terraform notices nothing changed infra-wise, so it only updates the function code.
    - Your API remains live the whole time with minimal cold starts.



### Usage & Interaction
1. #### Prerequisites & Setup
```bash
sudo apt-get update
sudo apt-get install -y awscli terraform git python3.9 python3-pip
```

2. #### Configure your AWS credentials
```bash
aws configure
# AWS Access Key ID [None]: YOUR_KEY_ID
# AWS Secret Access Key [None]: YOUR_SECRET
# Default region name [None]: us-east-1
# Default output format [None]: json
```

3. #### Update the source code to trigger GitHub Actions
```bash
git add .
git commit -m "updated the code"
git push origin main
```

4. #### Bootstrapping with Terraform Locally
```bash
# Build Lambda ZIP
mkdir -p build
cd lambda_fn
zip -r ../build/todo.zip todo_handler.py
cd ..
# Terraform init and apply
cd terraform/envs/dev
terraform init
terraform apply -auto-approve
```
5. #### Testing Your API from the CLI
```bash
API_URL=$(terraform output -raw invoke_url)
API_KEY=$(terraform output -raw api_key)

# Create
curl -X POST "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{"task":"Buy groceries","status":"open"}'

# Read
curl -H "x-api-key: $API_KEY" "$API_URL/todos"

# Update
curl -X PATCH "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{"id":"<PASTE_ID>","status":"done"}'

# Delete
curl -X DELETE "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{"id":"<PASTE_ID>"}'
```
