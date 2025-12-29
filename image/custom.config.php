<?php
$CONFIG = array (  
  'default_phone_region' => 'TW',
  'default_language' => 'zh_TW',
  'force_language' => 'zh_TW',
  'default_locale' => 'zh_TW',
  'force_locale' => 'zh_TW',
  'default_timezone' => 'Asia/Taipei',

  'logtimezone' => 'Asia/Taipei',
  'logfile' => '/var/www/log/nextcloud.log',
  'log_rotate_size' => 10 * 1024 * 1024,
  'logfile_audit' => '/var/www/log/audit.log',
  'cache_path' => '/var/www/cache/nextcloud',
  'skeletondirectory' => '',
  'trashbin_retention_obligation' => 'auto, 30',
  'versions_retention_obligation' => 'auto, 30',
  'activity_expire_days' => 30,

  'preview_imaginary_url' => 'http://imaginary:9000',
  'preview_ffmpeg_path' => '/usr/bin/ffmpeg',
  'preview_ffprobe_path' => '/usr/bin/ffprobe',
  'allow_local_remote_servers' => true,
  'enable_previews' => 'true',
  'jpeg_quality' => 60,
  'preview_max_x' => 2048,
  'preview_max_y' => 2048,
  'preview_max_memory' => 1024,
  'preview_max_filesize_image' => 50,
  'enabledPreviewProviders' =>
  array (
    0 => 'OC\\Preview\\Imaginary',
    1 => 'OC\\Preview\\Movie',
  ),

  'check_for_working_htaccess' => true,
  'maintenance_window_start' => 20,
  'files.chunked_upload.max_size' => 1073741824,
  'knowledgebaseenabled' => false,
  'filesystem_check_changes' => getenv('NEXTCLOUD_CHECK_CHANGE') ?: 0,
);
