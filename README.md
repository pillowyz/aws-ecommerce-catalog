<h1>AWS E-Commerce Catalog</h1>

<h2>Description</h2>

A scalable e-commerce catalog application built on AWS, demonstrating multi-tier cloud architecture with auto-scaling, load balancing, and content delivery optimization.
<br />

<h2>Architecture Overview</h2>

- <b>Web Tier:</b> Auto-scaling EC2 instances behind an Application Load Balancer
- <b>Application Tier:</b> PHP-based catalog with product search and filtering
- <b>Data Tier:</b> MySQL database with optimized queries
- <b>Storage:</b> S3 bucket for static assets and product images
- <b>CDN:</b> CloudFront distribution for global content delivery
- <b>Monitoring:</b> CloudWatch metrics and auto-scaling policies

<p align="left">
<b>Architecture Diagram:</b> <br/>
<img src=https://i.imgur.com/uh2akuG.png>  

<h2>Services Used</h2>

- <b>EC2</b> 
- <b>S3</b>
- <b>CloudFront</b>
- <b>Application Load Balancer</b>
- <b>Auto Scaling Groups</b>
- <b>CloudWatch</b>

<h2>Prerequisites</h2>

- <b>AWS Account with appropriate permissions</b>
- <b>Basic knowledge of AWS Console</b>
- <b>SSH key pair for EC2 access</b>

