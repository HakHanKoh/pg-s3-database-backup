# pg-s3-database-backup
Script to remotely backup Postgres database dump to S3


## Setup
### Amazon S3:
1) Create an S3 bucket. Public access is not required
	https://aws.amazon.com/getting-started/hands-on/backup-files-to-amazon-s3/
2) Create an IAM user with permission to AmazonS3
	* Go to Amazon IAM dashboard >> Users, and click 'Add users'
	* In the permissions page, click 'Attach policies directly' and select 'AmazonS3FullAccess' from the list
4) generate Access Key and Secret Key
	* Click into the IAM User's page >> 'Security credentials' tab >> 'Create access key'
	* Copy your access key and secret key
#### Delete files on S3 bucket after a set number of days(optional)
1) Open the bucket's console page
2) Click on the 'Management' tab
3) Click on 'Create lifecycle rule'
4) Choose 'Apply to all objects in the bucket'
5) Check 'Expire current versions of objects'
6) Enter the number of days till deletion
7) Click 'Create rule'
### Database machine:
1) edit `/etc/postgresql/{your postgres version}/main/postgresql.conf`
	Find and set the `listen_addresses` from `localhost` to `'*'`. This will make postgresql automatically listen to incoming connection on any IP assigned to the network interface. Or you could set it to the public IP address of the machine.
2) edit `/etc/postgresql/{your postgres version}/main/pg_hba.conf`
	add the following line to allow all remote connection from all users to connect to all postgresql databases
    ```
    host all all 0.0.0.0/0 md5
    ```
	or
	to allow only a specific user and specific ip to connect one database
    ```
    host  your_database_name  db_username   client_ip_address/32   md5
    ```
3) restart the postgresql service
    ```
    sudo /etc/init.d/postgresql restart
    ```
	  To check status:
    ```
	  sudo systemctl status postgresql
    ```
#### Open inbound port in AWS
This step is necessary if your database is hosted on a AWS EC2 instance.
1) Open the EC2 Management console page
2) Under Network&Security group in the sidemenu, click Security Groups
3) Select your EC2 server and click 'edit inbound rules'
4) Click add new rule
5) Choose Postgresql for Type, 0.0.0.0/0 for Source

### Client/backup machine:
1) install postgres-client on backup machine
    ```
    sudo apt-get update
    sudo apt-get install postgresql-client
    ```
    
To manually test client-host database remote connection:
```
psql --username=pg_username --host=your_host_ip --port=5432 your_database_name
```

#### Add a cronjon
1) Open crontab
	```
	crontab -e
	```
2) Add the following line to run it everyday at 12:01 am
	```
	1 0 * * 0-6 /script_path/backup.sh
	```

	or optionally, you can use the following line instead to redirect cron output to a file
	```
	1 0 * * 0-6 /script_path/backup.sh >> /script_path/cron_log.log
	```
