 <?php
 function endSendOggettoDigitale($checkMdInfoOutput, $webServicesServer) // $filename, $fTime
 {
     try {
         $endSend = array(
             "readInfoOutput" => $checkMdInfoOutput,
             "esito" => true
         );
         
         $client = new SoapClient($webServicesServer . "/MagazziniDigitaliServices/services/EndSendMDPort?wsdl",
             array('exceptions' => true,)
             );
         //         var_dump($client->__getFunctions());
         
         try {
             // NO RESPONSE from call    $readInfoOutput = $client->endSendMDOperation($endSend);
             $client->endSendMDOperation($endSend);
         } catch (SoapFault $e) {
             var_dump("endSendOggettoDigitale: ". $e->faultstring);
            //  var_dump(
            //      $client->__getLastRequestHeaders(),
            //      $client->__getLastRequest(),
            //      $client->__getLastResponseHeaders(),
            //      $client->__getLastResponse()
            //      );
            return;
         }
         
         //         var_dump("readInfoOutput");
         //         var_dump($readInfoOutput);
         
         //         $statoOggettoDigitale = $readInfoOutput->oggettoDigitale->statoOggettoDigitale;
         //         var_dump($statoOggettoDigitale);
         
         //         echo "<br>End send OK";
         
     }
     catch ( Exception $e )
     {
         echo "CheckMD web service in errore o non disponibile: ";
     }
 } // End endSendOggettoDigitale
 
 
 
 function initSendOggettoDigitale($filename, $readInfoInput, $webServicesServer)
 {
     //     var_dump("Sending $filename");
     try {
         $client = new SoapClient($webServicesServer . "/MagazziniDigitaliServices/services/InitSendMDPort?wsdl",
             array('exceptions' => true,)
             );
         //         var_dump($client->__getFunctions());
         
         //         var_dump($readInfoInput);
         //         var_dump($client->__getTypes());
         try {
             $ReadInfoOutput = $client->initSendMDOperation($readInfoInput);
         } catch (SoapFault $e) {
             var_dump("initSendOggettoDigitale: ". $e->faultstring);
            //  var_dump(
            //      $client->__getLastRequestHeaders(),
            //      $client->__getLastRequest(),
            //      $client->__getLastResponseHeaders(),
            //      $client->__getLastResponse()
            //      );
            return null;
         }
         
         //         var_dump("ReadInfoOutput");
         //         var_dump($ReadInfoOutput);
         
         $statoOggettoDigitale = $ReadInfoOutput->oggettoDigitale->statoOggettoDigitale;
         //         var_dump($statoOggettoDigitale);
         
     }
     catch ( Exception $e )
     {
         echo "CheckMD web service in errore o non disponibile";
         return null;
     }
     return $ReadInfoOutput;
 } // End initSendOggettoDigitale
 
 
 
 
 // Richiesto all'interffaccia MD lo stato dell'oggetto che devo inviare
 function webServiceCheckMD($readInfoInput, $webServicesServer)
 {
     
     try {
         $client = new SoapClient($webServicesServer . "/MagazziniDigitaliServices/services/CheckMDPort?wsdl",
             //*array('soap_version'   => SOAP_1_4)
             array('exceptions' => true,)
             );
         //         var_dump($client->__getFunctions());
         //         var_dump($client->__getTypes());
         
         
         try {
             $ReadInfoOutput = $client->checkMDOperation($readInfoInput);
             
         } catch (SoapFault $e) {
             var_dump("webServiceCheckMD: ". $e->faultstring);
            //  var_dump(
            //      $client->__getLastRequestHeaders(),
            //      $client->__getLastRequest(),
            //      $client->__getLastResponseHeaders(),
            //      $client->__getLastResponse()
            //      );
            return null;
         }
         
         //         var_dump("ReadInfoOutput");
         //         var_dump($ReadInfoOutput);
         
         
         return $ReadInfoOutput;
         
     }
     catch ( Exception $e )
     {
         echo "CheckMD web service in errore o non disponibile";
         return null;
     }
     
 } // End webServiceCheckMD
 
 function webServiceAuthenticateSoftware($authentication, $webServicesServer)
 {
     
     try {
        // $client = new SoapClient("http://localhost:8080/MagazziniDigitaliServices/services/AuthenticationSoftwarePort?wsdl",
        $client = new SoapClient($webServicesServer . "/MagazziniDigitaliServices/services/AuthenticationSoftwarePort?wsdl",
        array('exceptions' => true,)
        );
    //     var_dump($client->__getFunctions());
 
        // NO RESPONSE from call    $readInfoOutput = $client->endSendMDOperation($endSend);
         $software = $client->authenticationSoftwareOperation($authentication);
     } catch (SoapFault $e) {
         print("webServiceAuthenticateSoftware: ". $e->faultstring);

        //  var_dump(
        //      $client->__getLastRequestHeaders(),
        //      $client->__getLastRequest(),
        //      $client->__getLastResponseHeaders(),
        //      $client->__getLastResponse()
        //      );
        return null;
     }
     
     //     var_dump("software");
     //     var_dump($software);
     return $software;
 } // End webServiceAuthenticateSoftware
 
 
