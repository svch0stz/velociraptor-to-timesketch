# Watch this directory for new files (ie: vr_kapetriage_$system.zip added to /opt/IR_data)
PARENT_DATA_DIR="/opt/timesketch/upload"

process_files () {
    ZIP=$1
    
    # Get system name
    SYSTEM=$(echo $ZIP|cut -d"." -f 1)
    
    # Unzip
    echo A | unzip $PARENT_DATA_DIR/$ZIP -d $PARENT_DATA_DIR/$SYSTEM
    
    # Remove from subdir
    mv $PARENT_DATA_DIR/$SYSTEM/fs/clients/*/collections/*/uploads/* $PARENT_DATA_DIR/$SYSTEM/
    
    # Delete unnecessary collection data
    rm -r $PARENT_DATA_DIR/$SYSTEM/fs $PARENT_DATA_DIR/$SYSTEM/UploadFlow.json $PARENT_DATA_DIR/$SYSTEM/UploadFlow 
    
    # Make sure Plaso dirs exist
    mkdir -p /opt/timesketch/upload/plaso
    mkdir -p /opt/timesketch/upload/plaso_complete
    
    # Install requirements
    docker exec -i timesketch_timesketch-worker_1 /bin/bash -c "pip3 install timesketch-import-client redis==3.4 pyelasticsearch elasticsearch==7.13.1"
    
    # Run log2timeline and generate Plaso file
    docker exec -i timesketch_timesketch-worker_1 /bin/bash -c "log2timeline.py --status_view window --storage_file /usr/share/timesketch/upload/plaso/$SYSTEM.plaso /usr/share/timesketch/upload/$SYSTEM"

    # Run timesketch_importer to send Plaso data to Timesketch
    docker exec -it timesketch_timesketch-worker_1 /bin/bash -c "echo $SYSTEM | timesketch_importer --sketch_id 1 /usr/share/timesketch/upload/plaso/$SYSTEM.plaso"

    # Copy Plaso files to dir being watched to upload to S3
    cp -ar /usr/share/timesketch/upload/plaso/$SYSTEM.plaso /usr/share/timesketch/upload/plaso_complete
}

inotifywait -m -r -e move "$PARENT_DATA_DIR" --format "%f" | while read ZIP
do
  extension="${ZIP##*.}"
  if [[ $extension == "zip" ]]; then
    process_files $ZIP &
  fi
done
