<?


$dir = dirname(__FILE__);
require $dir . '/file.php';



$musor = findFiles($dir,array('dcu','bak','o','ppu','local','exe','lrs','~dsk'),true,true);

foreach($musor as $file)
    unlink($file);
    
    
rmdir_recursive($dir.'/__history');
rmdir_recursive($dir.'/project/__history');
rmdir_recursive($dir.'/project/backup');
rmdir_recursive($dir.'/backup');
rmdir_recursive($dir.'/libs/backup');
rmdir_recursive($dir.'/VM/__history');
rmdir_recursive($dir.'/VM/backup');
rmdir_recursive($dir.'/VM/funcs/__history');
rmdir_recursive($dir.'/VM/funcs/backup');

