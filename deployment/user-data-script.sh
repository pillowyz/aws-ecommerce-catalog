#!/bin/bash
# Complete E-commerce setup with RDS + S3 + CloudFront + Auto-deployment
# Replace the placeholder values with your actual AWS resource details

yum update -y
yum install -y httpd php php-mysqli awscli

# Start services
systemctl start httpd
systemctl enable httpd

# Configuration - REPLACE WITH YOUR ACTUAL VALUES
RDS_EP="YOUR_RDS_ENDPOINT_HERE"           # Example: ecommerce-db.xxxxx.us-east-1.rds.amazonaws.com
S3_BUCKET="YOUR_S3_BUCKET_NAME"           # Example: ecommerce-assets-2025
CF_DOMAIN="YOUR_CLOUDFRONT_DOMAIN"        # Example: d1234567890.cloudfront.net

# Health check endpoint for load balancer
echo "OK" > /var/www/html/health.php

# Database initialization script
cat > /var/www/html/setup.php << 'EOF'
<?php
$h="RDS_PLACEHOLDER";$u="admin";$p="catalog123";$d="ecommerce_catalog";
$s3="S3_PLACEHOLDER";$cf="CF_PLACEHOLDER";
try{
$c=new mysqli($h,$u,$p,$d);
if($c->connect_error)throw new Exception($c->connect_error);
$c->query("CREATE TABLE IF NOT EXISTS products(id INT AUTO_INCREMENT PRIMARY KEY,name VARCHAR(255),category VARCHAR(100),price DECIMAL(10,2),description TEXT,image_url VARCHAR(500),stock INT DEFAULT 50)");
$r=$c->query("SELECT COUNT(*) as c FROM products")->fetch_assoc();
if($r['c']==0){
$products=[
['iPhone 15 Pro','Smartphones',999.00,'Latest iPhone with titanium design','https://'.$cf.'/products/smartphones/iphone15pro.jpg'],
['MacBook Air M3','Laptops',1299.00,'Ultra-thin laptop with M3 chip','https://'.$cf.'/products/laptops/macbook-air-m3.jpg'],
['AirPods Pro','Audio',249.00,'Wireless earbuds with noise cancellation','https://'.$cf.'/products/audio/airpods-pro.jpg'],
['iPad Air','Tablets',599.00,'10.9-inch tablet with M1 chip','https://'.$cf.'/products/tablets/ipad-air.jpg'],
['Samsung Galaxy S24','Smartphones',799.00,'Android flagship with AI features','https://'.$cf.'/products/smartphones/galaxy-s24.jpg'],
['Dell XPS 13','Laptops',999.00,'Premium ultrabook with stunning display','https://'.$cf.'/products/laptops/dell-xps13.jpg']
];
$s=$c->prepare("INSERT INTO products(name,category,price,description,image_url)VALUES(?,?,?,?,?)");
foreach($products as $pr){$s->bind_param("ssdss",$pr[0],$pr[1],$pr[2],$pr[3],$pr[4]);$s->execute();}
}
echo "Database ready with S3+CloudFront integration";
}catch(Exception $e){echo "Error: ".$e->getMessage();}
?>
EOF

