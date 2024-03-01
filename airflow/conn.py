import os
from airflow.models.connection import Connection


conn = Connection(
    conn_id="AWS_DEFAULT",
    conn_type="aws",
    login="XXXX",  # Reference to AWS Access Key ID
    password="XXXXX",  # Reference to AWS Secret Access Key
    extra={
        # Specify extra parameters here
        "region_name": "us-west-2",
        "aws_session_token": "XXXX"
    },
)

# Generate Environment Variable Name and Connection URI
env_key = f"AIRFLOW_CONN_{conn.conn_id.upper()}"
conn_uri = conn.get_uri()
print(f"{env_key}={conn_uri}")
os.environ[env_key] = conn_uri
print(conn.test_connection())  # Validate connection credentials.