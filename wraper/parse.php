<?

/*
 
    Automatic Generate Wrap Headers Script 1.0
    Author: Dmirtiry Zaytsev /2010
    License: BSD or MIT
    
*/

define(DIR,dirname(__FILE__));
define(DEST_FILE,'../OriWrap.pas');
define(FUNC_INIT_TPL,"      %1 := dlsym(LIB_HANDLE, '%1');");
define(FUNC_DEF_TPL,"       %1: %2 %3");

$template = file_get_contents(DIR.'/template.txt');
$funcs    = file_get_contents(DIR.'/../VM/vmShortApi.pas');

    $funcs = explode(chr(13), str_replace(chr(10),'',$funcs));
    $infos = array();
    
    foreach ($funcs as $i=>$line){
        
        $line = trim($line);
        if (strtolower($line) == 'implementation') break;
        
        if (!$line){ $infos[] = null; continue; }
        $item = array();
        
        if (substr($line,0,2)=='//'){
            $item['name'] = $funcs[$i];
            $item['type'] = '//';
        } else {
            if (stripos($line,'function')===false && stripos($line,'procedure')===false) continue;
            
            $arr = explode('(',$line);
            $name = trim( str_ireplace(array('procedure','function'),'',$arr[0]) );
            $item['name'] = $name;
            $item['type'] = stripos($arr[0],'procedure')!==false ? 'procedure' : 'function';
            $item['params'] = '('.$arr[1];
        }
        $infos[] = $item;
    }
    
    $define_funcs = '';
    $init_funcs   = '';
    foreach ($infos as $item){
        
        if ($item['type'] == '//'){
            $define_funcs .= $item['name'] . "\n";
            $init_funcs   .= $item['name'] . "\n";
        }
        else {
            if ($item !== null){
                $define_funcs .= str_ireplace(array('%1','%2','%3'),array($item['name'],$item['type'],$item['params']),FUNC_DEF_TPL) . "\n";
                $init_funcs   .= str_replace('%1',$item['name'],FUNC_INIT_TPL) . "\n";
            } else {
                $define_funcs .= "\n";
            }
        }
    }
    
    $template = str_ireplace(array('%define_funcs%','%init_funcs%'),array($define_funcs,$init_funcs), $template);
    file_put_contents(DIR.'/'.DEST_FILE, $template);