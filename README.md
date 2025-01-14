# VPC-Module-Terraform

This repository is a challenge I gave myself to convert the manually-created AWS resources from this video from [Free Code Camp](https://www.freeCodeCamp.org)
<br >

[![Free Code Camp YouTube Video Link](https://img.youtube.com/vi/g2JOHLHh4rI/0.jpg)](https://www.youtube.com/watch?v=g2JOHLHh4rI)

I have used Pulumi in the past and wanted to get more familiar with HCL.

If you use this repository, be sure to verify that the AMI used is available in your region (and still free tier) or that you are OK with creating things in the us-west-2 region. Also make sure to not use the elastic IP and NAT Gateway if you are trying to do this for free. Elastic IPs **will** cost money.

Currently the user-data.txt file does not work. I'll revisit that later.
