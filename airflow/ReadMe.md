## Running Airflow Locally

In order to execute Airflow Locally you should perform these steps

1. [Install Docker and DockerCompose](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)
2. Fill up your AWS Credentials at this [.env file](./airflow/.env) - It will be used to configure SSM as Airflow Secret Store
3. [Install PyEnv](https://github.com/pyenv/pyenv) - optional [link](https://realpython.com/intro-to-pyenv/)
4. Install Linux Dependencies
```bash
sudo apt-get install -y --no-install-recommends \
        freetds-bin \
        krb5-user \
        ldap-utils \
        libsasl2-2 \
        libsasl2-modules \
        locales  \
        lsb-release \
        sasl2-bin \
        sqlite3 \
        unixodbc \
        mysql-server \
        libmysqlclient-dev \
        postgresql \
        libsasl2-dev \
        python3-dev \
        libldap2-dev \
        libssl-dev \
        libpq-dev
```
5. Install Python Dependencies
```
cd airflow
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

6. Fill in the variables `login`, `password`, `aws_session_token` at [conn.py file](./airflow/conn.py) - This will be used to interact with S3 and EMR Clusters

7. Execute the conn.py file to generate the default credential
```bash
cd airflow
python conn.py

# Generated Output
AIRFLOW_CONN_AWS_DEFAULT=aws://XXXX:XXXXX@/?region_name=us-west-2&aws_session_token=XXXX
```

8. Copy the output of the last step and past it on the [docker-compose.yaml](airflow/docker-compose.yaml)

9. Execute the Docker-compose
```bash
cd airflow
docker compose up .
```

10. Wait a couple minutes and access the `localhost:8080`

11. Use the username `airflow` and password `airflow` to access

12. Enjoy!
