import os, json, uuid
import boto3

dynamo = boto3.resource("dynamodb")
table = dynamo.Table(os.environ["TABLE"])

def lambda_handler(event, context):
    method = event.get("httpMethod", "")
    raw_body = event.get("body", "{}")
    if isinstance(raw_body, str):
        body = json.loads(raw_body)
    else:
        body = raw_body
    # POST /todos
    if method == "POST":
        todo_id = str(uuid.uuid4())
        table.put_item(Item={"id": todo_id, **body})
        return {"statusCode":200,"body":json.dumps({"id":todo_id})}

    # GET /todos
    if method == "GET":
        resp = table.scan()
        return {"statusCode":200,"body":json.dumps(resp.get("Items", []))}

    # PATCH /todos
    if method == "PATCH":
        todo_id = body.get("id")
        update_expr = "SET #st = :s"
        expr_values = {":s": body.get("status", "")}
        expr_names  = {"#st": "status"}
        table.update_item(
          Key={"id": todo_id},
          UpdateExpression=update_expr,
          ExpressionAttributeNames=expr_names,
          ExpressionAttributeValues=expr_values
        )
        return {"statusCode":200,"body":"{}"}

    # DELETE /todos
    if method == "DELETE":
        table.delete_item(Key={"id": body.get("id")})
        return {"statusCode":200,"body":"{}"}

    # Fallback
    return {"statusCode":400,"body":"Unsupported method"}
