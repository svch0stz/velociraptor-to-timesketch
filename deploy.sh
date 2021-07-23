#!/bin/bash 

# Install system requirements
apt install inotify-tools -y 

# Install pip requirements
pip3 install boto3 pytz 

# Install requirements within Timesketch container
docker exec -i timesketch_timesketch-worker_1 /bin/bash -c "pip3 install timesketch-import-client redis==3.4 pyelasticsearch elasticsearch==7.13.1"

# Copy files
cp python/watch-s3-to-timesketch.py /opt/watch-s3-to-timesketch.py
cp bash/watch-to-timesketch.sh /opt/watch-to-timesketch.sh
cp bash/watch-plaso-to-s3.sh /opt/watch-plaso-to-s3.sh

# Fix permissions
chmod +x /opt/watch-plaso-to-s3.sh
chmod +x /opt/watch-to-timesketch.sh

# Make sure Plaso dirs exist
mkdir -p /opt/timesketch/upload/plaso
mkdir -p /opt/timesketch/upload/plaso_complete

# Configure services
cp systemd/data-to-timesketch.service /etc/systemd/system/data-to-timesketch.service
systemctl enable data-to-timesketch.service
systemctl start data-to-timesketch.service

cp systemd/watch-plaso-to-s3.service /etc/systemd/system/watch-plaso-to-s3.service
systemctl enable watch-plaso-to-s3.service
systemctl start watch-plaso-to-s3.service

cp systemd/watch-s3-to-timesketch.service /etc/systemd/system/watch-s3-to-timesketch.service
systemctl enable watch-s3-to-timesketch.service
systemctl start watch-s3-to-timesketch.service

