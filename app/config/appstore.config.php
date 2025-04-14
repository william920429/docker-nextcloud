<?php
if (getenv('NEXTCLOUD_APPSTORE')) {
  $CONFIG = array(
    'appstoreenabled' => true,
    'appstoreurl' => getenv('NEXTCLOUD_APPSTORE'),
  );
}

