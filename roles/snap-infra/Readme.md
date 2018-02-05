Ansible Roles for AWS Infrastructure Creation :-
===========


Ansible role to launch ec2-instaces by snapshot.

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

Role Variables
--------------

Some available variables are listed below, these are provided at runtime :-

```
elb_name:
region: 
ec2_key_name: 
ec2_instance_type: 
server: 
env: prod
expday: 
ec2_assign_public_ip: 
stack:
```

Steps Performed
---------------
```
1. Creating ELB.
2. Find the latest snapshot of provided stack
3. Convert snapshot into AMI
4. Launch ec2-instace using AMI in provided subnet
5. Store daynamic host and variable of launced instances
6. Install All PCI related tasks to launched server.
7. Attach instances to ELB.
```


Example Playbook
----------------

```

ansible-playbook  deploy.yml --extra-vars  "host=localhost INCREMENTAL=$INCREMENTAL PORT=$PORT ec2_assign_public_ip=$IP
path=$WORKSPACE USER=$USER ossec_server_ip=$OSSEC_SERVER PASSWD=$ANSIBLE_SSH_PASS   ec2_count=$EC2_COUNT ec2_sg_id=${EC2_SG_ID}  
elb_name=$ELB_NAME  ec2_monitoring=$MONITORING ec2_vpc_subnet_id=$EC2_VPC_SUBNET_ID  Creater=$CAUSE 
stack=$STACK aws_access_key=$AWS_ACCESS_KEY aws_secret_key=$AWS_SECRET_KEY region=$REGION ec2_key_name=$KEYNAME
ec2_instance_type=$INSTANCE_TYPE server=$STACK env=$ENV expday=$DAY role=snap-infra"
```

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

deploy.yml:
```
- hosts: "{{host}}"
  gather_facts: True
  roles:
    - "{{ role }}"
```

JOB URL
-------
```
http://10.50.3.46:8080/view/AWSDomainDeployment/job/AWS_DR_By_Snapshot/
```
Pre-Requirement
--------------
```
- VPC
- Subnet
- Security Group (Default will be Ansible Security Group)
```

Post Tasks
----------
```
- Updatation of config.php according to new changes located at Ansible server 
- Deploy master on all server's
```

Deployment JOB:
--------------
```
http://10.50.3.46:8080/view/AWSDomainDeployment/job/AWSPayuBizDeploy-AllDomain/

```

Estimated time taken for all process
-----------------------------------
```
Time taken at Mock drill(For Infra) :-  5 min 36 sec 
Time to config changes :- 1-2 min
Time taken to Deploy code :- 4 min
```


Author Information
------------------

Sunil Malik




