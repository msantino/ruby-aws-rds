# ruby-aws-rds
Ruby with AWS SDK to manipulate RDS instances. 

Requirements
------------

AWS credential file is needed to use this project. Scripts will look for credentials file under user root directory. 

Installing
----------

To install this code, clone it under any directory and use the following command:
```sh
$ bundle install
```

Output tail log for current file:
```sh
$ ruby read_instance_logs.rb
```

Download available log files:
```sh
$ export RDS_LOG_PATH=/path/to/logfiles/
$ export RDS_PROFILE_NAME=aws-profile-name
$ export RDS_INSTANCE_IDENTIFIER=instance-identifier
$ ruby download_instance_logs.rb 
```