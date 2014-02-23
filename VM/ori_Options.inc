{$ALIGN 8}
{$ASSERTIONS ON}

// Расскоментировать для руссификации текстов ошибок
{.$DEFINE RUS}

// todo, not support
{.$DEFINE THREAD_SAFE}
{$DEFINE THREAD_VALUE_SAFE}



/////////// SYNTAX STYLE ///////////////////////
{.$DEFINE NAMESPACE_PHP_STYLE}

(*
   Orion Style:
   module App;

   class Name {

   }
   App:Name::callFunc();
*)

/////////////////////////////////////////////////
// not support
{.$DEFINE USE_WIDESTRING}

{.$DEFINE osLINUX}
{.$DEFINE osMAC}
{$DEFINE osWIN}


// hash Func for Tables
// slowly, but low memory use.
{.$DEFINE USE_maPrime2d}


{$ifdef THREAD_SAFE}

{$else}
   {$UNDEF THREAD_VALUE_SAFE}
{$endif}

{$IFDEF osLINUX}
        {$DEFINE UNIX}
        {$DEFINE UseCThreads}
{$ENDIF}


