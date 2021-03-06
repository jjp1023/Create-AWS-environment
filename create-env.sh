#!/bin/bash
if [ -z ${5+x} ]; 
then 
	echo "Error You didn't provide all the needed Variables!"
	echo "Look at the example needed below"
	echo "EX: ./create-env.sh ami-06b94666 Jiggy sg-91e12ae8 apache-conf 3
	   NAME                  Default Value
	1. AMI ID 		 ami-06b94666
	2. key-name		 Jiggy
	3. security-group	 sg-91e12ae8
	4. launch-configuration  apache-conf
	5. count		 3";
else 
	echo "Creating a load balancer"
	LBNAME=`aws elb create-load-balancer --load-balancer-name apache-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets subnet-88f6acec --security-groups sg-91e12ae8`
	sleep 2
	echo "Creating Launch Config"
	aws autoscaling create-launch-configuration --launch-configuration-name $4 --image-id $1 --security-groups sg-91e12ae8 --key-name $2 --instance-type t2.micro --user-data file://installenv.sh
	sleep 2
	echo "Creating auto scaling group"
	aws autoscaling create-auto-scaling-group --auto-scaling-group-name apache-auto --launch-configuration apache-conf --availability-zone us-west-2b --load-balancer-name apache-lb --max-size 5 --min-size 2 --desired-capacity $5
	echo "Attaching Load balancer and launching instances"
	aws autoscaling attach-load-balancers --load-balancer-names apache-lb --auto-scaling-group-name apache-auto
	echo "Lets wait for the instances to run"
	ID=
	ID=`aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId]' | grep -E 'running|pending' | awk '{print $3}'`
	aws ec2 wait instance-running --instance-ids $ID
	sleep 15
	echo "Load balancers live on: " $LBNAME
	echo "But please wait atleast a minute before accessing"
fi