function sendFile($login, $password, $filename, $webServicesServer)
{
    $authentication = array( // it.depositolegale.www.loginUtenti.AuthenticationUtentiAuthentication authentication
        // "login" => "GS_MD",
        // "password" => "36d4c3e2b842797fa1edfe5f396b896e08cd8f00dc7db16bd473a189a9b063504",
        "login" => $login,
        "password" => $password,
    ); // end authentication
    
    $software = webServiceAuthenticateSoftware ($authentication, $webServicesServer);
    if (isset($software->errorMsg->msgError))
{
    echo "\nERRORE: " . $software->errorMsg->msgError;
    return;
}
    if (! isset($software)) {
        echo "<BR>Invalid Software authentication";
        return;
    }
// var_dump($software);    

    $fTime = filemtime($filename);
    //     echo "fTime: " . $fTime;
    
    $md5 = md5_file($filename);
    $md5_base64 = base64_encode($md5);
    //     echo "<br>MD5: ".$md5;
    //     echo "<br>MD5 base64: " . $md5_base64;
    
    $sha1 = sha1_file($filename);
    $sha1_base64 = base64_encode($sha1);
    
    
    $readInfoInput = array (
        "software" => $software,
        "oggettoDigitale" => array(
            //                 "id" => "",
            "nomeFile" => $filename,
            "digest" => array (
                array(
                    "digestType" => "MD5",
                    "digestValue" => $md5),
                array(
                    "digestType" => "MD5-64Base",
                    "digestValue" => $md5_base64),
                array(
                    "digestType" => "SHA1",
                    "digestValue" => $sha1),
                array(
                    "digestType" => "SHA1-64Base",
                    "digestValue" => $sha1_base64),
            ),
            "ultimaModifica" => $fTime,
        ), // end oggettoDigitale
    ); // end readInfoInput
    
    //         var_dump($readInfoInput);
    
    
    $readInfoOutput = webServiceCheckMD($readInfoInput, $webServicesServer);

    
    $statoOggettoDigitale = $readInfoOutput->oggettoDigitale->statoOggettoDigitale;
    //     var_dump($statoOggettoDigitale);
    
    if ($statoOggettoDigitale == "NONPRESENTE")
    {
        $readInfoOutput = initSendOggettoDigitale($filename, $readInfoInput, $webServicesServer);
        $statoOggettoDigitale = $readInfoOutput->oggettoDigitale->statoOggettoDigitale;
        //         var_dump($statoOggettoDigitale);
        
        if ($statoOggettoDigitale == "INITTRASF")
            endSendOggettoDigitale($readInfoOutput, $webServicesServer); // Non manda risposta
            
            $readInfoOutput = webServiceCheckMD($readInfoInput, $webServicesServer); // Controlliamo se il fine tranfer e' andato a buon fine
            $statoOggettoDigitale = $readInfoOutput->oggettoDigitale->statoOggettoDigitale;
            //         var_dump($statoOggettoDigitale);
            
    }
    
    if ($statoOggettoDigitale == "INITTRASF")
    {
        endSendOggettoDigitale($readInfoOutput, $webServicesServer); // Non manda risposta
        
        $readInfoOutput = webServiceCheckMD($readInfoInput, $webServicesServer); // Controlliamo se il fine tranfer e' andato a buon fine
        $statoOggettoDigitale = $readInfoOutput->oggettoDigitale->statoOggettoDigitale;
    }
    
    if ($statoOggettoDigitale == "FINETRASF")
    {
        $idOggettoDigitale = $readInfoOutput->oggettoDigitale->id;
        echo "\nInviato: $filename";
        echo "\nRicevuta N.: $idOggettoDigitale";
    }
    else
    {
        echo "\nTransfer FAILED for $filename";
    }
} // End sendFile
    

// phpinfo();
// echo "hello arge";

// echo "argc=$argc";

if ($argc < 4)
{
    echo "ERROR, syntax: md_soap_client.php sw_login, sw_password, file_to_upload";
    return 1;
}
// var_dump($argv);

//$filename = "/home/argentino/magazzini_digitali/harvest/tmp.txt";
// $filename = $argv[1];

// print ("Mah ...");

// $sw_login = "GS_MD";
// $sw_password = "36d4c3e2b842797fa1edfe5f396b896e08cd8f0dc7db16bd473a189a9b063504";
// $filename = "/mnt/areaTemporanea/Ingest/80232070583/tmp.txt";

$sw_login = $argv[1];       // GS_MD
// $sw_password = $argv[2];    // ORG 36d4c3e2b842797fa1edfe5f396b896e08cd8f0dc7db16bd473a189a9b063504
// $sw_password_sha256 = hash('sha256', $sw_password);
$sw_password_sha256 = $argv[2]; // pwd gia' in sha256


$filename = $argv[3];
$webServicesServer = $argv[4];


// echo "\nsw_password: " . $sw_password;
echo "\nUtente: " . $sw_login;
// echo "\nsw_password_sha256 = $sw_password_sha256";
// echo "\nFilename: " . $filename;
// echo "\nwebServicesServer: ". $webServicesServer;


sendFile($sw_login, $sw_password_sha256, $filename, $webServicesServer);
echo "\n";
return 0;

?>
