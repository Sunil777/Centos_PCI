# Role ```snap```

This roles used to take snapshot of ec2-instnces which having tag ```backup=yes```

Example run:

```
ansible-playbook  deploy.yml --extra-vars  "host=localhost region=$REGION aws_access_key=$AWS_ACCESS_KEY aws_secret_key=$AWS_SECRET_KEY INCREMENTAL=$INCREMENTAL role=snap"

deploy.yml:

- hosts: "{{host}}"
  gather_facts: True
  roles:
    - "{{ role }}"
```
Requirements
------------
```
Ansible version:- 2.4.2.0
boto version :-  boto3
Jinja2 version :- Jinja2
```
Installation
------------
```
pip install -I ansible==2.4.2.0
pip install boto3
pip install --upgrade Jinja2
```
# JOB URL
```
http://10.50.3.46:8080/view/AWSDomainDeployment/job/AWS_Incremental_SnapShot/
```
# JENKINS MASK PASSWD



```
  aws_secret_key: SECRET_KEY
  aws_access_key: ACCESS_KEY
```


# AWS policy

The following is the AWS policy used to run this playbook.


```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:DeleteSnapshot",
                "ec2:CreateVolume",
                "ec2:Describe*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}


```