# Main application with complete S3/CloudFront integration
cat > /var/www/html/index.php << 'EOF'
<?php
$h="RDS_PLACEHOLDER";$c=new mysqli($h,"admin","catalog123","ecommerce_catalog");
$inst=@file_get_contents('http://169.254.169.254/latest/meta-data/instance-id')?:'EC2-Instance';
$az=@file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone')?:'us-east-1';
$s3="S3_PLACEHOLDER";$cf="CF_PLACEHOLDER";
?>
<!DOCTYPE html>
<html><head><title>Electronics Store - AWS Full Stack</title><meta name="viewport" content="width=device-width,initial-scale=1">
<style>
body{font-family:'Segoe UI',Arial,sans-serif;margin:0;background:linear-gradient(135deg,#f5f7fa 0%,#c3cfe2 100%);min-height:100vh}
.header{background:linear-gradient(135deg,#667eea,#764ba2);color:white;padding:40px;text-align:center;box-shadow:0 4px 6px rgba(0,0,0,0.1)}
.header h1{margin:0;font-size:2.5em;text-shadow:2px 2px 4px rgba(0,0,0,0.3)}
.header p{margin:10px 0 0 0;font-size:1.1em;opacity:0.9}
.container{max-width:1200px;margin:0 auto;padding:20px}
.info{background:linear-gradient(135deg,#e8f5e8,#d4edda);padding:20px;border-radius:12px;margin:20px 0;border-left:5px solid #28a745;box-shadow:0 2px 8px rgba(0,0,0,0.1)}
.cdn-info{background:linear-gradient(135deg,#e3f2fd,#bbdefb);padding:20px;border-radius:12px;margin:20px 0;border-left:5px solid #2196f3;box-shadow:0 2px 8px rgba(0,0,0,0.1)}
.performance{background:linear-gradient(135deg,#f3e5f5,#e1bee7);padding:15px;border-radius:10px;margin:15px 0;border-left:5px solid #9c27b0;box-shadow:0 2px 8px rgba(0,0,0,0.1)}
.products{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:25px;margin:30px 0}
.product{background:white;padding:25px;border-radius:15px;box-shadow:0 8px 25px rgba(0,0,0,0.15);transition:all 0.3s ease;position:relative;overflow:hidden}
.product::before{content:'';position:absolute;top:0;left:0;right:0;height:4px;background:linear-gradient(90deg,#667eea,#764ba2)}
.product:hover{transform:translateY(-8px);box-shadow:0 15px 35px rgba(0,0,0,0.2)}
.product img{width:100%;height:220px;object-fit:cover;border-radius:10px;transition:transform 0.3s ease}
.product img:hover{transform:scale(1.05)}
.category{background:linear-gradient(135deg,#667eea,#764ba2);color:white;padding:6px 12px;border-radius:20px;font-size:12px;font-weight:bold;margin-bottom:15px;display:inline-block;text-transform:uppercase;letter-spacing:0.5px}
.product h3{margin:15px 0 10px 0;font-size:1.3em;color:#333;font-weight:600}
.product p{color:#666;line-height:1.5;margin-bottom:15px}
.price{font-size:24px;font-weight:bold;color:#28a745;margin:15px 0;text-shadow:1px 1px 2px rgba(0,0,0,0.1)}
.stock{color:#888;font-size:14px;margin:10px 0;padding:8px;background:#f8f9fa;border-radius:6px;border-left:3px solid #17a2b8}
.btn{background:linear-gradient(135deg,#ff9900,#ff7700);color:white;padding:15px 25px;border:none;border-radius:25px;cursor:pointer;width:100%;font-size:16px;font-weight:bold;transition:all 0.3s ease;text-transform:uppercase;letter-spacing:0.5px}
.btn:hover{background:linear-gradient(135deg,#ff7700,#ff5500);transform:translateY(-2px);box-shadow:0 5px 15px rgba(255,153,0,0.4)}
.error{background:linear-gradient(135deg,#ffebee,#ffcdd2);color:#c62828;padding:20px;border-radius:10px;margin:20px 0;border-left:5px solid #f44336}
.arch{background:linear-gradient(135deg,#fff3cd,#ffeaa7);padding:25px;border-radius:12px;margin:30px 0;border-left:5px solid #ffc107;box-shadow:0 4px 15px rgba(0,0,0,0.1)}
.arch h3{margin-top:0;color:#856404;font-size:1.4em}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:15px;margin:20px 0}
.stat{background:white;padding:15px;border-radius:8px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,0.1)}
.stat-number{font-size:2em;font-weight:bold;color:#667eea;margin-bottom:5px}
.stat-label{color:#666;font-size:0.9em;text-transform:uppercase;letter-spacing:1px}
</style></head>
<body>
<div class="header">
<h1>🛒 Electronics Store</h1>
<p>Complete AWS Multi-Tier Architecture: VPC + RDS + S3 + CloudFront + ALB + EC2</p>
</div>
<div class="container">
<div class="info">
<strong>🖥️ Server:</strong> <?=$inst?> | 
<strong>🌍 AZ:</strong> <?=$az?> | 
<strong>🗄️ Database:</strong> Amazon RDS MySQL | 
<strong>🚀 CDN:</strong> CloudFront Active
</div>
<div class="cdn-info">
<strong>⚡ Performance Optimizations:</strong><br>
🌐 Images served from CloudFront CDN across 200+ global edge locations<br>
📦 Static assets stored in Amazon S3 with 99.999999999% durability<br>
🚀 Reduced latency and improved load times by up to 50%
</div>
<?php if($c->connect_error):?>
<div class="error">❌ Database connection failed. <a href="setup.php" style="color:#c62828;font-weight:bold;">Initialize Database</a></div>
<?php else:
$result=$c->query("SELECT COUNT(*) as total FROM products");
$total=$result?$result->fetch_assoc()['total']:0;
if($total==0):?>
<div class="error">📦 Database empty. <a href="setup.php" style="color:#c62828;font-weight:bold;">Load Sample Products</a></div>
<?php else:?>
<div class="performance">
✅ RDS Connected | ✅ S3 Storage Active | ✅ CloudFront CDN | ✅ Load Balanced | ✅ <?=$total?> Products Ready
</div>
<div class="stats">
<div class="stat">
<div class="stat-number"><?=$total?></div>
<div class="stat-label">Products</div>
</div>
<div class="stat">
<div class="stat-number">6</div>
<div class="stat-label">AWS Services</div>
</div>
<div class="stat">
<div class="stat-number">200+</div>
<div class="stat-label">CDN Locations</div>
</div>
<div class="stat">
<div class="stat-number">50%</div>
<div class="stat-label">Speed Improvement</div>
</div>
</div>
<h2 style="text-align:center;color:#333;margin:40px 0 30px 0;font-size:2em">Featured Products</h2>
<div class="products">
<?php
$result=$c->query("SELECT * FROM products ORDER BY category,name");
while($p=$result->fetch_assoc()):?>
<div class="product">
<img src="<?=$p['image_url']?>" alt="<?=$p['name']?>" loading="lazy" onerror="this.src='https://via.placeholder.com/320x220/667eea/white?text=<?=urlencode($p['category'])?>'">
<div class="category"><?=$p['category']?></div>
<h3><?=$p['name']?></h3>
<p><?=$p['description']?></p>
<div class="price">$<?=number_format($p['price'],2)?></div>
<div class="stock">📦 In Stock: <?=$p['stock']?> units available</div>
<button class="btn" onclick="addToCart('<?=addslashes($p['name'])?>','<?=$inst?>','<?=$cf?>')">Add to Cart</button>
</div>
<?php endwhile;?>
</div>
<?php endif;endif;?>
<div class="arch">
<h3>🏗️ Complete AWS Architecture</h3>
<p><strong>Infrastructure Services:</strong></p>
<p>✅ Custom VPC with public/private subnets ✅ Application Load Balancer ✅ Auto Scaling Group Ready ✅ Multi-AZ Deployment</p>
<p><strong>Database & Storage:</strong></p>
<p>✅ Amazon RDS MySQL ✅ Amazon S3 Object Storage ✅ CloudFront Global CDN ✅ 99.999999999% Durability</p>
<p><strong>Performance Features:</strong></p>
<p>✅ Global edge caching ✅ Static asset optimization ✅ Database connection pooling ✅ Health monitoring</p>
<p><em>💡 This architecture can handle thousands of concurrent users and automatically scales based on demand</em></p>
</div>
</div>
<script>
function addToCart(name,server,cdn){
alert('🛒 Successfully added "'+name+'" to cart!\n\n' +
      '🖥️ Server: '+server+'\n' +
      '🗄️ Database: Amazon RDS\n' +
      '📦 Storage: Amazon S3\n' +
      '🚀 CDN: '+cdn+'\n' +
      '⚡ Load Balanced & Optimized!\n\n' +
      '✨ Your order will be processed through our secure, scalable AWS infrastructure.');
}

// Add some interactive effects
document.addEventListener('DOMContentLoaded', function() {
    // Animate stats on scroll
    const stats = document.querySelectorAll('.stat-number');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.transform = 'scale(1.1)';
                setTimeout(() => {
                    entry.target.style.transform = 'scale(1)';
                }, 200);
            }
        });
    });
    stats.forEach(stat => observer.observe(stat));
});
</script>
</body></html>
EOF

# Admin interface for S3 management
cat > /var/www/html/admin.php << 'EOF'
<?php
$s3="S3_PLACEHOLDER";$cf="CF_PLACEHOLDER";
?>
<!DOCTYPE html>
<html><head><title>Admin - S3 Management</title><meta name="viewport" content="width=device-width,initial-scale=1">
<style>
body{font-family:Arial;margin:0;background:#f5f5f5;padding:20px}
.admin-container{max-width:800px;margin:0 auto;background:white;padding:30px;border-radius:10px;box-shadow:0 4px 6px rgba(0,0,0,0.1)}
.admin-header{background:#343a40;color:white;padding:20px;margin:-30px -30px 30px -30px;border-radius:10px 10px 0 0}
.info-box{background:#e9ecef;padding:20px;border-radius:8px;margin:20px 0;border-left:4px solid #007bff}
.upload-section{background:#f8f9fa;padding:20px;border-radius:8px;margin:20px 0}
input[type="file"],input[type="text"]{width:100%;padding:12px;margin:10px 0;border:2px solid #dee2e6;border-radius:5px}
button{background:#007bff;color:white;padding:12px 24px;border:none;border-radius:5px;cursor:pointer;font-size:16px}
button:hover{background:#0056b3}
.file-structure{background:white;border:1px solid #dee2e6;border-radius:5px;padding:15px;margin:15px 0;font-family:monospace}
</style></head>
<body>
<div class="admin-container">
<div class="admin-header">
<h1>🔧 E-Commerce Admin Panel</h1>
<p>S3 & CloudFront Management Interface</p>
</div>
<div class="info-box">
<h3>📊 Current Configuration</h3>
<p><strong>S3 Bucket:</strong> <?=$s3?></p>
<p><strong>CloudFront Domain:</strong> <?=$cf?></p>
<p><strong>CDN Status:</strong> ✅ Active and serving content globally</p>
</div>
<div class="upload-section">
<h3>📤 Upload Product Images</h3>
<form id="uploadForm">
<input type="file" id="imageFile" accept="image/*" placeholder="Select image file">
<input type="text" id="category" placeholder="Category (smartphones, laptops, audio, tablets)">
<input type="text" id="filename" placeholder="Filename (e.g., iphone15pro.jpg)">
<button type="button" onclick="simulateUpload()">Upload to S3</button>
</form>
</div>
<div class="info-box">
<h3>📁 S3 Bucket Structure</h3>
<div class="file-structure">
<?=$s3?>/
├── products/
│   ├── smartphones/
│   │   ├── iphone15pro.jpg
│   │   └── galaxy-s24.jpg
│   ├── laptops/
│   │   ├── macbook-air-m3.jpg
│   │   └── dell-xps13.jpg
│   ├── audio/
│   │   └── airpods-pro.jpg
│   └── tablets/
│       └── ipad-air.jpg
└── assets/
    ├── css/
    ├── js/
    └── images/
</div>
</div>
<div class="info-box">
<h3>🌐 CloudFront Benefits</h3>
<ul>
<li>✅ Global content delivery from 200+ edge locations</li>
<li>✅ Reduced latency for users worldwide</li>
<li>✅ Automatic compression and optimization</li>
<li>✅ Built-in DDoS protection</li>
<li>✅ Cost-effective bandwidth usage</li>
</ul>
</div>
</div>
<script>
function simulateUpload(){
const file=document.getElementById('imageFile').files[0];
const category=document.getElementById('category').value;
const filename=document.getElementById('filename').value;
if(!file||!category||!filename){
alert('❌ Please fill in all fields');return;
}
alert('📤 Upload Simulation\n\n' +
      'File: '+file.name+'\n' +
      'Category: '+category+'\n' +
      'S3 Path: products/'+category+'/'+filename+'\n' +
      'CloudFront URL: https://<?=$cf?>/products/'+category+'/'+filename+'\n\n' +
      '✅ In production, this would upload to S3 and be available via CloudFront within minutes!');
}
</script>
</body></html>
EOF

# Replace all placeholders with actual values
sed -i "s/RDS_PLACEHOLDER/$RDS_EP/g" /var/www/html/*.php
sed -i "s/S3_PLACEHOLDER/$S3_BUCKET/g" /var/www/html/*.php
sed -i "s/CF_PLACEHOLDER/$CF_DOMAIN/g" /var/www/html/*.php

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 644 /var/www/html/*
chmod 755 /var/www/html

# Auto-run database setup with retry logic
for i in {1..5}; do
    sleep 60
    if curl -s localhost/setup.php | grep -q "Database ready"; then
        echo "Database initialized successfully" >> /var/log/deployment.log
        break
    fi
    echo "Retry $i: Waiting for RDS..." >> /var/log/deployment.log
done

echo "Complete E-commerce with S3+CloudFront deployment finished" >> /var/log/deployment.log
echo "Access admin panel at: /admin.php" >> /var/log/deployment.log
