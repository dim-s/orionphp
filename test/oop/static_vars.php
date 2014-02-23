class IURa {

    static public $ex = 20;
    static $prop;
}

class URa extends IUra {
    
    static $var;
    static $var1 = 2.5;
    static public $var2 = 'abcd';
    static $var3 = true;
}

assert( URa::$ex !== 20, __LINE__ );
assert( URa::$var !== null, __LINE__ );
assert( URa::$var1 !== 2.5, __LINE__ );
assert( URa::$var2 !== 'abcd', __LINE__ );
assert( URa::$var3 !== true, __LINE__ );

URa::$prop = 'any';
assert( URa::$prop !== 'any', __LINE__ );
assert( IURa::$prop !== 'any', __LINE__ );