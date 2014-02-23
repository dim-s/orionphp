<?


function shortName($file){
    global $progDir;
    if (file_exists($progDir.'\\'.$file))
        return $progDir.'\\'.$file;
    else
        return $file;
}

// ���������� ����� ��� ������� ".", ��� ��������� � ������ ������� ��� ��������
// ���������
function fileExt($file){
    $file = basename($file);
    $k = strrpos($file,'.');
    if ($k===false) return '';
    return strtolower(substr($file, $k+1, strlen($file)-$k-1));
}

// ���������� true ���� ���� $file ���������� $ext, ���� ��� ���������� �������
// � ������� $ext. $ext - ������ ��� ������
function checkExt($file, $ext){
    $file_ext = fileExt($file);
    
    
    if (is_array($ext)){
        foreach ($ext as $item){
            $item = str_replace('.', '', strtolower(trim($item)));
            if ($item == $file_ext) return true;
        }
    } else {
        $ext = str_replace('.', '', strtolower(trim($ext)));
        if ($ext == $file_ext) return true;
    }
    
    return false;
}

// ���������� �������� ����� ��� ����������
function basenameNoExt($file){
    $file = basename($file);
    $ext = fileExt($file);
    return str_ireplace('.' . $ext, '', $file);
}


function getFileName($str, $check = true){
    
    if ($check && function_exists('resFile')){
        
        return resFile($str);
    }
    
    $last_s = $str;
    if (!file_exists($str))
        $str = DOC_ROOT .'/'. $str;
        
    if (!file_exists($str))
        $str = $last_s;
    else
        $str = str_replace('/', DIRECTORY_SEPARATOR, $str);
        
    return $str;
}

// ����� ������ � �����... � ��������� �� ����.
// ����� ������ �� ���������� exts - ������ ����������
function findFiles($dir, $exts = null, $recursive = false, $with_dir = false){
    //$dir = replaceSl($dir);
    
    $result = array();
    $check_ext = $exts;
    if (!file_exists($dir)) return array();
    
    if ($handle = @opendir($dir))
        while (($file = readdir($handle)) !== false){
            
            if ($file == '.' || $file == '..') continue;
            if (is_file($dir . '/' . $file)){
                
                if ($check_ext){
                    if (checkExt($file, $exts))
                        $result[] = $with_dir ? $dir .'/'. $file : $file;
                } else {
                    $result[] = $with_dir ? $dir .'/'. $file : $file;
                }
            } elseif ($recursive && is_dir($dir . '/' . $file)){
                
                $result = array_merge($result, findFiles($dir . '/' . $file, $exts, true, $with_dir));
            }
        }
    
    return $result;
}

function findDirs($dir){
    
    //$dir = replaceSl($dir);
    
    if (!is_dir($dir)) return array();
    
    $files = scandir($dir);
    array_shift($files); // remove �.� from array
    array_shift($files); // remove �..� from array
    
    $result = array();
    foreach ($files as $file){
        
        if (is_dir($dir .'/'. $file)){
            
            $result[] = $file;
        }
    }
    return $result;
}

function rmdir_recursive($dir) {
    //$dir = replaceSl($dir);
    
    if (!is_dir($dir)) return false;
    
    $files = scandir($dir);
    array_shift($files); // remove �.� from array
    array_shift($files); // remove �..� from array
    
    foreach ($files as $file) {
        $file = $dir . '/' . $file;
        if (is_dir($file)) {
            rmdir_recursive($file);
        
        if (is_dir($file))
            rmdir($file);
        } else {
            unlink($file);
        }
    }
    rmdir($dir);
}

function deleteDir($dir, $dir_del = true, $exts = null){
    
    //$dir = replaceSl($dir);
    $files = findFiles($dir, $exts, true, true);
    
    foreach ($files as $file){
        
        if (file_exists($file))
            unlink($file);
    }
    
    if ($dir_del)
        rmdir_recursive($dir);
}

function include_ex($file){
    
    $file = getFileName($file);
    include_enc($file);
}

function fileLock($file){
    
    $file = getFileName($file);
    $fp = fopen($file, "a");
    flock($fp, LOCK_SH);
    $GLOBALS['__fileLock'][$file] = $fp;
}

function fileUnlock($file){
    
    $file = getFileName($file);
    
    if (isset($GLOBALS['__fileLock'][$file]))
        flock($GLOBALS['__fileLock'][$file], LOCK_UN);
}

function dirLock($dir, $exts = null){
    
    $files = findFiles($dir, $exts, true, true);
    foreach ($files as $file)
        fileLock($file);
}

function dirUnlock($dir, $exts = null){
    $files = findDirs($dir, $exts, true, true);
    foreach ($files as $file)
        fileUnlock($file);
}


function file_p_contents($file, $data){
    
    $file = replaceSl($file);
    $dir  = dirname($file);
    
    if (!file_exists($dir))
        mkdir($dir, 0777, true);
    
    return file_put_contents($file, $data);    
}

function x_copy($from, $to){
    
    $from = replaceSl($from);
    $to   = replaceSl($to);
    $dir  = dirname($to);
    
    if (!file_exists($dir))
        mkdir($dir, 0777, true);
        
    return copy($from, $to);
}

function x_move($from, $to){
    
    $x = 0;
    while (!x_copy($from, $to)){
        if ($x>30){
            break;
        }
        $x++;
    }
    
    $x = 0;
    while (!unlink($from)){
        if ($x>30)
            break;
        $x++;
    }
}